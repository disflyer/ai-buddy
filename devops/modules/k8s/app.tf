# 创建 WebSocket 服务
resource "kubernetes_service" "websocket_service" {
  metadata {
    name      = "${var.env}-${local.app_name}"
    namespace = var.namespace
    labels    = local.app_labels
    
    # 不再需要负载均衡器相关注解
    # annotations = local.current_config.lb_annotations
  }

  spec {
    selector = {
      app = local.app_name
      env = var.env
    }

    port {
      name        = "ws"
      port        = 8080
      target_port = 8000
    }

    # 改为 ClusterIP 类型，由 Ingress 暴露
    type = "ClusterIP"
  }
}

# 应用部署
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
          "config-checksum" = sha256(jsonencode(kubernetes_config_map.app_config.data))
          "model-revision"  = var.model_revision != "" ? var.model_revision : "latest"
        }
      }

      spec {
        # 使用平台对应的节点选择器
        node_selector = local.current_config.node_selector
        
        # 初始化容器 - 用于下载模型
        init_container {
          name  = "model-downloader"
          image = "python:3.11-slim"
          
          command = [
            "bash",
            "-c",
            <<-EOT
            # 安装必要的库
            pip install huggingface_hub

            # 定义变量
            MODEL_DIR="${local.model_config.model_dir}"
            CACHE_DIR="${local.model_config.cache_dir}"
            DOWNLOADED_FLAG="$MODEL_DIR/.downloaded"
            MODEL_REVISION="${local.model_config.revision != null ? local.model_config.revision : ""}"

            # 创建目录
            mkdir -p $MODEL_DIR
            mkdir -p $CACHE_DIR

            # 检查是否已下载模型
            if [ ! -f "$DOWNLOADED_FLAG" ]; then
              echo "开始从 Hugging Face 下载 ${local.model_config.repo_id} 模型..."
              
              python -c "
from huggingface_hub import snapshot_download
import os

# 准备下载参数
download_args = {
    'repo_id': '${local.model_config.repo_id}',
    'local_dir': os.environ['MODEL_DIR'],
    'cache_dir': os.environ['CACHE_DIR'],
}

# 如果指定了版本，添加 revision 参数
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
          
          # 挂载模型卷
          volume_mount {
            name       = "models-volume"
            mount_path = "/app/models"
          }
          
          # 资源限制
          resources {
            limits = {
              cpu    = "1"
              memory = "1Gi"
            }
            requests = {
              cpu    = "500m"
              memory = "500Mi"
            }
          }
        }
        
        # 主应用容器
        container {
          name  = local.app_name
          image = "${var.image_registry}/${var.image_name}:${var.image_tag}"
          
          port {
            container_port = 8000
            name           = "http"
          }

          resources {
            limits = {
              cpu    = var.resource_limits.cpu
              memory = var.resource_limits.memory
              "nvidia.com/gpu" = var.resource_limits.gpu
            }
            requests = {
              cpu    = var.env == "prod" ? "1000m" : "500m"
              memory = var.env == "prod" ? "2Gi" : "1Gi"
            }
          }

          # 从配置映射获取环境变量
          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }
          
          # 添加健康检查
          liveness_probe {
            http_get {
              path = "/health"
              port = "http"
            }
            initial_delay_seconds = 60
            period_seconds        = 15
          }
          
          # 挂载模型卷
          volume_mount {
            name       = "models-volume"
            mount_path = "/app/models"
          }
        }
        
        # 模型卷 - 使用 emptyDir
        volume {
          name = "models-volume"
          empty_dir {
            size_limit = "5Gi"
          }
        }
      }
    }
  }
}

# 配置映射
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
  }
} 