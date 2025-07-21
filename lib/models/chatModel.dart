import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final Timestamp createdAt;
  final bool isRead;

  ChatModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }
}