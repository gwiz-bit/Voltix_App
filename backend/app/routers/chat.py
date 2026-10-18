import json

from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import SessionLocal, get_db
from ..models import Conversation, User
from ..schemas import ConversationOut, MessageIn, MessageOut
from ..security import get_current_user, require_staff, user_from_token
from ..serializers import message_dict
from ..services.chat import (
    accessible_conversation,
    conversation_dict,
    get_or_create_conversation,
    hub,
    mark_read,
    messages_of,
    save_message,
)

router = APIRouter(prefix="/chat", tags=["Chat"])


@router.get("/my-conversation", response_model=ConversationOut)
def my_conversation(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Khách hàng: lấy (hoặc tạo) cuộc trò chuyện với cửa hàng."""
    if user.is_staff:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Nhân viên dùng /chat/conversations")
    return conversation_dict(db, get_or_create_conversation(db, user), user)


@router.get("/conversations", response_model=list[ConversationOut])
def all_conversations(user: User = Depends(require_staff), db: Session = Depends(get_db)):
    convs = db.scalars(select(Conversation).order_by(Conversation.updated_at.desc())).all()
    return [conversation_dict(db, c, user) for c in convs]


@router.get("/conversations/{conversation_id}/messages", response_model=list[MessageOut])
def get_messages(conversation_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    conv = accessible_conversation(db, conversation_id, user)
    mark_read(db, conv, user)
    return messages_of(db, conv)


@router.post("/conversations/{conversation_id}/messages", response_model=MessageOut, status_code=201)
async def send_message(
    conversation_id: int, data: MessageIn, user: User = Depends(get_current_user), db: Session = Depends(get_db)
):
    conv = accessible_conversation(db, conversation_id, user)
    payload = message_dict(save_message(db, conv, user, data.content))
    await hub.broadcast(payload, conv.customer_id)
    return payload


# WebSocket không gửi được header Authorization từ trình duyệt nên nhận token qua query string.
ws_router = APIRouter()


@ws_router.websocket("/ws/chat")
async def chat_socket(ws: WebSocket, token: str = Query(...)):
    # Mỗi bước dùng session ngắn hạn: không giữ transaction/kết nối DB suốt thời gian socket mở.
    with SessionLocal() as db:
        user = user_from_token(token, db)
    if user is None:
        await ws.close(code=4401)
        return
    await ws.accept()
    hub.connect(user, ws)
    try:
        while True:
            # Client gửi: {"conversation_id": 1, "content": "..."}
            raw = await ws.receive_text()
            try:
                data = json.loads(raw)
                with SessionLocal() as db:
                    conv = accessible_conversation(db, int(data["conversation_id"]), user)
                    payload = message_dict(save_message(db, conv, user, str(data.get("content", ""))))
                    customer_id = conv.customer_id
            except (ValueError, KeyError, TypeError, HTTPException) as e:
                await ws.send_text(json.dumps({"error": getattr(e, "detail", "Dữ liệu không hợp lệ")}))
                continue
            await hub.broadcast(payload, customer_id)
    except WebSocketDisconnect:
        pass
    finally:
        hub.disconnect(user, ws)
