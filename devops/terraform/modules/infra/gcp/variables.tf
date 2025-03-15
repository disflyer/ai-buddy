variable "project_id" {
  description = "GCP 项目 ID"
  type        = string
}

variable "region" {
  description = "GCP 区域"
  type        = string
  default     = "us-central1"
}

variable "env" {
  description = "环境（prod 或 staging）"
  type        = string
}

variable "cluster_name" {
  description = "Kubernetes 集群名称"
  type        = string
  default     = "app-cluster"
}

variable "node_count" {
  description = "节点数量"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "节点机器类型"
  type        = string
  default     = "e2-standard-2"
}

variable "disk_size_gb" {
  description = "节点磁盘大小 (GB)"
  type        = number
  default     = 50
}

variable "node_service_account_email" {
  description = "GKE节点使用的服务账号"
  type        = string
  default     = ""  # 在部署时必须提供
}

variable "gpu_type" {
  description = "GPU 类型 (如果需要)"
  type        = string
  default     = ""
}

variable "gpu_count" {
  description = "每个节点的 GPU 数量"
  type        = number
  default     = 0
}

variable "deletion_protection" {
  description = "GKE 集群的删除保护设置"
  type        = bool
  default     = false
}

variable "manage_existing_resources" {
  description = "是否将现有资源纳入 Terraform 管理"
  type        = bool
  default     = false
} 