# 包含根配置
include {
  path = "${get_repo_root()}/devops/terragrunt.hcl"
}

# 环境特定变量
locals {
  env = "prod"
}

# 环境级输入变量
inputs = {
  region            = "us-central1"
  env               = local.env
  preemptible_nodes = false  # 生产环境不使用抢占式节点，保证稳定性
} 