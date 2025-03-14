# 引用现有的 VPC 网络
data "google_compute_network" "vpc" {
  name = var.vpc_name
}

# 引用现有的子网
data "google_compute_subnetwork" "subnet" {
  name    = "${var.env}-subnet"
  region  = var.region
  project = var.project_id
}

# 尝试获取现有的 NAT Router（如果存在）
data "google_compute_router" "existing_router" {
  count   = var.create_network_resources ? 0 : 1
  name    = "${var.env}-nat-router"
  region  = var.region
  network = data.google_compute_network.vpc.name
}

# 条件创建 NAT Router
resource "google_compute_router" "router" {
  count   = var.create_network_resources ? 1 : 0
  name    = "${var.env}-nat-router"
  region  = var.region
  network = data.google_compute_network.vpc.name
}

locals {
  # 使用三元运算符选择正确的 router 名称
  router_name = var.create_network_resources ? (
    length(google_compute_router.router) > 0 ? google_compute_router.router[0].name : ""
  ) : (
    length(data.google_compute_router.existing_router) > 0 ? data.google_compute_router.existing_router[0].name : ""
  )
}

# NAT网关配置
resource "google_compute_router_nat" "nat" {
  count                              = var.create_network_resources ? 1 : 0
  name                               = "${var.env}-cloud-nat"
  router                             = local.router_name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# 添加环境标签到集群资源
locals {
  common_labels = merge({
    environment = var.env
    managed_by  = "terraform"
    project     = var.project_id
  }, var.resource_labels)
}

# 创建GKE集群
resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.region
  initial_node_count = 1
  min_master_version = var.kubernetes_version

  network    = data.google_compute_network.vpc.name
  subnetwork = data.google_compute_subnetwork.subnet.name

  # 添加环境标签
  resource_labels = local.common_labels

  # 私有集群配置
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block = var.cluster_network_config.master_ipv4_cidr_block
  }

  # 维护窗口
  maintenance_policy {
    daily_maintenance_window {
      start_time = "${var.maintenance_window.start_time}:00Z"  # 例如 "03:00Z"
    }
  }

  # 集群自动扩缩容
  cluster_autoscaling {
    enabled = true
    
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = var.env == "prod" ? 32 : 16
    }
    
    resource_limits {
      resource_type = "memory"
      minimum       = 2
      maximum       = var.env == "prod" ? 128 : 64
    }

    # 如果启用了GPU，添加GPU资源限制
    dynamic "resource_limits" {
      for_each = var.cluster_tier.gpu_enabled ? [1] : []
      content {
        resource_type = "nvidia-tesla-t4"  # 根据GPU类型调整
        minimum       = 0
        maximum       = var.env == "prod" ? 8 : 4
      }
    }
    
    auto_provisioning_defaults {
      disk_size = var.cluster_tier.disk_size_gb
      disk_type = "pd-standard"
      oauth_scopes = [
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
        "https://www.googleapis.com/auth/service.management.readonly",
        "https://www.googleapis.com/auth/servicecontrol",
        "https://www.googleapis.com/auth/trace.append",
      ]
      
      management {
        auto_repair  = true
        auto_upgrade = true
      }
    }
  }

  # 安全加固
  release_channel {
    channel = var.env == "prod" ? "STABLE" : "REGULAR"
  }

  # 启用工作负载身份联合
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # 配置网络策略
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  # 配置IP分配策略
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.cluster_network_config.cluster_ipv4_cidr_block
    services_ipv4_cidr_block = var.cluster_network_config.services_ipv4_cidr_block
  }

  # 配置日志和监控
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # 配置附加组件
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
      disabled = false
    }
    gcp_filestore_csi_driver_config {
      enabled = true
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # 配置垂直Pod自动扩缩容
  vertical_pod_autoscaling {
    enabled = true
  }

  # 移除默认节点池
  remove_default_node_pool = true

  depends_on = [
    google_compute_router_nat.nat
  ]
}

output "cluster_location" {
  description = "GKE集群位置"
  value       = google_container_cluster.primary.location
}

output "workload_identity_pool" {
  description = "工作负载身份池"
  value       = google_container_cluster.primary.workload_identity_config[0].workload_pool
}