# 包含环境配置
# 包含根配置
include {
  path = "${get_repo_root()}/devops/terragrunt.hcl"
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
    cluster_name           = "ai-buddy-cluster"
    endpoint               = "https://mock-endpoint"
    cluster_ca_certificate = "mock-cert"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# 添加对Secret Manager的依赖
dependency "secret_manager" {
  config_path = "../secret_manager"

  # 配置依赖项输出的映射
  mock_outputs = {
    config_yaml_secret_name = "mock-secret-name"
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
  cluster_ca_certificate = base64decode("${dependency.gke_cluster.outputs.cluster_ca_certificate}")
  token                  = data.google_client_config.default.access_token
}
EOF
}

# 模块特定输入
inputs = {
  env              = "staging"
  gke_cluster_name = dependency.gke_cluster.outputs.cluster_name
  image_repo       = "us-central1-docker.pkg.dev" # 选择最近的镜像仓库
  image_name       = "app-server"
  image_tag        = "staging-latest"
  namespace        = "staging" # 使用staging命名空间

  resource_limits = {
    cpu    = "1"
    memory = "2Gi"
    gpu    = 0
  }

  autoscaling = {
    enabled            = true
    min_replicas       = 1
    max_replicas       = 5
    target_cpu_util    = 60
    target_memory_util = 80
  }

  # 添加Secret Manager配置
  config_yaml_secret_name = dependency.secret_manager.outputs.config_yaml_secret_name

  # 添加Google Cloud服务账号凭证
  google_application_credentials = file("${get_terragrunt_dir()}/../../../service-account.json")

  # WebSocket配置 - 直接IP访问
  internal_lb = false # 使用外部负载均衡器，允许公网访问

  # 禁用TLS和Ingress，使用IP直接访问
  enable_tls     = false
  enable_ingress = false

  # 保留域名配置以便将来使用
  # app_domain = "api-staging.aibuddy.cn"

  # 服务账号配置
  gcp_service_account = "terraform-deployer@rare-attic-453703-a8.iam.gserviceaccount.com"
}
