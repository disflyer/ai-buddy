from typing import Optional, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime

class DeviceIn(BaseModel):
    """
    设备信息
    """
    agent_id: Optional[str] = None
    device_code: str

class DeviceOut(BaseModel):
    """
    设备信息
    """
    success: bool
    message: Optional[str] = None
