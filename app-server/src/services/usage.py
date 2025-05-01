from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from src.models.usage import Usage
from src.schemas.usage import UsageCreate, UsageUpdate
from typing import List, Optional

class UsageService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, usage_in: UsageCreate) -> Usage:
        usage = Usage(**usage_in.model_dump(exclude_unset=True))
        self.db.add(usage)
        await self.db.commit()
        await self.db.refresh(usage)
        return usage

    async def get(self, usage_id: str) -> Optional[Usage]:
        result = await self.db.execute(select(Usage).where(Usage.id == usage_id))
        return result.scalar_one_or_none()

    async def get_multi(self, child_id: Optional[str] = None, type: Optional[str] = None) -> List[Usage]:
        stmt = select(Usage)
        if child_id:
            stmt = stmt.where(Usage.child_id == child_id)
        if type:
            stmt = stmt.where(Usage.type == type)
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def update(self, usage_id: str, usage_in: UsageUpdate) -> Optional[Usage]:
        usage = await self.get(usage_id)
        if not usage:
            return None
        for field, value in usage_in.model_dump(exclude_unset=True).items():
            setattr(usage, field, value)
        await self.db.commit()
        await self.db.refresh(usage)
        return usage

    async def delete(self, usage_id: str) -> bool:
        usage = await self.get(usage_id)
        if not usage:
            return False
        await self.db.delete(usage)
        await self.db.commit()
        return True 