"""Chuyển model SQLAlchemy sang dict có thêm các trường tính toán."""

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from .models import Message, Order, Product, Review


def rating_map(db: Session, product_ids: list[int]) -> dict[int, tuple[float, int]]:
    """{product_id: (điểm trung bình, số đánh giá)} cho danh sách sản phẩm."""
    if not product_ids:
        return {}
    rows = db.execute(
        select(Review.product_id, func.avg(Review.rating), func.count(Review.id))
        .where(Review.product_id.in_(product_ids))
        .group_by(Review.product_id)
    ).all()
    return {pid: (round(float(avg), 1), count) for pid, avg, count in rows}


def product_dict(p: Product, ratings: dict[int, tuple[float, int]] | None = None) -> dict:
    avg, count = (ratings or {}).get(p.id, (0.0, 0))
    return {
        "id": p.id,
        "category_id": p.category_id,
        "category_name": p.category.name,
        "category_slug": p.category.slug,
        "brand_id": p.brand_id,
        "brand_name": p.brand.name,
        "name": p.name,
        "description": p.description,
        "price": p.price,
        "sale_price": p.sale_price,
        "stock": p.stock,
        "image_url": p.image_url,
        "specs": p.specs or {},
        "is_active": p.is_active,
        "avg_rating": avg,
        "review_count": count,
    }


def products_dicts(db: Session, products: list[Product]) -> list[dict]:
    ratings = rating_map(db, [p.id for p in products])
    return [product_dict(p, ratings) for p in products]


def order_dict(o: Order) -> dict:
    return {
        "id": o.id,
        "user_id": o.user_id,
        "customer_name": o.user.full_name,
        "receiver": o.receiver,
        "phone": o.phone,
        "shipping_address": o.shipping_address,
        "note": o.note,
        "total": o.total,
        "status": o.status,
        "payment_method": o.payment_method,
        "created_at": o.created_at,
        "updated_at": o.updated_at,
        "items": [
            {
                "product_id": i.product_id,
                "product_name": i.product.name,
                "image_url": i.product.image_url,
                "quantity": i.quantity,
                "unit_price": i.unit_price,
            }
            for i in o.items
        ],
    }


def message_dict(m: Message) -> dict:
    return {
        "id": m.id,
        "conversation_id": m.conversation_id,
        "sender_id": m.sender_id,
        "sender_name": m.sender.full_name,
        "sender_role": m.sender.role,
        "content": m.content,
        "created_at": m.created_at,
    }
