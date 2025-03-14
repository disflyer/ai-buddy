# 网络模块 - 用于创建 VPC、子网和相关网络资源
# 注意：在使用此模块前，请确保以下 API 已手动启用：
# - compute.googleapis.com (Compute Engine API)
# - servicenetworking.googleapis.com (Service Networking API)
# - cloudresourcemanager.googleapis.com (Cloud Resource Manager API)
# - iam.googleapis.com (Identity and Access Management API)
# - container.googleapis.com (Kubernetes Engine API)

# 创建VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.env}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "VPC for ${var.env} environment"
}

# 创建子网
resource "google_compute_subnetwork" "primary" {
  name          = "${var.env}-subnet"
  ip_cidr_range = var.subnet_config.primary_cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.subnet_config.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.subnet_config.services_cidr
  }

  # 根据环境优化日志配置
  log_config {
    aggregation_interval = var.env == "prod" ? "INTERVAL_5_MIN" : "INTERVAL_15_MIN"
    flow_sampling        = var.env == "prod" ? 0.5 : 0.1  # 非生产环境减少采样
    metadata             = var.env == "prod" ? "INCLUDE_ALL_METADATA" : "EXCLUDE_ALL_METADATA"
  }
}

# 私有DNS和服务连接 - 仅在需要私有API访问或托管服务时使用
resource "google_compute_global_address" "dns_internal" {
  count = var.enable_private_services ? 1 : 0
  
  name          = "${var.env}-dns-internal"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# 启用私有服务连接 - 仅在需要私有API访问或托管服务时使用
resource "google_service_networking_connection" "private_vpc" {
  count = var.enable_private_services ? 1 : 0
  
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.dns_internal[0].name]
}