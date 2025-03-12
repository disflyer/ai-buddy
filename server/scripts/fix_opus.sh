#!/bin/bash
# 获取 opus 库的路径
OPUS_LIB_PATH=$(brew --prefix opus)/lib
PYTHON_SITE_PACKAGES=$(python -c "import site; print(site.getsitepackages()[0])")
OPUSLIB_INIT="$PYTHON_SITE_PACKAGES/opuslib_next/api/__init__.py"

if [ -f "$OPUSLIB_INIT" ]; then
  # 备份原始文件
  cp "$OPUSLIB_INIT" "${OPUSLIB_INIT}.bak"
  
  # 修改 opuslib_next 的库搜索路径
  sed -i.bak "s|find_library('opus')|find_library('opus') or '$OPUS_LIB_PATH/libopus.dylib'|g" "$OPUSLIB_INIT"
  
  echo "已修复 opuslib_next 库路径问题，原始文件已备份为 ${OPUSLIB_INIT}.bak"
else
  echo "未找到 opuslib_next 初始化文件，请确认安装路径"
fi
