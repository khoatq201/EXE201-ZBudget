import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings/security_settings.dart';
import '../services/security_service.dart';
import '../utils/auth_helper.dart';

class SessionManager {
  static SessionManager? _instance;
  static SessionManager get instance => _instance ??= SessionManager._();
  SessionManager._();

  Timer? _sessionTimer;
  DateTime? _lastActivityTime;
  bool _isActive = false;

  /// Bắt đầu session tracking sau khi login thành công
  void startSession(BuildContext context) {
    debugPrint('🔐 SessionManager: Starting session tracking');
    _lastActivityTime = DateTime.now();
    _isActive = true;
    _startSessionTimer(context);
  }

  /// Dừng session tracking khi logout
  void stopSession() {
    debugPrint('🔐 SessionManager: Stopping session tracking');
    _sessionTimer?.cancel();
    _isActive = false;
    _lastActivityTime = null;
  }

  /// Cập nhật thời gian hoạt động cuối cùng
  void updateActivity() {
    if (_isActive) {
      _lastActivityTime = DateTime.now();
      debugPrint('🔐 SessionManager: Activity updated at ${_lastActivityTime}');
    }
  }

  /// Bắt đầu timer check session timeout
  void _startSessionTimer(BuildContext context) {
    _sessionTimer?.cancel();

    _sessionTimer = Timer.periodic(
      const Duration(minutes: 1), // Check mỗi phút
      (timer) => _checkSessionTimeout(context),
    );
  }

  /// Kiểm tra có timeout không
  void _checkSessionTimeout(BuildContext context) async {
    if (!_isActive || _lastActivityTime == null) return;

    try {
      final securityService = Provider.of<SecurityService>(
        context,
        listen: false,
      );
      final settings = securityService.securitySettings;

      // Lấy timeout duration từ settings
      final timeoutDuration = _getTimeoutDuration(settings.sessionTimeout);

      // Nếu là "never" thì không timeout
      if (timeoutDuration == null) return;

      final timeSinceLastActivity = DateTime.now().difference(
        _lastActivityTime!,
      );

      debugPrint(
        '🔐 SessionManager: Time since last activity: ${timeSinceLastActivity.inMinutes} minutes',
      );
      debugPrint(
        '🔐 SessionManager: Timeout setting: ${timeoutDuration.inMinutes} minutes',
      );

      if (timeSinceLastActivity >= timeoutDuration) {
        debugPrint('🔐 SessionManager: Session timeout! Auto-logging out...');
        await _autoLogout(context);
      }
    } catch (e) {
      debugPrint('🔐 SessionManager: Error checking timeout: $e');
    }
  }

  /// Tự động logout khi timeout
  Future<void> _autoLogout(BuildContext context) async {
    try {
      stopSession();

      // Show dialog trước khi logout
      if (context.mounted) {
        _showTimeoutDialog(context);
      }

      // Logout sau 3 giây
      await Future.delayed(const Duration(seconds: 3));

      if (context.mounted) {
        await AuthHelper.safeLogout(context);
      }
    } catch (e) {
      debugPrint('🔐 SessionManager: Error during auto-logout: $e');
    }
  }

  /// Hiện dialog thông báo timeout
  void _showTimeoutDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.timer_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('Phiên làm việc hết hạn'),
            ],
          ),
          content: const Text(
            'Bạn đã không hoạt động trong thời gian dài. '
            'Hệ thống sẽ tự động đăng xuất để bảo mật tài khoản.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đã hiểu'),
            ),
          ],
        );
      },
    );
  }

  /// Convert SessionTimeout enum thành Duration
  Duration? _getTimeoutDuration(SessionTimeout timeout) {
    switch (timeout) {
      case SessionTimeout.never:
        return null; // Không timeout
      case SessionTimeout.minutes5:
        return const Duration(minutes: 5);
      case SessionTimeout.minutes15:
        return const Duration(minutes: 15);
      case SessionTimeout.minutes30:
        return const Duration(minutes: 30);
      case SessionTimeout.hour1:
        return const Duration(hours: 1);
      case SessionTimeout.hour4:
        return const Duration(hours: 4);
    }
  }

  /// Kiểm tra session có đang active không
  bool get isSessionActive => _isActive;

  /// Lấy thời gian hoạt động cuối
  DateTime? get lastActivityTime => _lastActivityTime;
}
