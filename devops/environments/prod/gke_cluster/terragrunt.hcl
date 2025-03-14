# 包含环境配置
include {
  path = "../terragrunt.hcl"
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
    machine_type        = "e2-standard-4"  # 生产环境使用更高性能机型
    disk_size_gb        = 100
    min_node_count      = 3
    max_node_count      = 10
    preemptible         = false            # 生产环境不使用抢占式节点
    gpu_enabled         = false
    gpu_type            = "nvidia-tesla-t4"
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
  }
  
  maintenance_window = {
    day        = "SUNDAY"
    start_time = "02:00"
  }
} 