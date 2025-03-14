# 定义远程状态存储
remote_state {
  backend = "gcs"
  config = {
    bucket  = "tfstate-rare-attic"
    prefix  = "${path_relative_to_include()}"
    credentials = "${get_repo_root()}/devops/service-account.json"
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
  credentials = file("${get_parent_terragrunt_dir()}/service-account.json")
}
EOF
}

# 全局变量
inputs = {
  terraform_version = "1.0.0"
  
  # 网络资源创建控制
  # 默认为false，表示使用现有资源
  # 在新环境部署时，可以通过环境变量 TF_VAR_create_network_resources=true 覆盖
  create_network_resources = get_env("TF_VAR_create_network_resources", "false")
}

# 设置Terragrunt工作目录
terraform {
  # 强制Terragrunt在执行Terraform之前总是运行'terraform init'
  before_hook "init" {
    commands = ["apply", "plan", "destroy"]
    execute  = ["terraform", "init"]
  }
}

# 设置项目级变量
locals {
  # 从环境目录中获取环境名称
  env = basename(get_terragrunt_dir())
  
  # 项目配置
  project_id       = "rare-attic-453703-a8"
  region           = "us-central1"
  gke_cluster_name = "ai-buddy-cluster"
  
  # 应用配置
  app_name  = "app-server"
  image_repo = "us-central1-docker.pkg.dev"
} 