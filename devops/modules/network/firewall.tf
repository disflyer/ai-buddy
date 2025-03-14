# 默认入口规则
resource "google_compute_firewall" "default_ingress" {
  name    = "${var.env}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [var.vpc_cidr]
  target_tags   = ["internal"]
}

# 默认出口规则 - 阻止所有流量
resource "google_compute_firewall" "default_egress" {
  name      = "${var.env}-deny-external-egress"
  network   = google_compute_network.vpc.name
  direction = "EGRESS"

  deny {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  priority           = 1000
  target_tags        = ["restricted-egress"]
}

# 例外允许规则 - 允许NTP和DNS
resource "google_compute_firewall" "allow_essential" {
  name      = "${var.env}-allow-essential-egress"
  network   = google_compute_network.vpc.name
  direction = "EGRESS"

  allow {
    protocol = "udp"
    ports    = ["123", "53"]  # NTP和DNS
  }
  
  allow {
    protocol = "tcp"
    ports    = ["53"]  # DNS
  }

  destination_ranges = ["0.0.0.0/0"]
  priority           = 900  # 优先级高于deny规则
  target_tags        = ["restricted-egress"]
}

# 自定义规则
resource "google_compute_firewall" "custom_rules" {
  for_each = { for rule in var.firewall_rules : rule.name => rule }

  name        = "${var.env}-${each.value.name}"
  network     = google_compute_network.vpc.name
  direction   = each.value.direction

  dynamic "allow" {
    for_each = each.value.ports
    content {
      protocol = "tcp"
      ports    = [allow.value]
    }
  }

  source_ranges = each.value.direction == "INGRESS" ? each.value.source_ranges : null
  target_tags   = each.value.target_tags
}