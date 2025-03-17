#!/bin/bash
# 文件名: download_models.sh
# 描述: 从Google Cloud Storage下载AI模型到本地

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
LOCAL_MODEL_DIR="./models"
GCS_BUCKET="gs://ai-buddy-models"
DOWNLOAD_LOG="download_models.log"

# 记录开始时间
START_TIME=$(date +%s)

# 创建日志文件
> $DOWNLOAD_LOG

# 记录日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $DOWNLOAD_LOG
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

# 创建本地目录
log "创建本地目录: $LOCAL_MODEL_DIR"
mkdir -p $LOCAL_MODEL_DIR

# 检查存储桶是否可访问
log "检查存储桶 $GCS_BUCKET 是否可访问..."
if ! gsutil ls $GCS_BUCKET &> /dev/null; then
    print_error "无法访问存储桶 $GCS_BUCKET，请检查权限或存储桶名称"
    exit 1
fi

print_info "开始从 $GCS_BUCKET 下载模型..."

# 获取所有模型目录
log "获取所有模型目录..."
MODEL_DIRS=$(gsutil ls $GCS_BUCKET/)
MODEL_COUNT=$(echo "$MODEL_DIRS" | wc -l)
print_info "发现 $MODEL_COUNT 个模型目录"

# 从GCS复制模型文件
CURRENT_MODEL=0
for model_dir in $MODEL_DIRS; do
    CURRENT_MODEL=$((CURRENT_MODEL + 1))
    model_name=$(basename $model_dir)
    
    print_info "[$CURRENT_MODEL/$MODEL_COUNT] 处理模型: $model_name"
    log "同步目录: $model_dir (模型名: $model_name)"
    
    # 创建模型目录
    mkdir -p $LOCAL_MODEL_DIR/$model_name
    
    # 列出模型目录中的所有文件
    log "列出 $model_dir 中的文件:"
    FILE_LIST=$(gsutil ls -r $model_dir)
    FILE_COUNT=$(echo "$FILE_LIST" | grep -v '/$' | wc -l)
    log "发现 $FILE_COUNT 个文件"
    echo "$FILE_LIST" >> $DOWNLOAD_LOG
    
    # 复制模型文件
    print_info "复制 $model_name 模型文件 ($FILE_COUNT 个文件)..."
    
    # 使用进度条显示
    if [ $FILE_COUNT -gt 0 ]; then
        log "开始复制文件..."
        gsutil -m cp -r $model_dir* $LOCAL_MODEL_DIR/$model_name/ 2>> $DOWNLOAD_LOG
        
        # 检查复制状态
        if [ $? -eq 0 ]; then
            print_success "$model_name 模型同步成功"
            
            # 列出下载的文件
            log "$model_name 目录内容:"
            ls -la $LOCAL_MODEL_DIR/$model_name/ >> $DOWNLOAD_LOG
            
            # 计算文件数量
            DOWNLOADED_COUNT=$(find $LOCAL_MODEL_DIR/$model_name -type f | wc -l)
            log "下载了 $DOWNLOADED_COUNT 个文件"
        else
            print_error "$model_name 模型同步失败"
            exit 1
        fi
    else
        print_warning "模型目录为空，跳过"
    fi
done

# 特别检查 snakers4_silero-vad 模型
if [ -d "$LOCAL_MODEL_DIR/snakers4_silero-vad" ]; then
    print_info "检查 snakers4_silero-vad 模型文件..."
    log "snakers4_silero-vad 目录内容:"
    ls -la $LOCAL_MODEL_DIR/snakers4_silero-vad/ | tee -a $DOWNLOAD_LOG
    
    # 检查关键文件
    if [ -f "$LOCAL_MODEL_DIR/snakers4_silero-vad/hubconf.py" ]; then
        print_success "找到 hubconf.py 文件"
    else
        print_warning "未找到 hubconf.py 文件，尝试单独下载"
        log "尝试单独下载 hubconf.py 文件"
        gsutil cp $GCS_BUCKET/snakers4_silero-vad/hubconf.py $LOCAL_MODEL_DIR/snakers4_silero-vad/ 2>> $DOWNLOAD_LOG
        
        if [ -f "$LOCAL_MODEL_DIR/snakers4_silero-vad/hubconf.py" ]; then
            print_success "hubconf.py 文件下载成功"
        else
            print_error "hubconf.py 文件下载失败"
        fi
    fi
    
    # 检查其他关键文件
    REQUIRED_FILES=("silero_vad.onnx" "models.yml")
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$LOCAL_MODEL_DIR/snakers4_silero-vad/$file" ]; then
            print_success "找到 $file 文件"
        else
            print_warning "未找到 $file 文件，尝试单独下载"
            log "尝试单独下载 $file 文件"
            gsutil cp $GCS_BUCKET/snakers4_silero-vad/$file $LOCAL_MODEL_DIR/snakers4_silero-vad/ 2>> $DOWNLOAD_LOG
            
            if [ -f "$LOCAL_MODEL_DIR/snakers4_silero-vad/$file" ]; then
                print_success "$file 文件下载成功"
            else
                print_error "$file 文件下载失败"
            fi
        fi
    done
else
    print_warning "snakers4_silero-vad 目录不存在，尝试单独下载"
    log "尝试单独下载 snakers4_silero-vad 模型"
    mkdir -p $LOCAL_MODEL_DIR/snakers4_silero-vad
    gsutil -m cp -r $GCS_BUCKET/snakers4_silero-vad/* $LOCAL_MODEL_DIR/snakers4_silero-vad/ 2>> $DOWNLOAD_LOG
    
    if [ $? -eq 0 ]; then
        print_success "snakers4_silero-vad 模型下载成功"
        ls -la $LOCAL_MODEL_DIR/snakers4_silero-vad/ | tee -a $DOWNLOAD_LOG
    else
        print_error "snakers4_silero-vad 模型下载失败"
    fi
fi

# 最终检查所有模型目录
print_info "最终模型目录结构:"
find $LOCAL_MODEL_DIR -type f | sort | tee -a $DOWNLOAD_LOG

# 计算总文件数
TOTAL_FILES=$(find $LOCAL_MODEL_DIR -type f | wc -l)
TOTAL_SIZE=$(du -sh $LOCAL_MODEL_DIR | cut -f1)

# 计算耗时
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

print_success "下载完成！"
echo "----------------------------------------"
echo "下载摘要:"
echo "- 模型保存在: $LOCAL_MODEL_DIR"
echo "- 总文件数: $TOTAL_FILES"
echo "- 总大小: $TOTAL_SIZE"
echo "- 耗时: ${MINUTES}分${SECONDS}秒"
echo "- 详细日志: $DOWNLOAD_LOG"
echo "----------------------------------------"