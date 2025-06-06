from fastapi import APIRouter

from .children import router as children_router
from .buddies import router as buddies_router
from .usages import router as usages_router
from .dialogues import router as dialogues_router
from .resources import router as resources_router
from .analysis import router as analysis_router
from .upload import router as upload_router

api_router = APIRouter()

api_router.include_router(children_router, prefix="/children", tags=["children"])
api_router.include_router(buddies_router, prefix="/buddies", tags=["buddies"])
api_router.include_router(usages_router, prefix="/usages", tags=["usages"])
api_router.include_router(dialogues_router, prefix="/dialogues", tags=["dialogues"])
api_router.include_router(resources_router, prefix="/resources", tags=["resources"])
api_router.include_router(analysis_router, prefix="/analysis", tags=["analysis"])
api_router.include_router(upload_router, prefix="/upload", tags=["upload"]) 