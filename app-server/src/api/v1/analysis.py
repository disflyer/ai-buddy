from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from src.schemas.analysis import CognitiveAnalysisOut, LanguageAnalysisOut, HealthAnalysisOut
from src.services.analysis import AnalysisService
from src.core.database import get_db
from src.api.deps import get_current_verified_user
from src.models.user import User as UserModel

router = APIRouter()

@router.get("/cognitive", response_model=CognitiveAnalysisOut)
async def cognitive_analysis(child_id: str = Query(...), db: AsyncSession = Depends(get_db), current_user: UserModel = Depends(get_current_verified_user)):
    service = AnalysisService(db)
    return await service.get_cognitive_analysis(child_id)

@router.get("/language", response_model=LanguageAnalysisOut)
async def language_analysis(child_id: str = Query(...), db: AsyncSession = Depends(get_db), current_user: UserModel = Depends(get_current_verified_user)):
    service = AnalysisService(db)
    return await service.get_language_analysis(child_id)

@router.get("/health", response_model=HealthAnalysisOut)
async def health_analysis(child_id: str = Query(...), db: AsyncSession = Depends(get_db), current_user: UserModel = Depends(get_current_verified_user)):
    service = AnalysisService(db)
    return await service.get_health_analysis(child_id) 