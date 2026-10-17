from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Đọc cấu hình từ biến môi trường / file .env."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    database_url: str = "mysql+pymysql://root:password@localhost:3306/voltix?charset=utf8mb4"

    jwt_secret: str = "change-me"
    jwt_expire_minutes: int = 60 * 24 * 7
    session_secret: str = "change-me-too"

    # URL công khai của backend, dùng làm vnp_ReturnUrl.
    # Android emulator gọi máy tính qua 10.0.2.2; khi deploy đổi thành https://<domain>.
    public_base_url: str = "http://10.0.2.2:8000"

    vnpay_tmn_code: str = ""
    vnpay_hash_secret: str = ""
    vnpay_url: str = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html"

    cors_origins: str = "*"


settings = Settings()
