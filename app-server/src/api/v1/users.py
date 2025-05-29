from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.services.user import UserService
from src.schemas.user import User, UserUpdate
from src.api.deps import get_firebase_user
from src.models.user import User as UserModel

router = APIRouter()

@router.get("/me", response_model=User)
async def read_user_me(firebase_user=Depends(get_firebase_user)):
    """获取当前用户信息"""
    return firebase_user

@router.put("/me", response_model=User)
async def update_user_me(
    user_in: UserUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    firebase_user=Depends(get_firebase_user)
) -> UserModel:
    """更新当前用户信息"""
    # 更新密码
    if user_in.password:
        user_service = UserService(db)
        if not await user_service.reset_password(firebase_user["uid"], user_in.password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="更新失败"
            )
        await db.refresh(firebase_user)
    
    return firebase_user 