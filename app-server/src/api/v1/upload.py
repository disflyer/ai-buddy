from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from google.cloud import storage
from uuid import uuid4
import os
from src.api.deps import get_firebase_user

router = APIRouter()

BUCKET_NAME = "tinybuddy"
AVATAR_PATH = "avatar/"

# 可选：从环境变量读取GCP密钥路径
# os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "/path/to/your/service-account.json"

@router.post("/upload/avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    firebase_user=Depends(get_firebase_user)
):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="只允许上传图片文件")

    # 生成唯一文件名
    ext = os.path.splitext(file.filename)[-1]
    filename = f"{uuid4().hex}{ext}"
    blob_path = f"{AVATAR_PATH}{filename}"

    # 上传到GCP
    try:
        storage_client = storage.Client()
        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(blob_path)
        blob.upload_from_file(file.file, content_type=file.content_type)
        
        # 对于启用了统一存储桶级别访问的存储桶，直接生成公共URL
        # 不需要调用 make_public()，因为权限在存储桶级别管理
        public_url = f"https://storage.googleapis.com/{BUCKET_NAME}/{blob_path}"
        
        # 注意: 确保存储桶已配置为允许公共读取访问
        # 可通过 Google Cloud Console 设置或运行以下命令:
        # gcloud storage buckets add-iam-policy-binding gs://tinybuddy --member="allUsers" --role="roles/storage.objectViewer"
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"上传失败: {str(e)}")

    return {"avatar_url": public_url, "avatar_path": blob_path} 