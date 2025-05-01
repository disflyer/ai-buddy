from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from src.models.resource import Resource
from src.schemas.resource import ResourceCreate, ResourceUpdate
from typing import List, Optional

class ResourceService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, resource_in: ResourceCreate) -> Resource:
        resource = Resource(**resource_in.model_dump(exclude_unset=True))
        self.db.add(resource)
        await self.db.commit()
        await self.db.refresh(resource)
        return resource

    async def get(self, resource_id: str) -> Optional[Resource]:
        result = await self.db.execute(select(Resource).where(Resource.id == resource_id))
        return result.scalar_one_or_none()

    async def get_multi(self, type: Optional[str] = None) -> List[Resource]:
        stmt = select(Resource)
        if type:
            stmt = stmt.where(Resource.type == type)
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def update(self, resource_id: str, resource_in: ResourceUpdate) -> Optional[Resource]:
        resource = await self.get(resource_id)
        if not resource:
            return None
        for field, value in resource_in.model_dump(exclude_unset=True).items():
            setattr(resource, field, value)
        await self.db.commit()
        await self.db.refresh(resource)
        return resource

    async def delete(self, resource_id: str) -> bool:
        resource = await self.get(resource_id)
        if not resource:
            return False
        await self.db.delete(resource)
        await self.db.commit()
        return True 