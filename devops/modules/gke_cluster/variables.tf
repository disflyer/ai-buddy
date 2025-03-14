variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

variable "env" {
  description = "环境标识 (staging/prod/dev)"
  type        = string
  validation {
    condition     = contains(["staging", "prod", "dev"], var.env)
    error_message = "环境标识必须是 staging、prod 或 dev"
  }
}

variable "region" {
  description = "集群部署区域"
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  description = "VPC网络名称"
  type        = string
}

variable "subnet_cidr" {
  description = "子网CIDR范围"
  type        = string
  default     = "10.20.0.0/20"
}

variable "cluster_tier" {
  description = "集群等级配置"
  type = object({
    machine_type        = string
    disk_size_gb        = number
    min_node_count      = number
    max_node_count      = number
    preemptible         = bool
    gpu_enabled         = bool
    gpu_type            = string
    autoscaling_profile = string
  })
  default = {
    machine_type        = "e2-medium"
    disk_size_gb        = 100
    min_node_count      = 1
    max_node_count      = 5
    preemptible         = true
    gpu_enabled         = false
    gpu_type            = "nvidia-tesla-t4"
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
  }
}

variable "maintenance_window" {
  description = "维护窗口配置"
  type = object({
    day       = string
    start_time = string
  })
  default = {
    day        = "SUNDAY"
    start_time = "03:00"
  }
}

variable "enable_multi_env" {
  description = "是否启用多环境支持（在同一集群中部署多个环境）"
  type        = bool
  default     = true
}

variable "resource_labels" {
  description = "集群资源标签"
  type        = map(string)
  default     = {}
}