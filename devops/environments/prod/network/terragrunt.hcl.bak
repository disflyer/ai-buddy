# 包含环境配置
# 包含根配置
include {
  path = "${get_repo_root()}/devops/terragrunt.hcl"
}

# 指定模块源
terraform {
  source = "../../../modules//network"
}

# 模块特定输入
inputs = {
  vpc_cidr = "10.30.0.0/16"  # 生产环境使用不同的CIDR范围
  
  subnet_config = {
    primary_cidr  = "10.30.1.0/24"
    pods_cidr     = "192.168.64.0/18"
    services_cidr = "192.168.128.0/18"
  }

  firewall_rules = [
    {
      name          = "allow-health-check"
      direction     = "INGRESS"
      ports         = ["80", "443"]
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]  # 仅允许GCP健康检查
      target_tags   = ["web"]
    }
  ]
} 
