from pydantic import BaseModel, Field
from typing import Optional, Dict

class ShopBase(BaseModel):
    name: str = Field(..., description="店铺名称")
    address: Optional[str] = Field(None, description="店铺地址")
    phone: Optional[str] = Field(None, description="联系电话")
    rating: Optional[float] = Field(None, description="评分")
    opening_hours: Optional[Dict[str, str]] = Field(None, description="营业时间，键为星期，值为时间段")
    photo_url: Optional[str] = Field(None, description="主图片 URL")
    google_maps_url: str = Field(..., description="原始 Google Maps 分享链接")
    place_id: str = Field(..., description="Google Maps place_id")

class ShopCreate(BaseModel):
    url: str = Field(..., description="Google Maps 分享链接")

class ShopOut(ShopBase):
    id: int = Field(..., description="主键 ID")

    class Config:
        orm_mode = True 