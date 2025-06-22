from typing import Any
from pydantic import (
    AnyHttpUrl,
    EmailStr,
    PostgresDsn,
    field_validator,
    ValidationInfo
)
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    """应用配置类"""

    # 应用配置
    APP_NAME: str
    ENVIRONMENT: str
    DEBUG: bool = False

    # 数据库配置
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_HOST: str
    POSTGRES_PORT: str
    POSTGRES_DB: str
    SQLALCHEMY_DATABASE_URI: PostgresDsn | None = None

    @field_validator("SQLALCHEMY_DATABASE_URI", mode="before")
    def assemble_db_connection(cls, v: str | None, info: ValidationInfo) -> Any:
        if isinstance(v, str):
            return v

        values = info.data
        return PostgresDsn.build(
            scheme="postgresql+asyncpg",
            username=values.get("POSTGRES_USER"),
            password=values.get("POSTGRES_PASSWORD"),
            host=values.get("POSTGRES_HOST"),
            port=int(values.get("POSTGRES_PORT")),
            path=values.get('POSTGRES_DB') or '',
        )

    # JWT配置
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # 邮件配置
    EMAILS_FROM_NAME: str
    EMAILS_FROM_EMAIL: EmailStr
    RESEND_API_KEY: str

    # 前端URL
    FRONTEND_URL: AnyHttpUrl

    # TINY BUDDY MANAGER配置
    TINY_BUDDY_MANAGER_TOKEN: str
    AGENT_ID: str = "default_agent"
    DEVICE_URL: str = "http://127.0.0.1:8002/tinybuddy/device/bind/{agent_id}/{device_code}"

    model_config = SettingsConfigDict(env_file=".env", case_sensitive=True)

# 创建全局配置实例
settings = Settings()
