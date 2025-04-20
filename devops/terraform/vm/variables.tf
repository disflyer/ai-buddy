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
  description = "环境名称（如 dev, prod）"
  type        = string
}

variable "container_image" {
  description = "Docker 镜像地址"
  type        = string
} 