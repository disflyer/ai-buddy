#!/bin/bash

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的信息
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 主函数
main() {
    info "开始修复tkinter问题..."
    
    # 检查是否安装了tcl-tk
    if ! brew list tcl-tk &> /dev/null; then
        warning "未找到tcl-tk。正在安装..."
        brew install tcl-tk || error "安装tcl-tk失败"
    fi
    
    # 检查是否安装了python-tk
    if ! brew list python-tk@3.11 &> /dev/null; then
        warning "未找到python-tk@3.11。正在安装..."
        brew install python-tk@3.11 || error "安装python-tk@3.11失败"
    fi
    
    # 获取pyenv的Python路径
    PYENV_ROOT=$(pyenv root)
    PYTHON_VERSION=$(python -V 2>&1 | cut -d' ' -f2)
    PYTHON_LIB_PATH="$PYENV_ROOT/versions/$PYTHON_VERSION/lib/python${PYTHON_VERSION%.*}"
    
    # 获取Homebrew的Python路径
    BREW_PYTHON_PATH=$(brew --prefix python@3.11)
    
    # 查找_tkinter.so文件
    info "查找_tkinter.so文件..."
    TKINTER_SO=$(find /opt/homebrew -name "_tkinter.cpython-311-darwin.so" 2>/dev/null | head -1)
    
    if [ -z "$TKINTER_SO" ]; then
        error "无法找到_tkinter.so文件，请确保已安装python-tk@3.11"
    fi
    
    info "找到_tkinter.so文件: $TKINTER_SO"
    
    # 创建目标目录（如果不存在）
    PYENV_DYNLOAD_PATH="$PYTHON_LIB_PATH/lib-dynload"
    if [ ! -d "$PYENV_DYNLOAD_PATH" ]; then
        warning "$PYENV_DYNLOAD_PATH 不存在，创建目录..."
        mkdir -p "$PYENV_DYNLOAD_PATH"
    fi
    
    # 创建符号链接
    PYENV_TKINTER_PATH="$PYENV_DYNLOAD_PATH/_tkinter.cpython-311-darwin.so"
    info "创建符号链接: $TKINTER_SO -> $PYENV_TKINTER_PATH"
    
    # 如果已存在，先删除
    if [ -f "$PYENV_TKINTER_PATH" ]; then
        rm -f "$PYENV_TKINTER_PATH"
    fi
    
    ln -sf "$TKINTER_SO" "$PYENV_TKINTER_PATH"
    
    if [ $? -ne 0 ]; then
        error "创建符号链接失败"
    fi
    
    # 验证tkinter是否可用
    if python -c "import tkinter; print('tkinter 已成功导入')" &> /dev/null; then
        success "tkinter 已成功安装并可用"
    else
        error "tkinter 安装失败，无法导入"
    fi
    
    success "tkinter问题已修复！您现在可以运行您的应用程序了"
}

# 执行主函数
main 