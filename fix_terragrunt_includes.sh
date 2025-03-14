#!/bin/bash

# 查找所有模块级别的 terragrunt.hcl 文件
FILES=$(find devops/environments -name terragrunt.hcl | grep -v "^devops/environments/[^/]*/terragrunt.hcl$")

# 修复每个文件中的 include 路径
for file in $FILES; do
  echo "修复文件: $file"
  # 使用 sed 替换 find_in_parent_folders() 为 ../terragrunt.hcl
  sed -i '' 's/path = find_in_parent_folders()/path = "..\/terragrunt.hcl"/' "$file"
done

echo "所有文件修复完成！" 