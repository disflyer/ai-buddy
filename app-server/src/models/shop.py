from sqlalchemy import Column, Integer, String, Float, Text
from sqlalchemy.ext.asyncio import AsyncAttrs
from sqlalchemy.orm import declarative_base

Base = declarative_base()

class Shop(AsyncAttrs, Base):
    __tablename__ = "shops"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(256), nullable=False, comment="店铺名称")
    address = Column(String(512), nullable=True, comment="店铺地址")
    phone = Column(String(64), nullable=True, comment="联系电话")
    rating = Column(Float, nullable=True, comment="评分")
    opening_hours = Column(Text, nullable=True, comment="营业时间，JSON 字符串")
    photo_url = Column(String(1024), nullable=True, comment="主图片 URL")
    google_maps_url = Column(String(1024), nullable=False, comment="原始 Google Maps 分享链接")
    place_id = Column(String(128), nullable=False, unique=True, comment="Google Maps place_id")

    # 可根据需要添加 __repr__ 或其他方法 