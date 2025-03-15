# 获取 GCP 认证信息
data "google_client_config" "default" {}

# 创建 Artifact Registry 仓库
resource "google_artifact_registry_repository" "app_registry" {
  location      = var.region
  repository_id = "${var.env}-app-registry"
  format        = "DOCKER"
  description   = "${var.env} 环境的容器镜像仓库"
  
  # 配置仓库的访问控制
  maven_config {
    version_policy = "RELEASE"
    allow_snapshot_overwrites = true
  }
}

# 授予 GKE 服务账号访问 Artifact Registry 的权限
resource "google_artifact_registry_repository_iam_member" "registry_access" {
  project    = var.project_id
  location   = google_artifact_registry_repository.app_registry.location
  repository = google_artifact_registry_repository.app_registry.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.project_id}.svc.id.goog[${var.env}/default]"
  
  depends_on = [google_container_cluster.primary]
}

# 创建 GKE 集群
resource "google_container_cluster" "primary" {
  name     = "${var.env}-${var.cluster_name}"
  location = var.region
  
  # 删除默认节点池，使用单独管理的节点池
  remove_default_node_pool = true
  initial_node_count       = 1

  # 启用 Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# 创建节点池
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.env}-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    
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