# 设置 GCP 提供者
provider "google" {
  project = var.project_id
  region  = var.region
}

# 启用必要的 API
resource "google_project_service" "required_apis" {
  for_each = toset([
    "iap.googleapis.com",              # Identity-Aware Proxy API
    "compute.googleapis.com",          # Compute Engine API
    "iam.googleapis.com",              # Identity and Access Management API
    "artifactregistry.googleapis.com", # Artifact Registry API
    "networkmanagement.googleapis.com" # Network Management API
  ])
  
  project = var.project_id
  service = each.key

  disable_dependent_services = false
  disable_on_destroy        = false

  timeouts {
    create = "30m"
    update = "40m"
  }
}

# 创建 Artifact Registry 仓库
resource "google_artifact_registry_repository" "docker_repo" {
  depends_on = [google_project_service.required_apis]

  location      = var.region
  repository_id = "shared-app-registry"
  description   = "Docker repository for AI Buddy applications"
  format        = "DOCKER"

  docker_config {
    immutable_tags = false
  }
}

# 为服务账号授予 Artifact Registry 访问权限
resource "google_artifact_registry_repository_iam_member" "docker_repo_access" {
  depends_on = [google_artifact_registry_repository.docker_repo]

  location   = google_artifact_registry_repository.docker_repo.location
  repository = google_artifact_registry_repository.docker_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.instance_sa.email}"
}

# 获取当前用户信息
data "google_client_openid_userinfo" "current_user" {}

# 创建 VPC 网络
resource "google_compute_network" "vpc" {
  name                    = "${var.env}-network"
  auto_create_subnetworks = false
}

# 创建子网
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.env}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# 创建防火墙规则
resource "google_compute_firewall" "allow_websocket" {
  name    = "${var.env}-allow-websocket"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8000", "22"]  # WebSocket 端口和 SSH
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["websocket-server"]
}

# 创建 IAP SSH 防火墙规则
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.env}-allow-iap-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP 的源 IP 范围
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["websocket-server"]
}

# 创建服务账号
resource "google_service_account" "instance_sa" {
  account_id   = "${var.env}-instance-sa"
  display_name = "Service Account for WebSocket Server ${var.env}"
}

# 为服务账号授予必要的权限
resource "google_project_iam_member" "instance_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/artifactregistry.reader",
    "roles/storage.objectViewer",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.writer",  # 添加写入权限以支持Docker操作
    "roles/compute.instanceAdmin.v1"  # 添加计算实例管理权限
  ])
  
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.instance_sa.email}"
}

# 为当前用户添加 IAP 访问权限
resource "google_iap_tunnel_iam_binding" "tunnel_iam" {
  depends_on = [google_project_service.required_apis]
  
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  members = [
    "serviceAccount:${google_service_account.instance_sa.email}",
    "user:${data.google_client_openid_userinfo.current_user.email}"
  ]
}

# 创建服务账号密钥
resource "google_service_account_key" "instance_sa_key" {
  service_account_id = google_service_account.instance_sa.name
}

# 创建 GCS bucket
resource "google_storage_bucket" "config_bucket" {
  name          = "${var.project_id}-config-${var.env}"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true
}

# 为服务账号授予 Storage Object Viewer 权限
resource "google_storage_bucket_iam_member" "config_viewer" {
  bucket = google_storage_bucket.config_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.instance_sa.email}"
}

# 添加输出 bucket 名称
output "config_bucket_name" {
  value = google_storage_bucket.config_bucket.name
  description = "配置文件存储桶名称"
}

# 创建启动脚本
locals {
  startup_script = <<-EOF
    #!/bin/bash
    exec 1>/var/log/startup-script.log 2>&1
    set -ex

    echo "开始执行启动脚本..."

    # 安装必要的软件包
    echo "安装必要的软件包..."
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common

    # 添加 Docker 的官方 GPG 密钥
    echo "添加 Docker GPG 密钥..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # 设置 Docker 的稳定版仓库
    echo "设置 Docker 仓库..."
    echo "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 安装 Docker
    echo "安装 Docker..."
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io

    # 等待 Docker 服务启动
    echo "等待 Docker 服务启动..."
    systemctl start docker
    systemctl enable docker
    while ! systemctl is-active docker >/dev/null 2>&1; do
      echo "等待 Docker 服务启动..."
      sleep 5
    done

    # 确保数据目录存在
    mkdir -p /app/data

    # 配置服务账号密钥
    if [ ! -f /app/data/key.json ]; then
      echo "配置服务账号..."
      echo '${base64decode(google_service_account_key.instance_sa_key.private_key)}' > /app/data/key.json
      chmod 600 /app/data/key.json
    fi

    # 配置 Docker 认证
    echo "配置 Docker 认证..."
    gcloud auth activate-service-account --key-file=/app/data/key.json
    gcloud auth configure-docker us-central1-docker.pkg.dev --quiet

    # 从 GCS 下载配置文件
    echo "下载配置文件..."
    gsutil cp gs://${google_storage_bucket.config_bucket.name}/config/.config.yaml /app/data/.config.yaml
    chmod 644 /app/data/.config.yaml

    # 停止并删除旧容器
    echo "清理旧容器..."
    docker rm -f websocket-server || true

    # 拉取镜像
    echo "拉取镜像..."
    for i in {1..3}; do
      if docker pull ${var.container_image}; then
        break
      fi
      echo "第$i次拉取失败，重试..."
      sleep 5
    done

    # 启动容器
    echo "启动容器..."
    docker run -d \
      --name websocket-server \
      --restart always \
      -p 8000:8000 \
      -e ENVIRONMENT=${var.env} \
      -e PORT=8000 \
      -e HOST=0.0.0.0 \
      -e GOOGLE_APPLICATION_CREDENTIALS=/app/data/key.json \
      -v /app/data:/app/data \
      ${var.container_image}

    # 验证容器是否正在运行
    echo "验证容器状态..."
    if ! docker ps | grep websocket-server; then
      echo "容器未能正常启动，查看日志："
      docker logs websocket-server
      exit 1
    fi

    echo "启动脚本执行完成"
  EOF
}

# 创建计算实例
resource "google_compute_instance" "websocket_server" {
  name         = "${var.env}-websocket-server"
  machine_type = "t2a-standard-2"  # ARM64 架构，2vCPU, 8GB RAM
  zone         = "${var.region}-a"

  tags = ["websocket-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts-arm64"  # Ubuntu 22.04 LTS ARM64 版本
      size  = 20  # GB
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link
    access_config {
      // 自动分配外部 IP
    }
  }

  metadata = {
    startup-script = local.startup_script
    enable-oslogin = "TRUE"  # 启用 OS Login
  }

  service_account {
    email  = google_service_account.instance_sa.email
    scopes = ["cloud-platform"]
  }

  # 确保网络和防火墙规则已创建
  depends_on = [
    google_compute_subnetwork.subnet,
    google_compute_firewall.allow_websocket,
    google_project_iam_member.instance_sa_roles,
    google_project_service.required_apis
  ]
}

# 输出
output "instance_ip" {
  value = google_compute_instance.websocket_server.network_interface[0].access_config[0].nat_ip
  description = "WebSocket 服务器的外部 IP 地址"
}

output "websocket_url" {
  value = "ws://${google_compute_instance.websocket_server.network_interface[0].access_config[0].nat_ip}:8000/ws"
  description = "WebSocket 服务的 URL"
} 