from datetime import datetime
import uuid
from sqlalchemy import String, DateTime, Text
from sqlalchemy.orm import Mapped, mapped_column
from src.core.database import Base

class Resource(Base):
    """
    资源模型（学习/音乐/故事）
    """
    __tablename__ = "resources"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    type: Mapped[str] = mapped_column(String(32), nullable=False)  # 学习/音乐/故事
    title: Mapped[str] = mapped_column(String(128), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=True)
    url: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False) 