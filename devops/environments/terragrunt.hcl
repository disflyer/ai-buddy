# 环境级别terragrunt配置，作为根配置和模块配置的中间层

# 包含根配置
include {
  path = find_in_parent_folders()
}

# 环境特定的默认配置
locals {
  # 从环境目录中获取环境名称
  env = basename(get_terragrunt_dir())
}

# 环境级别默认值，可以被子模块覆盖
inputs = {
  # 根据环境设置不同的默认参数
  common_tags = {
    environment = local.env
    managed_by  = "terragrunt"
  }
} 