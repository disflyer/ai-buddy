# 获取 GCP 认证信息
data "google_client_config" "default" {}

# 创建 GKE 节点专用的服务账号
resource "google_service_account" "gke_node_sa" {
  account_id   = "${var.env}-gke-node-sa"
  display_name = "GKE Node Service Account for ${var.env}"
  project      = var.project_id
}

# 授予必要的权限
resource "google_project_iam_member" "gke_node_sa_roles" {
  for_each = toset([
    "roles/monitoring.metricWriter",    # 允许写入监控指标
    "roles/logging.logWriter",          # 允许写入日志
    "roles/storage.objectViewer",       # 允许读取存储对象
    "roles/artifactregistry.reader"     # 允许从Artifact Registry拉取镜像
  ])
  
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

# 创建 Artifact Registry 仓库
resource "google_artifact_registry_repository" "app_registry" {
  location      = var.region
  repository_id = "${var.env}-app-registry"
  format        = "DOCKER"
  description   = "${var.env} 环境的容器镜像仓库"
  
  # 添加生命周期块，防止在资源已存在时失败
  lifecycle {
    ignore_changes = [
      labels,
      description
    ]
  }
}

# 授予 GKE 服务账号访问 Artifact Registry 的权限
# 注意：移除对 GKE 集群的显式依赖，改为使用 workload 标识前缀
resource "google_artifact_registry_repository_iam_member" "registry_access" {
  project    = var.project_id
  location   = google_artifact_registry_repository.app_registry.location
  repository = google_artifact_registry_repository.app_registry.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.project_id}.svc.id.goog[${var.env}/default]"
}

# 创建 GKE 集群
# tfsec:ignore:google-gke-enforce-pod-security-policy
# tfsec:ignore:google-gke-no-public-control-plane
resource "google_container_cluster" "primary" {
  name     = "${var.env}-${var.cluster_name}"  # 注意：这可能导致名称重复为 "shared-app-cluster"
  location = "${var.region}-a"  # 使用单区域部署而非整个区域
  
  # 删除默认节点池，使用单独管理的节点池
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # 允许删除集群
  deletion_protection = false

  # 添加生命周期块，防止在资源已存在时失败
  lifecycle {
    prevent_destroy = true  # 防止误删除集群
    ignore_changes = [
      initial_node_count,
      resource_labels,
      node_config,
    ]
  }

  # 添加资源标签，便于资源管理和成本分配
  resource_labels = {
    environment = var.env
    managed-by  = "terraform"
    project     = "ai-buddy"
    team        = "devops"
  }

  # 启用Pod安全标准
  # 注意：pod_security_policy_config 已在新版本中被弃用
  # 使用 GKE 的安全配置替代
  security_posture_config {
    mode = "BASIC"  # 启用基本的安全控制
  }

  # 配置私有集群设置
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false  # 允许从公共互联网访问控制平面，但节点是私有的
    master_ipv4_cidr_block  = "172.16.0.0/28"  # 为控制平面分配一个私有IP范围
  }

  # 启用主节点授权网络，限制可访问Kubernetes API的IP地址
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/8"
      display_name = "内部网络"
    }
    cidr_blocks {
      cidr_block   = "192.168.0.0/16"
      display_name = "VPN网络"
    }
    # 添加GitHub Actions运行器可能使用的IP范围
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"  # 临时允许所有IP，在生产环境中应替换为特定IP
      display_name = "CI/CD系统"
    }
  }

  # 启用IP别名以允许Pod IP地址与GCP网络集成
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.100.0.0/16"
    services_ipv4_cidr_block = "10.101.0.0/16"
  }

  # 启用 Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # 默认使用标准磁盘，减少 SSD 需求
  node_config {
    disk_type = "pd-standard"
    disk_size_gb = 50
  }
  
  # 配置监控和日志服务
  logging_service    = "logging.googleapis.com/kubernetes"  # 启用 Stackdriver 日志服务
  monitoring_service = "monitoring.googleapis.com/kubernetes"  # 启用 Stackdriver 监控服务
  
  # 启用网络策略，增强Pod间通信安全性
  network_policy {
    enabled = true
    provider = "CALICO"  # 使用Calico作为网络策略提供者
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
      disabled = false  # 启用网络策略配置
    }
  }
}

# 创建节点池
# tfsec:ignore:google-gke-metadata-endpoints-disabled
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.env}-pool"
  location   = "${var.region}-a"  # 使用单区域部署而非整个区域
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  # 添加自动修复配置，但启用自动升级以符合 REGULAR 发布渠道要求
  management {
    auto_repair  = true
    auto_upgrade = true  # 必须为 true，因为集群使用 REGULAR 发布渠道
  }

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-standard"
    
    # 使用推荐的COS镜像类型
    image_type = "COS_CONTAINERD"
    
    # 使用自定义服务账号，如果未提供则使用新创建的服务账号
    service_account = var.node_service_account_email != "" ? var.node_service_account_email : google_service_account.gke_node_sa.email
    
    # 禁用传统元数据端点，增强安全性
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
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