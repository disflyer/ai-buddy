from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from src.schemas.buddy import BuddyCreate, BuddyUpdate, BuddyOut, BuddyUpsert
from src.services.buddy import BuddyService
from src.core.database import get_db
from src.api.deps import get_firebase_user
from src.models.user import User as UserModel

router = APIRouter()

@router.post("/create", response_model=BuddyOut)
async def upsert_buddy(buddy_in: BuddyUpsert, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    """
    创建或更新玩偶（upsert）。
    如果 buddy_in.id 存在且数据库有记录，则更新，否则创建。
    """
    service = BuddyService(db)
    if buddy_in.id:
        buddy = await service.update(buddy_in.id, buddy_in)
        if buddy:
            return buddy
    return await service.create(buddy_in)

@router.get("/list", response_model=List[BuddyOut])
async def list_buddies(db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    service = BuddyService(db)
    return await service.get_multi()

@router.get("/{buddy_id}", response_model=BuddyOut)
async def get_buddy(buddy_id: str, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    service = BuddyService(db)
    buddy = await service.get(buddy_id)
    if not buddy:
        raise HTTPException(404, "Buddy not found")
    return buddy

@router.delete("/{buddy_id}", response_model=dict)
async def delete_buddy(buddy_id: str, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    service = BuddyService(db)
    ok = await service.delete(buddy_id)
    if not ok:
        raise HTTPException(404, "Buddy not found")
    return {"ok": True}

@router.post("/{buddy_id}/bind", response_model=BuddyOut)
async def bind_buddy(buddy_id: str, child_id: str, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    service = BuddyService(db)
    buddy = await service.bind(buddy_id, child_id)
    if not buddy:
        raise HTTPException(404, "Buddy not found")
    return buddy

@router.post("/{buddy_id}/unbind", response_model=BuddyOut)
async def unbind_buddy(buddy_id: str, db: AsyncSession = Depends(get_db), current_user: UserModel = Depends(get_firebase_user)):
    service = BuddyService(db)
    buddy = await service.unbind(buddy_id)
    if not buddy:
        raise HTTPException(404, "Buddy not found")
    return buddy 