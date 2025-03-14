output "vpc_name" {
  description = "VPC名称"
  value       = google_compute_network.vpc.name
}

output "subnet_self_link" {
  description = "子网自引用链接"
  value       = google_compute_subnetwork.primary.self_link
}

output "pod_cidr" {
  description = "GKE Pod CIDR范围"
  value       = var.subnet_config.pods_cidr
}

output "service_cidr" {
  description = "GKE Service CIDR范围"
  value       = var.subnet_config.services_cidr
}

output "network_self_link" {
  description = "VPC网络自引用链接"
  value       = google_compute_network.vpc.self_link
}