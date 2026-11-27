"""Application configuration loaded from environment / .env file."""
from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(BASE_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "GiziLens Detection API"
    api_prefix: str = "/api/v1"
    cors_origins: str = "*"
    max_upload_mb: int = 20

    detection_engine: str = "llm"

    sumopod_api_key: str = ""
    sumopod_api_base_url: str = "https://ai.sumopod.com/v1"
    llm_model: str = "gemini/gemini-3.5-flash"
    llm_timeout_seconds: float = 45.0

    onnx_model_path: str = "models/best.onnx"
    onnx_classes_path: str = "models/classes.json"
    onnx_input_size: int = 320
    onnx_conf_threshold: float = 0.25
    onnx_iou_threshold: float = 0.45
    onnx_max_items: int = 5

    require_api_key: bool = False
    api_keys: str = ""

    midtrans_server_key: str = ""
    midtrans_client_key: str = ""
    midtrans_is_production: bool = False

    @property
    def max_upload_bytes(self) -> int:
        return self.max_upload_mb * 1024 * 1024

    @property
    def allowed_api_keys(self) -> set[str]:
        return {key.strip() for key in self.api_keys.split(",") if key.strip()}

    def resolve_path(self, value: str) -> Path:
        """Resolve a possibly relative path against the backend directory."""
        path = Path(value)
        return path if path.is_absolute() else (BASE_DIR / path)


@lru_cache
def get_settings() -> Settings:
    return Settings()
