project_id        = "your-gcp-project-id"
region            = "us-central1"
cluster_name      = "app-cluster"
node_count        = 3
machine_type      = "e2-standard-4"
disk_size_gb      = 100
gpu_type          = ""  # 如需 GPU，填写如 "nvidia-tesla-t4"
gpu_count         = 0   # GPU 数量，默认 0 表示不使用 GPU
replica_count     = 3
# 不再需要 image_registry，会自动创建
image_name        = "app-server"
image_tag         = "latest"
huggingface_repo_id = "FunAudioLLM/SenseVoiceSmall"
resource_limits   = {
  cpu    = "2"
  memory = "4Gi"
  gpu    = 0
}
internal_lb       = false
domain_name       = ""  # 如有域名，在这里填写
enable_cdn        = false 