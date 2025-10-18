import 'package:flutter/material.dart';
import 'services/local_notification_service.dart';

/// Test script for local notifications
class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final LocalNotificationService _notificationService =
      LocalNotificationService();
  String _status = 'Ready to test notifications';

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      setState(() {
        _status = '✅ Notifications initialized successfully';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Failed to initialize: $e';
      });
    }
  }

  Future<void> _testInstantNotification() async {
    try {
      await _notificationService.showInstantNotification(
        id: 1,
        title: '🧪 Test Notification',
        body: 'This is a test notification from ZBudget!',
        payload: '/test',
      );
      setState(() {
        _status = '✅ Instant notification sent';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Failed to send instant notification: $e';
      });
    }
  }

  Future<void> _testScheduledNotification() async {
    try {
      final now = DateTime.now();
      final scheduledTime = now.add(const Duration(seconds: 5));

      await _notificationService.scheduleNotificationAt(
        id: 2,
        dateTime: scheduledTime,
        title: '⏰ Scheduled Test',
        body: 'This notification was scheduled 5 seconds ago',
        payload: '/scheduled',
      );
      setState(() {
        _status = '✅ Notification scheduled for ${scheduledTime.toString()}';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Failed to schedule notification: $e';
      });
    }
  }

  Future<void> _testDailyNotification() async {
    try {
      await _notificationService.scheduleDailyNotification(
        id: 999,
        time: const TimeOfDay(hour: 9, minute: 0),
        title: '📅 Daily Test',
        body: 'This is a daily test notification',
        payload: '/daily',
        channelId: 'finance_daily',
      );
      setState(() {
        _status = '✅ Daily notification scheduled for 9:00 AM';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Failed to schedule daily notification: $e';
      });
    }
  }

  Future<void> _testPermissionRequest() async {
    try {
      final hasPermission = await _notificationService.requestPermission();
      setState(() {
        _status = hasPermission
            ? '✅ Permission granted'
            : '❌ Permission denied';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Permission request failed: $e';
      });
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      setState(() {
        _status = '✅ All notifications cancelled';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Failed to cancel notifications: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Notification Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _testPermissionRequest,
              icon: const Icon(Icons.security),
              label: const Text('Request Permissions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _testInstantNotification,
              icon: const Icon(Icons.notifications),
              label: const Text('Send Instant Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _testScheduledNotification,
              icon: const Icon(Icons.schedule),
              label: const Text('Schedule Notification (5s)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _testDailyNotification,
              icon: const Icon(Icons.repeat),
              label: const Text('Schedule Daily Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _cancelAllNotifications,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel All Notifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Tap "Request Permissions" first'),
                    Text('2. Try "Send Instant Notification"'),
                    Text('3. Try "Schedule Notification" and wait 5 seconds'),
                    Text('4. Check if notifications appear in system tray'),
                    Text('5. Tap on notifications to test deep linking'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
