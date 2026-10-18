import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/storage.dart';
import '../models/misc.dart';

class ChatService {
  final _dio = ApiClient.dio;

  /// Khách hàng: cuộc trò chuyện với cửa hàng (server tự tạo nếu chưa có).
  Future<Conversation> myConversation() async =>
      Conversation.fromJson((await _dio.get('/chat/my-conversation')).data as Map<String, dynamic>);

  /// Nhân viên: tất cả cuộc trò chuyện.
  Future<List<Conversation>> conversations() async {
    final res = await _dio.get('/chat/conversations');
    return (res.data as List).map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ChatMessage>> messages(int conversationId) async {
    final res = await _dio.get('/chat/conversations/$conversationId/messages');
    return (res.data as List).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ChatMessage> send(int conversationId, String content) async {
    final res = await _dio.post('/chat/conversations/$conversationId/messages', data: {'content': content});
    return ChatMessage.fromJson(res.data as Map<String, dynamic>);
  }

  /// Mở WebSocket nhận tin nhắn realtime. Trả về null nếu chưa đăng nhập.
  Future<({WebSocketChannel channel, Stream<ChatMessage> messages})?> connect() async {
    final token = await AppStorage.getToken();
    if (token == null) return null;
    final channel = WebSocketChannel.connect(
      Uri.parse('${AppConstants.wsUrl}/ws/chat?token=${Uri.encodeQueryComponent(token)}'),
    );
    final stream = channel.stream
        .map((raw) => jsonDecode(raw as String) as Map<String, dynamic>)
        .where((json) => !json.containsKey('error'))
        .map(ChatMessage.fromJson);
    return (channel: channel, messages: stream);
  }
}
