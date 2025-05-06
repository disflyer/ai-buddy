from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from src.core.database import get_db
from src.schemas.shop import ShopCreate, ShopOut
from src.services.shop import parse_and_save_shop

router = APIRouter()

@router.post("/parse_google_map_link", response_model=ShopOut, summary="解析 Google Maps 分享链接并保存店铺信息")
async def parse_google_map_link(
    shop_in: ShopCreate,
    db: AsyncSession = Depends(get_db)
):
    """
    接收 Google Maps 分享链接，解析店铺信息并保存到数据库。
    """
    shop = await parse_and_save_shop(db, shop_in.url)
    if not shop:
        raise HTTPException(status_code=400, detail="无法解析该链接或未找到店铺信息")
    # 处理 opening_hours 字段反序列化
    from typing import cast
    import json
    opening_hours = None
    if shop.opening_hours:
        try:
            opening_hours = json.loads(shop.opening_hours)
        except Exception:
            opening_hours = None
    return ShopOut(
        id=shop.id,
        name=shop.name,
        address=shop.address,
        phone=shop.phone,
        rating=shop.rating,
        opening_hours=opening_hours,
        photo_url=shop.photo_url,
        google_maps_url=shop.google_maps_url,
        place_id=shop.place_id
    ) 