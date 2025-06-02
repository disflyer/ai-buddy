from typing import Optional
from pydantic import BaseModel, Field
from datetime import datetime

class UsageBase(BaseModel):
    """
    使用时长基础信息
    """
    child_id: str
    buddy_id: str
    type: str = Field(..., max_length=32)
    duration: float
    timestamp: Optional[datetime] = None

class UsageCreate(UsageBase):
    """
    创建使用时长
    """
    pass

class UsageUpdate(BaseModel):
    """
    更新使用时长
    """
    duration: Optional[float] = None
    timestamp: Optional[datetime] = None

class UsageOut(UsageBase):
    """
    返回给前端的使用时长信息
    """
    id: str
    timestamp: datetime

    class Config:
        orm_mode = True

class UsageUpsert(UsageBase):
    """
    创建或更新使用时长（upsert）
    """
    id: Optional[str] = None 