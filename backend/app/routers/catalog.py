from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Brand, Category, OrderItem, Product
from ..schemas import (
    BrandIn,
    BrandOut,
    CategoryIn,
    CategoryOut,
    ProductIn,
    ProductOut,
    ProductPage,
)
from ..security import require_staff
from ..serializers import product_dict, products_dicts, rating_map

router = APIRouter(tags=["Catalog"])


# ===== Public =====
@router.get("/categories", response_model=list[CategoryOut])
def list_categories(db: Session = Depends(get_db)):
    return db.scalars(select(Category).order_by(Category.id)).all()


@router.get("/brands", response_model=list[BrandOut])
def list_brands(db: Session = Depends(get_db)):
    return db.scalars(select(Brand).order_by(Brand.name)).all()


@router.get("/products", response_model=ProductPage)
def list_products(
    search: str | None = None,
    category: int | None = None,
    brand: int | None = None,
    min_price: int | None = Query(default=None, ge=0),
    max_price: int | None = Query(default=None, ge=0),
    sort: Literal["newest", "price_asc", "price_desc", "best_selling"] = "newest",
    page: int = Query(default=1, ge=1),
    size: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    final_price = func.coalesce(Product.sale_price, Product.price)
    query = select(Product).where(Product.is_active.is_(True))
    if search:
        like = f"%{search.strip()}%"
        query = query.join(Brand).where(or_(Product.name.ilike(like), Brand.name.ilike(like)))
    if category:
        query = query.where(Product.category_id == category)
    if brand:
        query = query.where(Product.brand_id == brand)
    if min_price is not None:
        query = query.where(final_price >= min_price)
    if max_price is not None:
        query = query.where(final_price <= max_price)

    total = db.scalar(select(func.count()).select_from(query.subquery()))

    if sort == "price_asc":
        query = query.order_by(final_price.asc())
    elif sort == "price_desc":
        query = query.order_by(final_price.desc())
    elif sort == "best_selling":
        sold = (
            select(OrderItem.product_id, func.sum(OrderItem.quantity).label("sold"))
            .group_by(OrderItem.product_id)
            .subquery()
        )
        query = query.outerjoin(sold, sold.c.product_id == Product.id).order_by(
            func.coalesce(sold.c.sold, 0).desc()
        )
    else:
        query = query.order_by(Product.created_at.desc(), Product.id.desc())

    products = db.scalars(query.offset((page - 1) * size).limit(size)).unique().all()
    return {"items": products_dicts(db, products), "total": total, "page": page, "size": size}


@router.get("/products/{product_id}", response_model=ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)):
    product = db.get(Product, product_id)
    if product is None or not product.is_active:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy sản phẩm")
    return product_dict(product, rating_map(db, [product.id]))


# ===== Admin CRUD (staff/admin) =====
admin = APIRouter(prefix="/admin", tags=["Admin - Catalog"], dependencies=[Depends(require_staff)])


def _commit_or_conflict(db: Session, message: str):
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, message)


@admin.post("/categories", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
def create_category(data: CategoryIn, db: Session = Depends(get_db)):
    category = Category(**data.model_dump())
    db.add(category)
    _commit_or_conflict(db, "Slug danh mục đã tồn tại")
    return category


@admin.put("/categories/{category_id}", response_model=CategoryOut)
def update_category(category_id: int, data: CategoryIn, db: Session = Depends(get_db)):
    category = db.get(Category, category_id) or _not_found("danh mục")
    category.name, category.slug = data.name, data.slug
    _commit_or_conflict(db, "Slug danh mục đã tồn tại")
    return category


@admin.delete("/categories/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(category_id: int, db: Session = Depends(get_db)):
    db.delete(db.get(Category, category_id) or _not_found("danh mục"))
    _commit_or_conflict(db, "Danh mục đang có sản phẩm, không thể xoá")


@admin.post("/brands", response_model=BrandOut, status_code=status.HTTP_201_CREATED)
def create_brand(data: BrandIn, db: Session = Depends(get_db)):
    brand = Brand(**data.model_dump())
    db.add(brand)
    _commit_or_conflict(db, "Thương hiệu đã tồn tại")
    return brand


@admin.put("/brands/{brand_id}", response_model=BrandOut)
def update_brand(brand_id: int, data: BrandIn, db: Session = Depends(get_db)):
    brand = db.get(Brand, brand_id) or _not_found("thương hiệu")
    brand.name, brand.logo_url = data.name, data.logo_url
    _commit_or_conflict(db, "Thương hiệu đã tồn tại")
    return brand


@admin.delete("/brands/{brand_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_brand(brand_id: int, db: Session = Depends(get_db)):
    db.delete(db.get(Brand, brand_id) or _not_found("thương hiệu"))
    _commit_or_conflict(db, "Thương hiệu đang có sản phẩm, không thể xoá")


@admin.get("/products", response_model=list[ProductOut])
def admin_list_products(db: Session = Depends(get_db)):
    """Bao gồm cả sản phẩm đã ẩn."""
    return products_dicts(db, db.scalars(select(Product).order_by(Product.id.desc())).unique().all())


@admin.post("/products", response_model=ProductOut, status_code=status.HTTP_201_CREATED)
def create_product(data: ProductIn, db: Session = Depends(get_db)):
    _check_refs(db, data)
    product = Product(**data.model_dump())
    db.add(product)
    db.commit()
    db.refresh(product)
    return product_dict(product)


@admin.put("/products/{product_id}", response_model=ProductOut)
def update_product(product_id: int, data: ProductIn, db: Session = Depends(get_db)):
    product = db.get(Product, product_id) or _not_found("sản phẩm")
    _check_refs(db, data)
    for key, value in data.model_dump().items():
        setattr(product, key, value)
    db.commit()
    db.refresh(product)
    return product_dict(product, rating_map(db, [product.id]))


@admin.delete("/products/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_product(product_id: int, db: Session = Depends(get_db)):
    """Xoá mềm (ẩn) để không làm hỏng lịch sử đơn hàng."""
    product = db.get(Product, product_id) or _not_found("sản phẩm")
    product.is_active = False
    db.commit()


def _check_refs(db: Session, data: ProductIn):
    if data.sale_price is not None and data.sale_price > data.price:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Giá khuyến mãi phải nhỏ hơn giá gốc")
    if db.get(Category, data.category_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Danh mục không tồn tại")
    if db.get(Brand, data.brand_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Thương hiệu không tồn tại")


def _not_found(what: str):
    raise HTTPException(status.HTTP_404_NOT_FOUND, f"Không tìm thấy {what}")
