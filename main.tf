provider "google" {}
provider "kubernetes" {
  host = "https://${google_container_cluster.ci.endpoint}"
}

locals {
  drone_server_proto = "https"
  drone_server_host = "drone.armand1m.dev"
  drone_github_client_id = "a5169671aa20c343320e"
  drone_github_client_secret = "f5159ddadd119506d119d43b2237f97ddef57fc5"
  drone_server_secret = "b941fef7954cfeb96f5ed91f53824c0d"
}

resource "google_container_cluster" "ci" {
  name = "ci-cluster"
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  initial_node_count = 1
  remove_default_node_pool = true
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name = "ci-cluster-pool"
  cluster = google_container_cluster.ci.name
  node_count = 1

  node_config {
    preemptible = true
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
  metadata {
    name = "drone"
  }
}

resource "kubernetes_secret" "drone" {
  metadata {
    name = "drone-secrets"
    namespace = kubernetes_namespace.drone.metadata[0].name
  }

  data = {
    server_secret = local.drone_server_secret
  }
}

resource "kubernetes_config_map" "drone" {
  metadata {
    name = "drone-config"
    namespace = kubernetes_namespace.drone.metadata[0].name
  }

  data = {
    drone_agents_enabled = true
    drone_github_server = "https://github.com"
    drone_github_client_id = local.drone_github_client_id
    drone_github_client_secret = local.drone_github_client_secret
    drone_server_host = local.drone_server_host
    drone_server_proto = local.drone_server_proto
  }
}

resource "kubernetes_service" "example" {
  metadata {
    name = "terraform-example"
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
    name = "terraform-example"
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
  dns_name    = "armand1m.dev."
  description = "Main DNS zone"
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