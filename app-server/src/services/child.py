from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from src.models.child import Child
from src.schemas.child import ChildCreate, ChildUpdate
from typing import List, Optional

class ChildService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, child_in: ChildCreate) -> Child:
        child = Child(**child_in.model_dump())
        self.db.add(child)
        await self.db.commit()
        await self.db.refresh(child)
        return child

    async def get(self, child_id: str) -> Optional[Child]:
        result = await self.db.execute(select(Child).where(Child.id == child_id))
        return result.scalar_one_or_none()

    async def get_multi(self) -> List[Child]:
        result = await self.db.execute(select(Child))
        return result.scalars().all()

    async def update(self, child_id: str, child_in: ChildUpdate) -> Optional[Child]:
        child = await self.get(child_id)
        if not child:
            return None
        for field, value in child_in.model_dump(exclude_unset=True).items():
            setattr(child, field, value)
        await self.db.commit()
        await self.db.refresh(child)
        return child

    async def delete(self, child_id: str) -> bool:
        child = await self.get(child_id)
        if not child:
            return False
        await self.db.delete(child)
        await self.db.commit()
        return True 