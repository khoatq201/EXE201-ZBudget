import 'package:flutter/material.dart';

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isStreaming = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? DateTime.now().toString(),
      content: json['content'] ?? '',
      role: MessageRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => MessageRole.user,
      ),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      isStreaming: json['isStreaming'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isStreaming': isStreaming,
    };
  }
}

enum MessageRole { user, assistant, system }

class ChatSession {
  final String sessionId;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int messageCount;
  final List<ChatMessage> messages;
  final bool isActive;

  ChatSession({
    required this.sessionId,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messageCount,
    required this.messages,
    this.isActive = true,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['sessionId'],
      createdAt: DateTime.parse(json['createdAt']),
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
      messageCount: json['messageCount'],
      messages:
          (json['messages'] as List?)
              ?.map((m) => ChatMessage.fromJson(m))
              .toList() ??
          [],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'messageCount': messageCount,
      'messages': messages.map((m) => m.toJson()).toList(),
      'isActive': isActive,
    };
  }
}

class QuickAction {
  final String id;
  final String title;
  final String message;
  final IconData icon;

  QuickAction({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
  });
}
