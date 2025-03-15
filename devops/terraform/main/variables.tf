variable "project_id" {
  description = "GCP 项目 ID"
  type        = string
}

variable "region" {
  description = "GCP 区域"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Kubernetes 集群名称"
  type        = string
  default     = "app-cluster"
}

variable "node_count" {
  description = "GKE 节点数量"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "GKE 节点机器类型"
  type        = string
  default     = "e2-standard-2"
}

variable "disk_size_gb" {
  description = "GKE 节点磁盘大小 (GB)"
  type        = number
  default     = 50
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