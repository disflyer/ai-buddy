# 包含环境配置
# 包含根配置
include {
  path = "${get_repo_root()}/devops/terragrunt.hcl"
}

# 指定模块源
terraform {
  source = "../../../modules//gke_cluster"
}

# 依赖关系
dependency "network" {
  config_path = "../network"
  
  # 配置依赖项输出的映射
  mock_outputs = {
    vpc_name = "mock-vpc"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# 从根配置获取全局变量
locals {
  # 从根配置获取变量
  root_config = read_terragrunt_config(find_in_parent_folders())
  
  # 获取项目配置
  project_id = local.root_config.locals.project_id
  region     = local.root_config.locals.region
  env        = "staging"  # 明确设置环境
  
  # 定义集群名称
  cluster_name = "ai-buddy-cluster"
}

# 模块特定输入
inputs = {
  # 项目和环境变量
  project_id = local.project_id
  region     = local.region
  env        = local.env
  
  # 网络配置
  vpc_name = dependency.network.outputs.vpc_name
  
  # 环境特定的网络资源创建控制
  # 可以被 TF_VAR_create_network_resources 环境变量覆盖
  create_network_resources = get_env("TF_VAR_create_network_resources", "false")
  
  # 集群配置
  cluster_name = local.cluster_name
  kubernetes_version = "1.31.5-gke.1233000"  # 指定最新的稳定版本
  
  cluster_tier = {
    machine_type        = "e2-standard-2"  # 测试环境使用经济机型
    disk_size_gb        = 50
    min_node_count      = 1
    max_node_count      = 3
    preemptible         = true             # 启用抢占式节点
    gpu_enabled         = false
    gpu_type            = "nvidia-tesla-t4"
    autoscaling_profile = "BALANCED"
  }
  
  maintenance_window = {
    start_time = "03:00"  # 每天凌晨3点开始维护
  }
  
  # 网络配置
  cluster_network_config = {
    master_ipv4_cidr_block   = "172.16.0.0/28"
    cluster_ipv4_cidr_block  = "10.100.0.0/16"
    services_ipv4_cidr_block = "10.101.0.0/16"
  }
} 
