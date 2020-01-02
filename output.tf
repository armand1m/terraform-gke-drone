output "cluster_username" {
  value = google_container_cluster.ci.master_auth[0].username
}

output "cluster_password" {
  value = google_container_cluster.ci.master_auth[0].password
}

output "cluster_endpoint" {
  value = google_container_cluster.ci.endpoint
}

output "cluster_node_pools" {
  value = google_container_cluster.ci.node_pool
}

output "drone_server_external_ip" {
  value = kubernetes_service.drone_server.load_balancer_ingress[0].ip
}