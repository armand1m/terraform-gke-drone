output "cluster_username" {
  value = google_container_cluster.ci.master_auth[0].username
}

output "cluster_password" {
  value = google_container_cluster.ci.master_auth[0].password
}

output "endpoint" {
  value = google_container_cluster.ci.endpoint
}

output "instance_group_urls" {
  value = google_container_cluster.ci.instance_group_urls
}

output "node_config" {
  value = google_container_cluster.ci.node_config
}

output "node_pools" {
  value = google_container_cluster.ci.node_pool
}

output "example-service-ingress-ip" {
  value = kubernetes_service.example.load_balancer_ingress[0].ip
}