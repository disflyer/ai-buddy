import httpx
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from src.models.shop import Shop
from src.core.config import settings
from typing import Optional
import json

GOOGLE_MAPS_API_KEY = settings.GOOGLE_MAPS_API_KEY

async def resolve_google_maps_url(short_url: str) -> Optional[str]:
    """
    解析 Google Maps 分享短链，获取最终跳转的标准 Google Maps URL。
    """
    async with httpx.AsyncClient(follow_redirects=True, timeout=10) as client:
        try:
            resp = await client.get(short_url)
            return str(resp.url)
        except Exception as e:
            return None

async def get_place_id_from_url(url: str) -> Optional[str]:
    """
    尝试从标准 Google Maps URL 中提取 place_id。
    """
    # 典型 URL: https://www.google.com/maps/place/?q=place_id:xxxx
    import re
    match = re.search(r'place_id:([a-zA-Z0-9_-]+)', url)
    if match:
        return match.group(1)
    return None

async def get_place_details(place_id: str) -> Optional[dict]:
    """
    调用 Google Maps Place Details API 获取店铺详细信息。
    """
    url = "https://maps.googleapis.com/maps/api/place/details/json"
    params = {
        "place_id": place_id,
        "key": GOOGLE_MAPS_API_KEY,
        "language": "zh-CN"
    }
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(url, params=params)
        data = resp.json()
        if data.get("status") == "OK":
            return data["result"]
        return None

async def save_shop_to_db(db: AsyncSession, shop_data: dict, google_maps_url: str, place_id: str) -> Shop:
    """
    保存店铺信息到数据库，若已存在则更新。
    """
    # 只取一张主图片
    photo_url = None
    photos = shop_data.get("photos")
    if photos and isinstance(photos, list):
        ref = photos[0].get("photo_reference")
        if ref:
            photo_url = f"https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference={ref}&key={GOOGLE_MAPS_API_KEY}"
    # 营业时间
    opening_hours = shop_data.get("opening_hours", {}).get("weekday_text")
    opening_hours_json = json.dumps(opening_hours, ensure_ascii=False) if opening_hours else None
    # 查重
    result = await db.execute(select(Shop).where(Shop.place_id == place_id))
    shop = result.scalar_one_or_none()
    if shop:
        # 更新
        shop.name = shop_data.get("name")
        shop.address = shop_data.get("formatted_address")
        shop.phone = shop_data.get("formatted_phone_number")
        shop.rating = shop_data.get("rating")
        shop.opening_hours = opening_hours_json
        shop.photo_url = photo_url
        shop.google_maps_url = google_maps_url
    else:
        shop = Shop(
            name=shop_data.get("name"),
            address=shop_data.get("formatted_address"),
            phone=shop_data.get("formatted_phone_number"),
            rating=shop_data.get("rating"),
            opening_hours=opening_hours_json,
            photo_url=photo_url,
            google_maps_url=google_maps_url,
            place_id=place_id
        )
        db.add(shop)
    await db.flush()
    return shop

async def parse_and_save_shop(db: AsyncSession, share_url: str) -> Optional[Shop]:
    """
    综合流程：解析分享链接，获取店铺信息并保存。
    """
    # 1. 解析短链
    resolved_url = await resolve_google_maps_url(share_url)
    if not resolved_url:
        return None
    # 2. 提取 place_id
    place_id = await get_place_id_from_url(resolved_url)
    if not place_id:
        # 若无法直接提取，可用 Find Place API 反查（此处略，可后续补充）
        return None
    # 3. 获取详细信息
    details = await get_place_details(place_id)
    if not details:
        return None
    # 4. 保存到数据库
    shop = await save_shop_to_db(db, details, share_url, place_id)
    return shop 