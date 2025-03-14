# 包含环境配置
include {
  path = "../terragrunt.hcl"
}

# 指定模块源
terraform {
  source = "../../../modules//network"
}

# 模块特定输入
inputs = {
  vpc_cidr = "10.30.0.0/16"
  
  subnet_config = {
    primary_cidr  = "10.30.1.0/24"
    pods_cidr     = "192.168.3.0/24"
    services_cidr = "192.168.4.0/24"
  }

  firewall_rules = [
    {
      name          = "allow-all-debug"
      direction     = "INGRESS"
      ports         = ["0-65535"]
      source_ranges = ["0.0.0.0/0"]  # 开发环境允许全开放
      target_tags   = ["debug"]
    }
  ]
} 