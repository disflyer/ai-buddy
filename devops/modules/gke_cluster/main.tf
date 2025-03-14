# 创建专用VPC网络
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# 创建子网
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.env}-gke-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = "192.168.0.0/18"
  }

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.64.0/18"
  }
}

# NAT网关配置
resource "google_compute_router" "router" {
  name    = "${var.env}-nat-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.env}-cloud-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# 创建GKE集群
resource "google_container_cluster" "primary" {
  name               = "${var.env}-gke-cluster"
  location           = var.region
  initial_node_count = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # 私有集群配置
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # 维护窗口
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_window.start_time
    }
  }

  # 集群自动扩缩容
  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      maximum       = 100
    }
    resource_limits {
      resource_type = "memory"
      maximum       = 512
    }
    autoscaling_profile = var.cluster_tier.autoscaling_profile
  }

  # 安全加固
  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  depends_on = [
    google_compute_router_nat.nat
  ]
}