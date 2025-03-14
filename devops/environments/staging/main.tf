# environments/staging/main.tf
module "app_server" {
  source = "../../modules/app_server"

  env       = "staging"
  project_id = "rare-attic-453703-a8"
  
  resource_limits = {
    cpu    = "2"
    memory = "8Gi"
    gpu    = 0  # Staging环境不启用GPU
  }
  
  autoscaling = {
    enabled         = true
    min_replicas    = 2
    max_replicas    = 8
    target_cpu_util = 60
  }
}

module "gke_cluster" {
  source = "../../modules/gke_cluster"

  project_id = "rare-attic-453703-a8"
  env        = "staging"
  region     = "us-central1"
  vpc_name   = "staging-vpc"

  cluster_tier = {
    machine_type        = "e2-medium"
    disk_size_gb        = 100
    min_node_count      = 1
    max_node_count      = 3
    preemptible         = true
    gpu_enabled         = false
    autoscaling_profile = "BALANCED"
  }
}

module "network" {
  source = "../../modules/network"

  project_id = "rare-attic-453703-a8"
  env        = "staging"
  region     = "us-central1"

  subnet_config = {
    primary_cidr  = "10.20.0.0/20"
    pods_cidr     = "192.168.128.0/18"  # Staging专用Pod CIDR
    services_cidr = "192.168.192.0/18"  # Staging专用Service CIDR
  }

  firewall_rules = [
    {
      name          = "allow-ssh",
      direction     = "INGRESS",
      ports         = ["22"],
      source_ranges = ["0.0.0.0/0"], # 仅示例，生产环境应限制IP
      target_tags   = ["bastion"]
    }
  ]
}