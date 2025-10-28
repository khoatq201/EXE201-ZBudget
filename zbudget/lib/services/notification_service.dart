import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings/notification_settings.dart';
import '../services/notification_api_service.dart';
import '../services/local_notification_service.dart';
import '../utils/auth_utils.dart';

class NotificationService extends ChangeNotifier {
  static const String _notificationKey = 'notification_settings';
  NotificationSettings _notificationSettings = const NotificationSettings();
  bool _isLoading = false;

  NotificationSettings get notificationSettings => _notificationSettings;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Initialize local notification service
      await LocalNotificationService().initialize();

      await _loadNotificationSettings();

      // Schedule notifications based on settings
      await _scheduleUserNotifications();
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      // Try to load from backend first if authenticated
      final isAuthenticated = await AuthUtils.isAuthenticated();
      if (isAuthenticated) {
        final backendSettings =
            await NotificationApiService.getNotificationSettings();
        if (backendSettings != null) {
          _notificationSettings = backendSettings;
          // Save to local storage as backup
          await _saveNotificationSettings();
          return;
        }
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_notificationKey);

      if (settingsJson != null) {
        final settingsData = jsonDecode(settingsJson);
        _notificationSettings = NotificationSettings.fromJson(settingsData);
      } else {
        // Create default notification settings
        _notificationSettings = _createDefaultNotificationSettings();
        await _saveNotificationSettings();
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      _notificationSettings = _createDefaultNotificationSettings();
    }
  }

  NotificationSettings _createDefaultNotificationSettings() {
    final defaultSettings = NotificationType.values.map((type) {
      // Set different defaults for different notification types
      switch (type) {
        case NotificationType.budget:
          return NotificationSetting(
            type: type,
            isEnabled: true,
            showBadge: true,
            playSound: true,
            vibrate: false,
            frequency: NotificationFrequency.daily,
            scheduledTime: const TimeOfDay(hour: 20, minute: 0),
          );
        case NotificationType.expense:
          return NotificationSetting(
            type: type,
            isEnabled: true,
            showBadge: true,
            playSound: false,
            vibrate: true,
            frequency: NotificationFrequency.immediately,
          );
        case NotificationType.income:
          return NotificationSetting(
            type: type,
            isEnabled: true,
            showBadge: true,
            playSound: true,
            vibrate: true,
            frequency: NotificationFrequency.immediately,
          );
        case NotificationType.challenge:
          return NotificationSetting(
            type: type,
            isEnabled: true,
            showBadge: true,
            playSound: true,
            vibrate: false,
            frequency: NotificationFrequency.daily,
            scheduledTime: const TimeOfDay(hour: 9, minute: 0),
          );
        case NotificationType.reminder:
          return NotificationSetting(
            type: type,
            isEnabled: true,
            showBadge: false,
            playSound: true,
            vibrate: true,
            frequency: NotificationFrequency.immediately,
          );
        case NotificationType.achievement:
          return NotificationSetting(
            type: type,
            isEnabled: true,
            showBadge: true,
            playSound: true,
            vibrate: true,
            frequency: NotificationFrequency.immediately,
          );
        case NotificationType.security:
          return NotificationSetting(
            type: type,
            isEnabled: true,
            showBadge: true,
            playSound: true,
            vibrate: true,
            frequency: NotificationFrequency.immediately,
          );
        case NotificationType.system:
          return NotificationSetting(
            type: type,
            isEnabled: false,
            showBadge: false,
            playSound: false,
            vibrate: false,
            frequency: NotificationFrequency.never,
          );
        case NotificationType.marketing:
          return NotificationSetting(
            type: type,
            isEnabled: false,
            showBadge: false,
            playSound: false,
            vibrate: false,
            frequency: NotificationFrequency.weekly,
          );
      }
    }).toList();

    return NotificationSettings(
      isGlobalEnabled: true,
      notificationSettings: defaultSettings,
      quietHours: const QuietHours(
        isEnabled: false,
        startTime: TimeOfDay(hour: 22, minute: 0),
        endTime: TimeOfDay(hour: 7, minute: 0),
        selectedDays: [1, 2, 3, 4, 5, 6, 7], // All days
      ),
      groupNotifications: true,
      showPreviewInNotifications: true,
      notificationSound: 'default',
      maxNotificationsPerDay: 50,
      enableSmartNotifications: true,
    );
  }

  Future<void> updateNotificationSettings(
    NotificationSettings newSettings,
  ) async {
    try {
      // Update settings immediately for optimistic UI
      _notificationSettings = newSettings;
      notifyListeners();

      // Save locally
      await _saveNotificationSettings();

      // Then sync with backend without showing loading
      final isAuthenticated = await AuthUtils.isAuthenticated();
      if (isAuthenticated) {
        try {
          await NotificationApiService.updateNotificationSettings(newSettings);
        } catch (e) {
          debugPrint('Error syncing with backend: $e');
          // Don't throw error for backend sync failure to prevent UI disruption
        }
      }

      // Reschedule local notifications based on new settings
      await _scheduleUserNotifications();
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
      // Only reload on critical error
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_notificationSettings.toJson());
      await prefs.setString(_notificationKey, settingsJson);
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
      rethrow;
    }
  }

  // Global notification toggle
  Future<void> toggleGlobalNotifications(bool enabled) async {
    if (enabled) {
      // When enabling global notifications, enable all individual notifications
      final updatedNotificationSettings = _notificationSettings
          .notificationSettings
          .map((setting) {
            return setting.copyWith(isEnabled: true);
          })
          .toList();

      final updatedSettings = _notificationSettings.copyWith(
        isGlobalEnabled: enabled,
        notificationSettings: updatedNotificationSettings,
      );
      await updateNotificationSettings(updatedSettings);
    } else {
      // When disabling global notifications, disable all individual notifications
      final updatedNotificationSettings = _notificationSettings
          .notificationSettings
          .map((setting) {
            return setting.copyWith(isEnabled: false);
          })
          .toList();

      final updatedSettings = _notificationSettings.copyWith(
        isGlobalEnabled: enabled,
        notificationSettings: updatedNotificationSettings,
      );
      await updateNotificationSettings(updatedSettings);
    }
  }

  // Update individual notification setting
  Future<void> updateNotificationSetting(
    NotificationType type,
    NotificationSetting newSetting,
  ) async {
    final updatedSettings = _notificationSettings.updateSettingForType(
      type,
      newSetting,
    );
    await updateNotificationSettings(updatedSettings);
  }

  // Toggle notification type
  Future<void> toggleNotificationType(
    NotificationType type,
    bool enabled,
  ) async {
    final currentSetting = _notificationSettings.getSettingForType(type);
    if (currentSetting != null) {
      final updatedSetting = currentSetting.copyWith(isEnabled: enabled);
      await updateNotificationSetting(type, updatedSetting);

      // If enabling an individual notification and global is disabled, enable global
      if (enabled && !_notificationSettings.isGlobalEnabled) {
        final updatedSettings = _notificationSettings.copyWith(
          isGlobalEnabled: true,
        );
        await updateNotificationSettings(updatedSettings);
      }
    }
  }

  // Update quiet hours
  Future<void> updateQuietHours(QuietHours quietHours) async {
    final updatedSettings = _notificationSettings.copyWith(
      quietHours: quietHours,
    );
    await updateNotificationSettings(updatedSettings);
  }

  // Toggle quiet hours
  Future<void> toggleQuietHours(bool enabled) async {
    final updatedQuietHours = _notificationSettings.quietHours.copyWith(
      isEnabled: enabled,
    );
    await updateQuietHours(updatedQuietHours);
  }

  // Update quiet hours time
  Future<void> updateQuietHoursTime(
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    final updatedQuietHours = _notificationSettings.quietHours.copyWith(
      startTime: startTime,
      endTime: endTime,
    );
    await updateQuietHours(updatedQuietHours);
  }

  // Update quiet hours days
  Future<void> updateQuietHoursDays(List<int> selectedDays) async {
    final updatedQuietHours = _notificationSettings.quietHours.copyWith(
      selectedDays: selectedDays,
    );
    await updateQuietHours(updatedQuietHours);
  }

  // Toggle group notifications
  Future<void> toggleGroupNotifications(bool enabled) async {
    final updatedSettings = _notificationSettings.copyWith(
      groupNotifications: enabled,
    );
    await updateNotificationSettings(updatedSettings);
  }

  // Toggle show preview in notifications
  Future<void> toggleShowPreviewInNotifications(bool enabled) async {
    final updatedSettings = _notificationSettings.copyWith(
      showPreviewInNotifications: enabled,
    );
    await updateNotificationSettings(updatedSettings);
  }

  // Update notification sound
  Future<void> updateNotificationSound(String sound) async {
    final updatedSettings = _notificationSettings.copyWith(
      notificationSound: sound,
    );
    await updateNotificationSettings(updatedSettings);
  }

  // Update max notifications per day
  Future<void> updateMaxNotificationsPerDay(int maxNotifications) async {
    final updatedSettings = _notificationSettings.copyWith(
      maxNotificationsPerDay: maxNotifications,
    );
    await updateNotificationSettings(updatedSettings);
  }

  // Toggle smart notifications
  Future<void> toggleSmartNotifications(bool enabled) async {
    final updatedSettings = _notificationSettings.copyWith(
      enableSmartNotifications: enabled,
    );
    await updateNotificationSettings(updatedSettings);
  }

  // Enable all notifications
  Future<void> enableAllNotifications() async {
    final updatedNotificationSettings = _notificationSettings
        .notificationSettings
        .map((setting) {
          return setting.copyWith(isEnabled: true);
        })
        .toList();

    final updatedSettings = _notificationSettings.copyWith(
      notificationSettings: updatedNotificationSettings,
    );
    await updateNotificationSettings(updatedSettings);
  }

  // Disable all notifications
  Future<void> disableAllNotifications() async {
    final updatedNotificationSettings = _notificationSettings
        .notificationSettings
        .map((setting) {
          return setting.copyWith(isEnabled: false);
        })
        .toList();

    final updatedSettings = _notificationSettings.copyWith(
      notificationSettings: updatedNotificationSettings,
    );
    await updateNotificationSettings(updatedSettings);
  }

  // Reset to default settings
  Future<void> resetToDefaults() async {
    final defaultSettings = _createDefaultNotificationSettings();
    await updateNotificationSettings(defaultSettings);
  }

  // Get notification statistics
  Map<String, dynamic> getNotificationStatistics() {
    final totalNotifications = _notificationSettings.totalNotificationCount;
    final enabledNotifications = _notificationSettings.enabledNotificationCount;
    final disabledNotifications = totalNotifications - enabledNotifications;

    final notificationsByFrequency = <NotificationFrequency, int>{};
    for (final setting in _notificationSettings.notificationSettings) {
      if (setting.isEnabled) {
        notificationsByFrequency[setting.frequency] =
            (notificationsByFrequency[setting.frequency] ?? 0) + 1;
      }
    }

    return {
      'totalNotifications': totalNotifications,
      'enabledNotifications': enabledNotifications,
      'disabledNotifications': disabledNotifications,
      'enabledPercentage': totalNotifications > 0
          ? (enabledNotifications / totalNotifications * 100).round()
          : 0,
      'notificationsByFrequency': notificationsByFrequency,
      'isQuietHoursEnabled': _notificationSettings.quietHours.isEnabled,
      'isSmartNotificationsEnabled':
          _notificationSettings.enableSmartNotifications,
    };
  }

  // Check if notification should be shown (considering quiet hours)
  bool shouldShowNotification(NotificationType type) {
    // Check global setting
    if (!_notificationSettings.isGlobalEnabled) return false;

    // Check specific notification type setting
    final setting = _notificationSettings.getSettingForType(type);
    if (setting == null || !setting.isEnabled) return false;

    // Check quiet hours
    if (_notificationSettings.quietHours.isEnabled) {
      final now = TimeOfDay.now();
      final quietStart = _notificationSettings.quietHours.startTime;
      final quietEnd = _notificationSettings.quietHours.endTime;

      // Check if current time is within quiet hours
      if (_isTimeInQuietHours(now, quietStart, quietEnd)) {
        // Only allow critical notifications during quiet hours
        if (type != NotificationType.security &&
            type != NotificationType.reminder) {
          return false;
        }
      }
    }

    return true;
  }

  bool _isTimeInQuietHours(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      // Same day range (e.g., 22:00 - 23:00)
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Overnight range (e.g., 22:00 - 07:00)
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  // Get notification recommendations
  List<String> getNotificationRecommendations() {
    final recommendations = <String>[];
    final stats = getNotificationStatistics();

    if (!_notificationSettings.isGlobalEnabled) {
      recommendations.add('Bật thông báo để không bỏ lỡ thông tin quan trọng');
      return recommendations;
    }

    if (stats['enabledNotifications'] == 0) {
      recommendations.add('Bật ít nhất một số loại thông báo quan trọng');
    }

    if (!_notificationSettings.quietHours.isEnabled) {
      recommendations.add(
        'Thiết lập giờ im lặng để tránh thông báo vào ban đêm',
      );
    }

    final budgetSetting = _notificationSettings.getSettingForType(
      NotificationType.budget,
    );
    if (budgetSetting == null || !budgetSetting.isEnabled) {
      recommendations.add(
        'Bật thông báo ngân sách để theo dõi chi tiêu hiệu quả',
      );
    }

    final challengeSetting = _notificationSettings.getSettingForType(
      NotificationType.challenge,
    );
    if (challengeSetting == null || !challengeSetting.isEnabled) {
      recommendations.add(
        'Bật thông báo thử thách để duy trì động lực tiết kiệm',
      );
    }

    if (_notificationSettings.maxNotificationsPerDay > 100) {
      recommendations.add(
        'Giảm số lượng thông báo tối đa mỗi ngày để tránh spam',
      );
    }

    if (!_notificationSettings.enableSmartNotifications) {
      recommendations.add(
        'Bật thông báo thông minh để nhận thông báo phù hợp hơn',
      );
    }

    return recommendations;
  }

  // Available notification sounds
  List<String> get availableNotificationSounds {
    return ['default', 'chime', 'bell', 'ding', 'pop', 'whistle', 'none'];
  }

  String getNotificationSoundDisplayName(String sound) {
    switch (sound) {
      case 'default':
        return 'Mặc định';
      case 'chime':
        return 'Chuông gió';
      case 'bell':
        return 'Chuông';
      case 'ding':
        return 'Tiếng ding';
      case 'pop':
        return 'Tiếng pop';
      case 'whistle':
        return 'Tiếng còi';
      case 'none':
        return 'Im lặng';
      default:
        return sound;
    }
  }

  // Format time for display
  String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Schedule local notifications based on user settings
  Future<void> _scheduleUserNotifications() async {
    try {
      if (!_notificationSettings.isGlobalEnabled) {
        // Cancel all notifications if global is disabled
        await LocalNotificationService().cancelAllNotifications();
        return;
      }

      // Cancel existing notifications first
      await LocalNotificationService().cancelAllNotifications();

      // Schedule based on individual notification settings
      for (final setting in _notificationSettings.notificationSettings) {
        if (!setting.isEnabled) continue;

        switch (setting.type) {
          case NotificationType.budget:
            if (setting.frequency == NotificationFrequency.daily &&
                setting.scheduledTime != null) {
              await LocalNotificationService().scheduleDailyNotification(
                id: 100,
                time: setting.scheduledTime!,
                title: '💰 Nhắc nhở ngân sách',
                body: 'Kiểm tra ngân sách và chi tiêu hôm nay',
                payload: '/budget',
                channelId: 'finance_daily',
              );
            }
            break;

          case NotificationType.expense:
            if (setting.frequency == NotificationFrequency.daily &&
                setting.scheduledTime != null) {
              await LocalNotificationService().scheduleDailyNotification(
                id: 200,
                time: setting.scheduledTime!,
                title: '📝 Nhắc ghi chi tiêu',
                body: 'Bạn đã ghi chi tiêu hôm nay chưa?',
                payload: '/add-expense',
                channelId: 'finance_daily',
              );
            }
            break;

          case NotificationType.reminder:
            if (setting.frequency == NotificationFrequency.daily &&
                setting.scheduledTime != null) {
              await LocalNotificationService().scheduleDailyNotification(
                id: 300,
                time: setting.scheduledTime!,
                title: '🔔 Nhắc nhở tài chính',
                body: 'Đừng quên cập nhật tình hình tài chính',
                payload: '/dashboard',
                channelId: 'finance_daily',
              );
            }
            break;

          case NotificationType.challenge:
            if (setting.frequency == NotificationFrequency.daily &&
                setting.scheduledTime != null) {
              await LocalNotificationService().scheduleDailyNotification(
                id: 400,
                time: setting.scheduledTime!,
                title: '🏆 Thử thách tiết kiệm',
                body: 'Tiếp tục thử thách tiết kiệm của bạn',
                payload: '/challenges',
                channelId: 'finance_savings',
              );
            }
            break;

          case NotificationType.achievement:
            // Achievement notifications are usually triggered by events, not scheduled
            break;

          case NotificationType.security:
            // Security notifications are usually triggered by events, not scheduled
            break;

          case NotificationType.system:
            // System notifications are usually triggered by events, not scheduled
            break;

          case NotificationType.income:
            if (setting.frequency == NotificationFrequency.daily &&
                setting.scheduledTime != null) {
              await LocalNotificationService().scheduleDailyNotification(
                id: 600,
                time: setting.scheduledTime!,
                title: '💰 Nhắc nhập thu nhập',
                body: 'Cập nhật thu nhập hôm nay',
                payload: '/income',
                channelId: 'finance_daily',
              );
            }
            break;

          case NotificationType.marketing:
            if (setting.frequency == NotificationFrequency.weekly) {
              await LocalNotificationService().scheduleWeeklyNotification(
                id: 500,
                weekday: 7, // Sunday
                time: const TimeOfDay(hour: 9, minute: 0),
                title: '📊 Báo cáo tuần',
                body: 'Xem báo cáo tài chính tuần này',
                payload: '/reports',
                channelId: 'finance_insights',
              );
            }
            break;
        }
      }

      debugPrint('✅ User notifications scheduled based on settings');
    } catch (e) {
      debugPrint('❌ Failed to schedule user notifications: $e');
    }
  }

  /// Show instant notification (for testing or immediate alerts)
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'finance_daily',
  }) async {
    try {
      await LocalNotificationService().showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        payload: payload,
        channelId: channelId,
      );
    } catch (e) {
      debugPrint('❌ Failed to show instant notification: $e');
    }
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    try {
      final pending = await LocalNotificationService()
          .getPendingNotifications();
      return pending.length;
    } catch (e) {
      debugPrint('❌ Failed to get pending notifications count: $e');
      return 0;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      return await LocalNotificationService().hasPermission();
    } catch (e) {
      debugPrint('❌ Failed to check notification permission: $e');
      return false;
    }
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    try {
      return await LocalNotificationService().requestPermission();
    } catch (e) {
      debugPrint('❌ Failed to request notification permission: $e');
      return false;
    }
  }
}
