from typing import Annotated
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from sqlalchemy.ext.asyncio import AsyncSession
from firebase_admin import auth as firebase_auth

from src.core.config import settings
from src.core.database import get_db
from src.services.user import UserService
from src.models.user import User
from src.schemas.user import TokenPayload
from src.core import firebase  # 确保初始化

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

async def get_current_user(
    db: Annotated[AsyncSession, Depends(get_db)],
    token: Annotated[str, Depends(oauth2_scheme)]
) -> User:
    """获取当前用户"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="无效的认证凭据",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        # 解码JWT token
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM]
        )
        token_data = TokenPayload(**payload)
    except JWTError:
        raise credentials_exception
    
    # 获取用户
    user_service = UserService(db)
    user = await user_service.get_by_id(token_data.sub)
    if not user:
        raise credentials_exception
    
    return user

async def get_current_active_user(
    current_user: Annotated[User, Depends(get_current_user)]
) -> User:
    """获取当前活跃用户"""
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户未激活"
        )
    return current_user

async def get_current_verified_user(
    current_user: Annotated[User, Depends(get_current_active_user)]
) -> User:
    """获取当前已验证用户"""
    if not current_user.is_verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户邮箱未验证"
        )
    return current_user

async def get_firebase_user(request: Request):
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="缺少或无效的认证信息")
    token = auth_header.split(" ")[1]
    try:
        # 验证 Firebase ID Token
        decoded_token = firebase_auth.verify_id_token(token)
        print(f"Firebase user authenticated: {decoded_token.get('uid')}")
        return decoded_token
    except firebase_auth.InvalidIdTokenError as e:
        print(f"无效的 Firebase Token: {e}")
        raise HTTPException(status_code=401, detail="无效的 Firebase Token")
    except firebase_auth.ExpiredIdTokenError as e:
        print(f"Firebase Token 已过期: {e}")
        raise HTTPException(status_code=401, detail="Firebase Token 已过期")
    except Exception as e:
        print(f"Firebase Token 验证失败: {e}")
        raise HTTPException(status_code=401, detail="Firebase Token 验证失败") 