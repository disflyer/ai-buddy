# 获取GKE集群信息
data "google_container_cluster" "target_cluster" {
  name     = var.gke_cluster_name
  location = var.region
}

# 移除本地 Kubernetes provider 配置
# 现在依赖于调用方传递的 provider 配置

data "google_client_config" "default" {}

# 从Secret Manager获取JWT密钥
data "google_secret_manager_secret_version" "jwt_secret" {
  secret = "jwt-secret"
}

# 本地变量定义
locals {
  app_name = "app-server"
  app_labels = {
    app         = local.app_name
    env         = var.env
    managed-by  = "terraform"
    namespace   = var.namespace
  }
  
  # 根据环境选择合适的节点池
  node_selector = var.env == "prod" ? {
    "cloud.google.com/gke-nodepool" = "prod-pool"
  } : {
    "cloud.google.com/gke-nodepool" = "default-pool"
  }
  
  # 根据环境设置资源请求
  resource_requests = var.env == "prod" ? {
    cpu    = "1000m"
    memory = "2Gi"
  } : {
    cpu    = "500m"
    memory = "1Gi"
  }
  
  # 模型配置
  model_config = {
    repo_id    = "FunAudioLLM/SenseVoiceSmall"
    cache_dir  = "/app/models/.cache"
    model_dir  = "/app/models/SenseVoiceSmall"
    revision   = var.model_revision != "" ? var.model_revision : null
  }
}

# 创建命名空间（如果不存在）
resource "kubernetes_namespace" "app_namespace" {
  count = var.namespace != "default" ? 1 : 0
  
  metadata {
    name = var.namespace
    
    labels = {
      environment = var.env
      managed-by  = "terraform"
    }
  }
}

# 部署应用服务
resource "kubernetes_deployment" "app_server" {
  metadata {
    name      = "${var.env}-${local.app_name}"
    namespace = var.namespace
    labels    = local.app_labels
  }

  spec {
    replicas = var.replica_count

    selector {
      match_labels = {
        app = local.app_name
        env = var.env
      }
    }

    template {
      metadata {
        labels = local.app_labels
        annotations = {
          # 添加注释以便在配置更改时触发重新部署
          "config-checksum" = sha256(jsonencode(kubernetes_config_map.app_config.data))
          "model-revision"  = var.model_revision != "" ? var.model_revision : "latest"
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
            MODEL_DIR="${local.model_config.model_dir}"
            # 缓存目录
            CACHE_DIR="${local.model_config.cache_dir}"
            # 标记文件，用于判断模型是否已下载
            DOWNLOADED_FLAG="$MODEL_DIR/.downloaded"
            # 模型版本（如果指定）
            MODEL_REVISION="${local.model_config.revision != null ? local.model_config.revision : ""}"

            # 创建模型目录和缓存目录
            mkdir -p $MODEL_DIR
            mkdir -p $CACHE_DIR

            # 检查是否需要下载模型
            if [ ! -f "$DOWNLOADED_FLAG" ]; then
              echo "正在从Hugging Face下载${local.model_config.repo_id}模型..."
              # 使用huggingface_hub下载模型，启用缓存，指定版本（可选）
              python -c "
from huggingface_hub import snapshot_download
import os

# 准备下载参数
download_args = {
    'repo_id': '${local.model_config.repo_id}',
    'local_dir': os.environ['MODEL_DIR'],
    'cache_dir': os.environ['CACHE_DIR'],
}

# 如果指定了版本，添加revision参数
if os.environ['MODEL_REVISION']:
    download_args['revision'] = os.environ['MODEL_REVISION']
    print(f'使用指定版本: {os.environ[\"MODEL_REVISION\"]}')
else:
    print('使用最新版本')

# 执行下载
snapshot_download(**download_args)
              "
              touch $DOWNLOADED_FLAG
              echo "模型下载完成"
            else
              echo "模型已存在，跳过下载"
            fi
            EOT
          ]
          
          env {
            name  = "MODEL_DIR"
            value = local.model_config.model_dir
          }
          
          env {
            name  = "CACHE_DIR"
            value = local.model_config.cache_dir
          }
          
          env {
            name  = "MODEL_REVISION"
            value = local.model_config.revision != null ? local.model_config.revision : ""
          }
          
          # 挂载模型持久卷
          volume_mount {
            name       = "models-volume"
            mount_path = "/app/models"
          }
          
          # 设置资源限制
          resources {
            requests = {
              cpu    = "500m"
              memory = "500Mi"
            }
            limits = {
              cpu    = "1"
              memory = "1Gi"
            }
          }
        }
        
        container {
          name  = local.app_name
          image = "${var.image_repo}/${var.project_id}/${var.image_name}:${var.image_tag}"
          ports {
            container_port = 8000
            name           = "http"
          }

          resources {
            limits = {
              cpu    = var.resource_limits.cpu
              memory = var.resource_limits.memory
              "nvidia.com/gpu" = var.resource_limits.gpu
            }
            requests = local.resource_requests
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
          
          env {
            name  = "NAMESPACE"
            value = var.namespace
          }
          
          env {
            name  = "ENVIRONMENT"
            value = var.env
          }

          # 添加存活探针
          liveness_probe {
            http_get {
              path = "/health"
              port = "http"
            }
            initial_delay_seconds = 60
            period_seconds        = 15
            timeout_seconds       = 5
            failure_threshold     = 3
          }
          
          # 添加就绪探针
          readiness_probe {
            http_get {
              path = "/health"
              port = "http"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
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

        # 根据环境选择合适的节点池
        node_selector = local.node_selector
        
        # 添加亲和性规则
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key      = "app"
                    operator = "In"
                    values   = [local.app_name]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }
        
        # 添加容忍度
        dynamic "toleration" {
          for_each = var.env == "prod" ? [1] : []
          content {
            key      = "dedicated"
            operator = "Equal"
            value    = "prod"
            effect   = "NoSchedule"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.app_namespace]
}

# 创建服务账号
resource "kubernetes_service_account" "app_server_sa" {
  metadata {
    name      = "${var.env}-${local.app_name}-sa"
    namespace = var.namespace
    labels    = local.app_labels
  }

  depends_on = [kubernetes_namespace.app_namespace]
}

# 创建IAM策略绑定，授予GCS访问权限
resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.gcp_service_account}"
  role               = "roles/iam.workloadIdentityUser"
  members            = [
    "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/${kubernetes_service_account.app_server_sa.metadata[0].name}]"
  ]
}

# 添加注解，启用Workload Identity
resource "kubernetes_annotations" "service_account_annotation" {
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = kubernetes_service_account.app_server_sa.metadata[0].name
    namespace = var.namespace
  }
  annotations = {
    "iam.gke.io/gcp-service-account" = var.gcp_service_account
  }
  depends_on = [kubernetes_service_account.app_server_sa]
}

# 创建Google Cloud SDK凭证Secret
resource "kubernetes_secret" "google_application_credentials" {
  metadata {
    name      = "${var.env}-google-application-credentials"
    namespace = var.namespace
    labels    = local.app_labels
  }

  data = {
    "credentials.json" = var.google_application_credentials
  }

  depends_on = [kubernetes_namespace.app_namespace]
}

# 暴露服务
resource "kubernetes_service" "lb_service" {
  metadata {
    name      = "${var.env}-${local.app_name}-lb"
    namespace = var.namespace
    labels    = local.app_labels
    annotations = {
      "cloud.google.com/load-balancer-type" = "Internal" # 内部负载均衡
    }
  }

  spec {
    selector = {
      app = local.app_name
      env = var.env
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8000
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_namespace.app_namespace]
}

# 自动扩缩容配置
resource "kubernetes_horizontal_pod_autoscaler" "autoscaler" {
  count = var.autoscaling.enabled ? 1 : 0

  metadata {
    name      = "${var.env}-${local.app_name}-hpa"
    namespace = var.namespace
    labels    = local.app_labels
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
    
    # 添加内存指标
    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.autoscaling.target_memory_util
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.app_namespace]
}

# 配置管理
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "${var.env}-${local.app_name}-config"
    namespace = var.namespace
    labels    = local.app_labels
  }

  data = {
    "APP_ENV"         = var.env
    "LOG_LEVEL"       = var.env == "prod" ? "INFO" : "DEBUG"
    "MAX_CONNECTIONS" = var.env == "prod" ? "1000" : "500"
    "MODEL_PATH"      = local.model_config.model_dir
    "MODEL_REVISION"  = local.model_config.revision != null ? local.model_config.revision : "latest"
    "NAMESPACE"       = var.namespace
  }

  depends_on = [kubernetes_namespace.app_namespace]
}

# 密钥管理
resource "kubernetes_secret" "auth_secrets" {
  metadata {
    name      = "${var.env}-auth-secrets"
    namespace = var.namespace
    labels    = local.app_labels
  }

  data = {
    "jwt_secret" = data.google_secret_manager_secret_version.jwt_secret.secret_data
  }

  depends_on = [kubernetes_namespace.app_namespace]
}

# 输出服务信息
output "service_endpoint" {
  description = "应用服务负载均衡器端点"
  value       = kubernetes_service.lb_service.status.0.load_balancer.0.ingress.0.ip
}

output "deployment_name" {
  description = "部署名称"
  value       = kubernetes_deployment.app_server.metadata.0.name
}

output "namespace" {
  description = "部署的命名空间"
  value       = var.namespace
}