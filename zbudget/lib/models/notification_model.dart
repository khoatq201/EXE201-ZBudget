import 'package:flutter/material.dart';

/// Helper function để parse double từ JSON
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Helper function để parse String từ JSON
String? _parseString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num) return value.toString();
  return null;
}

/// Model cho in-app notifications từ backend
class NotificationModel {
  final String id;
  final String type;
  final String category;
  final String title;
  final String message;
  final String? icon;
  final String? color;
  final String? imageUrl;
  final String priority;
  final bool requiresAction;
  final List<NotificationAction> actionButtons;
  final NotificationData? data;
  final String deliveryMethod;
  final bool isRead;
  final DateTime? readAt;
  final bool isArchived;
  final DateTime? archivedAt;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final DateTime? expiresAt;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    this.icon,
    this.color,
    this.imageUrl,
    required this.priority,
    required this.requiresAction,
    required this.actionButtons,
    this.data,
    required this.deliveryMethod,
    required this.isRead,
    this.readAt,
    required this.isArchived,
    this.archivedAt,
    this.scheduledFor,
    this.sentAt,
    this.expiresAt,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _parseString(json['_id'] ?? json['id']) ?? '',
      type: _parseString(json['type']) ?? '',
      category: _parseString(json['category']) ?? '',
      title: _parseString(json['title']) ?? '',
      message: _parseString(json['message']) ?? '',
      icon: _parseString(json['icon']),
      color: _parseString(json['color']),
      imageUrl: _parseString(json['imageUrl']),
      priority: _parseString(json['priority']) ?? 'normal',
      requiresAction: json['requiresAction'] ?? false,
      actionButtons:
          (json['actionButtons'] as List?)
              ?.map((action) => NotificationAction.fromJson(action))
              .toList() ??
          [],
      data: json['data'] != null
          ? NotificationData.fromJson(json['data'])
          : null,
      deliveryMethod: _parseString(json['deliveryMethod']) ?? 'in_app',
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      isArchived: json['isArchived'] ?? false,
      archivedAt: json['archivedAt'] != null
          ? DateTime.parse(json['archivedAt'])
          : null,
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.parse(json['scheduledFor'])
          : null,
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      version: json['version'] ?? 1,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Create a copy of this notification with updated fields
  NotificationModel copyWith({
    String? id,
    String? type,
    String? category,
    String? title,
    String? message,
    String? icon,
    String? color,
    String? imageUrl,
    String? priority,
    bool? requiresAction,
    List<NotificationAction>? actionButtons,
    NotificationData? data,
    String? deliveryMethod,
    bool? isRead,
    DateTime? readAt,
    bool? isArchived,
    DateTime? archivedAt,
    DateTime? scheduledFor,
    DateTime? sentAt,
    DateTime? expiresAt,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      imageUrl: imageUrl ?? this.imageUrl,
      priority: priority ?? this.priority,
      requiresAction: requiresAction ?? this.requiresAction,
      actionButtons: actionButtons ?? this.actionButtons,
      data: data ?? this.data,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      sentAt: sentAt ?? this.sentAt,
      expiresAt: expiresAt ?? this.expiresAt,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'category': category,
      'title': title,
      'message': message,
      'icon': icon,
      'color': color,
      'imageUrl': imageUrl,
      'priority': priority,
      'requiresAction': requiresAction,
      'actionButtons': actionButtons.map((action) => action.toJson()).toList(),
      'data': data?.toJson(),
      'deliveryMethod': deliveryMethod,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'isArchived': isArchived,
      'archivedAt': archivedAt?.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get priority color
  Color get priorityColor {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'normal':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  /// Get category icon
  IconData get categoryIcon {
    switch (category) {
      case 'budget':
        return Icons.account_balance_wallet;
      case 'expense':
        return Icons.shopping_cart;
      case 'challenge':
        return Icons.emoji_events;
      case 'group':
        return Icons.group;
      case 'social':
        return Icons.favorite;
      case 'system':
        return Icons.notifications;
      case 'insights':
        return Icons.analytics;
      case 'savings':
        return Icons.savings;
      case 'reminder':
        return Icons.schedule;
      default:
        return Icons.notifications;
    }
  }

  /// Check if notification is expired
  bool get isExpired {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  /// Check if notification can be delivered
  bool get canBeDelivered {
    if (isExpired) return false;
    if (sentAt != null) return false;
    if (scheduledFor != null && DateTime.now().isBefore(scheduledFor!))
      return false;
    return true;
  }
}

/// Notification action button
class NotificationAction {
  final String text;
  final String action;
  final Map<String, dynamic>? actionData;

  const NotificationAction({
    required this.text,
    required this.action,
    this.actionData,
  });

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      text: json['text'] ?? '',
      action: json['action'] ?? '',
      actionData: json['actionData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'action': action, 'actionData': actionData};
  }
}

/// Notification data payload
class NotificationData {
  final String? challengeId;
  final String? challengeName;
  final int? milestoneDay;
  final int? pointsEarned;
  final String? budgetId;
  final String? budgetName;
  final String? category;
  final double? spentPercentage;
  final double? remainingAmount;
  final String? expenseId;
  final double? expenseAmount;
  final String? groupId;
  final String? groupName;
  final String? memberName;
  final String? fromUserId;
  final String? fromUserName;
  final String? goalId;
  final String? goalName;
  final double? goalAmount;
  final double? currentAmount;
  final Map<String, dynamic>? customData;

  const NotificationData({
    this.challengeId,
    this.challengeName,
    this.milestoneDay,
    this.pointsEarned,
    this.budgetId,
    this.budgetName,
    this.category,
    this.spentPercentage,
    this.remainingAmount,
    this.expenseId,
    this.expenseAmount,
    this.groupId,
    this.groupName,
    this.memberName,
    this.fromUserId,
    this.fromUserName,
    this.goalId,
    this.goalName,
    this.goalAmount,
    this.currentAmount,
    this.customData,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      challengeId: _parseString(json['challengeId']),
      challengeName: _parseString(json['challengeName']),
      milestoneDay: json['milestoneDay'],
      pointsEarned: json['pointsEarned'],
      budgetId: _parseString(json['budgetId']),
      budgetName: _parseString(json['budgetName']),
      category: _parseString(json['category']),
      spentPercentage: _parseDouble(json['spentPercentage']),
      remainingAmount: _parseDouble(json['remainingAmount']),
      expenseId: _parseString(json['expenseId']),
      expenseAmount: _parseDouble(json['expenseAmount']),
      groupId: _parseString(json['groupId']),
      groupName: _parseString(json['groupName']),
      memberName: _parseString(json['memberName']),
      fromUserId: _parseString(json['fromUserId']),
      fromUserName: _parseString(json['fromUserName']),
      goalId: _parseString(json['goalId']),
      goalName: _parseString(json['goalName']),
      goalAmount: _parseDouble(json['goalAmount']),
      currentAmount: _parseDouble(json['currentAmount']),
      customData: json['customData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'challengeName': challengeName,
      'milestoneDay': milestoneDay,
      'pointsEarned': pointsEarned,
      'budgetId': budgetId,
      'budgetName': budgetName,
      'category': category,
      'spentPercentage': spentPercentage,
      'remainingAmount': remainingAmount,
      'expenseId': expenseId,
      'expenseAmount': expenseAmount,
      'groupId': groupId,
      'groupName': groupName,
      'memberName': memberName,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'goalId': goalId,
      'goalName': goalName,
      'goalAmount': goalAmount,
      'currentAmount': currentAmount,
      'customData': customData,
    };
  }
}

/// Notification pagination info
class NotificationPagination {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;
  final bool hasPrevPage;

  const NotificationPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalCount: json['totalCount'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
    );
  }
}

/// Notification statistics
class NotificationStats {
  final int unreadCount;
  final List<CategoryStats> categoryStats;

  const NotificationStats({
    required this.unreadCount,
    required this.categoryStats,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      unreadCount: json['unreadCount'] ?? 0,
      categoryStats:
          (json['categoryStats'] as List?)
              ?.map((stats) => CategoryStats.fromJson(stats))
              .toList() ??
          [],
    );
  }
}

/// Category statistics
class CategoryStats {
  final String category;
  final int count;

  const CategoryStats({required this.category, required this.count});

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      category: json['_id'] ?? json['category'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}
