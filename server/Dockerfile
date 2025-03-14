FROM python:3.10-slim

WORKDIR /app

# 安装PDM
RUN pip install pdm

# 复制依赖文件
COPY pyproject.toml pdm.lock ./

# 安装依赖（不创建虚拟环境）
RUN pdm install --no-self --no-editable --no-isolation

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 8000

# 启动应用
CMD ["pdm", "run", "start"] 