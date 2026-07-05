from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional


class Settings(BaseSettings):
    PROJECT_NAME: str = "EventSphere API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"

    MONGO_URI: str = "mongodb://localhost:27017"
    MONGO_DB_NAME: str = "eventsphere"
    
    REDIS_URL: str = "redis://localhost:6379"

    JWT_SECRET: str = "super_secret_default_key_change_me_in_prod"
    JWT_EXPIRE_MINUTES: int = 1440  # 24 hours
    JWT_ALGORITHM: str = "HS256"
    
    model_config = SettingsConfigDict(
        env_file=".env", 
        env_file_encoding="utf-8", 
        extra="ignore"
    )

settings = Settings()
