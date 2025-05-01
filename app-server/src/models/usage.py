from datetime import datetime
import uuid
from sqlalchemy import String, Float, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from src.core.database import Base

class Usage(Base):
    """
    使用时长模型
    """
    __tablename__ = "usages"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    child_id: Mapped[str] = mapped_column(String(36), ForeignKey("children.id"), nullable=False)
    buddy_id: Mapped[str] = mapped_column(String(36), ForeignKey("buddies.id"), nullable=False)
    type: Mapped[str] = mapped_column(String(32), nullable=False)  # 学习/音乐/故事
    duration: Mapped[float] = mapped_column(Float, nullable=False)  # 单位：分钟
    timestamp: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False) 