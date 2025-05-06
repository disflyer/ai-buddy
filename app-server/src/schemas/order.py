from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class OrderBase(BaseModel):
    customer_name: str = Field(..., description="预订者姓名")
    party_size: int = Field(..., description="预订人数")
    phone: str = Field(..., description="联系电话")
    arrive_time: datetime = Field(..., description="到店时间")
    remark: Optional[str] = Field(None, description="备注信息")
    shop_id: int = Field(..., description="关联餐厅ID")

class OrderCreate(OrderBase):
    pass

class OrderUpdate(BaseModel):
    customer_name: Optional[str] = Field(None, description="预订者姓名")
    party_size: Optional[int] = Field(None, description="预订人数")
    phone: Optional[str] = Field(None, description="联系电话")
    arrive_time: Optional[datetime] = Field(None, description="到店时间")
    remark: Optional[str] = Field(None, description="备注信息")
    status: Optional[str] = Field(None, description="订单状态")

class OrderOut(OrderBase):
    id: int = Field(..., description="订单ID")
    status: str = Field(..., description="订单状态")
    created_at: datetime = Field(..., description="下单时间")

    class Config:
        orm_mode = True 