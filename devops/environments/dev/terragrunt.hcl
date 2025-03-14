# 包含根配置
include {
  path = "${get_repo_root()}/devops/terragrunt.hcl"
}

# 环境特定变量
locals {
  env = "dev"
}

# 环境级输入变量
inputs = {
  region            = "us-central1"
  env               = local.env
  preemptible_nodes = true  # 开发环境使用抢占式节点节省成本
} 