terraform {
  backend "gcs" {
    bucket  = "tfstate-rare-attic"            # 存储桶名称
    prefix  = "terraform/prod"                # 状态文件路径前缀
    credentials = "../../service-account.json" # 服务账号凭证路径
  }
} 