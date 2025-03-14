# 默认节点池
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.env}-primary-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.cluster_tier.min_node_count

  autoscaling {
    min_node_count = var.cluster_tier.min_node_count
    max_node_count = var.cluster_tier.max_node_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.cluster_tier.machine_type
    disk_size_gb = var.cluster_tier.disk_size_gb
    disk_type    = "pd-balanced"
    image_type   = "COS_CONTAINERD"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    service_account = google_service_account.gke_node.email
    preemptible     = var.cluster_tier.preemptible

    dynamic "guest_accelerator" {
      for_each = var.cluster_tier.gpu_enabled ? [1] : []
      content {
        type  = var.cluster_tier.gpu_type
        count = 1
      }
    }

    labels = {
      env        = var.env
      workload   = "general"
    }

    # 只有在启用GPU时才添加污点
    dynamic "taint" {
      for_each = var.cluster_tier.gpu_enabled ? [1] : []
      content {
        key    = "dedicated"
        value  = "gpu"
        effect = "NO_SCHEDULE"
      }
    }
  }
}

# 如果需要，添加一个专用于生产环境的节点池
resource "google_container_node_pool" "prod_nodes" {
  count      = var.env == "prod" ? 1 : 0
  name       = "prod-dedicated-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 2

  autoscaling {
    min_node_count = 2
    max_node_count = 5
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = "e2-standard-4"
    disk_size_gb = 100
    disk_type    = "pd-ssd"
    image_type   = "COS_CONTAINERD"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    service_account = google_service_account.gke_node.email
    preemptible     = false

    labels = {
      env        = "prod"
      workload   = "critical"
    }

    taint {
      key    = "dedicated"
      value  = "prod"
      effect = "NO_SCHEDULE"
    }
  }
}

# 专用服务账号
resource "google_service_account" "gke_node" {
  account_id   = "${var.env}-gke-node"
  display_name = "GKE Node Service Account (${var.env})"
}

# IAM权限绑定
resource "google_project_iam_member" "gke_roles" {
  for_each = toset([
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
    "roles/storage.objectViewer",
    "roles/artifactregistry.reader"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}