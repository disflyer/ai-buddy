# 配置 GCS 作为远程状态存储后端
terraform {
  backend "gcs" {
    bucket = "rare-attic-453703-a8-terraform-state" # 存储桶名称，需要提前创建
    prefix = "terraform/state"                      # 状态文件路径前缀
    # credentials 将从 GOOGLE_APPLICATION_CREDENTIALS 环境变量获取
  }
} 