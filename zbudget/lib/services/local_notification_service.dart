import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Local Notification Service - Quản lý local notifications
/// Singleton service để schedule và hiển thị notifications
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  final Map<String, AndroidNotificationChannel> _channels = {};

  /// Khởi tạo service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Android initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            requestCriticalPermission: true,
          );

      // Initialize plugin
      await _flutterLocalNotificationsPlugin.initialize(
        InitializationSettings(android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      _isInitialized = true;
      debugPrint('✅ LocalNotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize LocalNotificationService: $e');
      rethrow;
    }
  }

  /// Tạo notification channels cho Android
  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      final List<AndroidNotificationChannel> channels = [
        AndroidNotificationChannel(
          'finance_daily',
          'Nhắc nhở hàng ngày',
          description: 'Nhắc ghi chi tiêu, báo cáo hàng ngày',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
          ledColor: const Color.fromARGB(255, 255, 0, 0),
        ),
        AndroidNotificationChannel(
          'finance_bills',
          'Hóa đơn sắp hết hạn',
          description: 'Nhắc nhở thanh toán hóa đơn, subscription',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
          ledColor: const Color.fromARGB(255, 255, 165, 0),
        ),
        AndroidNotificationChannel(
          'finance_alerts',
          'Cảnh báo vượt ngân sách',
          description: 'Cảnh báo khi vượt ngân sách, chi tiêu bất thường',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
          ledColor: const Color.fromARGB(255, 255, 0, 0),
        ),
        AndroidNotificationChannel(
          'finance_insights',
          'Báo cáo & Insights',
          description: 'Báo cáo tuần/tháng, phân tích tài chính',
          importance: Importance.defaultImportance,
          enableVibration: false,
          enableLights: false,
        ),
        AndroidNotificationChannel(
          'finance_savings',
          'Nhắc tiết kiệm',
          description: 'Nhắc nhở mục tiêu tiết kiệm, đóng góp định kỳ',
          importance: Importance.defaultImportance,
          enableVibration: true,
          enableLights: true,
          ledColor: const Color.fromARGB(255, 0, 255, 0),
        ),
      ];

      for (final channel in channels) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);
        _channels[channel.id] = channel;
      }

      debugPrint('✅ Created ${channels.length} notification channels');
    }
  }

  /// Hiển thị notification ngay lập tức
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'finance_daily',
    Importance importance = Importance.defaultImportance,
    bool enableVibration = true,
    bool enableSound = true,
  }) async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _channels[channelId]?.name ?? 'Default',
            channelDescription: _channels[channelId]?.description,
            importance: importance,
            priority: importance == Importance.max
                ? Priority.high
                : Priority.defaultPriority,
            enableVibration: enableVibration,
            enableLights: true,
            icon: '@mipmap/ic_launcher',
            playSound: enableSound,
            visibility: NotificationVisibility.private,
            actions: _getNotificationActions(channelId),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            badgeNumber: 1,
            categoryIdentifier: 'FINANCE_NOTIFICATION',
          ),
        ),
        payload: payload,
      );

      debugPrint('✅ Instant notification shown: $title');
    } catch (e) {
      debugPrint('❌ Failed to show instant notification: $e');
      rethrow;
    }
  }

  /// Lên lịch notification hàng ngày
  Future<void> scheduleDailyNotification({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
    String? payload,
    String channelId = 'finance_daily',
    List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7], // All days
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // If time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _channels[channelId]?.name ?? 'Daily Reminders',
            channelDescription: _channels[channelId]?.description,
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            enableLights: true,
            icon: '@mipmap/ic_launcher',
            actions: _getNotificationActions(channelId),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            categoryIdentifier: 'DAILY_REMINDER',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      debugPrint(
        '✅ Daily notification scheduled: $title at ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      debugPrint('❌ Failed to schedule daily notification: $e');
      rethrow;
    }
  }

  /// Lên lịch notification hàng tuần
  Future<void> scheduleWeeklyNotification({
    required int id,
    required int weekday, // 1=Monday, 7=Sunday
    required TimeOfDay time,
    required String title,
    required String body,
    String? payload,
    String channelId = 'finance_insights',
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // Find next occurrence of the weekday
      while (scheduledDate.weekday != weekday) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // If time has passed today, schedule for next week
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _channels[channelId]?.name ?? 'Weekly Reports',
            channelDescription: _channels[channelId]?.description,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            enableVibration: false,
            enableLights: false,
            icon: '@mipmap/ic_launcher',
            actions: _getNotificationActions(channelId),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            categoryIdentifier: 'WEEKLY_REPORT',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );

      debugPrint('✅ Weekly notification scheduled: $title on weekday $weekday');
    } catch (e) {
      debugPrint('❌ Failed to schedule weekly notification: $e');
      rethrow;
    }
  }

  /// Lên lịch notification theo thời gian cụ thể
  Future<void> scheduleNotificationAt({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
    String? payload,
    String channelId = 'finance_daily',
  }) async {
    try {
      final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _channels[channelId]?.name ?? 'Scheduled',
            channelDescription: _channels[channelId]?.description,
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            enableLights: true,
            icon: '@mipmap/ic_launcher',
            actions: _getNotificationActions(channelId),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            categoryIdentifier: 'SCHEDULED_NOTIFICATION',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      debugPrint('✅ Notification scheduled: $title at $dateTime');
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
      rethrow;
    }
  }

  /// Hủy notification theo ID
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('✅ Notification cancelled: $id');
    } catch (e) {
      debugPrint('❌ Failed to cancel notification: $e');
      rethrow;
    }
  }

  /// Hủy tất cả notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('✅ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Failed to cancel all notifications: $e');
      rethrow;
    }
  }

  /// Lấy danh sách pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Failed to get pending notifications: $e');
      return [];
    }
  }

  /// Kiểm tra quyền notification
  Future<bool> hasPermission() async {
    try {
      if (Platform.isAndroid) {
        final result = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled();
        return result ?? false;
      } else if (Platform.isIOS) {
        final result = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.checkPermissions();
        return result?.isEnabled ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Failed to check notification permission: $e');
      return false;
    }
  }

  /// Xin quyền notification
  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        final result = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        return result ?? false;
      } else if (Platform.isIOS) {
        final result = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return result ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Failed to request notification permission: $e');
      return false;
    }
  }

  /// Xử lý khi user tap vào notification
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');

    // Handle different payload routes
    final payload = response.payload;
    if (payload != null) {
      _handleNotificationPayload(payload);
    }
  }

  /// Xử lý notification payload để điều hướng
  void _handleNotificationPayload(String payload) {
    // This will be handled by the main app's navigation
    // The payload should contain route information
    debugPrint('🔗 Handling notification payload: $payload');

    // Common payloads:
    // '/add-expense' -> Navigate to add expense screen
    // '/budget/{budgetId}' -> Navigate to budget detail
    // '/notifications' -> Navigate to notifications list
    // '/savings/{goalId}' -> Navigate to savings goal
  }

  /// Lấy action buttons cho notification
  List<AndroidNotificationAction> _getNotificationActions(String channelId) {
    switch (channelId) {
      case 'finance_daily':
        return [
          const AndroidNotificationAction(
            'add_expense',
            'Thêm chi tiêu',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'snooze',
            'Hoãn',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        ];
      case 'finance_bills':
        return [
          const AndroidNotificationAction(
            'mark_paid',
            'Đã trả',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          const AndroidNotificationAction(
            'view_details',
            'Xem chi tiết',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            showsUserInterface: true,
          ),
        ];
      case 'finance_alerts':
        return [
          const AndroidNotificationAction(
            'view_budget',
            'Xem ngân sách',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'dismiss',
            'Bỏ qua',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        ];
      case 'finance_savings':
        return [
          const AndroidNotificationAction(
            'add_contribution',
            'Đóng góp ngay',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'view_goal',
            'Xem mục tiêu',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            showsUserInterface: true,
          ),
        ];
      default:
        return [];
    }
  }

  /// Schedule notifications mặc định cho user
  Future<void> scheduleDefaultNotifications() async {
    try {
      // Daily expense reminder at 21:00
      await scheduleDailyNotification(
        id: 100,
        time: const TimeOfDay(hour: 21, minute: 0),
        title: '📝 Nhắc ghi chi tiêu',
        body:
            'Bạn chưa ghi chi tiêu hôm nay. Hãy cập nhật để theo dõi tài chính tốt hơn!',
        payload: '/add-expense',
        channelId: 'finance_daily',
      );

      // Weekly report on Sunday at 08:00
      await scheduleWeeklyNotification(
        id: 200,
        weekday: 7, // Sunday
        time: const TimeOfDay(hour: 8, minute: 0),
        title: '📊 Báo cáo tuần',
        body: 'Báo cáo tài chính tuần này đã sẵn sàng.',
        payload: '/notifications',
        channelId: 'finance_insights',
      );

      debugPrint('✅ Default notifications scheduled');
    } catch (e) {
      debugPrint('❌ Failed to schedule default notifications: $e');
      rethrow;
    }
  }

  /// Clear tất cả scheduled notifications và schedule lại
  Future<void> rescheduleNotifications() async {
    try {
      await cancelAllNotifications();
      await scheduleDefaultNotifications();
      debugPrint('✅ Notifications rescheduled');
    } catch (e) {
      debugPrint('❌ Failed to reschedule notifications: $e');
      rethrow;
    }
  }

  /// Getter để check initialization status
  bool get isInitialized => _isInitialized;
}
