from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from src.schemas.resource import ResourceCreate, ResourceUpdate, ResourceOut
from src.services.resource import ResourceService
from src.core.database import get_db

router = APIRouter()

@router.post("/", response_model=ResourceOut)
async def create_resource(resource_in: ResourceCreate, db: AsyncSession = Depends(get_db)):
    service = ResourceService(db)
    return await service.create(resource_in)

@router.get("/", response_model=List[ResourceOut])
async def list_resources(
    type: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db)
):
    service = ResourceService(db)
    return await service.get_multi(type=type)

@router.get("/{resource_id}", response_model=ResourceOut)
async def get_resource(resource_id: str, db: AsyncSession = Depends(get_db)):
    service = ResourceService(db)
    resource = await service.get(resource_id)
    if not resource:
        raise HTTPException(404, "Resource not found")
    return resource

@router.put("/{resource_id}", response_model=ResourceOut)
async def update_resource(resource_id: str, resource_in: ResourceUpdate, db: AsyncSession = Depends(get_db)):
    service = ResourceService(db)
    resource = await service.update(resource_id, resource_in)
    if not resource:
        raise HTTPException(404, "Resource not found")
    return resource

@router.delete("/{resource_id}", response_model=dict)
async def delete_resource(resource_id: str, db: AsyncSession = Depends(get_db)):
    service = ResourceService(db)
    ok = await service.delete(resource_id)
    if not ok:
        raise HTTPException(404, "Resource not found")
    return {"ok": True} 