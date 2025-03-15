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
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "GKE 节点磁盘大小 (GB)"
  type        = number
  default     = 100
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

variable "replica_count" {
  description = "应用副本数量"
  type        = number
  default     = 3
}

variable "image_name" {
  description = "容器镜像名称"
  type        = string
}

variable "image_tag" {
  description = "容器镜像标签"
  type        = string
  default     = "latest"
}

variable "huggingface_repo_id" {
  description = "Hugging Face 模型仓库 ID"
  type        = string
  default     = "FunAudioLLM/SenseVoiceSmall"
}

variable "model_revision" {
  description = "模型版本/标签"
  type        = string
  default     = ""
}

variable "resource_limits" {
  description = "资源限制"
  type = object({
    cpu    = string
    memory = string
    gpu    = number
  })
  default = {
    cpu    = "2"
    memory = "4Gi"
    gpu    = 0
  }
}

variable "internal_lb" {
  description = "使用内部负载均衡器"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "应用的域名（可选），用于配置 Ingress"
  type        = string
  default     = ""
}

variable "enable_cdn" {
  description = "是否启用 Google Cloud CDN"
  type        = bool
  default     = false
} 