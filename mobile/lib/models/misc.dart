import '../core/format.dart';
import 'product.dart';

class Address {
  final int id;
  final String receiver;
  final String phone;
  final String detail;
  final bool isDefault;

  const Address({
    required this.id,
    required this.receiver,
    required this.phone,
    required this.detail,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'] as int,
        receiver: json['receiver'] as String,
        phone: json['phone'] as String,
        detail: json['detail'] as String,
        isDefault: json['is_default'] as bool,
      );
}

class Review {
  final int id;
  final String userName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as int,
        userName: json['user_name'] as String,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        createdAt: parseServerTime(json['created_at'] as String),
      );
}

class Brand {
  final int id;
  final String name;

  const Brand({required this.id, required this.name});

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(id: json['id'] as int, name: json['name'] as String);
}

class PcBuild {
  final int id;
  final String name;
  final int total;
  final DateTime createdAt;
  final List<Product> products;

  const PcBuild({
    required this.id,
    required this.name,
    required this.total,
    required this.createdAt,
    required this.products,
  });

  factory PcBuild.fromJson(Map<String, dynamic> json) => PcBuild(
        id: json['id'] as int,
        name: json['name'] as String,
        total: json['total'] as int,
        createdAt: parseServerTime(json['created_at'] as String),
        products: (json['products'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// Kết quả AI build PC.
class AiBuild {
  final bool aiPowered; // true nếu lời tư vấn do Claude viết
  final String title;
  final String explanation;
  final List<String> tips;
  final int total;
  final int estimatedWattage;
  final List<Product> products;

  const AiBuild({
    required this.aiPowered,
    required this.title,
    required this.explanation,
    required this.tips,
    required this.total,
    required this.estimatedWattage,
    required this.products,
  });

  factory AiBuild.fromJson(Map<String, dynamic> json) => AiBuild(
        aiPowered: json['ai_powered'] as bool,
        title: json['title'] as String,
        explanation: json['explanation'] as String,
        tips: (json['tips'] as List).cast<String>(),
        total: json['total'] as int,
        estimatedWattage: json['estimated_wattage'] as int,
        products: (json['products'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class Conversation {
  final int id;
  final String customerName;
  final String? lastMessage;
  final int unread;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.customerName,
    this.lastMessage,
    required this.unread,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as int,
        customerName: json['customer_name'] as String,
        lastMessage: json['last_message'] as String?,
        unread: json['unread'] as int,
        updatedAt: parseServerTime(json['updated_at'] as String),
      );
}

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as int,
        conversationId: json['conversation_id'] as int,
        senderId: json['sender_id'] as int,
        senderName: json['sender_name'] as String,
        senderRole: json['sender_role'] as String,
        content: json['content'] as String,
        createdAt: parseServerTime(json['created_at'] as String),
      );
}
