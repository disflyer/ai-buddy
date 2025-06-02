from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from src.schemas.resource import ResourceCreate, ResourceUpdate, ResourceOut, ResourceUpsert
from src.services.resource import ResourceService
from src.core.database import get_db
from src.api.deps import get_firebase_user
from src.models.user import User as UserModel

router = APIRouter()

@router.post("/", response_model=ResourceOut)
async def upsert_resource(resource_in: ResourceUpsert, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    """
    创建或更新资源（upsert）。
    如果 resource_in.id 存在且数据库有记录，则更新，否则创建。
    """
    service = ResourceService(db)
    if resource_in.id:
        resource = await service.update(resource_in.id, resource_in)
        if resource:
            return resource
    return await service.create(resource_in)

@router.get("/", response_model=List[ResourceOut])
async def list_resources(
    type: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    firebase_user=Depends(get_firebase_user)
):
    service = ResourceService(db)
    return await service.get_multi(type=type)

@router.get("/{resource_id}", response_model=ResourceOut)
async def get_resource(resource_id: str, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    service = ResourceService(db)
    resource = await service.get(resource_id)
    if not resource:
        raise HTTPException(404, "Resource not found")
    return resource

@router.delete("/{resource_id}", response_model=dict)
async def delete_resource(resource_id: str, db: AsyncSession = Depends(get_db), firebase_user=Depends(get_firebase_user)):
    service = ResourceService(db)
    ok = await service.delete(resource_id)
    if not ok:
        raise HTTPException(404, "Resource not found")
    return {"ok": True} 