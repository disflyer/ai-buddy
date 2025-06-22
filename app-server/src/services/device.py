import os
from typing import Any
import requests

from src.core.config import settings
from src.schemas.device import DeviceIn, DeviceOut

class DeviceService:
    def __init__(self):
        self.agent = settings.AGENT_ID
        self.device_url = settings.DEVICE_URL
        self.token = settings.TINY_BUDDY_MANAGER_TOKEN

    async def bind(self, device_in: DeviceIn) -> DeviceOut:
        try:
            result = requests.post(
                url = self.device_url.format(
                    agent_id=device_in.agent_id or self.agent,
                    device_code=device_in.device_code
                ),
                headers={"Authorization": "Bearer {tiny_buddy_manager_token}".format(tiny_buddy_manager_token=self.token)},
                json={}
            ).json()
            if result.get("code") != 0:
                return DeviceOut(success=False, message=result.get("msg", "Unknown error"))
        except Exception as e:
            print(f"Error binding device: {e}")
            return DeviceOut(success=False, message=f"Failed to bind device due to an {e}")
        return DeviceOut(success=True, message="Device bound successfully")
