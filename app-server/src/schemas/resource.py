from typing import Optional
from pydantic import BaseModel, Field
from datetime import datetime

class ResourceBase(BaseModel):
    """
    资源基础信息
    """
    type: str = Field(..., max_length=32)
    title: str = Field(..., max_length=128)
    description: Optional[str] = None
    url: str = Field(..., max_length=255)
    created_at: Optional[datetime] = None

class ResourceCreate(ResourceBase):
    """
    创建资源
    """
    pass

class ResourceUpdate(BaseModel):
    """
    更新资源
    """
    title: Optional[str] = Field(None, max_length=128)
    description: Optional[str] = None
    url: Optional[str] = Field(None, max_length=255)

class ResourceOut(ResourceBase):
    """
    返回给前端的资源信息
    """
    id: str
    created_at: datetime

    class Config:
        orm_mode = True 