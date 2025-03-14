# 包含环境配置
include {
  path = find_in_parent_folders()
}

# 指定模块源
terraform {
  source = "../../../modules//app_server"
  
  # 生成Kubernetes provider配置
  extra_arguments "common_vars" {
    commands = ["apply", "plan", "destroy"]
    
    # 在应用app_server模块之前，确保Kubernetes provider已正确配置
    env_vars = {
      TF_VAR_kubernetes_host                   = dependency.gke_cluster.outputs.endpoint
      TF_VAR_kubernetes_cluster_ca_certificate = dependency.gke_cluster.outputs.cluster_ca_certificate
    }
  }
}

# 依赖关系
dependency "gke_cluster" {
  config_path = "../gke_cluster"
  
  # 配置依赖项输出的映射
  mock_outputs = {
    cluster_name = "mock-cluster"
    endpoint     = "https://mock-endpoint"
    cluster_ca_certificate = "mock-cert"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# 生成Kubernetes provider配置
generate "kubernetes_provider" {
  path      = "kubernetes_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "kubernetes" {
  host                   = "https://${dependency.gke_cluster.outputs.endpoint}"
  cluster_ca_certificate = base64decode(data.google_container_cluster.target_cluster.master_auth[0].cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}
EOF
}

# 模块特定输入
inputs = {
  gke_cluster_name = dependency.gke_cluster.outputs.cluster_name
  image_repo       = "asia.gcr.io"  # 选择最近的镜像仓库
  image_name       = "app-server"
  image_tag        = "staging-latest"
  
  resource_limits = {
    cpu    = "1"
    memory = "2Gi"
    gpu    = 0
  }
  
  autoscaling = {
    enabled         = true
    min_replicas    = 1
    max_replicas    = 5
    target_cpu_util = 60
  }
} 