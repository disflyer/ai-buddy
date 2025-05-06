from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from src.core.database import get_db
from src.schemas.order import OrderCreate, OrderUpdate, OrderOut
from src.services.order import create_order, get_order, list_orders, update_order, delete_order
from typing import List, Optional

router = APIRouter()

@router.post("/", response_model=OrderOut, summary="创建订单")
async def create_order_api(order_in: OrderCreate, db: AsyncSession = Depends(get_db)):
    order = await create_order(db, order_in)
    return OrderOut.from_orm(order)

@router.get("/{order_id}", response_model=OrderOut, summary="查询单个订单")
async def get_order_api(order_id: int, db: AsyncSession = Depends(get_db)):
    order = await get_order(db, order_id)
    if not order:
        raise HTTPException(status_code=404, detail="订单不存在")
    return OrderOut.from_orm(order)

@router.get("/", response_model=List[OrderOut], summary="查询订单列表")
async def list_orders_api(
    shop_id: Optional[int] = Query(None, description="按餐厅筛选"),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db)
):
    orders = await list_orders(db, shop_id=shop_id, skip=skip, limit=limit)
    return [OrderOut.from_orm(o) for o in orders]

@router.put("/{order_id}", response_model=OrderOut, summary="更新订单")
async def update_order_api(order_id: int, order_in: OrderUpdate, db: AsyncSession = Depends(get_db)):
    order = await update_order(db, order_id, order_in)
    if not order:
        raise HTTPException(status_code=404, detail="订单不存在")
    return OrderOut.from_orm(order)

@router.delete("/{order_id}", response_model=dict, summary="删除订单")
async def delete_order_api(order_id: int, db: AsyncSession = Depends(get_db)):
    ok = await delete_order(db, order_id)
    if not ok:
        raise HTTPException(status_code=404, detail="订单不存在")
    return {"success": True} 