import 'package:flutter/material.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';

/// Notification Helper - Utility functions for notifications
class NotificationHelper {
  /// Schedule default notifications for new users
  static Future<void> scheduleDefaultNotifications() async {
    try {
      final localService = LocalNotificationService();

      // Daily expense reminder at 21:00
      await localService.scheduleDailyNotification(
        id: 100,
        time: const TimeOfDay(hour: 21, minute: 0),
        title: '📝 Nhắc ghi chi tiêu',
        body:
            'Bạn chưa ghi chi tiêu hôm nay. Hãy cập nhật để theo dõi tài chính tốt hơn!',
        payload: '/add-expense',
        channelId: 'finance_daily',
      );

      // Weekly report on Sunday at 08:00
      await localService.scheduleWeeklyNotification(
        id: 200,
        weekday: 7, // Sunday
        time: const TimeOfDay(hour: 8, minute: 0),
        title: '📊 Báo cáo tuần',
        body: 'Báo cáo tài chính tuần này đã sẵn sàng.',
        payload: '/notifications',
        channelId: 'finance_insights',
      );

      // Monthly budget summary on 1st at 09:00
      await localService.scheduleNotificationAt(
        id: 300,
        dateTime: _getNextFirstOfMonth(),
        title: '📈 Tóm tắt ngân sách tháng',
        body: 'Xem báo cáo ngân sách tháng vừa qua.',
        payload: '/reports',
        channelId: 'finance_insights',
      );

      debugPrint('✅ Default notifications scheduled');
    } catch (e) {
      debugPrint('❌ Failed to schedule default notifications: $e');
    }
  }

  /// Schedule expense reminder
  static Future<void> scheduleExpenseReminder(TimeOfDay time) async {
    try {
      final localService = LocalNotificationService();

      await localService.scheduleDailyNotification(
        id: 100,
        time: time,
        title: '📝 Nhắc ghi chi tiêu',
        body: 'Bạn đã ghi chi tiêu hôm nay chưa?',
        payload: '/add-expense',
        channelId: 'finance_daily',
      );

      debugPrint('✅ Expense reminder scheduled for ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('❌ Failed to schedule expense reminder: $e');
    }
  }

  /// Schedule bill reminder
  static Future<void> scheduleBillReminder({
    required String billName,
    required DateTime dueDate,
    required double amount,
  }) async {
    try {
      final localService = LocalNotificationService();
      final now = DateTime.now();
      final daysUntilDue = dueDate.difference(now).inDays;

      // Schedule reminder 3 days before due date
      final reminderDate = dueDate.subtract(const Duration(days: 3));

      if (reminderDate.isAfter(now)) {
        await localService.scheduleNotificationAt(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          dateTime: reminderDate,
          title: '📅 Nhắc nhở hóa đơn',
          body:
              'Hóa đơn $billName đến hạn trong $daysUntilDue ngày. Số tiền: ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
          payload: '/bills',
          channelId: 'finance_bills',
        );
      }

      debugPrint('✅ Bill reminder scheduled for $billName');
    } catch (e) {
      debugPrint('❌ Failed to schedule bill reminder: $e');
    }
  }

  /// Handle notification action
  static void handleNotificationAction(
    String action,
    Map<String, dynamic>? data,
  ) {
    debugPrint('🔗 Handling notification action: $action');

    switch (action) {
      case 'add_expense':
        // Navigate to add expense screen
        debugPrint('📝 Navigate to add expense');
        break;
      case 'view_budget':
        final budgetId = data?['budgetId'];
        if (budgetId != null) {
          debugPrint('💰 Navigate to budget: $budgetId');
        }
        break;
      case 'view_expense':
        final expenseId = data?['expenseId'];
        if (expenseId != null) {
          debugPrint('🛒 Navigate to expense: $expenseId');
        }
        break;
      case 'mark_bill_paid':
        final billName = data?['billName'];
        if (billName != null) {
          debugPrint('✅ Mark bill as paid: $billName');
        }
        break;
      case 'add_savings_contribution':
        final goalId = data?['goalId'];
        if (goalId != null) {
          debugPrint('💰 Navigate to savings goal: $goalId');
        }
        break;
      case 'snooze':
        final hours = data?['hours'] ?? 2;
        debugPrint('⏰ Snooze notification for $hours hours');
        break;
      case 'dismiss':
        debugPrint('❌ Dismiss notification');
        break;
      default:
        debugPrint('❓ Unknown action: $action');
    }
  }

  /// Show test notification
  static Future<void> showTestNotification() async {
    try {
      final localService = LocalNotificationService();

      await localService.showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: '🧪 Test Notification',
        body: 'This is a test notification from ZBudget',
        payload: '/dashboard',
        channelId: 'finance_daily',
      );

      debugPrint('✅ Test notification shown');
    } catch (e) {
      debugPrint('❌ Failed to show test notification: $e');
    }
  }

  /// Check notification permissions
  static Future<bool> checkPermissions() async {
    try {
      final localService = LocalNotificationService();
      return await localService.hasPermission();
    } catch (e) {
      debugPrint('❌ Failed to check permissions: $e');
      return false;
    }
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    try {
      final localService = LocalNotificationService();
      return await localService.requestPermission();
    } catch (e) {
      debugPrint('❌ Failed to request permissions: $e');
      return false;
    }
  }

  /// Get pending notifications count
  static Future<int> getPendingCount() async {
    try {
      final localService = LocalNotificationService();
      final pending = await localService.getPendingNotifications();
      return pending.length;
    } catch (e) {
      debugPrint('❌ Failed to get pending count: $e');
      return 0;
    }
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      final localService = LocalNotificationService();
      await localService.cancelAllNotifications();
      debugPrint('✅ All notifications cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear notifications: $e');
    }
  }

  /// Format notification time
  static String formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  /// Get notification priority color
  static Color getPriorityColor(String priority) {
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

  /// Get notification category icon
  static IconData getCategoryIcon(String category) {
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

  /// Get next first of month for monthly notifications
  static DateTime _getNextFirstOfMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1, 9, 0);
    return nextMonth;
  }

  /// Validate notification settings
  static bool validateNotificationSettings({
    required bool isGlobalEnabled,
    required List<Map<String, dynamic>> notificationSettings,
  }) {
    if (!isGlobalEnabled) return true;

    for (final setting in notificationSettings) {
      if (setting['isEnabled'] == true) {
        final frequency = setting['frequency'];
        final scheduledTime = setting['scheduledTime'];

        if (frequency == 'daily' && scheduledTime == null) {
          return false;
        }
      }
    }

    return true;
  }

  /// Get notification channel name
  static String getChannelName(String channelId) {
    switch (channelId) {
      case 'finance_daily':
        return 'Nhắc nhở hàng ngày';
      case 'finance_bills':
        return 'Hóa đơn sắp hết hạn';
      case 'finance_alerts':
        return 'Cảnh báo vượt ngân sách';
      case 'finance_insights':
        return 'Báo cáo & Insights';
      case 'finance_savings':
        return 'Nhắc tiết kiệm';
      default:
        return 'Thông báo tài chính';
    }
  }

  /// Get notification channel description
  static String getChannelDescription(String channelId) {
    switch (channelId) {
      case 'finance_daily':
        return 'Nhắc ghi chi tiêu, báo cáo hàng ngày';
      case 'finance_bills':
        return 'Nhắc nhở thanh toán hóa đơn, subscription';
      case 'finance_alerts':
        return 'Cảnh báo khi vượt ngân sách, chi tiêu bất thường';
      case 'finance_insights':
        return 'Báo cáo tuần/tháng, phân tích tài chính';
      case 'finance_savings':
        return 'Nhắc nhở mục tiêu tiết kiệm, đóng góp định kỳ';
      default:
        return 'Thông báo từ ứng dụng ZBudget';
    }
  }
}
