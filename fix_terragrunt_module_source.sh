#!/bin/bash

# 用法: ./fix_terragrunt_module_source.sh <环境>
# 例如: ./fix_terragrunt_module_source.sh staging

# 参数检查
if [ $# -lt 1 ]; then
  echo "用法: $0 <环境>"
  exit 1
fi

ENV=$1
MODULE_DIR="devops/environments/$ENV/network"

echo "修复 $ENV 环境的网络模块配置..."

# 检查目录是否存在
if [ ! -d "$MODULE_DIR" ]; then
  echo "错误: 目录 $MODULE_DIR 不存在"
  exit 1
fi

# 检查 terragrunt.hcl 文件是否存在
if [ ! -f "$MODULE_DIR/terragrunt.hcl" ]; then
  echo "错误: 文件 $MODULE_DIR/terragrunt.hcl 不存在"
  exit 1
fi

# 备份原始文件
cp "$MODULE_DIR/terragrunt.hcl" "$MODULE_DIR/terragrunt.hcl.bak"
echo "已备份原始文件到 $MODULE_DIR/terragrunt.hcl.bak"

# 修复 include 路径
sed -i.tmp 's|path = "${get_repo_root()}/devops/terragrunt.hcl"|path = "../terragrunt.hcl"|g' "$MODULE_DIR/terragrunt.hcl"
rm -f "$MODULE_DIR/terragrunt.hcl.tmp"

# 修复模块源路径
sed -i.tmp 's|source = "../../../modules//network"|source = "../../../modules/network"|g' "$MODULE_DIR/terragrunt.hcl"
rm -f "$MODULE_DIR/terragrunt.hcl.tmp"

echo "已修复 $MODULE_DIR/terragrunt.hcl 文件"

# 创建 .terraform 目录（如果不存在）
mkdir -p "$MODULE_DIR/.terraform"
echo "已创建 $MODULE_DIR/.terraform 目录"

# 创建 .terragrunt-cache 目录（如果不存在）
mkdir -p "$MODULE_DIR/.terragrunt-cache"
echo "已创建 $MODULE_DIR/.terragrunt-cache 目录"

# 创建一个简单的 main.tf 文件，确保目录中有 Terraform 文件
cat > "$MODULE_DIR/main.tf" << EOF
# 这是一个临时文件，确保目录中有 Terraform 文件
# 实际模块源将由 Terragrunt 管理
EOF
echo "已创建临时 $MODULE_DIR/main.tf 文件"

echo "修复完成！"
exit 0 