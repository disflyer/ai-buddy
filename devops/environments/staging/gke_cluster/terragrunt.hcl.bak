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

# 模块特定输入
inputs = {
  vpc_name = dependency.network.outputs.vpc_name
  
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
    day        = "SUNDAY"
    start_time = "03:00"
  }
} 
