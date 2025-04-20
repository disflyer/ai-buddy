# 使用 GCS 存储桶存储状态
terraform {
  backend "gcs" {
    bucket = "rare-attic-453703-a8-tfstate"
    prefix = "websocket/vm"
  }
} 