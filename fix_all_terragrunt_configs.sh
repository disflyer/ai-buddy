#!/bin/bash

# 用法: ./fix_all_terragrunt_configs.sh
# 此脚本会检查和修复所有环境的所有组件的 Terragrunt 配置

# 设置环境和组件
ENVIRONMENTS=("dev" "staging" "prod")
COMPONENTS=("network" "gke_cluster" "secret_manager" "app_server")

# 显示当前工作目录
echo "当前工作目录: $(pwd)"

# 检查 devops 目录是否存在
if [ ! -d "devops" ]; then
  echo "错误: devops 目录不存在"
  exit 1
fi

# 修复根目录的 terragrunt.hcl 文件
ROOT_TERRAGRUNT="devops/terragrunt.hcl"
if [ -f "$ROOT_TERRAGRUNT" ]; then
  echo "修复根目录的 terragrunt.hcl 文件..."
  
  # 备份原始文件
  cp "$ROOT_TERRAGRUNT" "${ROOT_TERRAGRUNT}.bak"
  
  # 添加禁用状态锁的配置
  if ! grep -q "lock = false" "$ROOT_TERRAGRUNT"; then
    sed -i 's/credentials = "${get_repo_root()}\/devops\/service-account.json"/credentials = "${get_repo_root()}\/devops\/service-account.json"\n    lock = false  # 禁用状态锁\n    skip_bucket_creation = true  # 跳过创建存储桶/g' "$ROOT_TERRAGRUNT"
    echo "已添加禁用状态锁的配置"
  else
    echo "已存在禁用状态锁的配置"
  fi
  
  echo "根目录的 terragrunt.hcl 文件修复完成"
else
  echo "警告: 根目录的 terragrunt.hcl 文件不存在"
fi

# 遍历所有环境和组件
for ENV in "${ENVIRONMENTS[@]}"; do
  for COMPONENT in "${COMPONENTS[@]}"; do
    MODULE_DIR="devops/environments/$ENV/$COMPONENT"
    
    # 检查目录是否存在
    if [ ! -d "$MODULE_DIR" ]; then
      echo "跳过: 目录 $MODULE_DIR 不存在"
      continue
    fi
    
    # 检查 terragrunt.hcl 文件是否存在
    if [ ! -f "$MODULE_DIR/terragrunt.hcl" ]; then
      echo "跳过: 文件 $MODULE_DIR/terragrunt.hcl 不存在"
      continue
    fi
    
    echo "修复 $ENV 环境的 $COMPONENT 组件配置..."
    
    # 备份原始文件
    cp "$MODULE_DIR/terragrunt.hcl" "$MODULE_DIR/terragrunt.hcl.bak"
    
    # 修复 include 路径
    sed -i 's|path = "${get_repo_root()}/devops/terragrunt.hcl"|path = "../terragrunt.hcl"|g' "$MODULE_DIR/terragrunt.hcl"
    
    # 创建 .terragrunt-cache 目录（如果不存在）
    mkdir -p "$MODULE_DIR/.terragrunt-cache"
    
    # 创建 terragrunt_config.hcl 文件
    cat > "$MODULE_DIR/terragrunt_config.hcl" << EOF
# 禁用状态锁
disable_init_lock = true

# 启用重试机制
retryable_errors = [
  "(?s).*Error acquiring the state lock.*",
  "(?s).*timeout while waiting for state to become unlocked.*",
  "(?s).*is already locked.*",
  "(?s).*TLS handshake timeout.*",
  "(?s).*connection reset by peer.*"
]

retry_max_attempts = 5
retry_sleep_interval_sec = 30
EOF
    
    echo "$ENV 环境的 $COMPONENT 组件配置修复完成"
  done
done

echo "所有 Terragrunt 配置修复完成！"
exit 0 