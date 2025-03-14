variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

variable "env" {
  description = "环境标识 (prod/staging)"
  type        = string
  validation {
    condition     = contains(["prod", "staging"], var.env)
    error_message = "The environment value must be one of: prod, staging, or dev."
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
    day        = string
    start_time = string
  })
  default = {
    day        = "SU"  # SUNDAY的缩写
    start_time = "03:00"
  }
  validation {
    condition     = contains(["MO", "TU", "WE", "TH", "FR", "SA", "SU"], var.maintenance_window.day)
    error_message = "维护窗口的日期必须是以下值之一: MO, TU, WE, TH, FR, SA, SU"
  }
  validation {
    condition     = can(regex("^([01]?[0-9]|2[0-3]):[0-5][0-9]$", var.maintenance_window.start_time))
    error_message = "开始时间必须是24小时制的时间格式，例如: 03:00, 15:30"
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