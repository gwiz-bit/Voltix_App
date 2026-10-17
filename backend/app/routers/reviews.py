from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Order, OrderItem, Product, Review, User
from ..schemas import ReviewIn, ReviewOut
from ..security import get_current_user

router = APIRouter(prefix="/products/{product_id}/reviews", tags=["Reviews"])


def _review_dict(r: Review) -> dict:
    return {"id": r.id, "user_name": r.user.full_name, "rating": r.rating, "comment": r.comment, "created_at": r.created_at}


@router.get("", response_model=list[ReviewOut])
def list_reviews(product_id: int, db: Session = Depends(get_db)):
    reviews = db.scalars(select(Review).where(Review.product_id == product_id).order_by(Review.id.desc())).all()
    return [_review_dict(r) for r in reviews]


@router.get("/eligibility")
def can_review(product_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return {"can_review": _has_purchased(db, user.id, product_id) and not _has_reviewed(db, user.id, product_id)}


@router.post("", response_model=ReviewOut, status_code=status.HTTP_201_CREATED)
def create_review(
    product_id: int, data: ReviewIn, user: User = Depends(get_current_user), db: Session = Depends(get_db)
):
    if db.get(Product, product_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy sản phẩm")
    if not _has_purchased(db, user.id, product_id):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Bạn chỉ có thể đánh giá sản phẩm đã mua và nhận hàng")
    review = Review(user_id=user.id, product_id=product_id, rating=data.rating, comment=data.comment)
    db.add(review)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, "Bạn đã đánh giá sản phẩm này")
    db.refresh(review)
    return _review_dict(review)


def _has_purchased(db: Session, user_id: int, product_id: int) -> bool:
    return (
        db.scalar(
            select(OrderItem.id)
            .join(Order)
            .where(Order.user_id == user_id, Order.status == "completed", OrderItem.product_id == product_id)
            .limit(1)
        )
        is not None
    )


def _has_reviewed(db: Session, user_id: int, product_id: int) -> bool:
    return db.scalar(select(Review.id).where(Review.user_id == user_id, Review.product_id == product_id)) is not None
