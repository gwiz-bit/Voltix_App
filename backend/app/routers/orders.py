from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Order, User
from ..schemas import OrderCreateIn, OrderOut, OrderStatusIn
from ..security import get_current_user, require_staff
from ..serializers import order_dict
from ..services.orders import change_status, create_order_from_cart

router = APIRouter(tags=["Orders"])


def _own_order(db: Session, order_id: int, user: User) -> Order:
    order = db.get(Order, order_id)
    if order is None or (order.user_id != user.id and not user.is_staff):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy đơn hàng")
    return order


@router.post("/orders", response_model=OrderOut, status_code=status.HTTP_201_CREATED)
def create_order(data: OrderCreateIn, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return order_dict(create_order_from_cart(db, user, data))


@router.get("/orders", response_model=list[OrderOut])
def my_orders(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    orders = db.scalars(select(Order).where(Order.user_id == user.id).order_by(Order.id.desc())).unique().all()
    return [order_dict(o) for o in orders]


@router.get("/orders/{order_id}", response_model=OrderOut)
def get_order(order_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return order_dict(_own_order(db, order_id, user))


@router.post("/orders/{order_id}/cancel", response_model=OrderOut)
def cancel_order(order_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    order = _own_order(db, order_id, user)
    # Khách chỉ được huỷ khi đơn chưa được cửa hàng xác nhận và chưa thanh toán online.
    if order.status != "pending":
        raise HTTPException(status.HTTP_409_CONFLICT, "Chỉ có thể huỷ đơn đang chờ xử lý")
    return order_dict(change_status(db, order, "cancelled"))


# ===== Admin =====
@router.get("/admin/orders", response_model=list[OrderOut], tags=["Admin - Orders"])
def admin_orders(
    status_filter: Literal["pending", "paid", "confirmed", "shipping", "completed", "cancelled"] | None = None,
    _: User = Depends(require_staff),
    db: Session = Depends(get_db),
):
    query = select(Order).order_by(Order.id.desc())
    if status_filter:
        query = query.where(Order.status == status_filter)
    return [order_dict(o) for o in db.scalars(query).unique().all()]


@router.put("/admin/orders/{order_id}/status", response_model=OrderOut, tags=["Admin - Orders"])
def admin_update_status(
    order_id: int, data: OrderStatusIn, _: User = Depends(require_staff), db: Session = Depends(get_db)
):
    order = db.get(Order, order_id)
    if order is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy đơn hàng")
    return order_dict(change_status(db, order, data.status))
