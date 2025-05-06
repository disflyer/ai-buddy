from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from src.models.order import Order
from src.schemas.order import OrderCreate, OrderUpdate
from typing import List, Optional
from datetime import datetime

async def create_order(db: AsyncSession, order_in: OrderCreate) -> Order:
    """
    创建新订单
    """
    order = Order(
        customer_name=order_in.customer_name,
        party_size=order_in.party_size,
        phone=order_in.phone,
        arrive_time=order_in.arrive_time,
        remark=order_in.remark,
        shop_id=order_in.shop_id,
        status="pending",
        created_at=datetime.utcnow()
    )
    db.add(order)
    await db.flush()
    return order

async def get_order(db: AsyncSession, order_id: int) -> Optional[Order]:
    """
    查询单个订单
    """
    result = await db.execute(select(Order).where(Order.id == order_id))
    return result.scalar_one_or_none()

async def list_orders(db: AsyncSession, shop_id: Optional[int] = None, skip: int = 0, limit: int = 20) -> List[Order]:
    """
    查询订单列表，可按餐厅筛选
    """
    stmt = select(Order)
    if shop_id:
        stmt = stmt.where(Order.shop_id == shop_id)
    stmt = stmt.offset(skip).limit(limit).order_by(Order.created_at.desc())
    result = await db.execute(stmt)
    return result.scalars().all()

async def update_order(db: AsyncSession, order_id: int, order_in: OrderUpdate) -> Optional[Order]:
    """
    更新订单
    """
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        return None
    for field, value in order_in.dict(exclude_unset=True).items():
        setattr(order, field, value)
    await db.flush()
    return order

async def delete_order(db: AsyncSession, order_id: int) -> bool:
    """
    删除订单
    """
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        return False
    await db.delete(order)
    await db.flush()
    return True 