#!/bin/bash

# 查找所有模块级别的 terragrunt.hcl 文件
FILES=$(find devops/environments -name terragrunt.hcl | grep -v "^devops/environments/[^/]*/terragrunt.hcl$")

# 清理每个文件中的重复注释
for file in $FILES; do
  echo "清理文件: $file"
  
  # 使用 sed 删除重复的注释行
  sed -i '' '/^# 包含根配置$/{N;/^# 包含根配置\n# 包含根配置$/d;}' "$file"
done

echo "所有文件清理完成！" 