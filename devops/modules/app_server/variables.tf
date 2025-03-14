variable "env" {
  description = "环境标识 (staging/prod)"
  type        = string
}

variable "project_id" {
  description = "GCP 项目ID"
  type        = string
}

variable "region" {
  description = "部署区域"
  type        = string
  default     = "us-central1"
}

variable "gke_cluster_name" {
  description = "GKE 集群名称"
  type        = string
}

variable "image_repo" {
  description = "容器镜像仓库地址"
  type        = string
  default     = "gcr.io"
}

variable "image_name" {
  description = "应用容器镜像名称"
  type        = string
  default     = "app-server"
}

variable "image_tag" {
  description = "容器镜像标签"
  type        = string
  default     = "latest"
}

variable "replica_count" {
  description = "初始副本数量"
  type        = number
  default     = 2
}

variable "resource_limits" {
  description = "容器资源限制配置"
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
    enabled         = bool
    min_replicas    = number
    max_replicas    = number
    target_cpu_util = number
  })
  default = {
    enabled         = true
    min_replicas    = 2
    max_replicas    = 10
    target_cpu_util = 70
  }
}

variable "config_yaml_secret_name" {
  description = "Kubernetes中配置文件Secret的名称"
  type        = string
}

variable "google_application_credentials" {
  description = "Google Cloud服务账号凭证JSON"
  type        = string
  sensitive   = true
}

variable "gcp_service_account" {
  description = "GCP服务账号邮箱，用于Workload Identity"
  type        = string
  default     = "ai-buddy-gcs@rare-attic-453703-a8.iam.gserviceaccount.com"
}