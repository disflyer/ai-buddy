# 设置 GCP 提供者
provider "google" {
  project = var.project_id
  region  = var.region
}

# 获取 GCP 认证信息
data "google_client_config" "default" {}

# 创建基础设施
module "infra" {
  source = "../../modules/infra/gcp"
  
  project_id   = var.project_id
  region       = var.region
  env          = "prod"
  cluster_name = var.cluster_name
  node_count   = var.node_count
  machine_type = var.machine_type
  disk_size_gb = var.disk_size_gb
  gpu_type     = var.gpu_type
  gpu_count    = var.gpu_count
}

# 配置 Kubernetes 提供者
provider "kubernetes" {
  host                   = "https://${module.infra.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = module.infra.cluster_ca_certificate
}

# 部署应用
module "app" {
  source = "../../modules/k8s"
  
  cloud_provider   = "gcp"
  env              = "prod"
  namespace        = "prod"
  replica_count    = var.replica_count
  image_registry   = module.infra.image_registry_path
  image_name       = var.image_name
  image_tag        = var.image_tag
  huggingface_repo_id = var.huggingface_repo_id
  model_revision   = var.model_revision
  resource_limits  = var.resource_limits
  internal_lb      = var.internal_lb
  domain_name      = var.domain_name
  enable_cdn       = var.enable_cdn
}

# 输出信息
output "kubernetes_cluster_name" {
  value = module.infra.cluster_name
}

output "service_endpoint" {
  value = module.app.service_endpoint
}

# 输出容器镜像仓库信息
output "image_registry_path" {
  description = "容器镜像仓库路径"
  value       = module.infra.image_registry_path
} 