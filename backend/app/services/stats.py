"""Báo cáo thống kê cho quản lý (dùng chung cho API và web admin)."""

from datetime import date, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..models import REVENUE_STATUSES, Category, Order, OrderItem, Product, User


def summary(db: Session) -> dict:
    revenue_q = select(func.coalesce(func.sum(Order.total), 0)).where(Order.status.in_(REVENUE_STATUSES))
    today = date.today()
    month_start = today.replace(day=1)
    return {
        "total_revenue": int(db.scalar(revenue_q)),
        "month_revenue": int(db.scalar(revenue_q.where(func.date(Order.created_at) >= month_start))),
        "today_revenue": int(db.scalar(revenue_q.where(func.date(Order.created_at) == today))),
        "total_orders": db.scalar(select(func.count(Order.id))),
        "pending_orders": db.scalar(select(func.count(Order.id)).where(Order.status.in_(("pending", "paid")))),
        "customers": db.scalar(select(func.count(User.id)).where(User.role == "customer")),
        "products": db.scalar(select(func.count(Product.id)).where(Product.is_active.is_(True))),
        "low_stock": db.scalar(
            select(func.count(Product.id)).where(Product.is_active.is_(True), Product.stock <= 5)
        ),
    }


def revenue_by_day(db: Session, days: int = 30) -> list[dict]:
    start = date.today() - timedelta(days=days - 1)
    day = func.date(Order.created_at)
    rows = dict(
        db.execute(
            select(day, func.sum(Order.total))
            .where(Order.status.in_(REVENUE_STATUSES), day >= start)
            .group_by(day)
        ).all()
    )
    # Điền 0 cho những ngày không có đơn để biểu đồ liên tục.
    return [
        {"date": (start + timedelta(days=i)).isoformat(), "revenue": int(rows.get(start + timedelta(days=i), 0))}
        for i in range(days)
    ]


def revenue_by_month(db: Session, months: int = 12) -> list[dict]:
    month = func.date_format(Order.created_at, "%Y-%m")
    rows = db.execute(
        select(month, func.sum(Order.total), func.count(Order.id))
        .where(Order.status.in_(REVENUE_STATUSES))
        .group_by(month)
        .order_by(month.desc())
        .limit(months)
    ).all()
    return [{"month": m, "revenue": int(r), "orders": c} for m, r, c in reversed(rows)]


def top_products(db: Session, limit: int = 5) -> list[dict]:
    sold = func.sum(OrderItem.quantity)
    rows = db.execute(
        select(Product.id, Product.name, sold, func.sum(OrderItem.quantity * OrderItem.unit_price))
        .join(OrderItem, OrderItem.product_id == Product.id)
        .join(Order, Order.id == OrderItem.order_id)
        .where(Order.status.in_(REVENUE_STATUSES))
        .group_by(Product.id, Product.name)
        .order_by(sold.desc())
        .limit(limit)
    ).all()
    return [{"product_id": i, "name": n, "sold": int(s), "revenue": int(r)} for i, n, s, r in rows]


def revenue_by_category(db: Session) -> list[dict]:
    rows = db.execute(
        select(Category.name, func.sum(OrderItem.quantity * OrderItem.unit_price))
        .join(Product, Product.category_id == Category.id)
        .join(OrderItem, OrderItem.product_id == Product.id)
        .join(Order, Order.id == OrderItem.order_id)
        .where(Order.status.in_(REVENUE_STATUSES))
        .group_by(Category.name)
        .order_by(func.sum(OrderItem.quantity * OrderItem.unit_price).desc())
    ).all()
    return [{"category": c, "revenue": int(r)} for c, r in rows]


def orders_by_status(db: Session) -> list[dict]:
    rows = dict(db.execute(select(Order.status, func.count(Order.id)).group_by(Order.status)).all())
    return [
        {"status": s, "count": rows.get(s, 0)}
        for s in ("pending", "paid", "confirmed", "shipping", "completed", "cancelled")
    ]


def low_stock_products(db: Session, threshold: int = 5) -> list[dict]:
    products = db.scalars(
        select(Product).where(Product.is_active.is_(True), Product.stock <= threshold).order_by(Product.stock)
    ).unique().all()
    return [{"id": p.id, "name": p.name, "stock": p.stock} for p in products]
