# 包含环境配置
include {
  path = find_in_parent_folders()
}

# 指定模块源
terraform {
  source = "../../../modules//secret_manager"
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
  env       = "staging"
  project_id = "rare-attic-453703-a8"
  region    = "us-central1"
  
  # 允许GKE节点池的服务账号访问Secret
  secret_accessor_members = [
    "serviceAccount:${dependency.gke_cluster.outputs.service_account}"
  ]
} 