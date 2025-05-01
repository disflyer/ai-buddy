from datetime import datetime
import uuid
from sqlalchemy import String, DateTime, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column
from src.core.database import Base

class Dialogue(Base):
    """
    对话历史模型
    """
    __tablename__ = "dialogues"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    child_id: Mapped[str] = mapped_column(String(36), ForeignKey("children.id"), nullable=False)
    buddy_id: Mapped[str] = mapped_column(String(36), ForeignKey("buddies.id"), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    timestamp: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False) 