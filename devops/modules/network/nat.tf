# 创建Cloud Router
resource "google_compute_router" "nat_router" {
  name    = "${var.env}-nat-router"
  region  = var.region
  network = google_compute_network.vpc.id
  bgp {
    asn = 64514
  }
}

# 配置Cloud NAT
resource "google_compute_router_nat" "nat" {
  name                               = "${var.env}-cloud-nat"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}