from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from ..database import get_db
from ..security import require_staff
from ..services import stats

router = APIRouter(prefix="/admin/stats", tags=["Admin - Statistics"], dependencies=[Depends(require_staff)])


@router.get("/summary")
def summary(db: Session = Depends(get_db)):
    return stats.summary(db)


@router.get("/revenue")
def revenue(
    group: str = Query(default="day", pattern="^(day|month)$"),
    days: int = Query(default=30, ge=1, le=365),
    db: Session = Depends(get_db),
):
    return stats.revenue_by_day(db, days) if group == "day" else stats.revenue_by_month(db)


@router.get("/top-products")
def top_products(limit: int = Query(default=5, ge=1, le=50), db: Session = Depends(get_db)):
    return stats.top_products(db, limit)


@router.get("/revenue-by-category")
def revenue_by_category(db: Session = Depends(get_db)):
    return stats.revenue_by_category(db)


@router.get("/orders-by-status")
def orders_by_status(db: Session = Depends(get_db)):
    return stats.orders_by_status(db)


@router.get("/low-stock")
def low_stock(threshold: int = Query(default=5, ge=0), db: Session = Depends(get_db)):
    return stats.low_stock_products(db, threshold)
