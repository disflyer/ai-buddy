from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from src.models.dialogue import Dialogue
from src.schemas.dialogue import DialogueCreate, DialogueUpdate
from typing import List, Optional

class DialogueService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, dialogue_in: DialogueCreate) -> Dialogue:
        dialogue = Dialogue(**dialogue_in.model_dump(exclude_unset=True))
        self.db.add(dialogue)
        await self.db.commit()
        await self.db.refresh(dialogue)
        return dialogue

    async def get(self, dialogue_id: str) -> Optional[Dialogue]:
        result = await self.db.execute(select(Dialogue).where(Dialogue.id == dialogue_id))
        return result.scalar_one_or_none()

    async def get_multi(self, child_id: Optional[str] = None, buddy_id: Optional[str] = None) -> List[Dialogue]:
        stmt = select(Dialogue)
        if child_id:
            stmt = stmt.where(Dialogue.child_id == child_id)
        if buddy_id:
            stmt = stmt.where(Dialogue.buddy_id == buddy_id)
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def update(self, dialogue_id: str, dialogue_in: DialogueUpdate) -> Optional[Dialogue]:
        dialogue = await self.get(dialogue_id)
        if not dialogue:
            return None
        for field, value in dialogue_in.model_dump(exclude_unset=True).items():
            setattr(dialogue, field, value)
        await self.db.commit()
        await self.db.refresh(dialogue)
        return dialogue

    async def delete(self, dialogue_id: str) -> bool:
        dialogue = await self.get(dialogue_id)
        if not dialogue:
            return False
        await self.db.delete(dialogue)
        await self.db.commit()
        return True 