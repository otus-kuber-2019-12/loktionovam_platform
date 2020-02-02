
output "kubernetes_endpoint" {
  value = "${google_container_cluster.primary.endpoint}"
}
