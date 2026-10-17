"""Web admin (HTML) tại /admin — đăng nhập bằng session cookie, chỉ cho staff/admin."""

import json
from pathlib import Path

from fastapi import APIRouter, Depends, Form, HTTPException, Request, status
from fastapi.responses import RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import ORDER_STATUSES, Brand, Category, Order, Product, User
from ..security import create_access_token, verify_password
from ..services import stats
from ..services.orders import TRANSITIONS, change_status

templates = Jinja2Templates(directory=Path(__file__).resolve().parent.parent / "templates")
templates.env.filters["vnd"] = lambda v: f"{int(v or 0):,}".replace(",", ".") + " ₫"
templates.env.globals["STATUS_LABELS"] = {
    "pending": ("Chờ xử lý", "secondary"),
    "paid": ("Đã thanh toán", "info"),
    "confirmed": ("Đã xác nhận", "primary"),
    "shipping": ("Đang giao", "warning"),
    "completed": ("Hoàn thành", "success"),
    "cancelled": ("Đã huỷ", "danger"),
}

router = APIRouter(prefix="/admin", include_in_schema=False)


# ===== Helpers =====
def current_staff(request: Request, db: Session = Depends(get_db)) -> User:
    user_id = request.session.get("user_id")
    user = db.get(User, user_id) if user_id else None
    if user is None or not user.is_active or not user.is_staff:
        request.session.clear()
        raise HTTPException(status.HTTP_303_SEE_OTHER, headers={"Location": "/admin/login"})
    return user


def flash(request: Request, message: str, category: str = "success"):
    request.session.setdefault("flash", []).append([category, message])


def render(request: Request, template: str, user: User | None = None, **context):
    messages = request.session.pop("flash", [])
    return templates.TemplateResponse(
        request, template, {"user": user, "messages": messages, "path": request.url.path, **context}
    )


def redirect(url: str) -> RedirectResponse:
    return RedirectResponse(url, status_code=status.HTTP_303_SEE_OTHER)


# ===== Auth =====
@router.get("/login")
def login_page(request: Request):
    return render(request, "login.html")


@router.post("/login")
def login(request: Request, email: str = Form(...), password: str = Form(...), db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.email == email.strip().lower()))
    if user is None or not verify_password(password, user.password_hash) or not user.is_staff or not user.is_active:
        flash(request, "Sai thông tin đăng nhập hoặc tài khoản không có quyền quản trị", "danger")
        return redirect("/admin/login")
    request.session["user_id"] = user.id
    return redirect("/admin")


@router.post("/logout")
def logout(request: Request):
    request.session.clear()
    return redirect("/admin/login")


# ===== Dashboard =====
@router.get("")
def dashboard(request: Request, user: User = Depends(current_staff), db: Session = Depends(get_db)):
    return render(
        request,
        "dashboard.html",
        user,
        summary=stats.summary(db),
        revenue_days=stats.revenue_by_day(db, 30),
        revenue_months=stats.revenue_by_month(db, 12),
        by_category=stats.revenue_by_category(db),
        by_status=stats.orders_by_status(db),
        top=stats.top_products(db, 5),
        low_stock=stats.low_stock_products(db),
    )


# ===== Products =====
@router.get("/products")
def products_page(
    request: Request, q: str = "", user: User = Depends(current_staff), db: Session = Depends(get_db)
):
    query = select(Product).order_by(Product.id.desc())
    if q:
        query = query.where(Product.name.ilike(f"%{q}%"))
    return render(request, "products.html", user, products=db.scalars(query).unique().all(), q=q)


def _product_form(request: Request, user: User, db: Session, product: Product | None, form: dict | None = None):
    return render(
        request,
        "product_form.html",
        user,
        product=product,
        form=form,
        categories=db.scalars(select(Category).order_by(Category.name)).all(),
        brands=db.scalars(select(Brand).order_by(Brand.name)).all(),
    )


@router.get("/products/new")
def new_product(request: Request, user: User = Depends(current_staff), db: Session = Depends(get_db)):
    return _product_form(request, user, db, None)


@router.get("/products/{product_id}/edit")
def edit_product(product_id: int, request: Request, user: User = Depends(current_staff), db: Session = Depends(get_db)):
    product = db.get(Product, product_id)
    if product is None:
        flash(request, "Không tìm thấy sản phẩm", "danger")
        return redirect("/admin/products")
    return _product_form(request, user, db, product)


@router.post("/products/save")
def save_product(
    request: Request,
    product_id: int | None = Form(None),
    name: str = Form(...),
    category_id: int = Form(...),
    brand_id: int = Form(...),
    price: int = Form(..., ge=0),
    sale_price: str = Form(""),
    stock: int = Form(..., ge=0),
    image_url: str = Form(""),
    description: str = Form(""),
    specs: str = Form(""),
    is_active: bool = Form(False),
    user: User = Depends(current_staff),
    db: Session = Depends(get_db),
):
    form = dict(name=name, category_id=category_id, brand_id=brand_id, price=price, sale_price=sale_price,
                stock=stock, image_url=image_url, description=description, specs=specs, is_active=is_active)
    product = db.get(Product, product_id) if product_id else None
    error = None
    try:
        specs_obj = json.loads(specs) if specs.strip() else {}
        if not isinstance(specs_obj, dict):
            raise ValueError
    except ValueError:
        error = 'Thông số kỹ thuật phải là JSON object, ví dụ {"socket": "AM5"}'
    sale = int(sale_price) if sale_price.strip().isdigit() else None
    if sale is not None and sale > price:
        error = "Giá khuyến mãi phải nhỏ hơn hoặc bằng giá gốc"
    if len(name.strip()) < 2:
        error = "Tên sản phẩm quá ngắn"
    if error:
        flash(request, error, "danger")
        return _product_form(request, user, db, product, form)

    if product is None:
        product = Product()
        db.add(product)
    product.name = name.strip()
    product.category_id = category_id
    product.brand_id = brand_id
    product.price = price
    product.sale_price = sale
    product.stock = stock
    product.image_url = image_url.strip() or None
    product.description = description.strip() or None
    product.specs = specs_obj
    product.is_active = is_active
    db.commit()
    flash(request, f'Đã lưu sản phẩm "{product.name}"')
    return redirect("/admin/products")


@router.post("/products/{product_id}/toggle")
def toggle_product(product_id: int, request: Request, user: User = Depends(current_staff), db: Session = Depends(get_db)):
    product = db.get(Product, product_id)
    if product:
        product.is_active = not product.is_active
        db.commit()
        flash(request, f'{"Hiện" if product.is_active else "Ẩn"} sản phẩm "{product.name}"')
    return redirect("/admin/products")


# ===== Categories & Brands (dùng chung 1 template) =====
SIMPLE = {
    "categories": (Category, "Danh mục", ["name", "slug"]),
    "brands": (Brand, "Thương hiệu", ["name", "logo_url"]),
}


@router.get("/{kind}")
def simple_list(kind: str, request: Request, edit: int | None = None, user: User = Depends(current_staff),
                db: Session = Depends(get_db)):
    if kind not in SIMPLE:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    model, title, fields = SIMPLE[kind]
    rows = db.scalars(select(model).order_by(model.id)).all()
    editing = db.get(model, edit) if edit else None
    return render(request, "simple_crud.html", user, kind=kind, title=title, fields=fields, rows=rows, editing=editing)


@router.post("/{kind}/save")
async def simple_save(kind: str, request: Request, user: User = Depends(current_staff), db: Session = Depends(get_db)):
    if kind not in SIMPLE:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    model, title, fields = SIMPLE[kind]
    form = await request.form()
    values = {f: (str(form.get(f, "")).strip() or None) for f in fields}
    if not values["name"] or (kind == "categories" and not values["slug"]):
        flash(request, "Vui lòng nhập đầy đủ thông tin", "danger")
        return redirect(f"/admin/{kind}")
    row_id = form.get("id")
    row = db.get(model, int(row_id)) if row_id else model()
    for key, value in values.items():
        setattr(row, key, value)
    db.add(row)
    try:
        db.commit()
        flash(request, f"Đã lưu {title.lower()} \"{row.name}\"")
    except IntegrityError:
        db.rollback()
        flash(request, f"{title} đã tồn tại", "danger")
    return redirect(f"/admin/{kind}")


@router.post("/{kind}/{row_id}/delete")
def simple_delete(kind: str, row_id: int, request: Request, user: User = Depends(current_staff),
                  db: Session = Depends(get_db)):
    if kind not in SIMPLE:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    model, title, _ = SIMPLE[kind]
    row = db.get(model, row_id)
    if row:
        db.delete(row)
        try:
            db.commit()
            flash(request, f"Đã xoá {title.lower()}")
        except IntegrityError:
            db.rollback()
            flash(request, f"{title} đang có sản phẩm, không thể xoá", "danger")
    return redirect(f"/admin/{kind}")


# ===== Orders =====
@router.get("/orders/list")
def orders_page(request: Request, status_filter: str = "", user: User = Depends(current_staff),
                db: Session = Depends(get_db)):
    query = select(Order).order_by(Order.id.desc())
    if status_filter in ORDER_STATUSES:
        query = query.where(Order.status == status_filter)
    return render(request, "orders.html", user, orders=db.scalars(query).unique().all(), status_filter=status_filter)


@router.get("/orders/{order_id}")
def order_detail(order_id: int, request: Request, user: User = Depends(current_staff), db: Session = Depends(get_db)):
    order = db.get(Order, order_id)
    if order is None:
        flash(request, "Không tìm thấy đơn hàng", "danger")
        return redirect("/admin/orders/list")
    return render(request, "order_detail.html", user, order=order, next_statuses=sorted(TRANSITIONS[order.status]))


@router.post("/orders/{order_id}/status")
def order_status(order_id: int, request: Request, new_status: str = Form(...), user: User = Depends(current_staff),
                 db: Session = Depends(get_db)):
    order = db.get(Order, order_id)
    if order is None:
        return redirect("/admin/orders/list")
    try:
        change_status(db, order, new_status)
        flash(request, f"Đơn #{order.id} đã chuyển sang trạng thái mới")
    except HTTPException as e:
        flash(request, e.detail, "danger")
    return redirect(f"/admin/orders/{order_id}")


# ===== Users =====
@router.get("/users/list")
def users_page(request: Request, q: str = "", user: User = Depends(current_staff), db: Session = Depends(get_db)):
    query = select(User).order_by(User.id)
    if q:
        query = query.where(or_(User.full_name.ilike(f"%{q}%"), User.email.ilike(f"%{q}%")))
    return render(request, "users.html", user, users=db.scalars(query).all(), q=q)


@router.post("/users/{user_id}/update")
def update_user(user_id: int, request: Request, role: str = Form(...), is_active: bool = Form(False),
                user: User = Depends(current_staff), db: Session = Depends(get_db)):
    if user.role != "admin":
        flash(request, "Chỉ admin mới được phân quyền người dùng", "danger")
        return redirect("/admin/users/list")
    target = db.get(User, user_id)
    if target is None or target.id == user.id:
        flash(request, "Không thể tự thay đổi tài khoản của chính mình", "danger")
        return redirect("/admin/users/list")
    if role in ("customer", "staff", "admin"):
        target.role = role
    target.is_active = is_active
    db.commit()
    flash(request, f'Đã cập nhật "{target.full_name}"')
    return redirect("/admin/users/list")


# ===== Chat =====
@router.get("/chat/inbox")
def chat_page(request: Request, user: User = Depends(current_staff)):
    # Token JWT ngắn hạn để trang chat mở WebSocket / gọi API thay mặt nhân viên.
    return render(request, "chat.html", user, token=create_access_token(user))
