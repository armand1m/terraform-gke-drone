provider "google" {}
provider "random" {}
provider "kubernetes" {
  host                   = google_container_cluster.ci.endpoint
  username               = google_container_cluster.ci.master_auth[0].username
  password               = google_container_cluster.ci.master_auth[0].password
  client_key             = base64decode(google_container_cluster.ci.master_auth[0].client_key)
  client_certificate     = base64decode(google_container_cluster.ci.master_auth[0].client_certificate)
  cluster_ca_certificate = base64decode(google_container_cluster.ci.master_auth[0].cluster_ca_certificate)
}

variable "domain_name" { type = string }
variable "drone_github_client_id" { type = string }
variable "drone_github_client_secret" { type = string }

locals {
  drone_secrets_name   = "drone-secrets"
  drone_configmap_name = "drone-config"
}

resource "random_password" "drone_server_secret" {
  length  = 16
  special = false
}

resource "random_password" "cluster_password" {
  length  = 16
  special = true
}

resource "google_container_cluster" "ci" {
  name                     = "ci-cluster"
  initial_node_count       = 1
  remove_default_node_pool = true

  master_auth {
    username = "gke-master"
    password = random_password.cluster_password.result

    client_certificate_config {
      issue_client_certificate = true
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "ci-cluster-pool"
  cluster    = google_container_cluster.ci.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_compute_disk" "ci" {
  name = "drone-server-sqlite"
  size = 5
}

resource "google_dns_managed_zone" "main" {
  name        = "main-zone"
  dns_name    = "${var.domain_name}."
  description = "Main DNS Zone"
}

resource "google_dns_record_set" "cname" {
  name         = "www.${google_dns_managed_zone.main.dns_name}"
  managed_zone = google_dns_managed_zone.main.name
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["www.${google_dns_managed_zone.main.dns_name}"]
}

resource "google_dns_record_set" "drone" {
  name = "drone.${google_dns_managed_zone.main.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.main.name

  rrdatas = [
    kubernetes_service.drone_server.load_balancer_ingress[0].ip
  ]
}

resource "kubernetes_namespace" "drone" {
  # This is needed for tearing it down
  depends_on = [google_container_node_pool.primary_preemptible_nodes]

  metadata {
    name = "drone"
  }
}

resource "kubernetes_secret" "drone" {
  metadata {
    name      = local.drone_secrets_name
    namespace = kubernetes_namespace.drone.metadata[0].name
  }

  data = {
    server_secret = random_password.drone_server_secret.result
  }
}

resource "kubernetes_config_map" "drone" {
  metadata {
    name      = local.drone_configmap_name
    namespace = kubernetes_namespace.drone.metadata[0].name
  }

  data = {
    drone_agents_enabled       = true
    drone_server_proto         = "https"
    drone_server_host          = "drone.${var.domain_name}"
    drone_github_server        = "https://github.com"
    drone_github_client_id     = var.drone_github_client_id
    drone_github_client_secret = var.drone_github_client_secret
    drone_runner_namespace     = kubernetes_namespace.drone.metadata[0].name
  }
}

resource "kubernetes_deployment" "drone_server" {
  metadata {
    name      = "drone-server"
    namespace = kubernetes_namespace.drone.metadata[0].name
    labels = {
      app = "DroneServer"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "DroneServer"
      }
    }

    template {
      metadata {
        labels = {
          app = "DroneServer"
        }
      }

      spec {
        container {
          name  = "drone-server"
          image = "drone/drone:1"

          port {
            container_port = 80
            protocol       = "TCP"
          }

          port {
            container_port = 443
            protocol       = "TCP"
          }

          env {
            name = "DRONE_AGENTS_ENABLED"
            value_from {
              config_map_key_ref {
                name = local.drone_configmap_name
                key  = "drone_agents_enabled"
              }
            }
          }

          env {
            name = "DRONE_GITHUB_SERVER"
            value_from {
              config_map_key_ref {
                name = local.drone_configmap_name
                key  = "drone_github_server"
              }
            }
          }

          env {
            name = "DRONE_GITHUB_CLIENT_ID"
            value_from {
              config_map_key_ref {
                name = local.drone_configmap_name
                key  = "drone_github_client_id"
              }
            }
          }

          env {
            name = "DRONE_GITHUB_CLIENT_SECRET"
            value_from {
              config_map_key_ref {
                name = local.drone_configmap_name
                key  = "drone_github_client_secret"
              }
            }
          }

          env {
            name = "DRONE_SERVER_HOST"
            value_from {
              config_map_key_ref {
                name = local.drone_configmap_name
                key  = "drone_server_host"
              }
            }
          }

          env {
            name = "DRONE_SERVER_PROTO"
            value_from {
              config_map_key_ref {
                name = local.drone_configmap_name
                key  = "drone_server_proto"
              }
            }
          }

          env {
            name = "DRONE_RPC_SECRET"

            value_from {
              secret_key_ref {
                name = local.drone_secrets_name
                key  = "server_secret"
              }
            }
          }

          volume_mount {
            name       = google_compute_disk.ci.name
            mount_path = "/var/lib/drone"
          }
        }

        volume {
          name = google_compute_disk.ci.name
          gce_persistent_disk {
            pd_name = google_compute_disk.ci.name
            fs_type = "ext4"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "drone_server" {
  metadata {
    name      = "drone-server-service"
    namespace = kubernetes_namespace.drone.metadata[0].name
  }

  spec {
    selector = {
      app = "${kubernetes_deployment.drone_server.metadata[0].labels.app}"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }

    port {
      name        = "https"
      port        = 443
      target_port = 443
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_service_account" "drone_runner" {
  metadata {
    name      = "drone-runner"
    namespace = kubernetes_namespace.drone.metadata[0].name
  }
}

resource "kubernetes_role" "drone_runner" {
  metadata {
    name      = "drone-runner-role"
    namespace = kubernetes_namespace.drone.metadata[0].name
  }

  rule {
    verbs      = ["create", "delete"]
    api_groups = [""]
    resources  = ["secrets"]
  }

  rule {
    verbs      = ["get", "create", "delete", "list", "watch", "update"]
    api_groups = [""]
    resources  = ["pods", "pods/log"]
  }
}

resource "kubernetes_role_binding" "drone_runner" {
  metadata {
    name      = "drone-runner-role-binding"
    namespace = kubernetes_namespace.drone.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.drone_runner.metadata[0].name
    namespace = kubernetes_namespace.drone.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.drone_runner.metadata[0].name
  }
}

resource "kubernetes_deployment" "drone_runner" {
  metadata {
    name = "drone-runner"
    namespace = kubernetes_namespace.drone.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "drone-runner"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "drone-runner"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "drone-runner"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.drone_runner.metadata[0].name
        automount_service_account_token = true

        container {
          name  = "drone-runner"
          image = "drone/drone-runner-kube:latest"

          port {
            container_port = 3000
          }

          env {
            name = "DRONE_RPC_HOST"
            value_from {
              config_map_key_ref {
                name = local.drone_configmap_name
                key  = "drone_server_host"
              }
            }
          }

          env {
            name = "DRONE_RPC_PROTO"
            value_from {
              config_map_key_ref {
                name = local.drone_configmap_name
                key  = "drone_server_proto"
              }
            }
          }

          env {
            name = "DRONE_RPC_SECRET"
            value_from {
              secret_key_ref {
                name = local.drone_secrets_name
                key  = "server_secret"
              }
            }
          }

          env {
            name = "DRONE_NAMESPACE_DEFAULT"
            value_from {
              config_map_key_ref {
                name = local.drone_configmap_name
                key  = "drone_runner_namespace"
              }
            }
          }
        }
      }
    }
  }
}
