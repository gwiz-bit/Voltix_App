"""AI build PC theo ngân sách + mục đích.

Lớp 1 (luôn chạy): thuật toán duyệt mọi tổ hợp linh kiện tương thích còn hàng, chấm điểm theo
mục đích sử dụng và chọn các cấu hình tốt nhất trong ngân sách -> luôn đúng tương thích, không vượt tiền.
Lớp 2 (khi có ANTHROPIC_API_KEY): Claude đọc yêu cầu tự do của khách, chọn 1 trong các phương án
của lớp 1 và viết lời tư vấn tiếng Việt. Claude chỉ được chọn trong danh sách nên không bịa linh kiện.
"""

import itertools
import json
import logging
from dataclasses import dataclass

import anthropic
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import settings
from ..models import Category, Product

log = logging.getLogger(__name__)

PURPOSES = {
    "gaming": "Chơi game",
    "office": "Văn phòng - học tập",
    "design": "Đồ hoạ - dựng phim",
    "streaming": "Chơi game + livestream",
}

# Trọng số "đáng đầu tư" của từng loại linh kiện theo mục đích; tiền dồn vào loại có trọng số cao.
WEIGHTS = {
    "gaming": {"cpu": 1.5, "vga": 3.0, "ram": 1.0, "ssd": 0.8, "mainboard": 0.4, "psu": 0.3, "case": 0.2, "cooler": 0.2},
    "office": {"cpu": 2.0, "vga": 0.0, "ram": 1.5, "ssd": 1.5, "mainboard": 0.3, "psu": 0.2, "case": 0.2, "cooler": 0.1},
    "design": {"cpu": 2.5, "vga": 2.0, "ram": 2.0, "ssd": 1.5, "mainboard": 0.4, "psu": 0.3, "case": 0.2, "cooler": 0.3},
    "streaming": {"cpu": 2.5, "vga": 2.5, "ram": 1.5, "ssd": 1.0, "mainboard": 0.4, "psu": 0.3, "case": 0.2, "cooler": 0.3},
}

# Dung lượng RAM tối thiểu theo mục đích (dựng phim/livestream cần nhiều RAM).
MIN_RAM_GB = {"gaming": 16, "office": 8, "design": 32, "streaming": 32}

BASE_WATTAGE = 150  # mainboard, RAM, ổ cứng, quạt
PSU_HEADROOM = 1.2  # nguồn nên dư 20%
CLAUDE_MODEL = "claude-opus-5-5"


@dataclass
class Build:
    parts: dict[str, Product]  # slug -> product (không có "vga" nếu dùng card onboard)
    total: int
    score: float
    wattage: int


class BuildError(ValueError):
    pass


def _spec(p: Product | None, key: str, default=None):
    return (p.specs or {}).get(key, default) if p else default


def _candidates(db: Session) -> dict[str, list[Product]]:
    rows = db.execute(
        select(Product, Category.slug)
        .join(Category)
        .where(Product.is_active.is_(True), Product.stock > 0)
        .order_by(Product.price)
    ).all()
    by_slug: dict[str, list[Product]] = {}
    for product, slug in rows:
        by_slug.setdefault(slug, []).append(product)
    return by_slug


def search_builds(db: Session, budget: int, purpose: str, limit: int = 3) -> list[Build]:
    """Trả về tối đa `limit` cấu hình tốt nhất (khác nhau về CPU/VGA) trong ngân sách."""
    if purpose not in WEIGHTS:
        raise BuildError("Mục đích không hợp lệ")
    weights = WEIGHTS[purpose]
    c = _candidates(db)
    missing = [s for s in ("cpu", "mainboard", "ram", "ssd", "psu", "case") if not c.get(s)]
    if missing:
        raise BuildError(f"Cửa hàng đang hết hàng: {', '.join(missing)}")

    # Bộ khung CPU + mainboard + RAM tương thích (socket, chuẩn RAM).
    cores = [
        (cpu, mb, ram)
        for cpu in c["cpu"]
        for mb in c["mainboard"]
        if _spec(cpu, "socket") == _spec(mb, "socket")
        for ram in c["ram"]
        if _spec(ram, "ram_type") == _spec(mb, "ram_type")
        and int(_spec(ram, "capacity_gb", 0)) >= MIN_RAM_GB[purpose]
    ]
    vgas: list[Product | None] = [None, *c.get("vga", [])]
    coolers: list[Product | None] = [None, *c.get("cooler", [])]

    best: dict[tuple[int, int | None], Build] = {}
    cheapest_total = None
    for cpu, mb, ram in cores:
        core_price = cpu.final_price + mb.final_price + ram.final_price
        for vga in vgas:
            # Không có card rời thì CPU phải có đồ hoạ tích hợp; chơi game/stream bắt buộc card rời.
            if vga is None and (not _spec(cpu, "igpu", False) or purpose in ("gaming", "streaming")):
                continue
            wattage = BASE_WATTAGE + int(_spec(cpu, "tdp", 0)) + int(_spec(vga, "tdp", 0))
            psus = [p for p in c["psu"] if int(_spec(p, "wattage", 0)) >= wattage * PSU_HEADROOM]
            for ssd, psu, case, cooler in itertools.product(c["ssd"], psus, c["case"], coolers):
                # CPU từ 105W (dòng K/X/X3D) không kèm tản -> bắt buộc mua tản tương thích socket.
                if cooler is None and int(_spec(cpu, "tdp", 0)) >= 105:
                    continue
                if cooler is not None and _spec(cpu, "socket") not in _spec(cooler, "sockets", []):
                    continue
                parts = {"cpu": cpu, "mainboard": mb, "ram": ram, "ssd": ssd, "psu": psu, "case": case}
                if vga:
                    parts["vga"] = vga
                if cooler:
                    parts["cooler"] = cooler
                total = core_price + sum(p.final_price for k, p in parts.items() if k not in ("cpu", "mainboard", "ram"))
                cheapest_total = total if cheapest_total is None else min(cheapest_total, total)
                if total > budget:
                    continue
                score = sum(weights[k] * p.final_price for k, p in parts.items())
                key = (cpu.id, vga.id if vga else None)
                current = best.get(key)
                if current is None or (score, -total) > (current.score, -current.total):
                    best[key] = Build(parts, total, score, wattage)

    if not best:
        if cheapest_total is None:
            raise BuildError("Không tìm được tổ hợp linh kiện tương thích")
        raise BuildError(f"Ngân sách quá thấp cho mục đích này. Cấu hình rẻ nhất khoảng {cheapest_total:,}₫".replace(",", "."))
    return sorted(best.values(), key=lambda b: (b.score, -b.total), reverse=True)[:limit]


def _fmt(v: int) -> str:
    return f"{v:,}₫".replace(",", ".")


def template_advice(build: Build, budget: int, purpose: str) -> dict:
    """Lời tư vấn khi không dùng được Claude."""
    p = build.parts
    gpu = p.get("vga")
    lines = [
        f"Với ngân sách {_fmt(budget)} cho nhu cầu {PURPOSES[purpose].lower()}, "
        f"cấu hình dùng {p['cpu'].name}" + (f" kết hợp {gpu.name}." if gpu else " với đồ hoạ tích hợp (không cần card rời)."),
        f"Tổng {_fmt(build.total)}, còn dư {_fmt(budget - build.total)}.",
        f"Công suất ước tính {build.wattage}W, nguồn {p['psu'].name} đáp ứng thoải mái.",
    ]
    tips = ["Mọi linh kiện đã được kiểm tra tương thích socket và chuẩn RAM."]
    if budget - build.total > 1_000_000:
        tips.append("Có thể dùng phần tiền dư để nâng dung lượng SSD hoặc RAM.")
    return {"title": f"Cấu hình {PURPOSES[purpose]}", "explanation": " ".join(lines), "tips": tips}


_ADVICE_SCHEMA = {
    "type": "object",
    "properties": {
        "choice": {"type": "integer", "description": "Chỉ số (bắt đầu từ 0) của phương án được chọn"},
        "title": {"type": "string"},
        "explanation": {"type": "string"},
        "tips": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["choice", "title", "explanation", "tips"],
    "additionalProperties": False,
}

_SYSTEM = (
    "Bạn là chuyên viên tư vấn build PC của cửa hàng linh kiện Voltix. "
    "Bạn nhận các phương án cấu hình đã được hệ thống kiểm tra tương thích và nằm trong ngân sách. "
    "Hãy chọn đúng MỘT phương án phù hợp nhất với nhu cầu và ghi chú của khách, rồi giải thích bằng tiếng Việt, "
    "thân thiện, 3-5 câu, nêu lý do chọn CPU/VGA và hiệu năng mong đợi. Đưa 2-3 lời khuyên ngắn. "
    "Chỉ nhắc tới linh kiện có trong phương án; không bịa thêm sản phẩm, giá hay số FPS cụ thể."
)


def _describe(builds: list[Build]) -> list[dict]:
    return [
        {
            "index": i,
            "total": b.total,
            "estimated_wattage": b.wattage,
            "parts": {slug: {"name": p.name, "price": p.final_price, "specs": p.specs or {}} for slug, p in b.parts.items()},
        }
        for i, b in enumerate(builds)
    ]


def claude_advice(builds: list[Build], budget: int, purpose: str, notes: str | None) -> tuple[int, dict] | None:
    """Nhờ Claude chọn phương án + viết tư vấn. Trả về None nếu chưa cấu hình key hoặc gọi lỗi."""
    if not settings.anthropic_api_key:
        return None
    client = anthropic.Anthropic(api_key=settings.anthropic_api_key, timeout=45.0, max_retries=1)
    user = json.dumps(
        {"budget": budget, "purpose": PURPOSES[purpose], "customer_notes": notes or "", "options": _describe(builds)},
        ensure_ascii=False,
    )
    try:
        response = client.beta.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=4000,
            system=_SYSTEM,
            messages=[{"role": "user", "content": user}],
            # Tư vấn ngắn, cần phản hồi nhanh cho app -> effort thấp.
            output_config={"effort": "low", "format": {"type": "json_schema", "schema": _ADVICE_SCHEMA}},
            # Nếu bộ lọc an toàn từ chối, API tự chạy lại trên model dự phòng được Anthropic khuyến nghị.
            betas=["server-side-fallback-2026-07-01"],
            fallbacks="default",
        )
    except (anthropic.APIConnectionError, anthropic.APIStatusError) as e:
        log.warning("Claude advice failed: %s", e)
        return None
    if response.stop_reason in ("refusal", "max_tokens"):
        log.warning("Claude advice stopped: %s", response.stop_reason)
        return None
    text = next((b.text for b in response.content if b.type == "text"), None)
    try:
        data = json.loads(text or "")
    except json.JSONDecodeError:
        return None
    choice = data.get("choice")
    if not isinstance(choice, int) or not 0 <= choice < len(builds):
        choice = 0
    return choice, {"title": data["title"], "explanation": data["explanation"], "tips": data["tips"][:3]}
