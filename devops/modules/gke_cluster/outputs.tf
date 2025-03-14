output "cluster_name" {
  description = "GKE集群名称"
  value       = google_container_cluster.primary.name
}

output "endpoint" {
  description = "集群API端点"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "集群CA证书"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "service_account_email" {
  description = "节点服务账号邮箱"
  value       = google_service_account.gke_node.email
}

output "network_name" {
  description = "VPC网络名称"
  value       = data.google_compute_network.vpc.name
}