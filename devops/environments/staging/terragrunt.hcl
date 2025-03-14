# 包含根配置
include {
  path = find_in_parent_folders()
}

# 环境特定变量
locals {
  env = "staging"
}

# 环境级输入变量
inputs = {
  project_id        = "rare-attic-453703-a8"
  region            = "us-central1"
  env               = local.env
  preemptible_nodes = true  # 使用抢占式节点节省成本
} 