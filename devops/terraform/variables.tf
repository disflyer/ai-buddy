variable "project_id" {
  description = "GCP项目ID"
  type        = string
  default     = "rare-attic-453703-a8"
}

variable "region" {
  description = "GCP区域"
  type        = string
  default     = "us-central1"
}

variable "gke_node_service_account" {
  description = "GKE节点服务账号名称"
  type        = string
  default     = "shared-gke-node-sa"
}

variable "gcs_model_bucket" {
  description = "存储模型的GCS存储桶名称"
  type        = string
  default     = "ai-buddy-models"
}

variable "environments" {
  description = "需要配置的环境列表"
  type        = list(string)
  default     = ["staging", "prod"]
} 