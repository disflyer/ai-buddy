variable "env" {
  description = "环境名称（如staging、production）"
  type        = string
}

variable "project_id" {
  description = "Google Cloud项目ID"
  type        = string
}

variable "region" {
  description = "Google Cloud区域"
  type        = string
}

variable "secret_accessor_members" {
  description = "可以访问Secret的成员列表（如服务账号）"
  type        = list(string)
  default     = []
} 