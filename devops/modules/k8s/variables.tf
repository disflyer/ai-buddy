variable "cloud_provider" {
  description = "云提供商 (gcp, aws, alicloud)"
  type        = string
  default     = "gcp"
}

variable "env" {
  description = "环境 (prod 或 staging)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes 命名空间"
  type        = string
}

variable "replica_count" {
  description = "副本数量"
  type        = number
  default     = 2
}

variable "image_registry" {
  description = "容器镜像仓库"
  type        = string
}

variable "image_name" {
  description = "容器镜像名称"
  type        = string
}

variable "image_tag" {
  description = "容器镜像标签"
  type        = string
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

# 新增域名相关变量
variable "domain_name" {
  description = "应用的域名（可选），用于配置 Ingress"
  type        = string
  default     = ""
}

# CDN 配置变量
variable "enable_cdn" {
  description = "是否启用 Google Cloud CDN"
  type        = bool
  default     = false
} 