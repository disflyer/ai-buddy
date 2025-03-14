variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

variable "env" {
  description = "环境标识 (prod/staging/dev)"
  type        = string
  validation {
    condition     = contains(["prod", "staging", "dev"], var.env)
    error_message = "The environment value must be one of: prod, staging, or dev."
  }
}

variable "region" {
  description = "部署区域"
  type        = string
  default     = "us-central1"
}

variable "vpc_cidr" {
  description = "VPC主CIDR范围"
  type        = string
  default     = "10.128.0.0/16"
}

variable "subnet_config" {
  description = "子网及次要范围配置"
  type = object({
    primary_cidr   = string
    pods_cidr      = string
    services_cidr  = string
  })
  default = {
    primary_cidr   = "10.128.0.0/20"
    pods_cidr      = "192.168.0.0/18"
    services_cidr  = "192.168.64.0/18"
  }
}

variable "firewall_rules" {
  description = "自定义防火墙规则"
  type = list(object({
    name        = string
    direction   = string
    ports       = list(string)
    source_ranges = list(string)
    target_tags = list(string)
  }))
  default = []
}