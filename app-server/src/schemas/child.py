from typing import List, Optional
from pydantic import BaseModel, Field
from datetime import datetime

class ChildBase(BaseModel):
    """
    孩童基础信息
    """
    name: str = Field(..., max_length=64)
    gender: str = Field(..., max_length=16)
    age: float
    interests: List[str] = []
    avatar_path: Optional[str] = None

class ChildCreate(ChildBase):
    """
    创建孩童
    """
    pass

class ChildUpdate(BaseModel):
    """
    更新孩童
    """
    name: Optional[str] = Field(None, max_length=64)
    gender: Optional[str] = Field(None, max_length=16)
    age: Optional[float] = None
    interests: Optional[List[str]] = None
    avatar_path: Optional[str] = None

class ChildOut(ChildBase):
    """
    返回给前端的孩童信息
    """
    id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True 