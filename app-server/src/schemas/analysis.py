from pydantic import BaseModel, Field
from typing import Any, Dict

class CognitiveAnalysisOut(BaseModel):
    """
    认知成长分析结果
    """
    child_id: str
    summary: str = Field(..., description="认知成长简要描述")
    details: Dict[str, Any] = Field(default_factory=dict, description="详细分析数据")

class LanguageAnalysisOut(BaseModel):
    """
    语言成长分析结果
    """
    child_id: str
    summary: str = Field(..., description="语言成长简要描述")
    details: Dict[str, Any] = Field(default_factory=dict, description="详细分析数据")

class HealthAnalysisOut(BaseModel):
    """
    健康状态分析结果
    """
    child_id: str
    summary: str = Field(..., description="健康状态简要描述")
    details: Dict[str, Any] = Field(default_factory=dict, description="详细分析数据") 