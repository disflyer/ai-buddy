# GKE 集群输出
output "cluster_name" {
  description = "GKE 集群名称"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE 集群 API 端点"
  value       = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  description = "GKE 集群 CA 证书"
  value       = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  sensitive   = true
}

# Artifact Registry 输出
output "artifact_registry_id" {
  description = "Artifact Registry 仓库 ID"
  value       = google_artifact_registry_repository.app_registry.id
}

output "artifact_registry_name" {
  description = "Artifact Registry 仓库名称"
  value       = google_artifact_registry_repository.app_registry.name
}

output "artifact_registry_location" {
  description = "Artifact Registry 仓库位置"
  value       = google_artifact_registry_repository.app_registry.location
}

output "image_registry_path" {
  description = "完整的容器镜像仓库路径"
  value       = "${google_artifact_registry_repository.app_registry.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app_registry.name}"
}

output "cluster_location" {
  value = google_container_cluster.primary.location
}

output "node_pool_name" {
  value = google_container_node_pool.primary_nodes.name
} 