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

resource "kubernetes_namespace" "drone" {
  # This is needed for tearing it down
  depends_on = [google_container_node_pool.primary_preemptible_nodes]

  metadata {
    name = "drone"
  }
}

resource "kubernetes_secret" "drone" {
  metadata {
    name      = "drone-secrets"
    namespace = kubernetes_namespace.drone.metadata[0].name
  }

  data = {
    server_secret = random_password.drone_server_secret.result
  }
}

resource "kubernetes_config_map" "drone" {
  metadata {
    name      = "drone-config"
    namespace = kubernetes_namespace.drone.metadata[0].name
  }

  data = {
    drone_agents_enabled       = true
    drone_server_proto         = "https"
    drone_server_host          = "drone.${var.domain_name}"
    drone_github_server        = "https://github.com"
    drone_github_client_id     = var.drone_github_client_id
    drone_github_client_secret = var.drone_github_client_secret
  }
}

resource "kubernetes_service" "example" {
  metadata {
    name      = "terraform-example"
    namespace = kubernetes_namespace.drone.metadata[0].name
  }

  spec {
    selector = {
      app = "${kubernetes_deployment.example.metadata.0.labels.app}"
    }

    port {
      port        = 8080
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "example" {
  metadata {
    name      = "terraform-example"
    namespace = kubernetes_namespace.drone.metadata[0].name
    labels = {
      app = "MyExampleApp"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "MyExampleApp"
      }
    }

    template {
      metadata {
        labels = {
          app = "MyExampleApp"
        }
      }

      spec {
        container {
          image = "nginx:1.7.8"
          name  = "example"
        }
      }
    }
  }
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

resource "google_dns_record_set" "example" {
  name = "example.${google_dns_managed_zone.main.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.main.name

  rrdatas = [
    kubernetes_service.example.load_balancer_ingress[0].ip
  ]
}

# resource "kubernetes_deployment" "drone-server" {

# }

# resource "kubernetes_deployment" "drone-agent" {

# }