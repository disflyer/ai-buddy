# FastAPI Auth App

基于FastAPI的用户认证系统，提供邮箱注册、登录、邮箱验证和密码重置功能。

## 功能特性

- 用户注册
- 邮箱验证
- 用户登录
- 密码重置
- JWT认证
- 异步SQL数据库
- 邮件发送

## 技术栈

- FastAPI
- SQLAlchemy
- Pydantic
- PostgreSQL
- Alembic
- Poetry

## 开发环境设置

1. 安装依赖：

```bash
# 安装poetry
curl -sSL https://install.python-poetry.org | python3 -

# 安装项目依赖
poetry install
```

2. 配置环境变量：

```bash
# 复制环境变量示例文件
cp .env.example .env

# 编辑.env文件，填写必要的配置信息
```

3. 初始化数据库：

```bash
# 创建数据库迁移
poetry run alembic revision --autogenerate -m "Initial migration"

# 执行数据库迁移
poetry run alembic upgrade head
```

4. 运行开发服务器：

```bash
poetry run uvicorn src.main:app --reload
```

## API文档

启动服务器后，可以访问以下地址查看API文档：

- Swagger UI: http://localhost:8000/api/docs
- ReDoc: http://localhost:8000/api/redoc

## 项目结构

```
app-server/
├── alembic/             # 数据库迁移
├── src/                 # 源代码
│   ├── api/            # API路由
│   ├── core/           # 核心配置
│   ├── models/         # 数据库模型
│   ├── schemas/        # Pydantic模型
│   ├── services/       # 业务逻辑
│   └── utils/          # 工具函数
└── tests/              # 测试文件
```

## 环境变量

项目使用以下环境变量：

- `APP_NAME`: 应用名称
- `ENVIRONMENT`: 环境（development/production）
- `DEBUG`: 调试模式
- `POSTGRES_*`: PostgreSQL数据库配置
- `JWT_*`: JWT配置
- `SMTP_*`: 邮件服务器配置
- `FRONTEND_URL`: 前端应用URL

## 许可证

MIT 