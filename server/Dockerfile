FROM python:3.11.11-slim

WORKDIR /app

# 安装系统依赖和网络工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libopus-dev \
    curl \
    dnsutils \
    iputils-ping \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# 安装PDM
RUN pip install pdm

# 设置PDM环境变量，使其使用系统Python而不是创建虚拟环境
ENV PDM_USE_VENV=false
ENV PYTHONPATH=/app

# 复制依赖文件
COPY pyproject.toml pdm.lock ./

# 安装依赖
RUN pdm install --prod --no-self

# 创建模型目录
RUN mkdir -p /app/models/

# 复制启动脚本
COPY scripts/docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 8000

# 启动应用
CMD ["/app/docker-entrypoint.sh"] 