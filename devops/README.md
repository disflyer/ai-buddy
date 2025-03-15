# 跨云平台 Kubernetes 服务部署

这个项目提供了使用 Terraform 实现的跨云平台 Kubernetes 服务部署解决方案，目前优先支持 GCP，同时设计架构便于未来集成其他云平台（AWS、阿里云等）。

## 功能特性

- Kubernetes 集群自动创建和配置
- 通过命名空间隔离 prod 和 staging 环境
- WebSocket 服务部署和配置
- 自动从 Hugging Face 拉取模型到 Pod

## 目录结构

```
terraform-multi-cloud/
├── modules/
│   ├── infra/
│   │   └── gcp/              # GCP 基础设施模块
│   │       ├── main.tf       # GKE 集群创建
│   │       ├── variables.tf  # 变量定义
│   │       └── outputs.tf    # 输出定义
│   └── k8s/                  # Kubernetes 应用模块
│       ├── main.tf           # 基础配置
│       ├── app.tf            # 应用部署
│       ├── model.tf          # 模型加载
│       ├── variables.tf      # 变量定义
│       └── outputs.tf        # 输出定义
└── environments/
    ├── prod/                 # 生产环境
    │   ├── main.tf           # 主配置
    │   ├── variables.tf      # 变量定义
    │   └── terraform.tfvars  # 环境变量值
    └── staging/              # 预发环境
        ├── main.tf           # 主配置
        ├── variables.tf      # 变量定义
        └── terraform.tfvars  # 环境变量值
```

## 使用方法

### 1. 前提条件

- 安装 Terraform (v1.0.0+)
- 配置云平台凭证 (GCP: 设置 GOOGLE_APPLICATION_CREDENTIALS 环境变量)
- 创建容器镜像并上传到容器仓库

### 2. 配置

1. 进入对应环境目录（prod 或 staging）
2. 编辑 `terraform.tfvars` 文件，设置您的项目配置：
   - 项目 ID
   - 区域
   - 镜像信息
   - 资源配置等

### 3. 部署

```bash
# 初始化 Terraform
cd environments/prod  # 或 staging
terraform init

# 查看执行计划
terraform plan

# 应用配置
terraform apply
```

### 4. 清理资源

```bash
terraform destroy
```

## 扩展到其他云平台

当需要扩展到其他云平台时，只需：

1. 在 `modules/infra/` 下创建对应平台实现
2. 确保新模块保持相同的输出接口
3. 更新 `k8s` 模块的云平台特定配置
4. 创建新环境配置，指定 `cloud_provider` 参数

## 注意事项

- 确保拥有足够的配额来创建资源
- 使用服务账号时赋予最小权限
- 部署前检查网络和防火墙配置
- 对于生产环境，建议启用额外的安全措施 