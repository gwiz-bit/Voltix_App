# Voltix – Ứng dụng mua bán linh kiện máy tính

**Power Your Next Level.**

> Đề tài PRM393 (Flutter Mobile Programming): **Ứng dụng mua bán linh kiện máy tính trực tuyến, hỗ trợ build PC, thanh toán VNPay và chat tư vấn, dành cho người dùng cá nhân và cửa hàng linh kiện.**

## Mô tả

Voltix giúp người dùng tìm và mua linh kiện máy tính (CPU, mainboard, RAM, VGA, SSD, nguồn, case, tản nhiệt) ngay trên điện thoại, tự build cấu hình PC với kiểm tra tương thích, thanh toán online qua VNPay và chat trực tiếp với nhân viên cửa hàng để được tư vấn. Cửa hàng quản lý sản phẩm, đơn hàng và xem báo cáo doanh thu qua web admin hoặc ngay trong app.

### Đối tượng sử dụng
| Vai trò | Nền tảng | Chức năng |
|---|---|---|
| Khách hàng | App Flutter | Đăng ký/đăng nhập, tìm kiếm & lọc sản phẩm, giỏ hàng, đặt hàng, thanh toán VNPay/COD, theo dõi đơn, đánh giá, PC Builder, chat tư vấn |
| Nhân viên / Admin | Web admin + App | CRUD sản phẩm/danh mục/thương hiệu, xử lý đơn hàng, trả lời chat, báo cáo thống kê, phân quyền người dùng (admin) |

## Chức năng
- [x] Đăng ký / đăng nhập (JWT), tự đăng nhập lại bằng token lưu trong SharedPreferences, tự đăng xuất khi token hết hạn
- [x] Trang chủ: danh mục, sản phẩm bán chạy, hàng mới, tìm kiếm
- [x] Danh sách sản phẩm: lọc theo danh mục/thương hiệu, sắp xếp (mới nhất, bán chạy, giá), cuộn để tải thêm
- [x] Chi tiết sản phẩm: giá khuyến mãi, tồn kho, thông số kỹ thuật, đánh giá
- [x] Giỏ hàng lưu trên server, kiểm tra tồn kho
- [x] Đặt hàng (trừ tồn kho trong transaction, khoá dòng chống bán vượt), lịch sử & chi tiết đơn, huỷ đơn (hoàn tồn kho)
- [x] Thanh toán online VNPay (sandbox) qua WebView, kiểm tra chữ ký HMAC-SHA512, IPN
- [x] Đánh giá sản phẩm (chỉ khi đơn đã hoàn thành)
- [x] PC Builder: lọc linh kiện tương thích (socket CPU–mainboard, chuẩn RAM, socket tản nhiệt, công suất nguồn), lưu cấu hình, thêm cả bộ vào giỏ
- [x] **Bộ PC ảo**: hình thùng máy nhìn qua kính hông, linh kiện đã chọn sáng lên, quạt quay; chạm vào từng khe để chọn linh kiện
- [x] **AI build PC**: nhập ngân sách + nhu cầu (game / văn phòng / đồ hoạ / livestream) + yêu cầu tự do → gợi ý cấu hình hoàn chỉnh, tương thích, trong ngân sách, kèm lời tư vấn
- [x] Ảnh thật cho từng loại linh kiện (nguồn & giấy phép: [docs/IMAGE_CREDITS.md](docs/IMAGE_CREDITS.md))
- [x] Chat realtime khách hàng ↔ nhân viên (WebSocket), có REST dự phòng và tự kết nối lại
- [x] Sổ địa chỉ, sửa hồ sơ, đổi mật khẩu
- [x] Báo cáo thống kê: doanh thu theo ngày/tháng/danh mục, đơn theo trạng thái, top bán chạy, sắp hết hàng (web admin + app)
- [x] Web admin: CRUD sản phẩm/danh mục/thương hiệu, xử lý đơn, quản lý người dùng, chat

## Công nghệ sử dụng
| Thành phần | Công nghệ |
|---|---|
| Mobile | Flutter 3 + Dart 3, Provider (state), go_router (navigation), dio (REST), web_socket_channel, webview_flutter (VNPay), fl_chart, shared_preferences, cached_network_image |
| Backend | Python 3.13, FastAPI, SQLAlchemy 2, PyMySQL, JWT (PyJWT), bcrypt, WebSocket, Claude API (Anthropic SDK); Swagger tại `/docs` |
| Database | MySQL 8 |
| Web admin | FastAPI + Jinja2 + Bootstrap 5 + Chart.js |
| Thanh toán | VNPay sandbox |

## Cấu trúc thư mục
```
Voltix_App/
├─ mobile/                # Ứng dụng Flutter
│  └─ lib/
│     ├─ core/            # cấu hình, API client, router, theme, validators, format
│     ├─ models/          # User, Product, Category, CartItem, Order, Address, Review, Chat...
│     ├─ services/        # gọi REST API / WebSocket
│     ├─ providers/       # state management (AuthProvider, CartProvider)
│     ├─ widgets/         # widget dùng chung
│     └─ screens/         # auth, home, product, cart, checkout, order, builder, chat, profile, admin
├─ backend/               # FastAPI
│  ├─ app/
│  │  ├─ main.py, config.py, database.py, security.py
│  │  ├─ models.py, schemas.py, serializers.py
│  │  ├─ routers/         # auth, catalog, cart, orders, payments, reviews, builder, chat, stats, admin_web
│  │  ├─ services/        # orders, vnpay, chat, stats
│  │  └─ templates/       # giao diện web admin
│  ├─ seed.py             # tạo database + dữ liệu mẫu
│  └─ tests/test_api.py   # kiểm thử end-to-end
├─ database/              # schema.sql, voltix.sql (schema + dữ liệu mẫu)
└─ docs/                  # ERD, mockup
```

## Thiết kế cơ sở dữ liệu
- Cấu trúc bảng: [database/schema.sql](database/schema.sql)
- Cấu trúc + dữ liệu mẫu: [database/voltix.sql](database/voltix.sql)
- ERD: [docs/erd.dbml](docs/erd.dbml) (mở bằng [dbdiagram.io](https://dbdiagram.io) → Export PNG)

Các bảng: `users`, `addresses`, `categories`, `brands`, `products`, `product_images`, `cart_items`, `orders`, `order_items`, `payments`, `reviews`, `conversations`, `messages`, `pc_builds`, `pc_build_items`.

## Hướng dẫn chạy

### 1. Backend
Yêu cầu: Python 3.11+, MySQL 8 đang chạy.
```bash
cd backend
python -m venv .venv
.venv\Scripts\activate            # macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
copy .env.example .env            # rồi sửa DATABASE_URL (mật khẩu MySQL), JWT_SECRET, SESSION_SECRET
python seed.py                    # tạo database 'voltix' + dữ liệu mẫu
uvicorn app.main:app --host 0.0.0.0 --port 8000
```
- Swagger (test API): http://localhost:8000/docs
- Web admin: http://localhost:8000/admin
- Kiểm thử: chạy server rồi `python tests/test_api.py`

Có thể thay `python seed.py` bằng import file SQL: `mysql -u root -p < database/voltix.sql`.

**VNPay sandbox:** đăng ký tại https://sandbox.vnpayment.vn/devreg/, điền `VNPAY_TMN_CODE` và `VNPAY_HASH_SECRET` vào `.env`. `PUBLIC_BASE_URL` là địa chỉ điện thoại truy cập được backend (emulator: `http://10.0.2.2:8000`). Thẻ test: NCB `9704198526191432198`, tên `NGUYEN VAN A`, ngày phát hành `07/15`, OTP `123456`.

**AI build PC:** hoạt động 2 lớp.
1. *Thuật toán tối ưu* (luôn chạy): duyệt mọi tổ hợp CPU–mainboard–RAM–VGA–SSD–nguồn–case–tản tương thích còn hàng, chấm điểm theo trọng số của nhu cầu (game dồn tiền cho VGA, văn phòng cho CPU/RAM/SSD...), chọn cấu hình tốt nhất trong ngân sách.
2. *Claude* (khi điền `ANTHROPIC_API_KEY` trong `.env`): đọc yêu cầu tự do của khách, chọn 1 trong 3 phương án tốt nhất của bước 1 và viết lời tư vấn tiếng Việt. Claude chỉ được chọn trong danh sách đã kiểm tra nên không bịa linh kiện. Không có key thì dùng lời tư vấn mẫu.

**Ảnh sản phẩm:** nằm trong `backend/app/static/products/`, tải lại bằng `python tools/fetch_images.py`.

### 2. App Flutter
```bash
cd mobile
flutter pub get
flutter run                                              # Android emulator, backend ở máy tính
flutter run --dart-define=SERVER_URL=http://192.168.1.10:8000   # điện thoại thật cùng mạng Wi-Fi
```
Build APK: `flutter build apk --release --dart-define=SERVER_URL=https://<domain-backend>`

## Tài khoản test
Mật khẩu tất cả tài khoản: `123456`

| Vai trò | Email |
|---|---|
| Admin | admin@voltix.vn |
| Nhân viên | staff@voltix.vn |
| Khách hàng | customer@voltix.vn |

## Danh sách API
Tất cả có tiền tố `/api`. 🔒 = cần JWT (`Authorization: Bearer <token>`), 🛡 = chỉ staff/admin.

| Nhóm | Method | Endpoint | Mô tả |
|---|---|---|---|
| Auth | POST | `/auth/register` | Đăng ký |
| | POST | `/auth/login` | Đăng nhập, trả JWT |
| | GET / PUT | `/auth/me` 🔒 | Xem / sửa hồ sơ |
| | POST | `/auth/change-password` 🔒 | Đổi mật khẩu |
| Địa chỉ | GET / POST | `/addresses` 🔒 | Danh sách / thêm địa chỉ |
| | DELETE | `/addresses/{id}` 🔒 | Xoá địa chỉ |
| Catalog | GET | `/categories`, `/brands` | Danh mục, thương hiệu |
| | GET | `/products?search=&category=&brand=&min_price=&max_price=&sort=&page=&size=` | Danh sách sản phẩm |
| | GET | `/products/{id}` | Chi tiết sản phẩm |
| | GET / POST / PUT / DELETE | `/admin/products`, `/admin/categories`, `/admin/brands` 🛡 | CRUD |
| Giỏ hàng | GET / DELETE | `/cart` 🔒 | Xem / xoá giỏ |
| | POST | `/cart/items` 🔒 | Thêm sản phẩm |
| | PUT / DELETE | `/cart/items/{id}` 🔒 | Sửa số lượng / xoá |
| Đơn hàng | POST / GET | `/orders` 🔒 | Đặt hàng từ giỏ / lịch sử đơn |
| | GET | `/orders/{id}` 🔒 | Chi tiết đơn |
| | POST | `/orders/{id}/cancel` 🔒 | Huỷ đơn |
| | GET | `/admin/orders?status_filter=` 🛡 | Tất cả đơn |
| | PUT | `/admin/orders/{id}/status` 🛡 | Cập nhật trạng thái |
| VNPay | POST | `/payments/vnpay/create` 🔒 | Tạo URL thanh toán |
| | GET | `/payments/vnpay/return` | VNPay chuyển về sau thanh toán |
| | GET | `/payments/vnpay/ipn` | VNPay gọi server-to-server |
| Đánh giá | GET / POST | `/products/{id}/reviews` (POST 🔒) | Xem / viết đánh giá |
| | GET | `/products/{id}/reviews/eligibility` 🔒 | Kiểm tra quyền đánh giá |
| PC Builder | GET | `/builder/compatible?category=&selected=` | Linh kiện tương thích |
| | POST | `/builder/ai-suggest` | AI gợi ý cấu hình (`budget`, `purpose`, `notes`) |
| | GET / POST | `/builds` 🔒 | Cấu hình đã lưu / lưu cấu hình |
| | DELETE | `/builds/{id}` 🔒 | Xoá cấu hình |
| Chat | GET | `/chat/my-conversation` 🔒 | Cuộc trò chuyện của khách |
| | GET | `/chat/conversations` 🛡 | Tất cả cuộc trò chuyện |
| | GET / POST | `/chat/conversations/{id}/messages` 🔒 | Xem / gửi tin nhắn |
| | WS | `/ws/chat?token=` | Nhận/gửi tin nhắn realtime |
| Thống kê | GET | `/admin/stats/summary`, `/revenue?group=day\|month`, `/top-products`, `/revenue-by-category`, `/orders-by-status`, `/low-stock` 🛡 | Báo cáo |

## Bảo mật
- Mật khẩu băm bằng bcrypt; JWT có hạn; kiểm tra quyền staff/admin ở mọi API quản trị
- Validate dữ liệu đầu vào bằng Pydantic; dùng ORM (truy vấn tham số hoá) chống SQL injection
- Người dùng chỉ xem được đơn/địa chỉ/cuộc trò chuyện của mình
- VNPay: kiểm tra chữ ký HMAC-SHA512 và số tiền ở server, không tin kết quả từ app
- Web admin dùng session cookie SameSite=Lax; file `.env` không đưa lên Git

## Lộ trình
| Mốc | Hạn | Nội dung | Trạng thái |
|---|---|---|---|
| 1 – Thiết kế | Slot 6 | Source Flutter + màn hình chính, mockup, ERD, README | ✅ |
| 2 – Backend & API | Slot 12 | FastAPI + MySQL, dữ liệu mẫu, REST API, Swagger, web admin | ✅ |
| 3 – Tích hợp | Slot 16 | App gọi API thật, VNPay, chat, thống kê | ✅ (còn deploy) |
| Nộp bài | Slot 18 | Video YouTube, GitHub, link tải app | ⏳ |
