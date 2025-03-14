# 定义远程状态存储
remote_state {
  backend = "gcs"
  config = {
    bucket  = "tfstate-rare-attic"
    prefix  = "${path_relative_to_include()}"
    credentials = "service-account.json"
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
  credentials = file("service-account.json")
}
EOF
}

# 全局变量
inputs = {
  terraform_version = "1.0.0"
}

# 设置Terragrunt工作目录
terraform {
  # 强制Terragrunt在执行Terraform之前总是运行'terraform init'
  before_hook "init" {
    commands = ["apply", "plan", "destroy"]
    execute  = ["terraform", "init"]
  }
} 