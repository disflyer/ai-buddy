# 创建用于存储 Terraform 状态的 GCS 存储桶
resource "google_storage_bucket" "terraform_state" {
  name          = "${var.project_id}-tfstate"
  location      = var.region
  force_destroy = true
  
  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true
} 