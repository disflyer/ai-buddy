from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from src.schemas.buddy import BuddyCreate, BuddyUpdate, BuddyOut
from src.services.buddy import BuddyService
from src.core.database import get_db
from src.api.deps import get_firebase_user
from src.models.user import User as UserModel

router = APIRouter()

@router.post("/", response_model=BuddyOut)
async def create_buddy(buddy_in: BuddyCreate, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    service = BuddyService(db)
    return await service.create(buddy_in)

@router.get("/", response_model=List[BuddyOut])
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

@router.put("/{buddy_id}", response_model=BuddyOut)
async def update_buddy(buddy_id: str, buddy_in: BuddyUpdate, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    service = BuddyService(db)
    buddy = await service.update(buddy_id, buddy_in)
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