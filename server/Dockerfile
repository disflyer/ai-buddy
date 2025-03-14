FROM python:3.11.11-slim

WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libopus-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装PDM
RUN pip install pdm

# 复制依赖文件
COPY pyproject.toml pdm.lock ./

# 安装依赖
RUN pdm sync

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 8000

# 启动应用
CMD ["pdm", "run", "start"] 