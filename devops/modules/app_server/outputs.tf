output "service_endpoint" {
  description = "应用服务访问端点"
  value       = kubernetes_service.lb_service.status[0].load_balancer[0].ingress[0].ip
}

output "deployment_name" {
  description = "Kubernetes部署名称"
  value       = kubernetes_deployment.app_server.metadata[0].name
}