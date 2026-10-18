from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import CartItem, Product, User
from ..schemas import CartItemIn, CartOut, CartQuantityIn
from ..security import get_current_user
from ..serializers import rating_map, product_dict

router = APIRouter(prefix="/cart", tags=["Cart"])


def _cart(db: Session, user: User) -> dict:
    items = db.scalars(select(CartItem).where(CartItem.user_id == user.id).order_by(CartItem.id)).unique().all()
    ratings = rating_map(db, [i.product_id for i in items])
    return {
        "items": [{"id": i.id, "quantity": i.quantity, "product": product_dict(i.product, ratings)} for i in items],
        "total": sum(i.product.final_price * i.quantity for i in items),
        "count": sum(i.quantity for i in items),
    }


@router.get("", response_model=CartOut)
def get_cart(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return _cart(db, user)


@router.post("/items", response_model=CartOut)
def add_item(data: CartItemIn, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    product = db.get(Product, data.product_id)
    if product is None or not product.is_active:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy sản phẩm")
    item = db.scalar(select(CartItem).where(CartItem.user_id == user.id, CartItem.product_id == product.id))
    quantity = (item.quantity if item else 0) + data.quantity
    if quantity > product.stock:
        raise HTTPException(status.HTTP_409_CONFLICT, f"Chỉ còn {product.stock} sản phẩm trong kho")
    if item:
        item.quantity = quantity
    else:
        db.add(CartItem(user_id=user.id, product_id=product.id, quantity=quantity))
    db.commit()
    return _cart(db, user)


@router.put("/items/{item_id}", response_model=CartOut)
def update_item(
    item_id: int, data: CartQuantityIn, user: User = Depends(get_current_user), db: Session = Depends(get_db)
):
    item = db.get(CartItem, item_id)
    if item is None or item.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy sản phẩm trong giỏ")
    if data.quantity > item.product.stock:
        raise HTTPException(status.HTTP_409_CONFLICT, f"Chỉ còn {item.product.stock} sản phẩm trong kho")
    item.quantity = data.quantity
    db.commit()
    return _cart(db, user)


@router.delete("/items/{item_id}", response_model=CartOut)
def remove_item(item_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    db.execute(delete(CartItem).where(CartItem.id == item_id, CartItem.user_id == user.id))
    db.commit()
    return _cart(db, user)


@router.delete("", response_model=CartOut)
def clear_cart(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    db.execute(delete(CartItem).where(CartItem.user_id == user.id))
    db.commit()
    return _cart(db, user)
