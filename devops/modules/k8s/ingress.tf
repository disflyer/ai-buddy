# 创建 Ingress 资源，使用 GKE 自带的 GCLB Ingress 控制器
resource "kubernetes_ingress_v1" "app_ingress" {
  metadata {
    name      = "${var.env}-${local.app_name}-ingress"
    namespace = var.namespace
    labels    = local.app_labels
    
    annotations = {
      # 使用 GCE Ingress 控制器（GKE 默认）
      "kubernetes.io/ingress.class" = "gce"
      
      # 内部/外部负载均衡器设置
      "networking.gke.io/internal" = var.internal_lb ? "true" : "false"
      
      # WebSocket 支持配置
      "kubernetes.io/ingress.allow-http" = "true"
      
      # WebSocket 需要较长的超时时间
      "kubernetes.io/ingress.gce.backend-service.timeout-sec" = "3600"
      
      # 可选：如果有域名且需要 HTTPS，可解除下面注释
      # "networking.gke.io/managed-certificates" = "${var.env}-${local.app_name}-cert"
      
      # 如果需要 CDN，可解除下面注释
      # "kubernetes.io/ingress.gce.backend-service.cache-mode" = var.enable_cdn ? "FORCE_CACHE_ALL" : "CACHE_ALL_STATIC"
    }
  }
  
  spec {
    # 基于主机名和路径的规则
    rule {
      # 如果有配置域名，则使用域名
      host = var.domain_name != "" ? var.domain_name : null
      
      http {
        path {
          path = "/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service.websocket_service.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
    
    # 如果没有定义规则或者规则不匹配时的默认后端
    default_backend {
      service {
        name = kubernetes_service.websocket_service.metadata[0].name
        port {
          number = 8080
        }
      }
    }
  }
}

# 输出 Ingress IP 地址（用于访问服务）
output "ingress_ip" {
  description = "Ingress 的 IP 地址（可用于访问服务）"
  value       = length(kubernetes_ingress_v1.app_ingress.status) > 0 ? kubernetes_ingress_v1.app_ingress.status[0].load_balancer[0].ingress[0].ip : ""
} 