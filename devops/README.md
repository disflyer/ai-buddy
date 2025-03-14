# AI Buddy 基础设施与部署说明

## 项目结构

```
devops/
├── environments/           # 环境特定配置
│   ├── prod/               # 生产环境
│   │   ├── network/        # 网络模块配置
│   │   ├── gke_cluster/    # GKE集群配置
│   │   ├── secret_manager/ # Secret Manager配置
│   │   └── app_server/     # 应用服务配置
│   └── staging/            # 预发布环境
│       ├── network/        # 网络模块配置
│       ├── gke_cluster/    # GKE集群配置
│       ├── secret_manager/ # Secret Manager配置
│       └── app_server/     # 应用服务配置
├── modules/                # Terraform模块
│   ├── network/            # 网络模块
│   ├── gke_cluster/        # GKE集群模块
│   ├── secret_manager/     # Secret Manager模块
│   └── app_server/         # 应用服务模块
├── terragrunt.hcl          # 根Terragrunt配置
└── service-account.json    # GCP服务账号凭证
```

## 访问配置

### 直接通过IP访问 (当前配置)

目前服务配置为可通过负载均衡器的IP地址直接访问：

- **HTTP访问**: `http://<负载均衡器IP>`
- **WebSocket访问**: `ws://<负载均衡器IP>:8080/ws`

通过IP访问时，不会进行TLS加密。如需安全连接，请配置域名和TLS证书。

### 域名结构 (未来配置)

当需要通过域名访问时，可使用以下域名结构：

| 环境 | 域名 | WebSocket路径 |
|-----|------|------------|
| 预发布环境 | api-staging.aibuddy.cn | wss://api-staging.aibuddy.cn/ws |
| 生产环境 | api.aibuddy.cn | wss://api.aibuddy.cn/ws |

启用域名访问需修改配置文件中的 `enable_tls` 和 `enable_ingress` 参数。

## 部署指南

### 前置条件

在开始部署基础设施前，请确保以下API服务已在GCP项目中启用：

1. Compute Engine API (`compute.googleapis.com`)
2. Service Networking API (`servicenetworking.googleapis.com`)
3. Cloud Resource Manager API (`cloudresourcemanager.googleapis.com`)
4. Identity and Access Management API (`iam.googleapis.com`)
5. Kubernetes Engine API (`container.googleapis.com`)

您可以通过Google Cloud Console的"API和服务"部分启用这些API，或使用以下gcloud命令：

```bash
# 启用所需的API
gcloud services enable compute.googleapis.com \
    servicenetworking.googleapis.com \
    cloudresourcemanager.googleapis.com \
    iam.googleapis.com \
    container.googleapis.com
```

确保执行此命令的账号拥有足够的权限。

### 基础设施部署

在部署应用前，需要先部署基础设施：

```bash
# 部署预发布环境基础设施
cd devops/environments/staging/network
terragrunt apply

cd ../gke_cluster
terragrunt apply

cd ../secret_manager
terragrunt apply

# 部署生产环境基础设施流程类似
```

### 应用部署

应用服务部署：

```bash
# 部署预发布环境应用
cd devops/environments/staging/app_server
terragrunt apply

# 部署生产环境应用
cd devops/environments/prod/app_server
terragrunt apply
```

## 获取负载均衡器IP

部署完成后，可以通过以下命令获取服务IP地址：

```bash
# 获取预发布环境IP
kubectl get svc -n staging staging-app-server-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# 获取生产环境IP
kubectl get svc -n production prod-app-server-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## 测试连接

您可以使用以下方法测试连接：

### HTTP测试
```bash
# 测试预发布环境
curl http://<预发布环境IP>/health

# 测试生产环境
curl http://<生产环境IP>/health
```

### WebSocket测试
```javascript
// 浏览器控制台测试预发布环境
const socket = new WebSocket('ws://<预发布环境IP>:8080/ws');
socket.onopen = () => console.log('连接成功');
socket.onmessage = (event) => console.log('收到消息:', event.data);
```

## 安全注意事项

1. IP直接访问不提供TLS加密，请勿在公开环境传输敏感数据
2. 防火墙规则已配置为仅允许必要的端口
3. 生产环境使用高优先级Pod保证服务稳定性

## 运维指南

### 监控

- 应用服务已配置监控
- 可通过Google Cloud Console或Kubernetes Dashboard查看监控数据

### 故障排除

如果通过IP访问失败，请检查：
1. 负载均衡器是否已成功创建并分配IP
2. 防火墙规则是否允许80和8080端口
3. 服务Pod是否正常运行
4. 网络策略是否限制了访问 