#!/bin/bash

# 查找所有模块级别的 terragrunt.hcl 文件
FILES=$(find devops/environments -name terragrunt.hcl | grep -v "^devops/environments/[^/]*/terragrunt.hcl$")

# 修复每个文件中的 include 路径
for file in $FILES; do
  echo "修复文件: $file"
  
  # 使用 awk 替换 include 块
  awk '
  BEGIN { print_mode = 1 }
  /^[[:space:]]*include[[:space:]]*{/ { 
    print "# 包含根配置"; 
    print "include {"; 
    print "  path = \"${get_repo_root()}/devops/terragrunt.hcl\""; 
    print "}"; 
    print_mode = 0 
  }
  /^[[:space:]]*}/ { 
    if (print_mode == 0) { 
      print_mode = 1; 
      next 
    } 
  }
  { if (print_mode == 1) print }
  ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
done

echo "所有文件修复完成！" 