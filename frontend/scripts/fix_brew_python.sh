#!/bin/bash
# 获取当前 pyenv 使用的 Python 版本和路径
PYENV_VERSION=$(pyenv version | cut -d' ' -f1)
PYENV_PYTHON_PATH=$(pyenv which python)
PYENV_PYTHON_DIR=$(dirname "$PYENV_PYTHON_PATH")

# 创建或更新 Homebrew 环境变量配置文件
BREW_ENV_FILE=~/.brew_env
echo "# Homebrew 环境变量配置，使用 pyenv 的 Python" > $BREW_ENV_FILE
echo "export PATH=\"$PYENV_PYTHON_DIR:\$PATH\"" >> $BREW_ENV_FILE
echo "export PYTHONPATH=\"$PYENV_PYTHON_DIR\"" >> $BREW_ENV_FILE

# 检查是否已经在 shell 配置文件中添加了 source 命令
for SHELL_RC in ~/.zshrc ~/.bashrc; do
  if [ -f "$SHELL_RC" ]; then
    if ! grep -q "source $BREW_ENV_FILE" "$SHELL_RC"; then
      echo "" >> "$SHELL_RC"
      echo "# 加载 Homebrew Python 环境变量" >> "$SHELL_RC"
      echo "if [ -f $BREW_ENV_FILE ]; then" >> "$SHELL_RC"
      echo "  source $BREW_ENV_FILE" >> "$SHELL_RC"
      echo "fi" >> "$SHELL_RC"
    fi
  fi
done

# 创建符号链接，确保 Homebrew 使用 pyenv 的 Python
mkdir -p ~/.homebrew/bin
ln -sf "$PYENV_PYTHON_PATH" ~/.homebrew/bin/python
ln -sf "$PYENV_PYTHON_PATH" ~/.homebrew/bin/python3

# 添加到 PATH
echo "export PATH=\"$HOME/.homebrew/bin:\$PATH\"" >> $BREW_ENV_FILE

# 输出提示信息
echo "已配置 Homebrew 使用 pyenv 的 Python $PYENV_VERSION"
echo "请运行以下命令使配置生效："
echo "  source $BREW_ENV_FILE"
echo "或者重新打开终端"
