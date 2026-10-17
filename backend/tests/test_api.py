"""Kiểm thử end-to-end trên server đang chạy (cần chạy `python seed.py` trước).

Chạy:  python -m pytest tests -q     hoặc     python tests/test_api.py
"""

import json
import os
import uuid

import httpx

BASE = os.getenv("API_BASE", "http://127.0.0.1:8000")
api = httpx.Client(base_url=f"{BASE}/api", timeout=15)


def login(email: str, password: str = "123456") -> dict:
    r = api.post("/auth/login", json={"email": email, "password": password})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def test_auth_validation_and_errors():
    assert api.post("/auth/login", json={"email": "customer@voltix.vn", "password": "sai"}).status_code == 401
    assert api.get("/auth/me").status_code == 401
    bad = api.post("/auth/register", json={"full_name": "A", "email": "x", "phone": "1", "password": "1"})
    assert bad.status_code == 422
    dup = api.post("/auth/register", json={"full_name": "Dup", "email": "customer@voltix.vn",
                                            "phone": "0901111111", "password": "123456"})
    assert dup.status_code == 409


def test_register_and_profile():
    email = f"test_{uuid.uuid4().hex[:8]}@gmail.com"
    r = api.post("/auth/register", json={"full_name": "Người Test", "email": email, "phone": "0987654321",
                                          "password": "123456"})
    assert r.status_code == 201, r.text
    h = {"Authorization": f"Bearer {r.json()['access_token']}"}
    assert api.get("/auth/me", headers=h).json()["email"] == email
    assert api.put("/auth/me", headers=h, json={"full_name": "Đã Đổi", "phone": "0987654322"}).json()["full_name"] == "Đã Đổi"
    assert api.post("/auth/change-password", headers=h, json={"old_password": "sai", "new_password": "1234567"}).status_code == 400
    assert api.post("/auth/change-password", headers=h, json={"old_password": "123456", "new_password": "1234567"}).status_code == 204
    login(email, "1234567")
    a = api.post("/addresses", headers=h, json={"receiver": "Người Test", "phone": "0987654321", "detail": "1 Lê Lợi, Q.1"})
    assert a.status_code == 201 and a.json()["is_default"] is True


def test_catalog():
    cats = api.get("/categories").json()
    assert len(cats) == 8
    page = api.get("/products", params={"size": 5}).json()
    assert page["total"] >= 40 and len(page["items"]) == 5
    cpu = api.get("/products", params={"category": cats[0]["id"], "sort": "price_asc"}).json()["items"]
    prices = [p["sale_price"] or p["price"] for p in cpu]
    assert prices == sorted(prices)
    assert all("ryzen" in p["name"].lower() or "amd" in p["brand_name"].lower()
               for p in api.get("/products", params={"search": "ryzen"}).json()["items"])
    assert api.get("/products/999999").status_code == 404


def test_admin_requires_staff():
    customer = login("customer@voltix.vn")
    assert api.get("/admin/stats/summary", headers=customer).status_code == 403
    staff = login("staff@voltix.vn")
    s = api.get("/admin/stats/summary", headers=staff).json()
    assert s["total_revenue"] > 0
    assert len(api.get("/admin/stats/revenue", headers=staff, params={"days": 30}).json()) == 30
    assert api.get("/admin/stats/top-products", headers=staff).json()


def test_admin_product_crud():
    staff = login("admin@voltix.vn")
    cat = api.get("/categories").json()[0]["id"]
    brand = api.get("/brands").json()[0]["id"]
    body = {"category_id": cat, "brand_id": brand, "name": "Sản phẩm test", "price": 1000, "stock": 3}
    created = api.post("/admin/products", headers=staff, json=body)
    assert created.status_code == 201, created.text
    pid = created.json()["id"]
    assert api.put(f"/admin/products/{pid}", headers=staff, json={**body, "price": 2000}).json()["price"] == 2000
    assert api.put(f"/admin/products/{pid}", headers=staff, json={**body, "sale_price": 5000}).status_code == 422
    assert api.delete(f"/admin/products/{pid}", headers=staff).status_code == 204
    assert api.get(f"/products/{pid}").status_code == 404


def test_cart_order_cancel_flow():
    h = login("tranthib@gmail.com")
    api.delete("/cart", headers=h)
    product = next(p for p in api.get("/products", params={"size": 50}).json()["items"] if p["stock"] >= 3)
    stock_before = product["stock"]

    assert api.post("/cart/items", headers=h, json={"product_id": product["id"], "quantity": stock_before + 1}).status_code == 409
    cart = api.post("/cart/items", headers=h, json={"product_id": product["id"], "quantity": 2}).json()
    assert cart["count"] == 2
    item_id = cart["items"][0]["id"]
    assert api.put(f"/cart/items/{item_id}", headers=h, json={"quantity": 1}).json()["count"] == 1

    order = api.post("/orders", headers=h, json={"receiver": "Trần Thị B", "phone": "0912345678",
                                                  "shipping_address": "45 Trần Duy Hưng, Hà Nội",
                                                  "payment_method": "COD"})
    assert order.status_code == 201, order.text
    order = order.json()
    assert order["total"] == (product["sale_price"] or product["price"])
    assert api.get("/cart", headers=h).json()["count"] == 0
    assert api.get(f"/products/{product['id']}").json()["stock"] == stock_before - 1
    assert api.post("/orders", headers=h, json={"receiver": "Trần B", "phone": "0912345678",
                                                 "shipping_address": "45 Trần Duy Hưng", "payment_method": "COD"}).status_code == 400

    other = login("leminhc@gmail.com")
    assert api.get(f"/orders/{order['id']}", headers=other).status_code == 404  # không xem được đơn người khác

    assert api.post(f"/orders/{order['id']}/cancel", headers=h).json()["status"] == "cancelled"
    assert api.get(f"/products/{product['id']}").json()["stock"] == stock_before


def test_admin_order_status_and_review():
    h = login("phamquocd@gmail.com")
    staff = login("staff@voltix.vn")
    api.delete("/cart", headers=h)
    product = next(p for p in api.get("/products", params={"size": 50, "sort": "price_asc"}).json()["items"] if p["stock"] > 0)
    api.post("/cart/items", headers=h, json={"product_id": product["id"]})
    order = api.post("/orders", headers=h, json={"receiver": "Phạm Quốc D", "phone": "0934567890",
                                                  "shipping_address": "102 Hùng Vương, Cần Thơ", "payment_method": "COD"}).json()
    oid = order["id"]
    assert api.put(f"/admin/orders/{oid}/status", headers=staff, json={"status": "completed"}).status_code == 409
    for s in ("confirmed", "shipping", "completed"):
        assert api.put(f"/admin/orders/{oid}/status", headers=staff, json={"status": s}).json()["status"] == s
    assert api.post(f"/orders/{oid}/cancel", headers=h).status_code == 409

    # Đã nhận hàng -> được đánh giá (nếu chưa đánh giá trước đó trong seed).
    if api.get(f"/products/{product['id']}/reviews/eligibility", headers=h).json()["can_review"]:
        r = api.post(f"/products/{product['id']}/reviews", headers=h, json={"rating": 5, "comment": "Tốt"})
        assert r.status_code == 201, r.text
    assert api.post(f"/products/{product['id']}/reviews", headers=h, json={"rating": 5}).status_code == 409


def test_vnpay_not_configured_or_url():
    h = login("customer@voltix.vn")
    api.delete("/cart", headers=h)
    product = next(p for p in api.get("/products").json()["items"] if p["stock"] > 0)
    api.post("/cart/items", headers=h, json={"product_id": product["id"]})
    order = api.post("/orders", headers=h, json={"receiver": "Nguyễn Văn A", "phone": "0901234567",
                                                  "shipping_address": "12 Nguyễn Huệ, Q.1", "payment_method": "VNPAY"}).json()
    r = api.post("/payments/vnpay/create", headers=h, json={"order_id": order["id"]})
    assert r.status_code in (200, 503), r.text
    if r.status_code == 200:
        assert r.json()["payment_url"].startswith("https://sandbox.vnpayment.vn")
    # Chữ ký giả mạo bị từ chối.
    ipn = api.get("/payments/vnpay/ipn", params={"vnp_TxnRef": "x", "vnp_SecureHash": "abc"}).json()
    assert ipn["RspCode"] == "97"
    api.post(f"/orders/{order['id']}/cancel", headers=h)


def test_builder_compatibility():
    cpus = api.get("/builder/compatible", params={"category": "cpu"}).json()
    am5 = next(c for c in cpus if c["specs"]["socket"] == "AM5")
    boards = api.get("/builder/compatible", params={"category": "mainboard", "selected": str(am5["id"])}).json()
    assert boards and all(b["specs"]["socket"] == "AM5" for b in boards)
    rams = api.get("/builder/compatible", params={"category": "ram", "selected": f"{am5['id']},{boards[0]['id']}"}).json()
    assert rams and all(r["specs"]["ram_type"] == boards[0]["specs"]["ram_type"] for r in rams)

    h = login("customer@voltix.vn")
    build = api.post("/builds", headers=h, json={"name": "PC AM5", "product_ids": [am5["id"], boards[0]["id"]]})
    assert build.status_code == 201 and build.json()["total"] > 0
    assert api.delete(f"/builds/{build.json()['id']}", headers=h).status_code == 204


def test_chat_rest_and_websocket():
    from websockets.sync.client import connect

    customer = login("customer@voltix.vn")
    staff = login("staff@voltix.vn")
    conv = api.get("/chat/my-conversation", headers=customer).json()
    staff_token = staff["Authorization"].split()[1]
    ws_base = BASE.replace("http", "ws")
    with connect(f"{ws_base}/ws/chat?token={staff_token}") as ws:
        sent = api.post(f"/chat/conversations/{conv['id']}/messages", headers=customer, json={"content": "Xin chào shop"})
        assert sent.status_code == 201
        pushed = json.loads(ws.recv(timeout=5))
        assert pushed["content"] == "Xin chào shop" and pushed["conversation_id"] == conv["id"]
        ws.send(json.dumps({"conversation_id": conv["id"], "content": "Chào bạn, shop có thể giúp gì?"}))
        echo = json.loads(ws.recv(timeout=5))
        assert echo["sender_role"] == "staff"
    msgs = api.get(f"/chat/conversations/{conv['id']}/messages", headers=customer).json()
    assert msgs[-1]["content"] == "Chào bạn, shop có thể giúp gì?"
    assert any(c["id"] == conv["id"] for c in api.get("/chat/conversations", headers=staff).json())


if __name__ == "__main__":
    import sys

    sys.stdout.reconfigure(encoding="utf-8")
    failed = 0
    for name, fn in list(globals().items()):
        if name.startswith("test_") and callable(fn):
            try:
                fn()
                print(f"PASS  {name}")
            except Exception as e:  # noqa: BLE001
                failed += 1
                print(f"FAIL  {name}: {e!r}")
    sys.exit(1 if failed else 0)
