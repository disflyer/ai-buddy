from typing import Optional, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime

class BuddyBase(BaseModel):
    """
    玩偶基础信息
    """
    name: str = Field(..., max_length=64)
    child_id: Optional[str] = None
    avatar_path: Optional[str] = None
    description: Optional[str] = None
    is_active: bool = False
    abilities: Dict[str, Any] = {}

class BuddyCreate(BuddyBase):
    """
    创建玩偶
    """
    pass

class BuddyUpdate(BaseModel):
    """
    更新玩偶
    """
    name: Optional[str] = Field(None, max_length=64)
    child_id: Optional[str] = None
    avatar_path: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None
    abilities: Optional[Dict[str, Any]] = None

class BuddyOut(BuddyBase):
    """
    返回给前端的玩偶信息
    """
    id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class BuddyUpsert(BuddyBase):
    """
    创建或更新玩偶（upsert）
    """
    id: Optional[str] = None 