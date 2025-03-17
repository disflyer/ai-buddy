#!/bin/bash
# 文件名: upload_models.sh
# 描述: 将本地模型文件同步到Google Cloud Storage存储桶

# 设置错误处理
set -e

# 彩色输出函数
print_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

# 设置变量
LOCAL_MODEL_DIR="../models"  # 本地模型目录
GCS_BUCKET="gs://ai-buddy-models"  # GCS存储桶路径
UPLOAD_LOG="upload_models.log"  # 日志文件
DRY_RUN=0  # 设置为1可以进行模拟运行，不实际上传文件

# 记录开始时间
START_TIME=$(date +%s)

# 创建日志文件
> $UPLOAD_LOG

# 记录日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $UPLOAD_LOG
}

# 检查gsutil是否安装
if ! command -v gsutil &> /dev/null; then
    print_error "gsutil 命令未找到，请安装 Google Cloud SDK"
    exit 1
fi

# 检查gcloud认证状态
log "检查 gcloud 认证状态..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    print_error "未检测到有效的 gcloud 认证，请先运行 'gcloud auth login'"
    exit 1
fi

# 检查本地目录是否存在
if [ ! -d "$LOCAL_MODEL_DIR" ]; then
    print_error "本地模型目录 $LOCAL_MODEL_DIR 不存在"
    exit 1
fi

# 检查存储桶是否可访问
log "检查存储桶 $GCS_BUCKET 是否可访问..."
if ! gsutil ls $GCS_BUCKET &> /dev/null; then
    print_warning "无法访问存储桶 $GCS_BUCKET，尝试创建..."
    
    # 提取存储桶名称（去掉gs://前缀）
    BUCKET_NAME=$(echo $GCS_BUCKET | sed 's/gs:\/\///')
    
    # 创建存储桶
    log "创建存储桶 $BUCKET_NAME..."
    if gsutil mb -l us-central1 $GCS_BUCKET; then
        print_success "存储桶创建成功"
    else
        print_error "存储桶创建失败，请检查权限或存储桶名称"
        exit 1
    fi
fi

# 获取本地模型目录列表
log "扫描本地模型目录..."
MODEL_DIRS=$(find $LOCAL_MODEL_DIR -maxdepth 1 -type d | grep -v "^$LOCAL_MODEL_DIR$")
MODEL_COUNT=$(echo "$MODEL_DIRS" | wc -l)

if [ $MODEL_COUNT -eq 0 ]; then
    print_warning "本地模型目录为空，没有可上传的模型"
    exit 0
fi

print_info "发现 $MODEL_COUNT 个模型目录"

# 确认上传
if [ $DRY_RUN -eq 0 ]; then
    echo "将上传以下模型目录到 $GCS_BUCKET:"
    for dir in $MODEL_DIRS; do
        echo "- $(basename $dir)"
    done
    
    read -p "是否继续上传？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "上传已取消"
        exit 0
    fi
else
    print_warning "模拟运行模式，不会实际上传文件"
fi

# 上传模型文件
CURRENT_MODEL=0
for model_dir in $MODEL_DIRS; do
    CURRENT_MODEL=$((CURRENT_MODEL + 1))
    model_name=$(basename $model_dir)
    
    print_info "[$CURRENT_MODEL/$MODEL_COUNT] 处理模型: $model_name"
    
    # 检查模型目录是否为空
    if [ -z "$(ls -A $model_dir)" ]; then
        print_warning "模型目录 $model_name 为空，跳过"
        continue
    fi
    
    # 计算文件数量和大小
    FILE_COUNT=$(find $model_dir -type f | wc -l)
    DIR_SIZE=$(du -sh $model_dir | cut -f1)
    
    log "模型 $model_name: $FILE_COUNT 个文件，总大小 $DIR_SIZE"
    
    # 上传前显示信息
    print_info "准备上传 $model_name ($FILE_COUNT 个文件，$DIR_SIZE)"
    
    # 执行上传
    if [ $DRY_RUN -eq 0 ]; then
        log "开始上传 $model_name 到 $GCS_BUCKET/$model_name/..."
        
        # 使用 -m 参数启用并行上传，提高速度
        if gsutil -m rsync -r $model_dir $GCS_BUCKET/$model_name/ 2>> $UPLOAD_LOG; then
            print_success "$model_name 上传成功"
        else
            print_error "$model_name 上传失败"
            exit 1
        fi
    else
        log "[DRY RUN] 将上传 $model_dir 到 $GCS_BUCKET/$model_name/"
        print_info "[DRY RUN] $model_name 模拟上传成功"
    fi
done

# 验证上传
if [ $DRY_RUN -eq 0 ]; then
    print_info "验证上传结果..."
    
    for model_dir in $MODEL_DIRS; do
        model_name=$(basename $model_dir)
        
        # 获取本地和远程文件列表
        LOCAL_FILES=$(find $model_dir -type f | sort)
        LOCAL_COUNT=$(echo "$LOCAL_FILES" | wc -l)
        
        REMOTE_FILES=$(gsutil ls -r $GCS_BUCKET/$model_name/ | grep -v '/$' | sort)
        REMOTE_COUNT=$(echo "$REMOTE_FILES" | wc -l)
        
        log "模型 $model_name: 本地 $LOCAL_COUNT 个文件，远程 $REMOTE_COUNT 个文件"
        
        if [ $LOCAL_COUNT -eq $REMOTE_COUNT ]; then
            print_success "$model_name 验证成功: 文件数量匹配"
        else
            print_warning "$model_name 验证警告: 文件数量不匹配 (本地: $LOCAL_COUNT, 远程: $REMOTE_COUNT)"
        fi
    done
fi

# 计算耗时
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# 显示上传摘要
if [ $DRY_RUN -eq 0 ]; then
    print_success "上传完成！"
else
    print_success "模拟上传完成！"
fi

echo "----------------------------------------"
echo "上传摘要:"
echo "- 源目录: $LOCAL_MODEL_DIR"
echo "- 目标存储桶: $GCS_BUCKET"
echo "- 上传模型数: $MODEL_COUNT"
if [ $DRY_RUN -eq 0 ]; then
    echo "- 耗时: ${MINUTES}分${SECONDS}秒"
else
    echo "- 模拟运行，未实际上传"
fi
echo "- 详细日志: $UPLOAD_LOG"
echo "----------------------------------------"

# 显示访问模型的命令示例
print_info "您可以使用以下命令查看上传的模型:"
echo "gsutil ls -r $GCS_BUCKET/"