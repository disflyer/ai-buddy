# 获取GKE集群信息
data "google_container_cluster" "target_cluster" {
  name     = var.gke_cluster_name
  location = var.region
}

# 移除本地 Kubernetes provider 配置
# 现在依赖于调用方传递的 provider 配置

data "google_client_config" "default" {}

# 部署应用服务
resource "kubernetes_deployment" "app_server" {
  metadata {
    name = "${var.env}-app-server"
    labels = {
      app  = "app-server"
      env  = var.env
    }
  }

  spec {
    replicas = var.replica_count

    selector {
      match_labels = {
        app = "app-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "app-server"
          env = var.env
        }
      }

      spec {
        container {
          name  = "app-server"
          image = "${var.image_repo}/${var.project_id}/${var.image_name}:${var.image_tag}"
          ports {
            container_port = 8000
          }

          resources {
            limits = {
              cpu    = var.resource_limits.cpu
              memory = var.resource_limits.memory
              "nvidia.com/gpu" = var.resource_limits.gpu
            }
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          env {
            name = "JWT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.auth_secrets.metadata[0].name
                key  = "jwt_secret"
              }
            }
          }
        }

        node_selector = {
          "cloud.google.com/gke-nodepool" = "default-pool"
        }
      }
    }
  }
}

# 暴露服务
resource "kubernetes_service" "lb_service" {
  metadata {
    name = "${var.env}-app-server-lb"
    annotations = {
      "cloud.google.com/load-balancer-type" = "Internal" # 内部负载均衡
    }
  }

  spec {
    selector = {
      app = "app-server"
    }

    port {
      port        = 80
      target_port = 8000
    }

    type = "LoadBalancer"
  }
}

# 自动扩缩容配置
resource "kubernetes_horizontal_pod_autoscaler" "autoscaler" {
  count = var.autoscaling.enabled ? 1 : 0

  metadata {
    name = "${var.env}-app-server-hpa"
  }

  spec {
    min_replicas = var.autoscaling.min_replicas
    max_replicas = var.autoscaling.max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app_server.metadata[0].name
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.autoscaling.target_cpu_util
        }
      }
    }
  }
}

# 配置管理
resource "kubernetes_config_map" "app_config" {
  metadata {
    name = "${var.env}-app-config"
  }

  data = {
    "APP_ENV"        = var.env
    "LOG_LEVEL"      = "INFO"
    "MAX_CONNECTIONS" = "1000"
  }
}

# 密钥管理
resource "kubernetes_secret" "auth_secrets" {
  metadata {
    name = "${var.env}-auth-secrets"
  }

  data = {
    "jwt_secret" = base64encode(random_password.jwt.result)
  }
}

resource "random_password" "jwt" {
  length  = 32
  special = false
}