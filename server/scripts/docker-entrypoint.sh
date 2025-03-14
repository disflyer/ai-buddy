#!/bin/bash
set -e

# 显示Python路径
echo "Python path: $PYTHONPATH"
echo "Python version: $(python --version)"

# 显示已安装的包
echo "Installed packages:"
pip list | grep -E "ruamel|yaml"

# 确保ruamel.yaml已安装
if ! pip list | grep -q "ruamel.yaml"; then
  echo "Installing ruamel.yaml..."
  pip install ruamel.yaml
fi

# 测试导入
echo "Testing imports..."
python /app/scripts/test-imports.py

# 启动应用
echo "Starting application..."
exec pdm run start