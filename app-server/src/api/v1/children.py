from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from src.schemas.child import ChildCreate, ChildUpdate, ChildOut, ChildUpsert
from src.services.child import ChildService
from src.core.database import get_db
from src.api.deps import get_firebase_user
from src.models.user import User as UserModel

router = APIRouter()

@router.post("/", response_model=ChildOut)
async def upsert_child(child_in: ChildUpsert, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    """
    创建或更新孩童（upsert）。
    如果 child_in.id 存在且数据库有记录，则更新，否则创建。
    """
    service = ChildService(db)
    if child_in.id:
        child = await service.update(child_in.id, child_in)
        if child:
            return child
    return await service.create(child_in)

@router.get("/", response_model=List[ChildOut])
async def list_children(db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    service = ChildService(db)
    return await service.get_multi()

@router.get("/{child_id}", response_model=ChildOut)
async def get_child(child_id: str, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    service = ChildService(db)
    child = await service.get(child_id)
    if not child:
        raise HTTPException(404, "Child not found")
    return child

@router.delete("/{child_id}", response_model=dict)
async def delete_child(child_id: str, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    service = ChildService(db)
    ok = await service.delete(child_id)
    if not ok:
        raise HTTPException(404, "Child not found")
    return {"ok": True} 