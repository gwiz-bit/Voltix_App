"""Nghiệp vụ đơn hàng dùng chung cho API mobile và web admin."""

from fastapi import HTTPException, status
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from ..models import CartItem, Order, OrderItem, Product, User
from ..schemas import OrderCreateIn

# Chuyển trạng thái hợp lệ: trạng thái hiện tại -> các trạng thái được phép đổi sang.
TRANSITIONS: dict[str, set[str]] = {
    "pending": {"paid", "confirmed", "cancelled"},
    "paid": {"confirmed", "cancelled"},
    "confirmed": {"shipping", "cancelled"},
    "shipping": {"completed"},
    "completed": set(),
    "cancelled": set(),
}


def create_order_from_cart(db: Session, user: User, data: OrderCreateIn) -> Order:
    """Tạo đơn từ giỏ hàng: khoá dòng sản phẩm, kiểm tra & trừ tồn kho, xoá giỏ — trong 1 transaction."""
    cart = db.scalars(select(CartItem).where(CartItem.user_id == user.id)).all()
    if not cart:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Giỏ hàng trống")

    product_ids = [c.product_id for c in cart]
    # SELECT ... FOR UPDATE: tránh 2 đơn cùng lúc mua vượt tồn kho.
    products = {
        p.id: p
        for p in db.scalars(select(Product).where(Product.id.in_(product_ids)).with_for_update()).unique()
    }

    order = Order(
        user_id=user.id,
        receiver=data.receiver.strip(),
        phone=data.phone,
        shipping_address=data.shipping_address.strip(),
        note=data.note,
        payment_method=data.payment_method,
        status="pending",
        total=0,
    )
    total = 0
    for item in cart:
        product = products[item.product_id]
        if not product.is_active:
            db.rollback()
            raise HTTPException(status.HTTP_409_CONFLICT, f'"{product.name}" đã ngừng kinh doanh')
        if product.stock < item.quantity:
            db.rollback()
            raise HTTPException(
                status.HTTP_409_CONFLICT, f'"{product.name}" chỉ còn {product.stock} sản phẩm'
            )
        product.stock -= item.quantity
        total += product.final_price * item.quantity
        order.items.append(OrderItem(product_id=product.id, quantity=item.quantity, unit_price=product.final_price))

    order.total = total
    db.add(order)
    db.execute(delete(CartItem).where(CartItem.user_id == user.id))
    db.commit()
    db.refresh(order)
    return order


def change_status(db: Session, order: Order, new_status: str) -> Order:
    if new_status == order.status:
        return order
    if new_status not in TRANSITIONS[order.status]:
        raise HTTPException(
            status.HTTP_409_CONFLICT, f"Không thể chuyển đơn từ '{order.status}' sang '{new_status}'"
        )
    if new_status == "cancelled":
        # Hoàn lại tồn kho khi huỷ.
        for item in order.items:
            item.product.stock += item.quantity
    order.status = new_status
    db.commit()
    db.refresh(order)
    return order
