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

output "cloud_dns_name" {
  value = google_dns_managed_zone.main.dns_name
}

output "cloud_dns_name_servers" {
  value = google_dns_managed_zone.main.name_servers
}

output "cloud_dns_example_record_set_name" {
  value = google_dns_record_set.example.name
}

output "cloud_dns_example_record_set_rrdatas" {
  value = google_dns_record_set.example.rrdatas
}