"""Tải ảnh linh kiện (giấy phép tự do) từ Wikimedia Commons về app/static/products.

Chạy (từ thư mục backend):  python tools/fetch_images.py
Kết quả: ảnh vuông 800x800 nền trắng + file docs/IMAGE_CREDITS.md ghi nguồn/giấy phép.
"""

import html
import io
import json
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

from PIL import Image

sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "app" / "static" / "products"
CREDITS = ROOT.parent / "docs" / "IMAGE_CREDITS.md"
API = "https://commons.wikimedia.org/w/api.php"
UA = {"User-Agent": "VoltixStudentProject/1.0 (PRM393 coursework)"}

# key ảnh -> tên file trên Wikimedia Commons
IMAGES = {
    "cpu-intel": "File:Intel Core i7 13700K.jpg",
    "cpu-amd": "File:AMD Ryzen 9 7900X.jpg",
    "mainboard": "File:2023 Płyta główna Asus ROG STRIX Z690-A GAMING WIFI.jpg",
    "ram": "File:2*8Go DDR4 Corsair - 2018-05-08.jpg",
    "vga-gigabyte": "File:Gigabyte GeForce RTX 3090 Eagle OC 24G, 24576 MiB GDDR6X Front 20201114 DSC5880.jpg",
    "vga-nvidia": "File:MSI GeForce RTX 3070 VENTUS 3X OC.jpg",
    "vga-amd": "File:Sapphire AMD Radeon RX 7900 XTX.jpg",
    "ssd": "File:1TB 2280 NVME SSD.jpg",
    "psu": "File:Full modular ATX power supply unit.jpg",
    "case": "File:PC-Gehäuse Kolink Observatory RGB Midi-Tower 20201120 DSC6134.jpg",
    "case-corsair": "File:Corsair 4000D Airflow mid-tower ATX case.tif",
    "cooler-air": "File:Cooler Master Hyper 212 EVO - CPU Cooler with 120mm PWM Fan (RR-212E-20PK-R2).jpg",
    "cooler-aio": "File:Corsair H100i 240mm CPU cooler. On MSI Z590 Torpedo motherboard. (51987363353).jpg",
}


def fetch(url: str) -> bytes:
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
        return r.read()


def strip_tags(value: str) -> str:
    return html.unescape(re.sub(r"<[^>]+>", "", value or "")).strip()


def square(img: Image.Image, size: int = 800) -> Image.Image:
    """Thu nhỏ giữ tỉ lệ, đặt giữa khung vuông nền trắng."""
    img = img.convert("RGB")
    img.thumbnail((size - 40, size - 40), Image.LANCZOS)
    canvas = Image.new("RGB", (size, size), (255, 255, 255))
    canvas.paste(img, ((size - img.width) // 2, (size - img.height) // 2))
    return canvas


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    params = {
        "action": "query", "titles": "|".join(IMAGES.values()), "prop": "imageinfo",
        "iiprop": "url|extmetadata", "iiurlwidth": 1000, "format": "json",
    }
    data = json.loads(fetch(API + "?" + urllib.parse.urlencode(params)))
    pages = {p["title"]: p for p in data["query"]["pages"].values()}
    # API chuẩn hoá tên file (vd. dấu cách / gạch dưới) -> tra theo bảng normalized.
    normalized = {n["from"]: n["to"] for n in data["query"].get("normalized", [])}

    credits = [
        "# Nguồn ảnh linh kiện",
        "",
        "Ảnh minh hoạ sản phẩm lấy từ Wikimedia Commons theo giấy phép tự do ghi bên dưới.",
        "Ảnh đã được thu nhỏ và đặt trên nền trắng.",
        "",
        "| Ảnh | Tác giả | Giấy phép | Nguồn |",
        "|---|---|---|---|",
    ]
    for key, title in IMAGES.items():
        page = pages[normalized.get(title, title)]
        info = page["imageinfo"][0]
        meta = info.get("extmetadata", {})
        img = Image.open(io.BytesIO(fetch(info["thumburl"])))
        square(img).save(OUT / f"{key}.jpg", "JPEG", quality=85, optimize=True)
        author = strip_tags(meta.get("Artist", {}).get("value", "Không rõ"))
        license_ = strip_tags(meta.get("LicenseShortName", {}).get("value", "?"))
        credits.append(f"| `{key}.jpg` | {author} | {license_} | [{page['title']}]({info['descriptionurl']}) |")
        print(f"OK {key}.jpg  ({license_})")

    CREDITS.write_text("\n".join(credits) + "\n", encoding="utf-8")
    print(f"Ghi nguồn ảnh: {CREDITS}")


if __name__ == "__main__":
    main()
