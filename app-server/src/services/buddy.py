from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from src.models.buddy import Buddy
from src.schemas.buddy import BuddyCreate, BuddyUpdate
from typing import List, Optional

class BuddyService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, buddy_in: BuddyCreate) -> Buddy:
        buddy = Buddy(**buddy_in.model_dump())
        self.db.add(buddy)
        await self.db.commit()
        await self.db.refresh(buddy)
        return buddy

    async def get(self, buddy_id: str) -> Optional[Buddy]:
        result = await self.db.execute(select(Buddy).where(Buddy.id == buddy_id))
        return result.scalar_one_or_none()

    async def get_multi(self) -> List[Buddy]:
        result = await self.db.execute(select(Buddy))
        return result.scalars().all()

    async def update(self, buddy_id: str, buddy_in: BuddyUpdate) -> Optional[Buddy]:
        buddy = await self.get(buddy_id)
        if not buddy:
            return None
        for field, value in buddy_in.model_dump(exclude_unset=True).items():
            setattr(buddy, field, value)
        await self.db.commit()
        await self.db.refresh(buddy)
        return buddy

    async def delete(self, buddy_id: str) -> bool:
        buddy = await self.get(buddy_id)
        if not buddy:
            return False
        await self.db.delete(buddy)
        await self.db.commit()
        return True

    async def bind(self, buddy_id: str, child_id: str) -> Optional[Buddy]:
        buddy = await self.get(buddy_id)
        if not buddy:
            return None
        buddy.child_id = child_id
        await self.db.commit()
        await self.db.refresh(buddy)
        return buddy

    async def unbind(self, buddy_id: str) -> Optional[Buddy]:
        buddy = await self.get(buddy_id)
        if not buddy:
            return None
        buddy.child_id = None
        await self.db.commit()
        await self.db.refresh(buddy)
        return buddy 