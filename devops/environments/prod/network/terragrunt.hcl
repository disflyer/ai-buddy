# 指定模块源
terraform {
  source = "../../../modules//network"
}

# 包含环境级别配置
include {
  path = "../terragrunt.hcl"
}

# 覆盖输入变量，自定义生产环境网络
inputs = {
  env    = "prod"
  region = "us-central1"
  project_id = "rare-attic-453703-a8"
  
  subnet_config = {
    primary_cidr  = "10.129.0.0/20"
    pods_cidr     = "192.169.0.0/18"
    services_cidr = "192.169.64.0/18"
  }
  
  # 禁用私有服务连接，避免需要额外API权限
  enable_private_services = false
  
  # 生产环境防火墙规则 - 更严格的安全配置
  firewall_rules = [
    {
      name        = "prod-allow-internal"
      direction   = "INGRESS"
      source_ranges = ["10.0.0.0/8"]
      target_tags = []
      ports       = ["0-65535"]
    },
    {
      name        = "prod-allow-http"
      direction   = "INGRESS"
      source_ranges = ["0.0.0.0/0"]
      target_tags = ["http-server"]
      ports       = ["80", "443", "8080", "8443"]
    },
    {
      name         = "prod-allow-websocket"
      direction    = "INGRESS"
      source_ranges = ["0.0.0.0/0"]
      target_tags  = ["ws-server"]
      ports        = ["8080", "8443"] 
    },
    {
      name         = "prod-allow-ssh"
      direction    = "INGRESS"
      source_ranges = ["35.235.240.0/20"] # 仅允许通过 Google Cloud IAP 访问
      target_tags  = []
      ports        = ["22"]
    }
  ]
} 
