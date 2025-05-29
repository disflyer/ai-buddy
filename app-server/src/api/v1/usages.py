from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from src.schemas.usage import UsageCreate, UsageUpdate, UsageOut
from src.services.usage import UsageService
from src.core.database import get_db
from src.api.deps import get_firebase_user
from src.models.user import User as UserModel

router = APIRouter()

@router.post("/", response_model=UsageOut)
async def create_usage(usage_in: UsageCreate, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    service = UsageService(db)
    return await service.create(usage_in)

@router.get("/", response_model=List[UsageOut])
async def list_usages(
    child_id: Optional[str] = Query(None),
    type: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    firebase_user=Depends(get_firebase_user)
):
    service = UsageService(db)
    return await service.get_multi(child_id=child_id, type=type)

@router.get("/{usage_id}", response_model=UsageOut)
async def get_usage(usage_id: str, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    service = UsageService(db)
    usage = await service.get(usage_id)
    if not usage:
        raise HTTPException(404, "Usage not found")
    return usage

@router.put("/{usage_id}", response_model=UsageOut)
async def update_usage(usage_id: str, usage_in: UsageUpdate, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    service = UsageService(db)
    usage = await service.update(usage_id, usage_in)
    if not usage:
        raise HTTPException(404, "Usage not found")
    return usage

@router.delete("/{usage_id}", response_model=dict)
async def delete_usage(usage_id: str, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    service = UsageService(db)
    ok = await service.delete(usage_id)
    if not ok:
        raise HTTPException(404, "Usage not found")
    return {"ok": True} 