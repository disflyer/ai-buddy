output "cluster_name" {
  description = "GKE集群名称"
  value       = google_container_cluster.primary.name
}

output "endpoint" {
  description = "集群API端点"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "service_account_email" {
  description = "节点服务账号邮箱"
  value       = google_service_account.gke_node.email
}

output "network_self_link" {
  description = "VPC网络链接"
  value       = google_compute_network.vpc.self_link
}