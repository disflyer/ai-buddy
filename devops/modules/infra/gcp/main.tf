# 获取 GCP 认证信息
data "google_client_config" "default" {}

# 创建 Artifact Registry 仓库
resource "google_artifact_registry_repository" "app_registry" {
  location      = var.region
  repository_id = "${var.env}-app-registry"
  format        = "DOCKER"
  description   = "${var.env} 环境的容器镜像仓库"
}

# 授予 GKE 服务账号访问 Artifact Registry 的权限
# 注意：移除对 GKE 集群的显式依赖，改为使用 workload 标识前缀
resource "google_artifact_registry_repository_iam_member" "registry_access" {
  project    = var.project_id
  location   = google_artifact_registry_repository.app_registry.location
  repository = google_artifact_registry_repository.app_registry.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.project_id}.svc.id.goog[${var.env}/default]"
  
  # 移除依赖项
  # depends_on = [google_container_cluster.primary]
}

# 创建 GKE 集群
resource "google_container_cluster" "primary" {
  name     = "${var.env}-${var.cluster_name}"
  location = "${var.region}-a"  # 使用单区域部署而非整个区域
  
  # 删除默认节点池，使用单独管理的节点池
  remove_default_node_pool = true
  initial_node_count       = 1

  # 启用 Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # 默认使用标准磁盘，减少 SSD 需求
  node_config {
    disk_type = "pd-standard"
    disk_size_gb = 10
  }
  
  # 减少资源消耗的配置
  logging_service    = "none"  # 禁用默认的 Stackdriver 日志服务
  monitoring_service = "none"  # 禁用默认的监控服务
  
  # 禁用默认的网络策略
  network_policy {
    enabled = false
  }
  
  # 精简 GKE 集群控制平面
  addons_config {
    http_load_balancing {
      disabled = false  # 保留 HTTP 负载均衡
    }
    horizontal_pod_autoscaling {
      disabled = true  # 禁用 Pod 自动扩缩
    }
    network_policy_config {
      disabled = true  # 禁用网络策略
    }
  }
}

# 创建节点池
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.env}-pool"
  location   = "${var.region}-a"  # 使用单区域部署而非整个区域
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  # 添加自动修复配置，但禁用自动升级以减少系统开销
  management {
    auto_repair  = true
    auto_upgrade = false
  }

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-standard"
    
    # 添加节点标签
    labels = {
      env = var.env
    }

    # 使用 GKE Metadata 服务
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # 添加 GPU 配置 (如果需要)
    dynamic "guest_accelerator" {
      for_each = var.gpu_type != "" ? [1] : []
      content {
        type  = var.gpu_type
        count = var.gpu_count
      }
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]
  }
} 