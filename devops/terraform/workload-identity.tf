# Workload Identity配置

locals {
  # 构建服务账号邮箱和ID
  service_account_email = "${var.gke_node_service_account}@${var.project_id}.iam.gserviceaccount.com"
  service_account_id    = "projects/${var.project_id}/serviceAccounts/${local.service_account_email}"
}

# 允许Kubernetes服务账号模拟GCP服务账号
resource "google_service_account_iam_binding" "default_workload_identity_binding" {
  for_each = toset(var.environments)
  
  service_account_id = local.service_account_id
  role               = "roles/iam.workloadIdentityUser"
  members            = [
    "serviceAccount:${var.project_id}.svc.id.goog[${each.value}/${each.value}-default]"
  ]
}

# 为GCS存储桶添加读取权限
resource "google_storage_bucket_iam_binding" "model_bucket_access" {
  bucket = var.gcs_model_bucket
  role   = "roles/storage.objectViewer"
  members = [
    "serviceAccount:${local.service_account_email}"
  ]
} 