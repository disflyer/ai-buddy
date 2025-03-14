output "config_yaml_secret_id" {
  description = "配置文件Secret的ID"
  value       = google_secret_manager_secret.config_yaml.id
}

output "config_yaml_secret_name" {
  description = "Kubernetes中配置文件Secret的名称"
  value       = kubernetes_secret.config_yaml.metadata[0].name
} 