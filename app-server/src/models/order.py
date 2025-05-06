from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.ext.asyncio import AsyncAttrs
from sqlalchemy.orm import declarative_base, relationship
from datetime import datetime

Base = declarative_base()

class Order(AsyncAttrs, Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    customer_name = Column(String(128), nullable=False, comment="预订者姓名")
    party_size = Column(Integer, nullable=False, comment="预订人数")
    phone = Column(String(64), nullable=False, comment="联系电话")
    arrive_time = Column(DateTime, nullable=False, comment="到店时间")
    remark = Column(Text, nullable=True, comment="备注信息")
    shop_id = Column(Integer, ForeignKey("shops.id"), nullable=False, comment="关联餐厅ID")
    status = Column(String(32), nullable=False, default="pending", comment="订单状态")
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow, comment="下单时间")

    # 关联餐厅对象（可选）
    shop = relationship("Shop", backref="orders")