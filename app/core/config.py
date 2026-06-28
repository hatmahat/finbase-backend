from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    anthropic_api_key: str
    supabase_url: str
    supabase_service_key: str

    model_config = {"env_file": ".env", "extra": "ignore"}


settings = Settings()
