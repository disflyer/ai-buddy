# 创建命名空间
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

# 本地变量
locals {
  app_name = "app-server"
  app_labels = {
    app         = local.app_name
    env         = var.env
    managed-by  = "terraform"
  }
  
  # 云平台特定配置
  cloud_configs = {
    gcp = {
      node_selector = {
        "cloud.google.com/gke-nodepool" = "${var.env}-pool"
      }
      lb_annotations = {
        "cloud.google.com/load-balancer-type" = var.internal_lb ? "Internal" : "External"
        "cloud.google.com/app-protocols"      = "{\"ws\": \"HTTP\"}"
      }
    }
    aws = {
      node_selector = {
        "eks.amazonaws.com/nodegroup" = "${var.env}-nodegroup"
      }
      lb_annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-internal" = var.internal_lb ? "true" : "false"
        "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "http"
      }
    }
  }
  
  # 获取当前云平台配置，默认为 GCP
  current_config = lookup(local.cloud_configs, var.cloud_provider, local.cloud_configs.gcp)
  
  # 模型配置
  model_config = {
    repo_id    = var.huggingface_repo_id
    cache_dir  = "/app/models/.cache"
    model_dir  = "/app/models/${replace(var.huggingface_repo_id, "/", "_")}" 
    revision   = var.model_revision != "" ? var.model_revision : null
  }
} 