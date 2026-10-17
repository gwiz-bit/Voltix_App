"""Tạo URL thanh toán và kiểm tra chữ ký VNPay (API v2.1.0)."""

import hashlib
import hmac
from datetime import datetime, timedelta, timezone
from urllib.parse import quote_plus

from ..config import settings

VN_TZ = timezone(timedelta(hours=7))


def _sign(params: dict[str, str]) -> str:
    # VNPay yêu cầu: sắp xếp key tăng dần, urlencode từng giá trị, nối bằng '&', HMAC-SHA512.
    query = "&".join(f"{k}={quote_plus(str(v))}" for k, v in sorted(params.items()))
    return hmac.new(settings.vnpay_hash_secret.encode(), query.encode(), hashlib.sha512).hexdigest()


def is_configured() -> bool:
    return bool(settings.vnpay_tmn_code and settings.vnpay_hash_secret)


def build_payment_url(*, txn_ref: str, amount: int, order_info: str, client_ip: str) -> str:
    now = datetime.now(VN_TZ)
    params = {
        "vnp_Version": "2.1.0",
        "vnp_Command": "pay",
        "vnp_TmnCode": settings.vnpay_tmn_code,
        "vnp_Amount": str(amount * 100),  # VNPay tính theo đơn vị x100
        "vnp_CurrCode": "VND",
        "vnp_TxnRef": txn_ref,
        "vnp_OrderInfo": order_info,
        "vnp_OrderType": "other",
        "vnp_Locale": "vn",
        "vnp_ReturnUrl": f"{settings.public_base_url}/api/payments/vnpay/return",
        "vnp_IpAddr": client_ip,
        "vnp_CreateDate": now.strftime("%Y%m%d%H%M%S"),
        "vnp_ExpireDate": (now + timedelta(minutes=15)).strftime("%Y%m%d%H%M%S"),
    }
    query = "&".join(f"{k}={quote_plus(str(v))}" for k, v in sorted(params.items()))
    return f"{settings.vnpay_url}?{query}&vnp_SecureHash={_sign(params)}"


def verify(query_params: dict[str, str]) -> bool:
    """Kiểm tra vnp_SecureHash trong dữ liệu VNPay gửi về."""
    received = query_params.get("vnp_SecureHash", "")
    params = {
        k: v
        for k, v in query_params.items()
        if k.startswith("vnp_") and k not in ("vnp_SecureHash", "vnp_SecureHashType")
    }
    return bool(received) and hmac.compare_digest(_sign(params), received.lower())
