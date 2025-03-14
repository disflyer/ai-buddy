variable "env" {
  description = "环境标识 (prod/staging/dev)"
  type        = string
  validation {
    condition     = contains(["prod", "staging", "dev"], var.env)
    error_message = "The environment value must be one of: prod, staging, or dev."
  }
}

variable "project_id" {
  description = "Google Cloud项目ID"
  type        = string
}

variable "region" {
  description = "Google Cloud区域"
  type        = string
}

variable "gke_cluster_name" {
  description = "GKE集群名称"
  type        = string
}

variable "replica_count" {
  description = "应用服务副本数量"
  type        = number
  default     = 1
}

variable "image_repo" {
  description = "容器镜像仓库地址"
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

variable "resource_limits" {
  description = "资源限制配置"
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

variable "autoscaling" {
  description = "自动扩缩容配置"
  type = object({
    enabled          = bool
    min_replicas     = number
    max_replicas     = number
    target_cpu_util  = number
    target_memory_util = number
  })
  default = {
    enabled          = false
    min_replicas     = 1
    max_replicas     = 5
    target_cpu_util  = 80
    target_memory_util = 80
  }
}

variable "gcp_service_account" {
  description = "GCP服务账号邮箱"
  type        = string
}

variable "google_application_credentials" {
  description = "Google Cloud服务账号凭证JSON内容"
  type        = string
  sensitive   = true
}

variable "config_yaml_secret_name" {
  description = "配置文件Secret名称"
  type        = string
}

variable "namespace" {
  description = "Kubernetes命名空间"
  type        = string
  default     = "default"
}

variable "model_revision" {
  description = "Hugging Face模型版本（分支、标签或提交哈希）"
  type        = string
  default     = ""
}

variable "enable_ingress" {
  description = "是否创建Ingress资源"
  type        = bool
  default     = false
}

variable "ingress_host" {
  description = "Ingress主机名"
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "是否启用监控"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "是否启用网络策略"
  type        = bool
  default     = false
}

variable "pod_annotations" {
  description = "Pod附加注解"
  type        = map(string)
  default     = {}
}

variable "pod_labels" {
  description = "Pod附加标签"
  type        = map(string)
  default     = {}
}

variable "priority_class_name" {
  description = "Pod优先级类名称"
  type        = string
  default     = ""
}