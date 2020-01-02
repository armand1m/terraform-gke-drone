output "cluster_username" {
  value = google_container_cluster.drone.master_auth[0].username
}

output "cluster_password" {
  value = google_container_cluster.drone.master_auth[0].password
}

output "cluster_endpoint" {
  value = google_container_cluster.drone.endpoint
}

output "cluster_node_pools" {
  value = google_container_cluster.drone.node_pool
}

output "drone_server_external_ip" {
  value = kubernetes_service.drone_server.load_balancer_ingress[0].ip
}