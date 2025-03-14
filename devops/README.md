# 基础设施即代码 (IaC) - Terragrunt

本项目使用Terragrunt管理多环境基础设施，实现了配置的DRY（不重复自己）原则和模块间依赖管理。

## 目录结构

```
devops/
├── terragrunt.hcl                # 根配置，定义共享设置
├── environments/
│   ├── staging/                  # 测试环境
│   │   ├── terragrunt.hcl        # 环境级配置
│   │   ├── network/              # 网络模块
│   │   ├── gke_cluster/          # GKE集群模块
│   │   └── app_server/           # 应用服务模块
│   └── prod/                     # 生产环境
│       ├── terragrunt.hcl
│       ├── network/
│       ├── gke_cluster/
│       └── app_server/
└── modules/                      # Terraform模块
    ├── network/
    ├── gke_cluster/
    └── app_server/
```

## 前置条件

1. 安装Terraform (>= 1.0.0)
2. 安装Terragrunt
3. 配置GCP服务账号凭证 (`service-account.json`)

## 使用方法

### 初始化和规划单个模块

```bash
# 进入模块目录
cd environments/staging/network

# 初始化
terragrunt init

# 查看计划
terragrunt plan

# 应用更改
terragrunt apply
```

### 初始化和规划整个环境

```bash
# 进入环境目录
cd environments/staging

# 初始化所有模块
terragrunt run-all init

# 查看所有模块的计划
terragrunt run-all plan

# 应用所有模块的更改
terragrunt run-all apply
```

### 销毁资源

```bash
# 销毁单个模块
cd environments/staging/app_server
terragrunt destroy

# 销毁整个环境
cd environments/staging
terragrunt run-all destroy
```

## 依赖关系

模块间的依赖关系通过Terragrunt的`dependency`块自动管理：

1. 网络模块无依赖
2. GKE集群模块依赖网络模块
3. 应用服务模块依赖GKE集群模块

## 环境特定配置

每个环境都有自己的配置文件，可以根据需要调整参数：

- `staging`：测试环境，使用较小的资源配置和抢占式节点
- `prod`：生产环境，使用更高性能的资源配置和稳定节点

## 环境管理

本项目仅维护两个环境：

- `staging`：用于测试和预发布
- `prod`：生产环境

如需修改环境配置，请编辑对应环境目录下的 terragrunt.hcl 文件。 