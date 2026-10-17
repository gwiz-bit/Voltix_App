# Voltix – Ứng dụng mua bán linh kiện máy tính

**Power Your Next Level.**

> Đề tài PRM393 (Flutter Mobile Programming): **Ứng dụng mua bán linh kiện máy tính trực tuyến, hỗ trợ build PC, thanh toán VNPay và chat tư vấn, dành cho người dùng cá nhân và cửa hàng linh kiện.**

## Mô tả

Voltix giúp người dùng tìm và mua linh kiện máy tính (CPU, mainboard, RAM, VGA, SSD, nguồn, case, tản nhiệt) ngay trên điện thoại, tự build cấu hình PC với kiểm tra tương thích, thanh toán online qua VNPay và chat trực tiếp với nhân viên cửa hàng để được tư vấn. Cửa hàng quản lý sản phẩm, đơn hàng và xem báo cáo doanh thu qua web admin.

### Đối tượng sử dụng
| Vai trò | Nền tảng | Chức năng |
|---|---|---|
| Khách hàng | App Flutter | Đăng ký/đăng nhập, tìm kiếm & lọc sản phẩm, giỏ hàng, đặt hàng, thanh toán VNPay/COD, theo dõi đơn, đánh giá, PC Builder, chat tư vấn |
| Nhân viên / Admin | Web admin (+ app) | CRUD sản phẩm/danh mục/thương hiệu, xử lý đơn hàng, trả lời chat, thống kê doanh thu |

## Chức năng dự kiến
- [x] Đăng ký / đăng nhập, tự đăng nhập lại bằng token (SharedPreferences)
- [x] Trang chủ: danh mục, sản phẩm nổi bật, tìm kiếm
- [x] Danh sách sản phẩm theo danh mục / từ khoá, chi tiết sản phẩm
- [x] Giỏ hàng (thêm, sửa số lượng, xoá, kiểm tra tồn kho)
- [ ] Đặt hàng, lịch sử & chi tiết đơn hàng
- [ ] Thanh toán online VNPay (sandbox)
- [ ] Đánh giá sản phẩm (chỉ khi đã mua)
- [ ] PC Builder: lọc linh kiện tương thích (socket, chuẩn RAM), gợi ý công suất nguồn
- [ ] Chat realtime khách hàng ↔ nhân viên (WebSocket)
- [ ] Web admin: CRUD dữ liệu, xử lý đơn, báo cáo thống kê (doanh thu, top sản phẩm, đơn theo trạng thái)
- [ ] Thông báo khi đơn hàng đổi trạng thái

## Công nghệ sử dụng
| Thành phần | Công nghệ |
|---|---|
| Mobile | Flutter 3 + Dart 3, Provider (state), go_router (navigation), dio (REST), shared_preferences, cached_network_image |
| Backend | Python FastAPI, SQLAlchemy, PyMySQL, JWT, bcrypt, WebSocket; Swagger tại `/docs` |
| Database | MySQL 8 |
| Web admin | FastAPI + Jinja2 + Bootstrap + Chart.js |
| Thanh toán | VNPay sandbox |

## Cấu trúc thư mục
```
voltix/
├─ mobile/          # Ứng dụng Flutter
│  └─ lib/
│     ├─ core/       # cấu hình, API client, router, theme, validators
│     ├─ models/     # User, Category, Product, CartItem
│     ├─ services/   # gọi API (Api*Service) + dữ liệu mock (Mock*Service)
│     ├─ providers/  # state management (Provider)
│     ├─ widgets/    # widget dùng chung
│     └─ screens/    # splash, auth, home, product, cart, profile
├─ backend/         # FastAPI (Mốc 2)
├─ database/        # schema.sql, seed.sql
└─ docs/            # ERD, mockup, Postman collection
```

## Thiết kế cơ sở dữ liệu
- Script tạo bảng: [database/schema.sql](database/schema.sql)
- ERD: [docs/erd.dbml](docs/erd.dbml) (mở bằng [dbdiagram.io](https://dbdiagram.io) → Export PNG)

Các bảng: `users`, `addresses`, `categories`, `brands`, `products`, `product_images`, `cart_items`, `orders`, `order_items`, `payments`, `reviews`, `conversations`, `messages`, `pc_builds`, `pc_build_items`.

## Chạy ứng dụng Flutter
```bash
cd mobile
flutter pub get
flutter run
```
Hiện tại (Mốc 1) app dùng dữ liệu mock (`AppConstants.useMock = true` trong `mobile/lib/core/constants.dart`).
Tài khoản demo: `customer@voltix.vn` / `123456`.

## Lộ trình
| Mốc | Hạn | Nội dung |
|---|---|---|
| 1 – Thiết kế | Slot 6 | Source Flutter + màn hình chính, mockup, ERD, README |
| 2 – Backend & API | Slot 12 | FastAPI + MySQL, dữ liệu mẫu, REST API, Swagger/Postman, web admin |
| 3 – Tích hợp | Slot 16 | App gọi API thật, VNPay, chat, thống kê, deploy |
| Nộp bài | Slot 18 | Video YouTube, GitHub, link tải app |
