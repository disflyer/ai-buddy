# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/google" {
  version = "6.25.0"
  hashes = [
    "h1:rvsmJc5J5OMMFXj9th8Yqfwm7cLZdRM/stPo0B8Datg=",
    "zh:115ce3e84a02412a9a42c7c8f1c4568ab470bdd93c9a3a1f9202d4b77d7bc236",
    "zh:623a32acea92d98a8bb66481fa9489e0a1e4dd6fc57ab70dbb53fae5732c1c63",
    "zh:6440fc959b5e316152e26c916d55566311dafbe5b64e45d4b9c9931a5b29fa13",
    "zh:91edb056638e723b1c7802d0e6e293611208e2825f645572ddba98122723f11c",
    "zh:9b57ee44172677d2c2df03b22cf4b40e184ac8bd8facdd456ccbfdb7fee4684a",
    "zh:9e2a97dd09b78b36caecdd990fff80bdb47a6a6d45c8b2dd4d23885d6bc89e65",
    "zh:b33e40e9ba745f15b1c2e9ebcdccbac185788a4eb57450820cec7b9585858522",
    "zh:d9e051bb703597384d83d924c49770e3bcdc1b68583d3def33a607ab168c634b",
    "zh:e84253140fc3b0bd5cf7a1ebb54f993bacc6d5ee33c7b5e714ad834d5b2d35d0",
    "zh:ebb624504c6f4297e691b6e3c00f789a6729461e5aa80fc165ef2ecd878e2d87",
    "zh:f569b65999264a9416862bca5cd2a6177d94ccb0424f3a4ef424428912b9cb3c",
    "zh:f8c3e8192e98eff09a9453b52424c0d9727ae284de4fafbc498f2d527e026850",
  ]
}

provider "registry.terraform.io/hashicorp/kubernetes" {
  version = "2.36.0"
  hashes = [
    "h1:94wlXkBzfXwyLVuJVhMdzK+VGjFnMjdmFkYhQ1RUFhI=",
    "zh:07f38fcb7578984a3e2c8cf0397c880f6b3eb2a722a120a08a634a607ea495ca",
    "zh:1adde61769c50dbb799d8bf8bfd5c8c504a37017dfd06c7820f82bcf44ca0d39",
    "zh:39707f23ab58fd0e686967c0f973c0f5a39c14d6ccfc757f97c345fdd0cd4624",
    "zh:4cc3dc2b5d06cc22d1c734f7162b0a8fdc61990ff9efb64e59412d65a7ccc92a",
    "zh:8382dcb82ba7303715b5e67939e07dd1c8ecddbe01d12f39b82b2b7d7357e1d9",
    "zh:88e8e4f90034186b8bfdea1b8d394621cbc46a064ff2418027e6dba6807d5227",
    "zh:a6276a75ad170f76d88263fdb5f9558998bf3a3f7650d7bd3387b396410e59f3",
    "zh:bc816c7e0606e5df98a0c7634b240bb0c8100c3107b8b17b554af702edc6a0c5",
    "zh:cb2f31d58f37020e840af52755c18afd1f09a833c4903ac59270ab440fab57b7",
    "zh:ee0d103b8d0089fb1918311683110b4492a9346f0471b136af46d3b019576b22",
    "zh:f569b65999264a9416862bca5cd2a6177d94ccb0424f3a4ef424428912b9cb3c",
    "zh:f688b9ec761721e401f6859c19c083e3be20a650426f4747cd359cdc079d212a",
  ]
}

provider "registry.terraform.io/hashicorp/time" {
  version = "0.13.0"
  hashes = [
    "h1:iwR4JouIoeVPDabb8XCqsiaZlZ28IcB3tDD9MuPeSXE=",
    "zh:3776dd78ef3053562ccb2f8916d5d3f21a28f05e78859f0f1e4510525f891ecb",
    "zh:541ca0b56f808c15d208b9396f149563b133223c4b66cdefbcfe2d8f1c23497e",
    "zh:67ed315f3572eb20ce6778423b14fbb6faba3090f454bc20ec4146489b4738c0",
    "zh:69dc375845bcfc451426480119f2941ee28b9ef01273d228bb66918180863b3a",
    "zh:78d5eefdd9e494defcb3c68d282b8f96630502cac21d1ea161f53cfe9bb483b3",
    "zh:93c24b7c87b5db9721f60782ac784152599aa78b30fdea2fc9c594d46d92767c",
    "zh:95441cf14312041ae0b34640ff33975c09540125b01f9131358fca50e7be239d",
    "zh:a294103aeed868c58987e131357a3ec259316c937c909e8a726b862d5a227b82",
    "zh:adf6ded3f2e2f318e8aebf1040bc2791b448d006af7d12f7ddc3e8d40b22047a",
    "zh:b2d9c16b7acd20d3813060c4d3647dc5f40598ebbdf59f642d53d189e4e3870a",
    "zh:bc76a5161e9bcf74cadd76b3d4a51de508aa0c62e7f7ae536a87cd7595d81ebf",
    "zh:ce6df2c1052c60b4432cb5c0ead471d7cdb4b285b807c265328a358631fc3610",
  ]
}

# 创建 VPC 网络
resource "google_compute_network" "vpc_network" {
  name                    = "${var.env}-vpc-network"
  auto_create_subnetworks = false
  description             = "${var.env} 环境的 VPC 网络"
  
  lifecycle {
    prevent_destroy = true
  }
}

# 创建子网
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.env}-${var.region}-subnet"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = "10.0.0.0/20"
  
  # 启用私有 Google 访问，允许节点在没有外部 IP 的情况下访问 Google API
  private_ip_google_access = true
  
  lifecycle {
    prevent_destroy = true
  }
}

# 创建防火墙规则 - 允许内部通信
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.env}-allow-internal"
  network = google_compute_network.vpc_network.name
  
  allow {
    protocol = "icmp"
  }
  
  allow {
    protocol = "tcp"
  }
  
  allow {
    protocol = "udp"
  }
  
  source_ranges = ["10.0.0.0/8"]
}

# 创建防火墙规则 - 允许健康检查
resource "google_compute_firewall" "allow_healthcheck" {
  name    = "${var.env}-allow-healthcheck"
  network = google_compute_network.vpc_network.name
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
}

# 创建 GKE 集群
resource "google_container_cluster" "primary" {
  name     = "${var.env}-${var.cluster_name}"
  location = "${var.region}-a"
  
  # 使用我们创建的网络和子网
  network    = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.subnet.name
  
  # 其他配置保持不变...
  remove_default_node_pool = true
  initial_node_count       = 1
  
  deletion_protection = false
  
  # 添加全面的生命周期块
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      initial_node_count,
      node_config,
      master_authorized_networks_config,
      private_cluster_config,
      ip_allocation_policy,
      resource_labels,
      remove_default_node_pool,
      workload_identity_config,
      network_policy,
      addons_config,
      security_posture_config
    ]
  }
  
  # 其余配置保持不变...
}
