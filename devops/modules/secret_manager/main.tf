/**
 * # Secret Manager 模块
 * 
 * 该模块用于管理Google Cloud Secret Manager中的密钥
 */

# 获取项目信息
data "google_project" "project" {}

# 获取Google Cloud客户端配置
data "google_client_config" "default" {}

# 创建Secret Manager密钥
resource "google_secret_manager_secret" "config_yaml" {
  secret_id = "${var.env}_config_yaml"
  
  replication {
    automatic = true
  }
}

# 为Secret Manager密钥授予访问权限
resource "google_secret_manager_secret_iam_binding" "config_yaml_access" {
  project   = data.google_project.project.project_id
  secret_id = google_secret_manager_secret.config_yaml.secret_id
  role      = "roles/secretmanager.secretAccessor"
  members   = var.secret_accessor_members
}

# 获取Secret Manager中的最新配置
data "google_secret_manager_secret_version" "config_yaml" {
  secret    = google_secret_manager_secret.config_yaml.id
  version   = "latest"
  depends_on = [google_secret_manager_secret.config_yaml]
}

# 创建Kubernetes Secret，包含完整的配置文件内容
resource "kubernetes_secret" "config_yaml" {
  metadata {
    name = "${var.env}-config-yaml"
  }

  data = {
    ".config.yaml" = data.google_secret_manager_secret_version.config_yaml.secret_data
  }
} 