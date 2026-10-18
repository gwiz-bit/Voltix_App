import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../models/misc.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/common.dart';

/// Điểm vào /chat: khách hàng vào thẳng phòng chat với cửa hàng, nhân viên xem danh sách.
class ChatEntryScreen extends StatelessWidget {
  const ChatEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isStaff = context.watch<AuthProvider>().user?.isStaff ?? false;
    return isStaff ? const ConversationsScreen() : const _CustomerChat();
  }
}

class _CustomerChat extends StatefulWidget {
  const _CustomerChat();

  @override
  State<_CustomerChat> createState() => _CustomerChatState();
}

class _CustomerChatState extends State<_CustomerChat> {
  late Future<Conversation> _future = context.read<ChatService>().myConversation();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ChatRoomScreen(conversationId: snapshot.data!.id, title: 'Voltix – Tư vấn');
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Chat tư vấn')),
          body: FutureView(
            future: _future,
            onRetry: () => setState(() => _future = context.read<ChatService>().myConversation()),
            builder: (_, _) => const SizedBox(),
          ),
        );
      },
    );
  }
}

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late Future<List<Conversation>> _future = context.read<ChatService>().conversations();

  void _reload() => setState(() => _future = context.read<ChatService>().conversations());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hộp thư khách hàng')),
      body: FutureView(
        future: _future,
        onRetry: _reload,
        builder: (context, convs) => RefreshIndicator(
          onRefresh: () async => _reload(),
          child: convs.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 300, child: EmptyView(icon: Icons.forum_outlined, message: 'Chưa có cuộc trò chuyện')),
                ])
              : ListView.separated(
                  itemCount: convs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = convs[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(c.customerName.characters.first)),
                      title: Text(c.customerName, style: TextStyle(fontWeight: c.unread > 0 ? FontWeight.bold : null)),
                      subtitle: Text(c.lastMessage ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: c.unread > 0
                          ? Badge(label: Text('${c.unread}'))
                          : Text(formatTime(c.updatedAt), style: const TextStyle(color: Colors.grey)),
                      onTap: () async {
                        await context.push('/chat/${c.id}?name=${Uri.encodeQueryComponent(c.customerName)}');
                        _reload();
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.conversationId, required this.title});

  final int conversationId;
  final String title;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  WebSocketChannel? _channel;
  StreamSubscription<ChatMessage>? _sub;
  Timer? _reconnect;
  bool _online = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _connect();
  }

  @override
  void dispose() {
    _reconnect?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final list = await context.read<ChatService>().messages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
        _loading = false;
        _error = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = ApiClient.messageOf(e);
        });
      }
    }
  }

  Future<void> _connect() async {
    final conn = await context.read<ChatService>().connect();
    if (conn == null || !mounted) return;
    _channel = conn.channel;
    try {
      await conn.channel.ready;
      if (mounted) setState(() => _online = true);
    } catch (_) {
      _scheduleReconnect();
      return;
    }
    _sub = conn.messages.listen(
      (m) {
        if (m.conversationId != widget.conversationId || _messages.any((x) => x.id == m.id)) return;
        setState(() => _messages.add(m));
        _scrollToBottom();
      },
      onDone: _scheduleReconnect,
      onError: (_) => _scheduleReconnect(),
    );
  }

  void _scheduleReconnect() {
    if (!mounted) return;
    setState(() => _online = false);
    _sub?.cancel();
    _reconnect?.cancel();
    _reconnect = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _connect();
        _loadHistory(); // bù các tin nhắn bị lỡ khi mất kết nối
      }
    });
  }

  Future<void> _send() async {
    final content = _input.text.trim();
    if (content.isEmpty) return;
    _input.clear();
    if (_online && _channel != null) {
      _channel!.sink.add(jsonEncode({'conversation_id': widget.conversationId, 'content': content}));
      return;
    }
    // Không có WebSocket -> gửi qua REST.
    try {
      final m = await context.read<ChatService>().send(widget.conversationId, content);
      if (mounted && !_messages.any((x) => x.id == m.id)) {
        setState(() => _messages.add(m));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        _input.text = content;
        showMessage(context, ApiClient.messageOf(e), error: true);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Text(
              _online ? 'Trực tuyến' : 'Đang kết nối lại...',
              style: TextStyle(fontSize: 12, color: _online ? Colors.green : Colors.orange),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _loadHistory)
                    : _messages.isEmpty
                        ? const EmptyView(icon: Icons.chat_outlined, message: 'Hãy gửi câu hỏi, nhân viên Voltix sẽ phản hồi ngay!')
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(12),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) => _Bubble(message: _messages[i], mine: _messages[i].senderId == me.id),
                          ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Nhập tin nhắn...', counterText: '', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: mine ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: mine ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Text(message.senderName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            Text(message.content, style: TextStyle(color: mine ? Colors.white : null)),
            Text(formatTime(message.createdAt),
                style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : Colors.grey)),
          ],
        ),
      ),
    );
  }
}
