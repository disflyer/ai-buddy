terraform {
  backend "gcs" {
    bucket  = "tfstate-rare-attic"            # 存储桶名称
    prefix  = "terraform/staging"             # 状态文件路径前缀
  }
} 