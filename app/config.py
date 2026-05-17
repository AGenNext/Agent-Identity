from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    APP_NAME: str = "Agent Identity"
    ENVIRONMENT: str = "development"
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    LOG_LEVEL: str = "INFO"
    SECRET_KEY: str = "change-me-in-production"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
