#!/bin/bash

# 用法: ./terraform_state_manager.sh <操作> <环境> <组件> [其他参数]
# 操作:
#   - unlock: 解锁状态 (需要锁ID)
#   - delete-lock: 删除锁文件
#   - deploy: 部署组件 (需要项目ID)
#   - check: 检查状态锁
#   - fix-module: 修复模块源路径
#
# 例如:
#   ./terraform_state_manager.sh unlock staging network 1741967207231199
#   ./terraform_state_manager.sh delete-lock staging network
#   ./terraform_state_manager.sh deploy staging network rare-attic-453703-a8
#   ./terraform_state_manager.sh check staging network
#   ./terraform_state_manager.sh fix-module staging network

# 参数检查
if [ $# -lt 3 ]; then
  echo "用法: $0 <操作> <环境> <组件> [其他参数]"
  exit 1
fi

ACTION=$1
ENV=$2
COMPONENT=$3
BUCKET_NAME="tfstate-rare-attic"
LOCK_FILE="environments/$ENV/$COMPONENT/default.tflock"
MODULE_DIR="devops/environments/$ENV/$COMPONENT"

# 根据操作执行不同的功能
case $ACTION in
  unlock)
    if [ $# -lt 4 ]; then
      echo "解锁操作需要锁ID参数"
      exit 1
    fi
    
    LOCK_ID=$4
    echo "开始解锁 $ENV 环境的 $COMPONENT 组件状态..."
    cd devops/environments/$ENV/$COMPONENT || exit 1
    
    # 执行 Terraform 强制解锁命令
    echo "执行 terragrunt force-unlock..."
    terragrunt force-unlock -force $LOCK_ID
    
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      echo "解锁失败，退出代码: $exit_code"
      exit $exit_code
    fi
    
    echo "状态解锁成功！"
    ;;
    
  delete-lock)
    echo "开始删除 $ENV 环境的 $COMPONENT 组件锁文件..."
    
    # 检查锁文件是否存在
    if gsutil -q stat gs://$BUCKET_NAME/$LOCK_FILE 2>/dev/null; then
      echo "锁文件存在，正在删除..."
      gsutil rm gs://$BUCKET_NAME/$LOCK_FILE
      
      exit_code=$?
      if [ $exit_code -ne 0 ]; then
        echo "删除锁文件失败，退出代码: $exit_code"
        exit $exit_code
      fi
      
      echo "锁文件删除成功！"
    else
      echo "锁文件不存在或无法访问。"
    fi
    ;;
    
  deploy)
    if [ $# -lt 4 ]; then
      echo "部署操作需要项目ID参数"
      exit 1
    fi
    
    PROJECT_ID=$4
    echo "开始部署 $COMPONENT 到 $ENV 环境..."
    cd devops/environments/$ENV/$COMPONENT || exit 1
    
    # 创建 terragrunt-cache 目录（如果不存在）
    mkdir -p .terragrunt-cache
    
    # 创建 Terragrunt 配置文件，启用重试机制
    cat > terragrunt_config.hcl << EOF
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
    
    # 执行 Terragrunt 命令
    echo "执行 terragrunt init..."
    TERRAGRUNT_CONFIG="terragrunt_config.hcl" terragrunt init
    
    echo "执行 terragrunt apply..."
    TERRAGRUNT_CONFIG="terragrunt_config.hcl" terragrunt apply -auto-approve -var="env=$ENV" -var="project_id=$PROJECT_ID" -lock=false
    
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      echo "部署 $COMPONENT 失败，退出代码: $exit_code"
      exit $exit_code
    fi
    
    echo "$COMPONENT 部署完成！"
    ;;
    
  check)
    echo "检查 $ENV 环境的 $COMPONENT 组件锁状态..."
    
    # 检查锁文件是否存在
    if gsutil -q stat gs://$BUCKET_NAME/$LOCK_FILE 2>/dev/null; then
      echo "锁文件存在，获取锁信息..."
      gsutil cat gs://$BUCKET_NAME/$LOCK_FILE
    else
      echo "锁文件不存在或无法访问。"
    fi
    ;;
    
  fix-module)
    echo "修复 $ENV 环境的 $COMPONENT 模块源路径..."
    
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
    sed -i.tmp 's|source = "../../../modules//gke_cluster"|source = "../../../modules/gke_cluster"|g' "$MODULE_DIR/terragrunt.hcl"
    sed -i.tmp 's|source = "../../../modules//secret_manager"|source = "../../../modules/secret_manager"|g' "$MODULE_DIR/terragrunt.hcl"
    sed -i.tmp 's|source = "../../../modules//app_server"|source = "../../../modules/app_server"|g' "$MODULE_DIR/terragrunt.hcl"
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
    ;;
    
  *)
    echo "未知操作: $ACTION"
    echo "支持的操作: unlock, delete-lock, deploy, check, fix-module"
    exit 1
    ;;
esac

exit 0 