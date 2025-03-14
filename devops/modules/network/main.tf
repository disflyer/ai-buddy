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

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# 保留内部DNS名称
resource "google_compute_global_address" "dns_internal" {
  name          = "${var.env}-dns-internal"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# 启用私有服务连接
resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.dns_internal.name]
}