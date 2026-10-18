"""Tạo database + bảng + dữ liệu mẫu cho Voltix.

Chạy:  python seed.py          (xoá dữ liệu cũ và tạo lại)
"""

import random
import sys
from datetime import datetime, timedelta
from urllib.parse import urlsplit

from sqlalchemy import create_engine, text

from app.config import settings
from app.database import Base, SessionLocal, engine
from app.models import (
    Address,
    Brand,
    Category,
    Conversation,
    Message,
    Order,
    OrderItem,
    Payment,
    Product,
    Review,
    User,
)
from app.security import hash_password

random.seed(393)

CATEGORIES = [
    ("CPU", "cpu"), ("Mainboard", "mainboard"), ("RAM", "ram"), ("Card đồ hoạ", "vga"),
    ("SSD", "ssd"), ("Nguồn", "psu"), ("Vỏ case", "case"), ("Tản nhiệt", "cooler"),
]

BRANDS = ["Intel", "AMD", "ASUS", "MSI", "GIGABYTE", "ASRock", "Kingston", "Corsair", "G.Skill",
          "Samsung", "WD", "Crucial", "Seasonic", "Cooler Master", "NZXT", "Lian Li", "Deepcool", "Noctua"]

# (danh mục, thương hiệu, tên, giá, giá KM, tồn kho, specs, mô tả)
PRODUCTS = [
    ("cpu", "Intel", "Intel Core i3-14100F", 2590000, None, 30, {"igpu": False, "socket": "LGA1700", "cores": 4, "threads": 8, "tdp": 58}, "4 nhân 8 luồng, xung tối đa 4.7GHz, lựa chọn tiết kiệm cho PC văn phòng và gaming nhẹ."),
    ("cpu", "Intel", "Intel Core i5-14400F", 4290000, 3990000, 25, {"igpu": False, "socket": "LGA1700", "cores": 10, "threads": 16, "tdp": 65}, "10 nhân 16 luồng, xung tối đa 4.7GHz. CPU gaming quốc dân phân khúc tầm trung."),
    ("cpu", "Intel", "Intel Core i7-14700K", 9890000, 9490000, 10, {"igpu": True, "socket": "LGA1700", "cores": 20, "threads": 28, "tdp": 125}, "20 nhân 28 luồng, xung 5.6GHz, mở khoá ép xung, mạnh cho cả game và đồ hoạ."),
    ("cpu", "Intel", "Intel Core i9-14900K", 14490000, None, 4, {"igpu": True, "socket": "LGA1700", "cores": 24, "threads": 32, "tdp": 125}, "24 nhân 32 luồng, xung tối đa 6.0GHz – CPU desktop mạnh nhất của Intel thế hệ 14."),
    ("cpu", "AMD", "AMD Ryzen 5 7600", 5190000, None, 18, {"igpu": True, "socket": "AM5", "cores": 6, "threads": 12, "tdp": 65}, "6 nhân 12 luồng, kiến trúc Zen 4, hỗ trợ DDR5 và PCIe 5.0."),
    ("cpu", "AMD", "AMD Ryzen 7 7700X", 7690000, 7290000, 12, {"igpu": True, "socket": "AM5", "cores": 8, "threads": 16, "tdp": 105}, "8 nhân 16 luồng, xung 5.4GHz, hiệu năng đơn nhân rất mạnh."),
    ("cpu", "AMD", "AMD Ryzen 7 7800X3D", 10990000, 10490000, 7, {"igpu": True, "socket": "AM5", "cores": 8, "threads": 16, "tdp": 120}, "8 nhân 16 luồng với 3D V-Cache 96MB – CPU chơi game hàng đầu."),
    ("cpu", "AMD", "AMD Ryzen 5 5600", 2790000, 2590000, 22, {"igpu": False, "socket": "AM4", "cores": 6, "threads": 12, "tdp": 65}, "6 nhân 12 luồng, nền tảng AM4 giá tốt, dùng RAM DDR4."),

    ("mainboard", "ASUS", "ASUS PRIME B760M-A WIFI D4", 3490000, None, 12, {"socket": "LGA1700", "ram_type": "DDR4", "form": "mATX"}, "Chipset B760, hỗ trợ DDR4, WiFi 6, 2 khe M.2."),
    ("mainboard", "MSI", "MSI PRO B760M-P DDR5", 2890000, 2690000, 15, {"socket": "LGA1700", "ram_type": "DDR5", "form": "mATX"}, "Chipset B760, DDR5, thiết kế tối giản, giá tốt."),
    ("mainboard", "GIGABYTE", "GIGABYTE Z790 AORUS ELITE AX", 6990000, None, 6, {"socket": "LGA1700", "ram_type": "DDR5", "form": "ATX"}, "Chipset Z790 cho CPU K, VRM 16+1+2 pha, WiFi 6E, PCIe 5.0."),
    ("mainboard", "MSI", "MSI B650M GAMING PLUS WIFI", 4190000, None, 9, {"socket": "AM5", "ram_type": "DDR5", "form": "mATX"}, "Chipset B650 cho Ryzen 7000, DDR5, WiFi 6E."),
    ("mainboard", "ASUS", "ASUS TUF GAMING B650-PLUS WIFI", 5290000, 4990000, 8, {"socket": "AM5", "ram_type": "DDR5", "form": "ATX"}, "Độ bền chuẩn quân đội, VRM 12+2 pha, 3 khe M.2."),
    ("mainboard", "ASRock", "ASRock B550M Pro4", 2290000, None, 14, {"socket": "AM4", "ram_type": "DDR4", "form": "mATX"}, "Chipset B550 cho Ryzen AM4, PCIe 4.0, 2 khe M.2."),

    ("ram", "Kingston", "Kingston Fury Beast 16GB (2x8GB) DDR4 3200", 1090000, None, 40, {"ram_type": "DDR4", "capacity_gb": 16, "speed": 3200}, "Kit RAM 16GB bus 3200MHz, tản nhiệt nhôm."),
    ("ram", "Corsair", "Corsair Vengeance LPX 32GB (2x16GB) DDR4 3200", 1890000, 1790000, 25, {"ram_type": "DDR4", "capacity_gb": 32, "speed": 3200}, "Kit 32GB DDR4 cấu hình thấp, tương thích tốt."),
    ("ram", "Corsair", "Corsair Vengeance 32GB (2x16GB) DDR5 6000", 2890000, 2690000, 22, {"ram_type": "DDR5", "capacity_gb": 32, "speed": 6000}, "Kit DDR5 32GB, hỗ trợ Intel XMP 3.0 và AMD EXPO."),
    ("ram", "G.Skill", "G.Skill Trident Z5 RGB 32GB (2x16GB) DDR5 6400", 3590000, None, 10, {"ram_type": "DDR5", "capacity_gb": 32, "speed": 6400}, "RAM DDR5 cao cấp, LED RGB, bus 6400MHz."),
    ("ram", "Kingston", "Kingston Fury Beast 16GB (2x8GB) DDR5 5600", 1590000, None, 30, {"ram_type": "DDR5", "capacity_gb": 16, "speed": 5600}, "Kit DDR5 16GB giá tốt cho PC đời mới."),
    ("ram", "G.Skill", "G.Skill Ripjaws V 16GB (2x8GB) DDR4 3600", 1190000, 1090000, 3, {"ram_type": "DDR4", "capacity_gb": 16, "speed": 3600}, "Bus 3600MHz, tối ưu cho Ryzen AM4."),

    ("vga", "GIGABYTE", "GIGABYTE RTX 4060 WINDFORCE OC 8GB", 7990000, 7590000, 15, {"vram_gb": 8, "tdp": 115}, "RTX 4060, DLSS 3, chơi tốt Full HD."),
    ("vga", "ASUS", "ASUS Dual RTX 4060 Ti 8GB", 10490000, None, 9, {"vram_gb": 8, "tdp": 160}, "RTX 4060 Ti, tản 2 quạt Axial-tech, chơi tốt 1080p/1440p."),
    ("vga", "MSI", "MSI RTX 4070 SUPER VENTUS 2X 12GB", 16990000, 16490000, 6, {"vram_gb": 12, "tdp": 220}, "RTX 4070 SUPER 12GB, chơi mượt 2K max setting."),
    ("vga", "ASUS", "ASUS TUF RTX 4080 SUPER 16GB", 30990000, None, 3, {"vram_gb": 16, "tdp": 320}, "RTX 4080 SUPER, chơi 4K, tản nhiệt TUF siêu bền."),
    ("vga", "GIGABYTE", "GIGABYTE Radeon RX 7600 GAMING OC 8GB", 6890000, 6490000, 11, {"vram_gb": 8, "tdp": 165}, "RX 7600, hiệu năng/giá tốt cho game Full HD."),
    ("vga", "ASRock", "ASRock Radeon RX 7800 XT Challenger 16GB", 13990000, None, 5, {"vram_gb": 16, "tdp": 263}, "RX 7800 XT 16GB VRAM, mạnh ở độ phân giải 2K."),

    ("ssd", "Samsung", "Samsung 990 EVO 1TB NVMe", 2190000, None, 30, {"capacity_gb": 1000, "interface": "PCIe 4.0"}, "Đọc 5000MB/s, ghi 4200MB/s."),
    ("ssd", "Samsung", "Samsung 990 PRO 2TB NVMe", 4990000, 4690000, 12, {"capacity_gb": 2000, "interface": "PCIe 4.0"}, "Đọc 7450MB/s, SSD PCIe 4.0 hàng đầu."),
    ("ssd", "WD", "WD Black SN770 1TB NVMe", 1890000, 1690000, 20, {"capacity_gb": 1000, "interface": "PCIe 4.0"}, "Đọc 5150MB/s, tối ưu cho game."),
    ("ssd", "Kingston", "Kingston NV2 500GB NVMe", 890000, None, 45, {"capacity_gb": 500, "interface": "PCIe 4.0"}, "SSD NVMe giá rẻ, đọc 3500MB/s."),
    ("ssd", "Crucial", "Crucial P3 Plus 1TB NVMe", 1690000, None, 2, {"capacity_gb": 1000, "interface": "PCIe 4.0"}, "Đọc 5000MB/s, bảo hành 5 năm."),

    ("psu", "Corsair", "Corsair CV550 550W 80 Plus Bronze", 1290000, None, 20, {"wattage": 550}, "Nguồn 550W, đủ cho cấu hình tầm trung."),
    ("psu", "Cooler Master", "Cooler Master MWE 650 Bronze V2", 1490000, 1390000, 18, {"wattage": 650}, "Nguồn 650W 80 Plus Bronze, quạt 120mm êm."),
    ("psu", "Corsair", "Corsair RM750e 750W 80 Plus Gold", 2590000, None, 14, {"wattage": 750}, "Full modular, ATX 3.0, hỗ trợ cáp 12VHPWR."),
    ("psu", "Seasonic", "Seasonic FOCUS GX-850 850W Gold", 3290000, 3090000, 8, {"wattage": 850}, "Full modular, bảo hành 10 năm."),
    ("psu", "MSI", "MSI MPG A1000G PCIE5 1000W Gold", 4290000, None, 5, {"wattage": 1000}, "1000W, ATX 3.0, dành cho cấu hình cao cấp."),

    ("case", "NZXT", "NZXT H5 Flow", 2290000, None, 10, {"form": "ATX"}, "Mid-tower, mặt lưới thông gió tốt, kèm 2 quạt."),
    ("case", "Lian Li", "Lian Li LANCOOL 216", 2490000, 2290000, 8, {"form": "ATX"}, "Kèm 2 quạt 160mm phía trước, luồng gió cực tốt."),
    ("case", "Cooler Master", "Cooler Master MasterBox Q300L", 990000, None, 25, {"form": "mATX"}, "Case nhỏ gọn mATX, giá rẻ."),
    ("case", "Corsair", "Corsair 4000D Airflow", 2390000, None, 0, {"form": "ATX"}, "Case bán chạy nhất của Corsair, đi dây gọn gàng."),
    ("case", "Deepcool", "Deepcool CH560 Digital", 2190000, 1990000, 7, {"form": "ATX"}, "Màn hình hiển thị nhiệt độ, kèm 4 quạt ARGB."),

    ("cooler", "Deepcool", "Deepcool AK400", 690000, None, 35, {"type": "air", "sockets": ["LGA1700", "AM5", "AM4"]}, "Tản khí 4 ống đồng, tản tốt CPU 220W."),
    ("cooler", "Noctua", "Noctua NH-D15", 2690000, None, 6, {"type": "air", "sockets": ["LGA1700", "AM5", "AM4"]}, "Tản khí tháp đôi huyền thoại, cực êm."),
    ("cooler", "Cooler Master", "Cooler Master Hyper 212 Black", 590000, 490000, 28, {"type": "air", "sockets": ["LGA1700", "AM4"]}, "Tản khí phổ thông, dễ lắp."),
    ("cooler", "NZXT", "NZXT Kraken 240", 2990000, 2790000, 9, {"type": "aio", "sockets": ["LGA1700", "AM5", "AM4"]}, "Tản nước AIO 240mm, màn hình LCD trên block."),
    ("cooler", "Corsair", "Corsair iCUE H150i ELITE 360", 4590000, None, 4, {"type": "aio", "sockets": ["LGA1700", "AM5", "AM4"]}, "Tản nước 360mm, 3 quạt RGB, cho CPU cao cấp."),
]


def image_url(slug: str, brand: str, name: str, specs: dict) -> str:
    """Ảnh thật theo loại linh kiện / hãng (tải bằng tools/fetch_images.py, nguồn trong docs/IMAGE_CREDITS.md).

    Đường dẫn tương đối: app tự ghép với địa chỉ server nên đổi server không cần sửa DB.
    """
    if slug == "cpu":
        key = "cpu-intel" if brand == "Intel" else "cpu-amd"
    elif slug == "vga":
        key = "vga-amd" if "Radeon" in name else ("vga-gigabyte" if brand == "GIGABYTE" else "vga-nvidia")
    elif slug == "case":
        key = "case-corsair" if "4000D" in name else "case"
    elif slug == "cooler":
        key = "cooler-aio" if specs.get("type") == "aio" else "cooler-air"
    else:
        key = slug
    return f"/static/products/{key}.jpg"


def create_database():
    url = urlsplit(settings.database_url)
    db_name = url.path.lstrip("/")
    server_url = settings.database_url.replace(f"/{db_name}", "/", 1)
    with create_engine(server_url).connect() as conn:
        conn.execute(text(f"CREATE DATABASE IF NOT EXISTS `{db_name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"))


def main():
    sys.stdout.reconfigure(encoding="utf-8")  # console Windows mặc định cp1252
    create_database()
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    db = SessionLocal()

    cats = {slug: Category(name=name, slug=slug) for name, slug in CATEGORIES}
    brands = {name: Brand(name=name) for name in BRANDS}
    db.add_all([*cats.values(), *brands.values()])
    db.flush()

    products = []
    for i, (slug, brand, name, price, sale, stock, specs, desc) in enumerate(PRODUCTS):
        p = Product(
            category_id=cats[slug].id, brand_id=brands[brand].id, name=name, description=desc,
            price=price, sale_price=sale, stock=stock, image_url=image_url(slug, brand, name, specs), specs=specs,
            created_at=datetime.now() - timedelta(days=len(PRODUCTS) - i),
        )
        products.append(p)
    db.add_all(products)

    pw = hash_password("123456")
    admin = User(full_name="Quản trị viên", email="admin@voltix.vn", phone="0900000001", password_hash=pw, role="admin")
    staff = User(full_name="Nhân viên tư vấn", email="staff@voltix.vn", phone="0900000002", password_hash=pw, role="staff")
    customers = [
        User(full_name="Nguyễn Văn A", email="customer@voltix.vn", phone="0901234567", password_hash=pw),
        User(full_name="Trần Thị B", email="tranthib@gmail.com", phone="0912345678", password_hash=pw),
        User(full_name="Lê Minh C", email="leminhc@gmail.com", phone="0923456789", password_hash=pw),
        User(full_name="Phạm Quốc D", email="phamquocd@gmail.com", phone="0934567890", password_hash=pw),
    ]
    db.add_all([admin, staff, *customers])
    db.flush()

    addresses = ["12 Nguyễn Huệ, Q.1, TP.HCM", "45 Trần Duy Hưng, Cầu Giấy, Hà Nội",
                 "8 Lê Duẩn, Hải Châu, Đà Nẵng", "102 Hùng Vương, Ninh Kiều, Cần Thơ"]
    for c, addr in zip(customers, addresses):
        db.add(Address(user_id=c.id, receiver=c.full_name, phone=c.phone, detail=addr, is_default=True))

    # Đơn hàng rải trong 60 ngày qua để biểu đồ thống kê có dữ liệu.
    in_stock = [p for p in products if p.stock > 0]
    statuses = ["completed"] * 6 + ["shipping", "confirmed", "paid", "pending", "cancelled"]
    for n in range(45):
        customer = random.choice(customers)
        created = datetime.now() - timedelta(days=random.randint(0, 59), hours=random.randint(0, 12))
        status = statuses[n % len(statuses)] if n >= 5 else "completed"
        method = random.choice(["COD", "VNPAY"])
        order = Order(
            user_id=customer.id, receiver=customer.full_name, phone=customer.phone,
            shipping_address=addresses[customers.index(customer)], payment_method=method,
            status=status, total=0, created_at=created, updated_at=created,
        )
        for p in random.sample(in_stock, random.randint(1, 3)):
            order.items.append(OrderItem(product_id=p.id, quantity=random.randint(1, 2), unit_price=p.final_price))
        order.total = sum(i.unit_price * i.quantity for i in order.items)
        db.add(order)
        db.flush()
        if method == "VNPAY" and status not in ("pending", "cancelled"):
            db.add(Payment(order_id=order.id, txn_ref=f"{order.id}-seed", amount=order.total,
                           status="success", response_code="00", paid_at=created))

    # Đánh giá cho các sản phẩm đã mua (đơn hoàn thành).
    comments = {5: "Hàng chính hãng, đóng gói cẩn thận, giao nhanh!", 4: "Sản phẩm tốt, đúng mô tả.",
                3: "Ổn trong tầm giá."}
    db.flush()
    seen = set()
    for order in db.query(Order).filter(Order.status == "completed").all():
        for item in order.items:
            key = (order.user_id, item.product_id)
            if key in seen:
                continue
            seen.add(key)
            rating = random.choice([5, 5, 4, 4, 3])
            db.add(Review(user_id=order.user_id, product_id=item.product_id, rating=rating, comment=comments[rating]))

    # Một cuộc trò chuyện mẫu.
    conv = Conversation(customer_id=customers[0].id, staff_id=staff.id)
    db.add(conv)
    db.flush()
    for sender, content in [
        (customers[0], "Chào shop, mình muốn build PC chơi game tầm 25 triệu thì nên chọn VGA nào ạ?"),
        (staff, "Chào bạn! Tầm 25 triệu bạn nên chọn RTX 4060 Ti hoặc RX 7800 XT nếu ưu tiên 2K ạ."),
        (customers[0], "Vậy CPU đi kèm nên là i5-14400F hay Ryzen 5 7600 ạ?"),
    ]:
        db.add(Message(conversation_id=conv.id, sender_id=sender.id, content=content, is_read=sender is staff))

    db.commit()
    db.close()
    print(f"Seed xong: {len(products)} sản phẩm, {len(customers)} khách hàng, 45 đơn hàng.")
    print("Tài khoản (mật khẩu 123456): admin@voltix.vn | staff@voltix.vn | customer@voltix.vn")


if __name__ == "__main__":
    main()
