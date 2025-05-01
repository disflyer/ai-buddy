from typing import Optional
from pydantic import BaseModel, Field
from datetime import datetime

class DialogueBase(BaseModel):
    """
    对话历史基础信息
    """
    child_id: str
    buddy_id: str
    content: str = Field(..., max_length=2048)
    timestamp: Optional[datetime] = None

class DialogueCreate(DialogueBase):
    """
    创建对话历史
    """
    pass

class DialogueUpdate(BaseModel):
    """
    更新对话历史
    """
    content: Optional[str] = Field(None, max_length=2048)
    timestamp: Optional[datetime] = None

class DialogueOut(DialogueBase):
    """
    返回给前端的对话历史信息
    """
    id: str
    timestamp: datetime

    class Config:
        orm_mode = True 