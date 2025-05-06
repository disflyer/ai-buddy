from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from src.schemas.dialogue import DialogueCreate, DialogueUpdate, DialogueOut
from src.services.dialogue import DialogueService
from src.core.database import get_db
from src.api.deps import get_current_verified_user
from src.models.user import User as UserModel

router = APIRouter()

@router.post("/", response_model=DialogueOut)
async def create_dialogue(dialogue_in: DialogueCreate, db: AsyncSession = Depends(get_db), current_user: UserModel = Depends(get_current_verified_user)):
    service = DialogueService(db)
    return await service.create(dialogue_in)

@router.get("/", response_model=List[DialogueOut])
async def list_dialogues(
    child_id: Optional[str] = Query(None),
    buddy_id: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: UserModel = Depends(get_current_verified_user)
):
    service = DialogueService(db)
    return await service.get_multi(child_id=child_id, buddy_id=buddy_id)

@router.get("/{dialogue_id}", response_model=DialogueOut)
async def get_dialogue(dialogue_id: str, db: AsyncSession = Depends(get_db), current_user: UserModel = Depends(get_current_verified_user)):
    service = DialogueService(db)
    dialogue = await service.get(dialogue_id)
    if not dialogue:
        raise HTTPException(404, "Dialogue not found")
    return dialogue

@router.put("/{dialogue_id}", response_model=DialogueOut)
async def update_dialogue(dialogue_id: str, dialogue_in: DialogueUpdate, db: AsyncSession = Depends(get_db), current_user: UserModel = Depends(get_current_verified_user)):
    service = DialogueService(db)
    dialogue = await service.update(dialogue_id, dialogue_in)
    if not dialogue:
        raise HTTPException(404, "Dialogue not found")
    return dialogue

@router.delete("/{dialogue_id}", response_model=dict)
async def delete_dialogue(dialogue_id: str, db: AsyncSession = Depends(get_db), current_user: UserModel = Depends(get_current_verified_user)):
    service = DialogueService(db)
    ok = await service.delete(dialogue_id)
    if not ok:
        raise HTTPException(404, "Dialogue not found")
    return {"ok": True} 