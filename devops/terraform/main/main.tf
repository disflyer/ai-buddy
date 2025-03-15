# 设置 GCP 提供者
provider "google" {
  project = var.project_id
  region  = var.region
  # credentials 会自动从 GOOGLE_APPLICATION_CREDENTIALS 环境变量获取
}

# 获取 GCP 认证信息
data "google_client_config" "default" {}

# 创建基础设施
module "infra" {
  source = "../modules/infra/gcp"

  project_id   = var.project_id
  region       = var.region
  env          = "shared" # 共享环境标识
  cluster_name = var.cluster_name
  node_count   = var.node_count
  machine_type = var.machine_type
  disk_size_gb = var.disk_size_gb
  gpu_type     = var.gpu_type
  gpu_count    = var.gpu_count

  # 允许 Terraform 修改资源
  manage_existing_resources = false
}

# 配置 Kubernetes 提供者
provider "kubernetes" {
  host                   = "https://${module.infra.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = module.infra.cluster_ca_certificate
}

# 创建环境命名空间
resource "kubernetes_namespace" "environments" {
  for_each = toset(["staging", "prod"])

  metadata {
    name = each.key
    labels = {
      environment = each.key
    }
  }

  depends_on = [module.infra]
}

# 创建资源配额
resource "kubernetes_resource_quota" "staging_quota" {
  metadata {
    name      = "staging-quota"
    namespace = kubernetes_namespace.environments["staging"].metadata[0].name
  }

  spec {
    hard = {
      "cpu"    = "6"
      "memory" = "6Gi"
      "pods"   = "20"
    }
  }
}

resource "kubernetes_resource_quota" "prod_quota" {
  metadata {
    name      = "prod-quota"
    namespace = kubernetes_namespace.environments["prod"].metadata[0].name
  }

  spec {
    hard = {
      "cpu"    = "7"
      "memory" = "7Gi"
      "pods"   = "30"
    }
  }
}

# 创建网络策略
resource "kubernetes_network_policy" "isolate_prod" {
  metadata {
    name      = "isolate-prod"
    namespace = kubernetes_namespace.environments["prod"].metadata[0].name
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            environment = "prod"
          }
        }
      }
    }
  }
}

resource "kubernetes_network_policy" "isolate_staging" {
  metadata {
    name      = "isolate-staging"
    namespace = kubernetes_namespace.environments["staging"].metadata[0].name
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            environment = "staging"
          }
        }
      }
    }
  }
}

# 输出信息
output "kubernetes_cluster_name" {
  value = module.infra.cluster_name
}

output "image_registry_path" {
  description = "容器镜像仓库路径"
  value       = module.infra.image_registry_path
}

output "cluster_endpoint" {
  description = "Kubernetes 集群 API 端点"
  value       = module.infra.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Kubernetes 集群 CA 证书"
  value       = module.infra.cluster_ca_certificate
  sensitive   = true
} 