from datetime import timedelta
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.config import settings
from src.models.user import User
from src.schemas.user import UserCreate
from src.utils.security import get_password_hash, verify_password, create_access_token
from src.utils.email import send_email

class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_by_email(self, email: str) -> Optional[User]:
        """通过邮箱获取用户"""
        result = await self.db.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()
    
    async def get_by_id(self, user_id: str) -> Optional[User]:
        """通过ID获取用户"""
        result = await self.db.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()
    
    async def create(self, user_in: UserCreate) -> User:
        """创建新用户"""
        # 创建用户实例
        db_user = User(
            email=user_in.email,
            hashed_password=get_password_hash(user_in.password),
            is_active=True,
            is_verified=False
        )
        
        # 保存到数据库
        self.db.add(db_user)
        await self.db.commit()
        await self.db.refresh(db_user)
        
        # 发送验证邮件
        verification_token = create_access_token(
            subject={"user_id": db_user.id, "action": "verify_email"},
            expires_delta=timedelta(hours=24)
        )
        
        await send_email(
            email_to=user_in.email,
            subject="请验证您的邮箱",
            template_name="verification",
            template_data={"token": verification_token}
        )
        
        return db_user
    
    async def authenticate(self, email: str, password: str) -> Optional[User]:
        """用户认证"""
        user = await self.get_by_email(email)
        if not user:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user
    
    async def verify_email(self, user_id: str) -> bool:
        """验证用户邮箱"""
        user = await self.get_by_id(user_id)
        if not user:
            return False
        
        user.is_verified = True
        await self.db.commit()
        return True
    
    async def request_password_reset(self, email: str) -> bool:
        """请求密码重置"""
        user = await self.get_by_email(email)
        if not user:
            return False
        
        # 创建密码重置token
        reset_token = create_access_token(
            subject={"user_id": user.id, "action": "reset_password"},
            expires_delta=timedelta(hours=1)
        )
        
        # 发送密码重置邮件
        await send_email(
            email_to=user.email,
            subject="密码重置请求",
            template_name="reset_password",
            template_data={"token": reset_token}
        )
        
        return True
    
    async def reset_password(self, user_id: str, new_password: str) -> bool:
        """重置密码"""
        user = await self.get_by_id(user_id)
        if not user:
            return False
        
        user.hashed_password = get_password_hash(new_password)
        await self.db.commit()
        return True 