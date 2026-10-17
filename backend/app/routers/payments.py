import time
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.responses import HTMLResponse
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Order, Payment, User
from ..schemas import VnpayCreateIn, VnpayCreateOut
from ..security import get_current_user
from ..services import vnpay

router = APIRouter(prefix="/payments/vnpay", tags=["Payment - VNPay"])


@router.post("/create", response_model=VnpayCreateOut)
def create_payment(
    data: VnpayCreateIn, request: Request, user: User = Depends(get_current_user), db: Session = Depends(get_db)
):
    if not vnpay.is_configured():
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "VNPay chưa được cấu hình trên máy chủ")
    order = db.get(Order, data.order_id)
    if order is None or order.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy đơn hàng")
    if order.payment_method != "VNPAY" or order.status != "pending":
        raise HTTPException(status.HTTP_409_CONFLICT, "Đơn hàng không ở trạng thái chờ thanh toán")

    txn_ref = f"{order.id}-{int(time.time())}"
    db.add(Payment(order_id=order.id, txn_ref=txn_ref, amount=order.total))
    db.commit()
    url = vnpay.build_payment_url(
        txn_ref=txn_ref,
        amount=order.total,
        order_info=f"Thanh toan don hang {order.id}",
        client_ip=request.client.host if request.client else "127.0.0.1",
    )
    return VnpayCreateOut(payment_url=url)


def _apply_result(db: Session, params: dict[str, str]) -> tuple[str, Payment | None]:
    """Cập nhật payment/order theo kết quả VNPay. Trả về (mã kết quả, payment)."""
    if not vnpay.verify(params):
        return "97", None  # sai chữ ký
    payment = db.scalar(select(Payment).where(Payment.txn_ref == params.get("vnp_TxnRef")))
    if payment is None:
        return "01", None  # không tìm thấy giao dịch
    if int(params.get("vnp_Amount", 0)) != payment.amount * 100:
        return "04", payment  # sai số tiền
    if payment.status != "pending":
        return "02", payment  # đã xử lý trước đó
    success = params.get("vnp_ResponseCode") == "00" and params.get("vnp_TransactionStatus") == "00"
    payment.status = "success" if success else "failed"
    payment.response_code = params.get("vnp_ResponseCode")
    if success:
        payment.paid_at = datetime.now()
        if payment.order.status == "pending":
            payment.order.status = "paid"
    db.commit()
    return "00", payment


@router.get("/ipn")
def vnpay_ipn(request: Request, db: Session = Depends(get_db)):
    """VNPay gọi server-to-server (cần URL công khai khi deploy)."""
    code, _ = _apply_result(db, dict(request.query_params))
    messages = {"00": "Confirm Success", "01": "Order not found", "02": "Order already confirmed",
                "04": "Invalid amount", "97": "Invalid signature"}
    return {"RspCode": code, "Message": messages[code]}


@router.get("/return", response_class=HTMLResponse)
def vnpay_return(request: Request, db: Session = Depends(get_db)):
    """Trang VNPay chuyển về sau khi thanh toán; app Flutter bắt URL này để đóng WebView."""
    params = dict(request.query_params)
    code, payment = _apply_result(db, params)
    paid = payment is not None and payment.status == "success"
    title = "Thanh toán thành công" if paid else "Thanh toán không thành công"
    color = "#2e7d32" if paid else "#c62828"
    detail = f"Đơn hàng #{payment.order_id}" if payment else f"Mã lỗi {code}"
    return f"""<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title></head>
<body style="font-family:sans-serif;text-align:center;padding:48px 16px">
<h2 style="color:{color}">{title}</h2><p>{detail}</p><p>Bạn có thể quay lại ứng dụng Voltix.</p></body></html>"""
