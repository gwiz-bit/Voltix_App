"""Pydantic schemas: kiểm tra dữ liệu vào và định dạng JSON trả về."""

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field

PHONE_PATTERN = r"^0\d{9}$"


class ORM(BaseModel):
    model_config = ConfigDict(from_attributes=True)


# ===== Auth / User =====
class UserOut(ORM):
    id: int
    full_name: str
    email: str
    phone: str | None
    role: str
    avatar_url: str | None
    created_at: datetime


class RegisterIn(BaseModel):
    full_name: str = Field(min_length=2, max_length=100)
    email: EmailStr
    phone: str = Field(pattern=PHONE_PATTERN)
    password: str = Field(min_length=6, max_length=100)


class LoginIn(BaseModel):
    email: EmailStr
    password: str


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class UpdateProfileIn(BaseModel):
    full_name: str = Field(min_length=2, max_length=100)
    phone: str = Field(pattern=PHONE_PATTERN)


class ChangePasswordIn(BaseModel):
    old_password: str
    new_password: str = Field(min_length=6, max_length=100)


class AddressIn(BaseModel):
    receiver: str = Field(min_length=2, max_length=100)
    phone: str = Field(pattern=PHONE_PATTERN)
    detail: str = Field(min_length=5, max_length=255)
    is_default: bool = False


class AddressOut(ORM):
    id: int
    receiver: str
    phone: str
    detail: str
    is_default: bool


# ===== Catalog =====
class CategoryIn(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    slug: str = Field(min_length=1, max_length=50, pattern=r"^[a-z0-9-]+$")


class CategoryOut(ORM):
    id: int
    name: str
    slug: str


class BrandIn(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    logo_url: str | None = None


class BrandOut(ORM):
    id: int
    name: str
    logo_url: str | None


class ProductIn(BaseModel):
    category_id: int
    brand_id: int
    name: str = Field(min_length=2, max_length=200)
    description: str | None = None
    price: int = Field(ge=0)
    sale_price: int | None = Field(default=None, ge=0)
    stock: int = Field(ge=0)
    image_url: str | None = None
    specs: dict | None = None
    is_active: bool = True


class ProductOut(ORM):
    id: int
    category_id: int
    category_name: str
    brand_id: int
    brand_name: str
    name: str
    description: str | None
    price: int
    sale_price: int | None
    stock: int
    image_url: str | None
    specs: dict | None
    is_active: bool
    avg_rating: float = 0
    review_count: int = 0


class ProductPage(BaseModel):
    items: list[ProductOut]
    total: int
    page: int
    size: int


# ===== Cart =====
class CartItemIn(BaseModel):
    product_id: int
    quantity: int = Field(default=1, ge=1, le=99)


class CartQuantityIn(BaseModel):
    quantity: int = Field(ge=1, le=99)


class CartItemOut(ORM):
    id: int
    quantity: int
    product: ProductOut


class CartOut(BaseModel):
    items: list[CartItemOut]
    total: int
    count: int


# ===== Orders =====
class OrderCreateIn(BaseModel):
    receiver: str = Field(min_length=2, max_length=100)
    phone: str = Field(pattern=PHONE_PATTERN)
    shipping_address: str = Field(min_length=5, max_length=255)
    note: str | None = Field(default=None, max_length=255)
    payment_method: Literal["COD", "VNPAY"]


class OrderItemOut(ORM):
    product_id: int
    product_name: str
    image_url: str | None
    quantity: int
    unit_price: int


class OrderOut(ORM):
    id: int
    user_id: int
    customer_name: str
    receiver: str
    phone: str
    shipping_address: str
    note: str | None
    total: int
    status: str
    payment_method: str
    created_at: datetime
    updated_at: datetime
    items: list[OrderItemOut]


class OrderStatusIn(BaseModel):
    status: Literal["pending", "paid", "confirmed", "shipping", "completed", "cancelled"]


# ===== Payment =====
class VnpayCreateIn(BaseModel):
    order_id: int


class VnpayCreateOut(BaseModel):
    payment_url: str


# ===== Reviews =====
class ReviewIn(BaseModel):
    rating: int = Field(ge=1, le=5)
    comment: str | None = Field(default=None, max_length=1000)


class ReviewOut(BaseModel):
    id: int
    user_name: str
    rating: int
    comment: str | None
    created_at: datetime


# ===== Chat =====
class MessageIn(BaseModel):
    content: str = Field(min_length=1, max_length=2000)


class MessageOut(BaseModel):
    id: int
    conversation_id: int
    sender_id: int
    sender_name: str
    sender_role: str
    content: str
    created_at: datetime


class ConversationOut(BaseModel):
    id: int
    customer_id: int
    customer_name: str
    last_message: str | None
    unread: int
    updated_at: datetime


# ===== PC Builder =====
class BuildIn(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    product_ids: list[int] = Field(min_length=1)


class BuildOut(BaseModel):
    id: int
    name: str
    total: int
    created_at: datetime
    products: list[ProductOut]
