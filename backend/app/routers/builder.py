"""PC Builder: lọc linh kiện tương thích và lưu cấu hình."""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Category, PcBuild, PcBuildItem, Product, User
from ..schemas import AiBuildIn, AiBuildOut, BuildIn, BuildOut, ProductOut
from ..security import get_current_user
from ..serializers import products_dicts
from ..services import ai_builder

router = APIRouter(tags=["PC Builder"])

# Công suất dự phòng cho mainboard, RAM, ổ cứng, quạt... (W)
BASE_WATTAGE = 150


def estimated_wattage(selected: list[Product]) -> int:
    return BASE_WATTAGE + sum(int((p.specs or {}).get("tdp", 0)) for p in selected)


def is_compatible(candidate: Product, slug: str, selected: list[Product]) -> bool:
    """Kiểm tra `candidate` (thuộc danh mục `slug`) với các linh kiện đã chọn ở danh mục khác."""
    spec = candidate.specs or {}
    by_slug = {p.category.slug: (p.specs or {}) for p in selected if p.category.slug != slug}
    cpu, board, ram = by_slug.get("cpu"), by_slug.get("mainboard"), by_slug.get("ram")

    if slug == "cpu" and board:
        return spec.get("socket") == board.get("socket")
    if slug == "mainboard":
        if cpu and spec.get("socket") != cpu.get("socket"):
            return False
        if ram and spec.get("ram_type") != ram.get("ram_type"):
            return False
    if slug == "ram" and board:
        return spec.get("ram_type") == board.get("ram_type")
    if slug == "cooler" and cpu:
        return cpu.get("socket") in spec.get("sockets", [])
    if slug == "psu":
        others = [p for p in selected if p.category.slug != "psu"]
        return int(spec.get("wattage", 0)) >= estimated_wattage(others)
    return True


@router.get("/builder/compatible", response_model=list[ProductOut])
def compatible_products(
    category: str = Query(description="slug danh mục: cpu, mainboard, ram, vga, ssd, psu, case, cooler"),
    selected: str = Query(default="", description="id các sản phẩm đã chọn, cách nhau bởi dấu phẩy"),
    db: Session = Depends(get_db),
):
    cat = db.scalar(select(Category).where(Category.slug == category))
    if cat is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy danh mục")
    ids = [int(x) for x in selected.split(",") if x.strip().isdigit()]
    chosen = db.scalars(select(Product).where(Product.id.in_(ids))).unique().all() if ids else []
    candidates = db.scalars(
        select(Product)
        .where(Product.category_id == cat.id, Product.is_active.is_(True), Product.stock > 0)
        .order_by(Product.price)
    ).unique().all()
    return products_dicts(db, [p for p in candidates if is_compatible(p, category, chosen)])


SLOT_ORDER = ["cpu", "mainboard", "ram", "vga", "ssd", "psu", "case", "cooler"]


@router.post("/builder/ai-suggest", response_model=AiBuildOut)
def ai_suggest(data: AiBuildIn, db: Session = Depends(get_db)):
    """AI gợi ý cấu hình hoàn chỉnh theo ngân sách + mục đích."""
    try:
        builds = ai_builder.search_builds(db, data.budget, data.purpose)
    except ai_builder.BuildError as e:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, str(e))
    ai = ai_builder.claude_advice(builds, data.budget, data.purpose, data.notes)
    choice, advice = ai if ai else (0, ai_builder.template_advice(builds[0], data.budget, data.purpose))
    build = builds[choice]
    products = [build.parts[s] for s in SLOT_ORDER if s in build.parts]
    return {
        "ai_powered": ai is not None,
        **advice,
        "total": build.total,
        "estimated_wattage": build.wattage,
        "products": products_dicts(db, products),
    }


def _build_dict(db: Session, build: PcBuild) -> dict:
    products = [i.product for i in build.items]
    return {
        "id": build.id,
        "name": build.name,
        "created_at": build.created_at,
        "total": sum(p.final_price * i.quantity for p, i in zip(products, build.items)),
        "products": products_dicts(db, products),
    }


@router.get("/builds", response_model=list[BuildOut])
def my_builds(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    builds = db.scalars(select(PcBuild).where(PcBuild.user_id == user.id).order_by(PcBuild.id.desc())).all()
    return [_build_dict(db, b) for b in builds]


@router.post("/builds", response_model=BuildOut, status_code=status.HTTP_201_CREATED)
def save_build(data: BuildIn, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    ids = list(dict.fromkeys(data.product_ids))
    found = db.scalars(select(Product.id).where(Product.id.in_(ids))).all()
    if len(found) != len(ids):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Có sản phẩm không tồn tại")
    build = PcBuild(user_id=user.id, name=data.name.strip(), items=[PcBuildItem(product_id=i) for i in ids])
    db.add(build)
    db.commit()
    db.refresh(build)
    return _build_dict(db, build)


@router.delete("/builds/{build_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_build(build_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    build = db.get(PcBuild, build_id)
    if build is None or build.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy cấu hình")
    db.delete(build)
    db.commit()
