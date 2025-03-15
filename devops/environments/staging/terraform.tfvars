project_id        = "rare-attic-453703-a8"
region            = "us-central1"
cluster_name      = "app-cluster"
node_count        = 2
machine_type      = "e2-standard-2"
disk_size_gb      = 50
gpu_type          = ""  # 如需 GPU，填写如 "nvidia-tesla-t4"
gpu_count         = 0   # GPU 数量，默认 0 表示不使用 GPU
replica_count     = 1
# 不再需要 image_registry，会自动创建
image_name        = "ai-buddy/app-server"
image_tag         = "latest"
huggingface_repo_id = "FunAudioLLM/SenseVoiceSmall"
resource_limits   = {
  cpu    = "4"
  memory = "8Gi"
  gpu    = 0
}
internal_lb       = false
domain_name       = ""  # 如有域名，在这里填写
enable_cdn        = false 