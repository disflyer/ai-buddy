# 直接定义staging环境的配置，不再包含根配置
# 这解决了嵌套include问题

# 定义远程状态存储
remote_state {
  backend = "gcs"
  config = {
    bucket  = "tfstate-rare-attic"
    prefix  = "${path_relative_to_include()}"
    credentials = "${get_original_terragrunt_dir()}/../../../service-account.json"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# 生成provider配置
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.10"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file("${get_original_terragrunt_dir()}/../../../service-account.json")
}
EOF
}

# 环境特定的默认配置
locals {
  # 环境名称
  env = "staging"
  
  # 项目配置
  project_id = "rare-attic-453703-a8"
  region     = "us-central1"
}

# 环境级别默认值
inputs = {
  env        = local.env
  project_id = local.project_id
  region     = local.region
  
  # 公共标签
  common_tags = {
    environment = local.env
    managed_by  = "terragrunt"
  }
} 