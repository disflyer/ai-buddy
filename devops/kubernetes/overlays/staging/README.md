# Kubernetes 配置说明

## 敏感信息管理

本项目使用 Kubernetes Secret 来管理敏感信息，如 API 密钥、访问令牌等。

### 本地开发

对于本地开发和测试，请按照以下步骤操作：

1. 复制示例 Secret 文件：
   ```bash
   cp app-secrets.example.yaml app-secrets.yaml
   ```

2. 编辑 `app-secrets.yaml` 文件，填入实际的密钥和令牌：
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: app-secrets
   type: Opaque
   stringData:
     DEVICE_TOKEN_1: "实际的设备令牌1"
     # ... 其他密钥 ...
   ```

3. 应用 Secret 到本地 Kubernetes 集群：
   ```bash
   kubectl apply -f app-secrets.yaml
   ```

4. 部署应用：
   ```bash
   kubectl apply -k .
   ```

> **注意**：`app-secrets.yaml` 文件已添加到 `.gitignore` 中，不会被提交到 Git 仓库。

### CI/CD 部署

在 CI/CD 环境中，整个 Secret 文件内容存储在一个 GitHub Secret 中，并在部署过程中应用到 Kubernetes 集群。

#### 设置 GitHub Secret

1. 创建并编辑你的 `app-secrets.yaml` 文件，确保包含所有必要的敏感信息
2. 将整个文件内容复制到剪贴板
3. 在 GitHub 仓库中，导航到 Settings > Secrets and variables > Actions
4. 点击 "New repository secret"
5. 名称设置为 `APP_SECRETS_YAML`
6. 值设置为你复制的 YAML 文件内容
7. 点击 "Add secret"

这种方法的优点是：
- 只需要管理一个 GitHub Secret，而不是多个
- 可以直接编辑 YAML 文件，然后更新 Secret
- 更容易维护和更新

## 配置文件说明

- `websocket-server.yaml`: 定义 WebSocket 服务器的 Deployment
- `app-config.yaml`: 包含应用程序的配置信息
- `app-secrets.yaml`: 包含敏感信息（本地开发使用，不提交到仓库）
- `app-secrets.example.yaml`: 示例 Secret 文件，用于参考

## 工作原理

1. 应用启动时，初始化容器 `config-setup` 会将配置文件复制到 `/app/data/.config.yaml`
2. 在复制过程中，使用 `envsubst` 命令替换配置文件中的环境变量引用
3. 环境变量来自 Kubernetes Secret `app-secrets`
4. 应用程序容器可以读取 `/app/data/.config.yaml` 获取配置 