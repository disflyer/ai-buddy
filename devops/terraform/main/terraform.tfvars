project_id   = "rare-attic-453703-a8"
region       = "us-central1"
cluster_name = "app-cluster"
node_count   = 1               # 1个节点
machine_type = "n2-highcpu-8"  # 标准高CPU机型: 8个vCPU，8GB内存
disk_size_gb = 50
gpu_type     = "" # 如需 GPU，填写如 "nvidia-tesla-t4"
gpu_count    = 0  # GPU 数量，默认 0 表示不使用 GPU 