output "service_endpoint" {
  description = "服务访问端点"
  value       = length(kubernetes_ingress_v1.app_ingress.status) > 0 ? kubernetes_ingress_v1.app_ingress.status[0].load_balancer[0].ingress[0].ip : ""
}

output "namespace" {
  description = "应用命名空间"
  value       = var.namespace
}

output "deployment_name" {
  description = "应用部署名称"
  value       = kubernetes_deployment.app_server.metadata.0.name
} 