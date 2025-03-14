include {
  path = "${get_repo_root()}/devops/terragrunt.hcl"
}

# 指定模块源
terraform {
  source = "../../../modules//network"
}

# 模块特定输入
inputs = {
  vpc_cidr = "10.20.0.0/16"
  
  subnet_config = {
    primary_cidr  = "10.20.1.0/24"
    pods_cidr     = "192.168.1.0/24"
    services_cidr = "192.168.2.0/24"
  }

  firewall_rules = [
    {
      name          = "allow-http-debug"
      direction     = "INGRESS"
      ports         = ["80", "8080"]
      source_ranges = ["0.0.0.0/0"]  # 仅测试环境允许临时开放
      target_tags   = ["debug"]
    },
    {
      name          = "allow-websocket"
      direction     = "INGRESS"
      ports         = ["443", "8443"]  # WSS协议端口
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["app-server"]
    }
  ]
  
  # 是否启用私有服务连接 - 一般只在需要私有API访问或托管服务时使用
  enable_private_services = false
} 
