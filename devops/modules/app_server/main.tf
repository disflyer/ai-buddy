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
        # 添加服务账号
        service_account_name = kubernetes_service_account.app_server_sa.metadata[0].name
        
        # 初始化容器 - 用于下载模型文件
        init_container {
          name  = "model-downloader"
          image = "python:3.11-slim"
          
          command = [
            "bash",
            "-c",
            <<-EOT
            # 安装huggingface_hub
            pip install huggingface_hub

            # 模型目录
            MODEL_DIR="/app/models/SenseVoiceSmall"
            # 缓存目录
            CACHE_DIR="/app/models/.cache"
            # 标记文件，用于判断模型是否已下载
            DOWNLOADED_FLAG="$MODEL_DIR/.downloaded"

            # 创建模型目录和缓存目录
            mkdir -p $MODEL_DIR
            mkdir -p $CACHE_DIR

            # 检查是否需要下载模型
            if [ ! -f "$DOWNLOADED_FLAG" ]; then
              echo "正在从Hugging Face下载SenseVoiceSmall模型..."
              # 使用huggingface_hub下载模型，启用缓存，指定版本（可选）
              python -c "
from huggingface_hub import snapshot_download
# 下载模型，使用缓存，可以指定特定版本（如果需要）
# 如果需要特定版本，取消下面一行的注释并指定revision参数
# snapshot_download(repo_id='FunAudioLLM/SenseVoiceSmall', local_dir='$MODEL_DIR', cache_dir='$CACHE_DIR', revision='main')
snapshot_download(repo_id='FunAudioLLM/SenseVoiceSmall', local_dir='$MODEL_DIR', cache_dir='$CACHE_DIR')
              "
              touch $DOWNLOADED_FLAG
              echo "模型下载完成"
            else
              echo "模型已存在，跳过下载"
            fi
            EOT
          ]
          
          # 挂载模型持久卷
          volume_mount {
            name       = "models-volume"
            mount_path = "/app/models"
          }
        }
        
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

          # 挂载配置文件
          volume_mount {
            name       = "config-volume"
            mount_path = "/app/data"
            read_only  = true
          }
          
          # 挂载模型持久卷
          volume_mount {
            name       = "models-volume"
            mount_path = "/app/models"
          }
        }

        # 配置文件卷
        volume {
          name = "config-volume"
          secret {
            secret_name = var.config_yaml_secret_name
            items {
              key  = ".config.yaml"
              path = ".config.yaml"
            }
          }
        }
        
        # 模型持久卷 - 使用emptyDir，这样Pod重启时模型会保留
        volume {
          name = "models-volume"
          empty_dir {
            # 可以设置大小限制，防止模型文件过大占用太多空间
            size_limit = "5Gi"
          }
        }

        node_selector = {
          "cloud.google.com/gke-nodepool" = "default-pool"
        }
      }
    }
  }
}

# 创建服务账号
resource "kubernetes_service_account" "app_server_sa" {
  metadata {
    name = "${var.env}-app-server-sa"
  }
}

# 创建IAM策略绑定，授予GCS访问权限
resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.gcp_service_account}"
  role               = "roles/iam.workloadIdentityUser"
  members            = [
    "serviceAccount:${var.project_id}.svc.id.goog[default/${kubernetes_service_account.app_server_sa.metadata[0].name}]"
  ]
}

# 添加注解，启用Workload Identity
resource "kubernetes_annotations" "service_account_annotation" {
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name = kubernetes_service_account.app_server_sa.metadata[0].name
  }
  annotations = {
    "iam.gke.io/gcp-service-account" = var.gcp_service_account
  }
  depends_on = [kubernetes_service_account.app_server_sa]
}

# 创建Google Cloud SDK凭证Secret
resource "kubernetes_secret" "google_application_credentials" {
  metadata {
    name = "${var.env}-google-application-credentials"
  }

  data = {
    "credentials.json" = var.google_application_credentials
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