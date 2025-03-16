# 跨云平台 Kubernetes 服务部署

这个项目提供了使用 Terraform 实现的跨云平台 Kubernetes 服务部署解决方案，目前优先支持 GCP，同时设计架构便于未来集成其他云平台（AWS、阿里云等）。

## 功能特性

- Kubernetes 集群自动创建和配置
- 单集群多环境架构（通过命名空间隔离 prod 和 staging 环境）
- WebSocket 服务部署和配置
- 自动从 Hugging Face 拉取模型到 Pod

## 目录结构

```
devops/
├── terraform/                     # 基础设施层
│   ├── modules/                   # 可复用模块
│   │   └── infra/                 # 基础设施模块
│   │       └── gcp/               # GCP 实现
│   └── main/                      # 主集群配置
│       ├── main.tf                # 主配置文件
│       ├── variables.tf           # 变量定义
│       └── terraform.tfvars       # 变量值
├── kubernetes/                    # 应用层
│   ├── namespaces/                # 命名空间定义
│   ├── base/                      # 基础应用配置
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   └── overlays/                  # 环境特定覆盖
│       ├── prod/
│       └── staging/
└── deploy.sh                      # 部署脚本
```

## 架构说明

本项目采用单集群多环境架构：

1. **基础设施层**：
   - 使用 Terraform 创建和管理单一共享 GKE 集群
   - 集群内通过命名空间隔离不同环境
   - 使用资源配额和网络策略确保环境隔离

2. **应用层**：
   - 使用 Kustomize 管理不同环境的应用配置
   - 基础配置位于 `kubernetes/base/`
   - 环境特定配置位于 `kubernetes/overlays/<环境>/`

## 使用方法

### 1. 前提条件

- 安装 Terraform (v1.0.0+)
- 安装 kubectl 和 kustomize
- 配置 GCP 凭证 (设置 GOOGLE_APPLICATION_CREDENTIALS 环境变量)
- 创建容器镜像并上传到容器仓库

### 2. 配置

1. 编辑 `terraform/main/terraform.tfvars` 文件，设置您的项目配置：
   - 项目 ID
   - 区域
   - 集群配置
   - 资源配置等

2. 根据需要调整环境特定的 Kustomize 配置：
   - `kubernetes/overlays/staging/`
   - `kubernetes/overlays/prod/`

### 3. 部署

使用部署脚本进行部署：

```bash
# 部署基础设施和应用（默认 staging 环境）
./deploy.sh

# 仅部署基础设施
./deploy.sh --infra

# 仅部署应用
./deploy.sh --app

# 部署到生产环境
./deploy.sh --env prod

# 查看帮助
./deploy.sh --help
```

### 4. 清理资源

```bash
cd terraform/main
terraform destroy
```

## 扩展到其他云平台

当需要扩展到其他云平台时，只需：

1. 在 `terraform/modules/infra/` 下创建对应平台实现
2. 确保新模块保持相同的输出接口
3. 更新应用部署配置，适应新平台特性

## 注意事项

- 确保拥有足够的配额来创建资源
- 使用服务账号时赋予最小权限
- 部署前检查网络和防火墙配置
- 对于生产环境，建议启用额外的安全措施

## Workload Identity配置

项目使用GKE Workload Identity使Kubernetes Pod能够以受控方式访问Google Cloud资源，如GCS存储桶中的模型文件。

### 配置架构

我们采用混合配置方式：

1. **Terraform管理IAM权限**：
   - 基于`terraform/variables.tf`中定义的变量
   - 管理Kubernetes服务账号对GCP服务账号的模拟权限
   - 配置GCS存储桶的访问权限

2. **Kubernetes管理服务账号注释**：
   - 基础配置位于`kubernetes/base/service-account.yaml`
   - 环境特定配置位于`kubernetes/overlays/<环境>/service-account-patch.yaml`
   - 通过kustomize应用到各环境

### 配置方法

1. **应用Terraform配置**：
   ```bash
   cd devops/terraform
   terraform init
   terraform plan    # 查看变更
   terraform apply   # 应用变更
   ```

2. **应用Kubernetes配置**：
   ```bash
   # staging环境
   kubectl apply -k devops/kubernetes/overlays/staging
   
   # 生产环境
   kubectl apply -k devops/kubernetes/overlays/prod
   ```

### 验证配置

```bash
# 检查服务账号注释
kubectl describe serviceaccount default -n staging

# 验证IAM绑定
gcloud iam service-accounts get-iam-policy shared-gke-node-sa@rare-attic-453703-a8.iam.gserviceaccount.com

# 重启Pod以应用新配置
kubectl delete pod <pod-name> -n staging
``` 