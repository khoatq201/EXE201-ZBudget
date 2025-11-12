import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/auth_utils.dart';
import '../models/settings/notification_settings.dart';
import '../config/api_config.dart';

class NotificationApiService {
  static String get baseUrl => ApiConfig.baseUrl + '/settings';

  /// Get notification settings from backend
  static Future<NotificationSettings?> getNotificationSettings() async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final notificationData = data['data']['notificationSettings'];
          return NotificationSettings.fromJson(notificationData);
        }
      }
      return null;
    } catch (e) {
      print('Error getting notification settings: $e');
      return null;
    }
  }

  /// Update notification settings on backend
  static Future<bool> updateNotificationSettings(
    NotificationSettings settings,
  ) async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final requestBody = {'notifications': settings.toJson()};

      print(
        'NotificationApiService: Sending request to $baseUrl/notifications',
      );
      print('NotificationApiService: Request body JSON:');
      print(jsonEncode(requestBody));

      final response = await http.put(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('NotificationApiService: Response status: ${response.statusCode}');
      print('NotificationApiService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        print(
          'NotificationApiService: Error ${response.statusCode}: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print(
        'NotificationApiService: Exception updating notification settings: $e',
      );
      return false;
    }
  }

  /// Update specific notification type settings
  static Future<bool> updateNotificationTypeSettings(
    NotificationType type,
    NotificationSetting setting,
  ) async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/notifications/${type.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(setting.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating notification type settings: $e');
      return false;
    }
  }

  /// Toggle all notifications on/off
  static Future<bool> toggleAllNotifications(bool enabled) async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/notifications/toggle-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'enabled': enabled}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error toggling all notifications: $e');
      return false;
    }
  }
}
