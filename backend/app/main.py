from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from starlette.middleware.sessions import SessionMiddleware

from .config import settings
from .routers import admin_web, auth, builder, cart, catalog, chat, orders, payments, reviews, stats

app = FastAPI(
    title="Voltix API",
    description="Backend cho ứng dụng Voltix – mua bán linh kiện máy tính. **Power Your Next Level.**",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.cors_origins.split(",")],
    allow_methods=["*"],
    allow_headers=["*"],
)
# Session cookie cho web admin; SameSite=lax chặn form POST từ trang web khác (CSRF).
app.add_middleware(SessionMiddleware, secret_key=settings.session_secret, same_site="lax", max_age=60 * 60 * 8)

for r in (
    auth.router,
    catalog.router,
    catalog.admin,
    cart.router,
    orders.router,
    payments.router,
    reviews.router,
    builder.router,
    chat.router,
    stats.router,
):
    app.include_router(r, prefix="/api")

app.include_router(chat.ws_router)
app.include_router(admin_web.router)


@app.get("/", include_in_schema=False)
def root():
    return RedirectResponse("/docs")


@app.get("/api/health", tags=["Health"])
def health():
    return {"status": "ok"}
