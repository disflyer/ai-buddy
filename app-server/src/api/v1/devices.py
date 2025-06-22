from fastapi import APIRouter, Depends, HTTPException
from src.schemas.device import DeviceIn, DeviceOut
from src.services.device import DeviceService
from src.api.deps import get_firebase_user
from src.models.user import User as UserModel

router = APIRouter()

@router.post("/bind", response_model=DeviceOut)
async def bind_device(
    device_in: DeviceIn,
    # firebase_user=Depends(get_firebase_user)
):
    """
    根据验证码绑定设备
    """
    service = DeviceService()
    result = await service.bind(device_in)
    return result
