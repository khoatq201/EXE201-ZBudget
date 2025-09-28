import 'package:flutter/material.dart';

// Notification types
enum NotificationType {
  budget('budget', 'Ngân sách', Icons.account_balance_wallet),
  expense('expense', 'Chi tiêu', Icons.shopping_cart),
  income('income', 'Thu nhập', Icons.attach_money),
  challenge('challenge', 'Thử thách', Icons.emoji_events),
  reminder('reminder', 'Nhắc nhở', Icons.schedule),
  achievement('achievement', 'Thành tích', Icons.star),
  security('security', 'Bảo mật', Icons.security),
  system('system', 'Hệ thống', Icons.notifications),
  marketing('marketing', 'Khuyến mãi', Icons.local_offer);

  const NotificationType(this.id, this.displayName, this.icon);

  final String id;
  final String displayName;
  final IconData icon;
}

// Notification frequency
enum NotificationFrequency {
  immediately('immediately', 'Ngay lập tức'),
  daily('daily', 'Hàng ngày'),
  weekly('weekly', 'Hàng tuần'),
  monthly('monthly', 'Hàng tháng'),
  never('never', 'Không bao giờ');

  const NotificationFrequency(this.id, this.displayName);

  final String id;
  final String displayName;
}

// Quiet hours
class QuietHours {
  final bool isEnabled;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<int> selectedDays; // 1=Monday, 7=Sunday

  const QuietHours({
    this.isEnabled = false,
    this.startTime = const TimeOfDay(hour: 22, minute: 0),
    this.endTime = const TimeOfDay(hour: 7, minute: 0),
    this.selectedDays = const [1, 2, 3, 4, 5, 6, 7], // All days
  });

  QuietHours copyWith({
    bool? isEnabled,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<int>? selectedDays,
  }) {
    return QuietHours(
      isEnabled: isEnabled ?? this.isEnabled,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      selectedDays: selectedDays ?? this.selectedDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'selectedDays': selectedDays,
    };
  }

  factory QuietHours.fromJson(Map<String, dynamic> json) {
    final startTimeParts = json['startTime'].split(':');
    final endTimeParts = json['endTime'].split(':');

    return QuietHours(
      isEnabled: json['isEnabled'] ?? false,
      startTime: TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      ),
      selectedDays: List<int>.from(
        json['selectedDays'] ?? [1, 2, 3, 4, 5, 6, 7],
      ),
    );
  }

  String get timeRangeText {
    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  String get daysText {
    final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    if (selectedDays.length == 7) return 'Hàng ngày';
    if (selectedDays.length == 5 && selectedDays.every((day) => day <= 5))
      return 'Thứ 2 - Thứ 6';
    if (selectedDays.length == 2 &&
        selectedDays.contains(6) &&
        selectedDays.contains(7))
      return 'Cuối tuần';

    return selectedDays.map((day) => dayNames[day - 1]).join(', ');
  }
}

// Individual notification setting
class NotificationSetting {
  final NotificationType type;
  final bool isEnabled;
  final bool showBadge;
  final bool playSound;
  final bool vibrate;
  final NotificationFrequency frequency;
  final TimeOfDay? scheduledTime;

  const NotificationSetting({
    required this.type,
    this.isEnabled = true,
    this.showBadge = true,
    this.playSound = true,
    this.vibrate = true,
    this.frequency = NotificationFrequency.immediately,
    this.scheduledTime,
  });

  NotificationSetting copyWith({
    NotificationType? type,
    bool? isEnabled,
    bool? showBadge,
    bool? playSound,
    bool? vibrate,
    NotificationFrequency? frequency,
    TimeOfDay? scheduledTime,
  }) {
    return NotificationSetting(
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      showBadge: showBadge ?? this.showBadge,
      playSound: playSound ?? this.playSound,
      vibrate: vibrate ?? this.vibrate,
      frequency: frequency ?? this.frequency,
      scheduledTime: scheduledTime ?? this.scheduledTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.id,
      'isEnabled': isEnabled,
      'showBadge': showBadge,
      'playSound': playSound,
      'vibrate': vibrate,
      'frequency': frequency.id,
      'scheduledTime': scheduledTime != null
          ? '${scheduledTime!.hour}:${scheduledTime!.minute}'
          : null,
    };
  }

  factory NotificationSetting.fromJson(Map<String, dynamic> json) {
    TimeOfDay? scheduledTime;
    if (json['scheduledTime'] != null) {
      final timeParts = json['scheduledTime'].split(':');
      scheduledTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }

    return NotificationSetting(
      type: NotificationType.values.firstWhere(
        (type) => type.id == json['type'],
        orElse: () => NotificationType.system,
      ),
      isEnabled: json['isEnabled'] ?? true,
      showBadge: json['showBadge'] ?? true,
      playSound: json['playSound'] ?? true,
      vibrate: json['vibrate'] ?? true,
      frequency: NotificationFrequency.values.firstWhere(
        (freq) => freq.id == json['frequency'],
        orElse: () => NotificationFrequency.immediately,
      ),
      scheduledTime: scheduledTime,
    );
  }
}

// Main notification settings class
class NotificationSettings {
  final bool isGlobalEnabled;
  final List<NotificationSetting> notificationSettings;
  final QuietHours quietHours;
  final bool groupNotifications;
  final bool showPreviewInNotifications;
  final String notificationSound;
  final int maxNotificationsPerDay;
  final bool enableSmartNotifications;

  const NotificationSettings({
    this.isGlobalEnabled = true,
    this.notificationSettings = const [],
    this.quietHours = const QuietHours(),
    this.groupNotifications = true,
    this.showPreviewInNotifications = true,
    this.notificationSound = 'default',
    this.maxNotificationsPerDay = 50,
    this.enableSmartNotifications = true,
  });

  NotificationSettings copyWith({
    bool? isGlobalEnabled,
    List<NotificationSetting>? notificationSettings,
    QuietHours? quietHours,
    bool? groupNotifications,
    bool? showPreviewInNotifications,
    String? notificationSound,
    int? maxNotificationsPerDay,
    bool? enableSmartNotifications,
  }) {
    return NotificationSettings(
      isGlobalEnabled: isGlobalEnabled ?? this.isGlobalEnabled,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      quietHours: quietHours ?? this.quietHours,
      groupNotifications: groupNotifications ?? this.groupNotifications,
      showPreviewInNotifications:
          showPreviewInNotifications ?? this.showPreviewInNotifications,
      notificationSound: notificationSound ?? this.notificationSound,
      maxNotificationsPerDay:
          maxNotificationsPerDay ?? this.maxNotificationsPerDay,
      enableSmartNotifications:
          enableSmartNotifications ?? this.enableSmartNotifications,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isGlobalEnabled': isGlobalEnabled,
      'notificationSettings': notificationSettings
          .map((setting) => setting.toJson())
          .toList(),
      'quietHours': quietHours.toJson(),
      'groupNotifications': groupNotifications,
      'showPreviewInNotifications': showPreviewInNotifications,
      'notificationSound': notificationSound,
      'maxNotificationsPerDay': maxNotificationsPerDay,
      'enableSmartNotifications': enableSmartNotifications,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      isGlobalEnabled: json['isGlobalEnabled'] ?? true,
      notificationSettings:
          (json['notificationSettings'] as List?)
              ?.map((setting) => NotificationSetting.fromJson(setting))
              .toList() ??
          [],
      quietHours: json['quietHours'] != null
          ? QuietHours.fromJson(json['quietHours'])
          : const QuietHours(),
      groupNotifications: json['groupNotifications'] ?? true,
      showPreviewInNotifications: json['showPreviewInNotifications'] ?? true,
      notificationSound: json['notificationSound'] ?? 'default',
      maxNotificationsPerDay: json['maxNotificationsPerDay'] ?? 50,
      enableSmartNotifications: json['enableSmartNotifications'] ?? true,
    );
  }

  // Get setting for specific notification type
  NotificationSetting? getSettingForType(NotificationType type) {
    try {
      return notificationSettings.firstWhere((setting) => setting.type == type);
    } catch (e) {
      return null;
    }
  }

  // Update setting for specific type
  NotificationSettings updateSettingForType(
    NotificationType type,
    NotificationSetting newSetting,
  ) {
    final updatedSettings = notificationSettings.map((setting) {
      if (setting.type == type) {
        return newSetting;
      }
      return setting;
    }).toList();

    return copyWith(notificationSettings: updatedSettings);
  }

  // Get enabled notification count
  int get enabledNotificationCount {
    return notificationSettings.where((setting) => setting.isEnabled).length;
  }

  // Get total notification count
  int get totalNotificationCount {
    return notificationSettings.length;
  }

  // Check if all notifications are enabled
  bool get areAllNotificationsEnabled {
    return notificationSettings.every((setting) => setting.isEnabled);
  }

  // Check if any notifications are enabled
  bool get areAnyNotificationsEnabled {
    return notificationSettings.any((setting) => setting.isEnabled);
  }
}
