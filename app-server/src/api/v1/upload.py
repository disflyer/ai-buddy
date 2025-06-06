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
        # 设置为公开可读
        blob.make_public()
        public_url = blob.public_url
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"上传失败: {e}")

    return {"avatar_url": public_url, "avatar_path": blob_path} 