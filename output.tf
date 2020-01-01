output "cluster_username" {
  value = google_container_cluster.ci.master_auth[0].username
}

output "cluster_password" {
  value = google_container_cluster.ci.master_auth[0].password
}

output "endpoint" {
  value = google_container_cluster.ci.endpoint
}

output "node_pools" {
  value = google_container_cluster.ci.node_pool
}
