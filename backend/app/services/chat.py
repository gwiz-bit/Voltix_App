"""Chat khách hàng <-> nhân viên: lưu tin nhắn + đẩy realtime qua WebSocket."""

import json
from collections import defaultdict

from fastapi import HTTPException, WebSocket, status
from sqlalchemy import func, select, update
from sqlalchemy.orm import Session

from ..models import Conversation, Message, User
from ..serializers import message_dict


class ChatHub:
    """Giữ các kết nối WebSocket đang mở. Mỗi user có thể mở nhiều thiết bị/tab."""

    def __init__(self):
        self._sockets: dict[int, set[WebSocket]] = defaultdict(set)
        self._staff_ids: set[int] = set()

    def connect(self, user: User, ws: WebSocket):
        self._sockets[user.id].add(ws)
        if user.is_staff:
            self._staff_ids.add(user.id)

    def disconnect(self, user: User, ws: WebSocket):
        self._sockets[user.id].discard(ws)
        if not self._sockets[user.id]:
            self._sockets.pop(user.id, None)
            self._staff_ids.discard(user.id)

    async def broadcast(self, payload: dict, customer_id: int):
        """Gửi cho khách hàng của cuộc trò chuyện và toàn bộ nhân viên đang online."""
        text = json.dumps(payload, default=str, ensure_ascii=False)
        for uid in {customer_id, *self._staff_ids}:
            for ws in list(self._sockets.get(uid, ())):
                try:
                    await ws.send_text(text)
                except Exception:
                    self._sockets[uid].discard(ws)


hub = ChatHub()


def get_or_create_conversation(db: Session, customer: User) -> Conversation:
    conv = db.scalar(select(Conversation).where(Conversation.customer_id == customer.id))
    if conv is None:
        conv = Conversation(customer_id=customer.id)
        db.add(conv)
        db.commit()
        db.refresh(conv)
    return conv


def accessible_conversation(db: Session, conversation_id: int, user: User) -> Conversation:
    conv = db.get(Conversation, conversation_id)
    if conv is None or (conv.customer_id != user.id and not user.is_staff):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy cuộc trò chuyện")
    return conv


def save_message(db: Session, conv: Conversation, sender: User, content: str) -> Message:
    content = content.strip()
    if not content:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Tin nhắn trống")
    msg = Message(conversation_id=conv.id, sender_id=sender.id, content=content[:2000])
    db.add(msg)
    if sender.is_staff and conv.staff_id is None:
        conv.staff_id = sender.id
    conv.updated_at = func.now()
    db.commit()
    db.refresh(msg)
    return msg


def mark_read(db: Session, conv: Conversation, reader: User):
    db.execute(
        update(Message)
        .where(Message.conversation_id == conv.id, Message.sender_id != reader.id, Message.is_read.is_(False))
        .values(is_read=True)
    )
    db.commit()


def conversation_dict(db: Session, conv: Conversation, viewer: User) -> dict:
    last = db.scalar(select(Message).where(Message.conversation_id == conv.id).order_by(Message.id.desc()).limit(1))
    unread = db.scalar(
        select(func.count(Message.id)).where(
            Message.conversation_id == conv.id, Message.sender_id != viewer.id, Message.is_read.is_(False)
        )
    )
    return {
        "id": conv.id,
        "customer_id": conv.customer_id,
        "customer_name": conv.customer.full_name,
        "last_message": last.content if last else None,
        "unread": unread or 0,
        "updated_at": conv.updated_at,
    }


def messages_of(db: Session, conv: Conversation) -> list[dict]:
    msgs = db.scalars(select(Message).where(Message.conversation_id == conv.id).order_by(Message.id)).all()
    return [message_dict(m) for m in msgs]
