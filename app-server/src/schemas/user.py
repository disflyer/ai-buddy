from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field, ConfigDict

class UserBase(BaseModel):
    """用户基础模型"""
    email: EmailStr

class UserCreate(UserBase):
    """用户创建模型"""
    password: str = Field(..., min_length=8, max_length=32)
    
class UserLogin(UserBase):
    """用户登录模型"""
    password: str

class UserUpdate(BaseModel):
    """用户更新模型"""
    password: Optional[str] = Field(None, min_length=8, max_length=32)

class UserInDB(UserBase):
    """数据库中的用户模型"""
    id: str
    is_active: bool
    is_verified: bool
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

class User(UserInDB):
    """用户响应模型"""
    pass

class Token(BaseModel):
    """Token响应模型"""
    access_token: str
    token_type: str = "bearer"

class TokenPayload(BaseModel):
    """Token载荷模型"""
    sub: str
    exp: datetime

class PasswordReset(BaseModel):
    """密码重置模型"""
    email: EmailStr

class PasswordResetConfirm(BaseModel):
    """密码重置确认模型"""
    token: str
    new_password: str = Field(..., min_length=8, max_length=32) 