import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../utils/secure_storage_manager.dart';

/// Notification Sync Service - Đồng bộ notifications với backend
class NotificationSyncService extends ChangeNotifier {
  static const String baseUrl = 'http://10.0.2.2:3000/api/notifications';

  List<NotificationModel> _notifications = [];
  NotificationPagination? _pagination;
  NotificationStats? _stats;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  NotificationPagination? get pagination => _pagination;
  NotificationStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _stats?.unreadCount ?? 0;

  /// Get authorization header
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorageManager.getToken();

    if (token == null) {
      throw Exception('No access token found. Please login again.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Handle API errors
  void _handleError(dynamic error, String context) {
    debugPrint('❌ Error in $context: $error');
    _error = error.toString();
    _isLoading = false;
    notifyListeners();
  }

  /// Fetch notifications from backend
  Future<void> fetchNotifications({
    int page = 1,
    int limit = 20,
    String? category,
    bool? isRead,
    String? priority,
    String? type,
    String sort = '-createdAt',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': sort,
      };

      if (category != null) queryParams['category'] = category;
      if (isRead != null) queryParams['isRead'] = isRead.toString();
      if (priority != null) queryParams['priority'] = priority;
      if (type != null) queryParams['type'] = type;

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _notifications = (data['data']['notifications'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();
          _pagination = NotificationPagination.fromJson(
            data['data']['pagination'],
          );
          _error = null;
        } else {
          _handleError(
            data['error'] ?? 'Failed to fetch notifications',
            'fetchNotifications',
          );
        }
      } else {
        _handleError(
          'HTTP ${response.statusCode}: ${response.body}',
          'fetchNotifications',
        );
      }
    } catch (error) {
      _handleError(error, 'fetchNotifications');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/unread-count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']['unreadCount'] ?? 0;
        }
      }
      return 0;
    } catch (error) {
      debugPrint('❌ Failed to get unread count: $error');
      return 0;
    }
  }

  /// Get notification statistics
  Future<NotificationStats?> getNotificationStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _stats = NotificationStats.fromJson(data['data']);
          return _stats;
        }
      }
      return null;
    } catch (error) {
      debugPrint('❌ Failed to get notification stats: $error');
      return null;
    }
  }

  /// Get notifications by category
  Future<List<NotificationModel>> getNotificationsByCategory(
    String category, {
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/by-category/$category?limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data']['notifications'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (error) {
      debugPrint('❌ Failed to get notifications by category: $error');
      return [];
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$notificationId/read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update local notification
          final index = _notifications.indexWhere(
            (n) => n.id == notificationId,
          );
          if (index != -1) {
            _notifications[index] = _notifications[index].copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
            notifyListeners();
          }
          return true;
        }
      }
      return false;
    } catch (error) {
      debugPrint('❌ Failed to mark notification as read: $error');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead({String? category}) async {
    try {
      final headers = await _getHeaders();
      final body = category != null ? {'category': category} : {};

      final response = await http.put(
        Uri.parse('$baseUrl/mark-all-read'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update local notifications
          _notifications = _notifications.map((notification) {
            if (category == null || notification.category == category) {
              return notification.copyWith(
                isRead: true,
                readAt: DateTime.now(),
              );
            }
            return notification;
          }).toList();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (error) {
      debugPrint('❌ Failed to mark all notifications as read: $error');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$notificationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Remove from local list
          _notifications.removeWhere((n) => n.id == notificationId);
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (error) {
      debugPrint('❌ Failed to delete notification: $error');
      return false;
    }
  }

  /// Create test notification (dev only)
  Future<bool> createTestNotification({
    String type = 'system',
    String title = 'Test Notification',
    String message = 'This is a test notification',
    String category = 'system',
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'type': type,
        'title': title,
        'message': message,
        'category': category,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/test'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Refresh notifications
          await fetchNotifications();
          return true;
        }
      }
      return false;
    } catch (error) {
      debugPrint('❌ Failed to create test notification: $error');
      return false;
    }
  }

  /// Sync notifications (refresh from backend)
  Future<void> syncNotifications() async {
    await fetchNotifications();
    await getNotificationStats();
  }

  /// Get filtered notifications
  List<NotificationModel> getFilteredNotifications({
    String? category,
    bool? isRead,
    String? priority,
    String? type,
  }) {
    return _notifications.where((notification) {
      if (category != null && notification.category != category) return false;
      if (isRead != null && notification.isRead != isRead) return false;
      if (priority != null && notification.priority != priority) return false;
      if (type != null && notification.type != type) return false;
      return true;
    }).toList();
  }

  /// Get unread notifications
  List<NotificationModel> get unreadNotifications {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Get notifications by category
  List<NotificationModel> getNotificationsByCategoryLocal(String category) {
    return _notifications.where((n) => n.category == category).toList();
  }

  /// Get high priority notifications
  List<NotificationModel> get highPriorityNotifications {
    return _notifications
        .where((n) => n.priority == 'high' || n.priority == 'urgent')
        .toList();
  }

  /// Clear all notifications
  void clearNotifications() {
    _notifications.clear();
    _pagination = null;
    _stats = null;
    _error = null;
    notifyListeners();
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await syncNotifications();
  }
}
