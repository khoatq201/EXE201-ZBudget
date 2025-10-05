import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings/security_settings.dart';
import 'security_api_service.dart';

class SecurityService extends ChangeNotifier {
  static const String _securityKey = 'security_settings';
  SecuritySettings _securitySettings = const SecuritySettings();
  bool _isLoading = false;

  SecuritySettings get securitySettings => _securitySettings;
  bool get isLoading => _isLoading;

  // Biometric availability check
  bool _isBiometricAvailable = false;
  bool get isBiometricAvailable => _isBiometricAvailable;

  Future<void> initialize() async {
    _isLoading = true;
    // Defer notifyListeners to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      await _loadSecuritySettings();
      await _checkBiometricAvailability();
      await _loadActiveSessions();
    } catch (e) {
      debugPrint('Error initializing SecurityService: $e');
    } finally {
      _isLoading = false;
      // Defer notifyListeners to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> _loadSecuritySettings() async {
    try {
      // First load from local storage for immediate UI
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_securityKey);

      if (settingsJson != null) {
        final settingsData = jsonDecode(settingsJson);
        _securitySettings = SecuritySettings.fromJson(settingsData);
      } else {
        // Create default security settings with demo data
        _securitySettings = _createDefaultSecuritySettings();
        await _saveSecuritySettings();
      }

      // Then fetch from API to get latest settings
      try {
        final response = await SecurityApiService.getSecuritySettings();
        if (response['success'] == true && response['data'] != null) {
          _securitySettings = SecuritySettings.fromJson(response['data']);
          // Save updated settings to local storage
          await prefs.setString(
            _securityKey,
            jsonEncode(_securitySettings.toJson()),
          );
        }
      } catch (apiError) {
        debugPrint('API error (using local settings): $apiError');
        // Continue with local settings if API fails
      }
    } catch (e) {
      debugPrint('Error loading security settings: $e');
      _securitySettings = _createDefaultSecuritySettings();
    }
  }

  SecuritySettings _createDefaultSecuritySettings() {
    return SecuritySettings(
      isBiometricEnabled: false,
      isTwoFactorEnabled: false,
      isAutoLockEnabled: true,
      sessionTimeout: SessionTimeout.minutes30,
      isLoginNotificationEnabled: true,
      isDataEncryptionEnabled: true,
      maxFailedAttempts: 5,
      isScreenshotBlocked: false,
      isAppPinEnabled: false,
      primaryAuthMethod: AuthenticationMethod.password,
      enabledAuthMethods: const [AuthenticationMethod.password],
      lastPasswordChange: DateTime.now().subtract(const Duration(days: 45)),
      activeSessions: _getDemoSessions(),
    );
  }

  List<LoginSession> _getDemoSessions() {
    final now = DateTime.now();
    return [
      LoginSession(
        id: 'session_1',
        deviceName: 'Chrome - Windows 11',
        deviceType: 'web',
        location: 'Hồ Chí Minh, Việt Nam',
        ipAddress: '192.168.1.1',
        loginTime: now.subtract(const Duration(minutes: 5)),
        lastActiveTime: now,
        isCurrent: true,
      ),
      LoginSession(
        id: 'session_2',
        deviceName: 'iPhone 15 Pro',
        deviceType: 'mobile',
        location: 'Hồ Chí Minh, Việt Nam',
        ipAddress: '192.168.1.102',
        loginTime: now.subtract(const Duration(hours: 3)),
        lastActiveTime: now.subtract(const Duration(minutes: 30)),
        isCurrent: false,
      ),
      LoginSession(
        id: 'session_3',
        deviceName: 'Samsung Galaxy S24',
        deviceType: 'mobile',
        location: 'Hà Nội, Việt Nam',
        ipAddress: '10.0.0.45',
        loginTime: now.subtract(const Duration(days: 2)),
        lastActiveTime: now.subtract(const Duration(hours: 4)),
        isCurrent: false,
      ),
      LoginSession(
        id: 'session_4',
        deviceName: 'MacBook Pro M3',
        deviceType: 'desktop',
        location: 'Đà Nẵng, Việt Nam',
        ipAddress: '172.16.0.10',
        loginTime: now.subtract(const Duration(days: 7)),
        lastActiveTime: now.subtract(const Duration(days: 1)),
        isCurrent: false,
      ),
    ];
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      // In a real app, you would use local_auth package
      // For demo purposes, we'll simulate availability
      _isBiometricAvailable = true;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      _isBiometricAvailable = false;
    }
  }

  Future<void> _loadActiveSessions() async {
    // In a real app, this would fetch from server
    // For demo, we use the sessions from default settings
  }

  Future<void> updateSecuritySettings(SecuritySettings newSettings) async {
    try {
      debugPrint(
        '🔄 Updating security settings - Auto Lock: ${newSettings.isAutoLockEnabled}',
      );

      // First update locally for immediate UI response
      _securitySettings = newSettings;
      notifyListeners(); // Immediate UI update
      await _saveSecuritySettings();

      debugPrint(
        '✅ Local update complete - Auto Lock: ${_securitySettings.isAutoLockEnabled}',
      );

      // Then sync with API using the correct property names
      final response = await SecurityApiService.updateSecuritySettings(
        isBiometricEnabled: newSettings.isBiometricEnabled,
        isTwoFactorEnabled: newSettings.isTwoFactorEnabled,
        isAutoLockEnabled: newSettings.isAutoLockEnabled,
        sessionTimeout: _getSessionTimeoutInMinutes(newSettings.sessionTimeout),
        isLoginNotificationEnabled: newSettings.isLoginNotificationEnabled,
        isDataEncryptionEnabled: newSettings.isDataEncryptionEnabled,
        maxFailedAttempts: newSettings.maxFailedAttempts,
        isScreenshotBlocked: newSettings.isScreenshotBlocked,
        isAppPinEnabled: newSettings.isAppPinEnabled,
        primaryAuthMethod: newSettings.primaryAuthMethod.name,

        // Legacy compatibility
        biometricAuth: newSettings.isBiometricEnabled,
      );

      if (response['success'] == true) {
        debugPrint('✅ Security settings synced with server');
        // Only update with server response if it contains valid data
        if (response['data'] != null) {
          try {
            final serverSettings = SecuritySettings.fromJson(response['data']);
            // Only update if server data looks valid (not default values)
            if (serverSettings.toString() !=
                const SecuritySettings().toString()) {
              _securitySettings = serverSettings;
              await _saveSecuritySettings();
              notifyListeners(); // Update again with server data
            }
          } catch (e) {
            debugPrint(
              'Error parsing server response, keeping local changes: $e',
            );
            // Keep local changes if server response is invalid
          }
        }
      } else {
        debugPrint('⚠️ API sync failed: ${response['message']}');
        // Keep local changes even if API fails
      }

      // Trigger any necessary system-level changes
      await _applySecurityChanges();
    } catch (e) {
      debugPrint('Error updating security settings: $e');
      // Don't rethrow - keep local changes
    }
  }

  Future<void> _saveSecuritySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_securitySettings.toJson());
      await prefs.setString(_securityKey, settingsJson);
    } catch (e) {
      debugPrint('Error saving security settings: $e');
      rethrow;
    }
  }

  Future<void> _applySecurityChanges() async {
    // Apply security changes to the system
    // This would include:
    // - Setting up biometric authentication
    // - Configuring session timeouts
    // - Setting up screen recording protection
    // etc.
  }

  // Biometric Authentication
  Future<bool> enableBiometric() async {
    if (!_isBiometricAvailable) {
      throw Exception('Thiết bị không hỗ trợ sinh trắc học');
    }

    try {
      // In a real app, you would use local_auth package
      // For demo, we'll simulate the process
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedSettings = _securitySettings.copyWith(
        isBiometricEnabled: true,
        enabledAuthMethods: [
          ..._securitySettings.enabledAuthMethods,
          if (!_securitySettings.enabledAuthMethods.contains(
            AuthenticationMethod.biometric,
          ))
            AuthenticationMethod.biometric,
        ],
      );

      await updateSecuritySettings(updatedSettings);
      return true;
    } catch (e) {
      debugPrint('Error enabling biometric: $e');
      return false;
    }
  }

  Future<bool> disableBiometric() async {
    try {
      final updatedSettings = _securitySettings.copyWith(
        isBiometricEnabled: false,
        enabledAuthMethods: _securitySettings.enabledAuthMethods
            .where((method) => method != AuthenticationMethod.biometric)
            .toList(),
      );

      await updateSecuritySettings(updatedSettings);
      return true;
    } catch (e) {
      debugPrint('Error disabling biometric: $e');
      return false;
    }
  }

  // Two-Factor Authentication
  Future<String> setupTwoFactor() async {
    try {
      final response = await SecurityApiService.setup2FA();

      if (response['success'] == true && response['data'] != null) {
        // Return QR code data or secret from server
        return response['data']['secret'] ??
            response['data']['qrCode'] ??
            'JBSWY3DPEHPK3PXP';
      } else {
        throw Exception(response['message'] ?? 'Không thể thiết lập 2FA');
      }
    } catch (e) {
      debugPrint('Error setting up 2FA: $e');
      rethrow;
    }
  }

  Future<bool> enableTwoFactor(String verificationCode) async {
    try {
      // Verify with server
      final response = await SecurityApiService.enable2FA(verificationCode);

      if (response['success'] == true) {
        // Update local settings
        final updatedSettings = _securitySettings.copyWith(
          isTwoFactorEnabled: true,
        );

        _securitySettings = updatedSettings;
        await _saveSecuritySettings();
        notifyListeners();

        return true;
      } else {
        throw Exception(response['message'] ?? 'Mã xác thực không hợp lệ');
      }
    } catch (e) {
      debugPrint('Error enabling 2FA: $e');
      return false;
    }
  }

  Future<bool> disableTwoFactor(String password) async {
    try {
      // Disable 2FA via API
      final response = await SecurityApiService.disable2FA();

      if (response['success'] == true) {
        // Update local settings
        final updatedSettings = _securitySettings.copyWith(
          isTwoFactorEnabled: false,
        );

        _securitySettings = updatedSettings;
        await _saveSecuritySettings();
        notifyListeners();

        return true;
      } else {
        throw Exception(response['message'] ?? 'Không thể tắt 2FA');
      }
    } catch (e) {
      debugPrint('Error disabling 2FA: $e');
      return false;
    }
  }

  // Password Management
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Validate inputs
      if (currentPassword.isEmpty || newPassword.isEmpty) {
        throw Exception('Vui lòng nhập đầy đủ thông tin');
      }

      if (newPassword.length < 8) {
        throw Exception('Mật khẩu mới phải có ít nhất 8 ký tự');
      }

      // Change password via API
      final response = await SecurityApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (response['success'] == true) {
        // Update local settings
        final updatedSettings = _securitySettings.copyWith(
          lastPasswordChange: DateTime.now(),
        );

        _securitySettings = updatedSettings;
        await _saveSecuritySettings();
        notifyListeners();

        return true;
      } else {
        throw Exception(response['message'] ?? 'Không thể đổi mật khẩu');
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      return false;
    }
  }

  // Session Management
  Future<bool> terminateSession(String sessionId) async {
    try {
      // Terminate session via API
      final response = await SecurityApiService.terminateSession(sessionId);

      if (response['success'] == true) {
        // Update local state
        final updatedSessions = _securitySettings.activeSessions
            .where((session) => session.id != sessionId)
            .toList();

        final updatedSettings = _securitySettings.copyWith(
          activeSessions: updatedSessions,
        );

        _securitySettings = updatedSettings;
        await _saveSecuritySettings();
        notifyListeners();

        return true;
      } else {
        throw Exception(response['message'] ?? 'Không thể kết thúc phiên');
      }
    } catch (e) {
      debugPrint('Error terminating session: $e');
      return false;
    }
  }

  Future<bool> terminateAllOtherSessions() async {
    try {
      // Terminate all sessions via API
      final response = await SecurityApiService.terminateAllSessions();

      if (response['success'] == true) {
        // Update local state - keep only current session
        final currentSession = _securitySettings.activeSessions
            .where((session) => session.isCurrent)
            .toList();

        final updatedSettings = _securitySettings.copyWith(
          activeSessions: currentSession,
        );

        _securitySettings = updatedSettings;
        await _saveSecuritySettings();
        notifyListeners();

        return true;
      } else {
        throw Exception(response['message'] ?? 'Không thể kết thúc phiên');
      }
    } catch (e) {
      debugPrint('Error terminating all sessions: $e');
      return false;
    }
  }

  // Security Toggles
  Future<void> toggleAutoLock(bool enabled) async {
    debugPrint('🔄 Toggling Auto Lock: $enabled');
    final updatedSettings = _securitySettings.copyWith(
      isAutoLockEnabled: enabled,
    );
    await updateSecuritySettings(updatedSettings);
    debugPrint(
      '✅ Auto Lock toggled to: ${_securitySettings.isAutoLockEnabled}',
    );
  }

  Future<void> updateSessionTimeout(SessionTimeout timeout) async {
    debugPrint('🔄 Updating Session Timeout: $timeout');
    final updatedSettings = _securitySettings.copyWith(sessionTimeout: timeout);
    await updateSecuritySettings(updatedSettings);
    debugPrint(
      '✅ Session Timeout updated to: ${_securitySettings.sessionTimeout}',
    );
  }

  Future<void> toggleLoginNotifications(bool enabled) async {
    debugPrint('🔄 Toggling Login Notifications: $enabled');
    final updatedSettings = _securitySettings.copyWith(
      isLoginNotificationEnabled: enabled,
    );
    await updateSecuritySettings(updatedSettings);
    debugPrint(
      '✅ Login Notifications toggled to: ${_securitySettings.isLoginNotificationEnabled}',
    );
  }

  Future<void> toggleScreenshotBlocking(bool enabled) async {
    debugPrint('🔄 Toggling Screenshot Blocking: $enabled');
    final updatedSettings = _securitySettings.copyWith(
      isScreenshotBlocked: enabled,
    );
    await updateSecuritySettings(updatedSettings);
    debugPrint(
      '✅ Screenshot Blocking toggled to: ${_securitySettings.isScreenshotBlocked}',
    );
  }

  Future<void> updateMaxFailedAttempts(int attempts) async {
    debugPrint('🔄 Updating Max Failed Attempts: $attempts');
    final updatedSettings = _securitySettings.copyWith(
      maxFailedAttempts: attempts,
    );
    await updateSecuritySettings(updatedSettings);
    debugPrint(
      '✅ Max Failed Attempts updated to: ${_securitySettings.maxFailedAttempts}',
    );
  }

  // Security Analysis
  List<String> getSecurityRecommendations() {
    final recommendations = <String>[];

    if (!_securitySettings.isBiometricEnabled && _isBiometricAvailable) {
      recommendations.add('Bật xác thực sinh trắc học để tăng cường bảo mật');
    }

    if (!_securitySettings.isTwoFactorEnabled) {
      recommendations.add('Thiết lập xác thực 2 bước cho bảo mật tối đa');
    }

    if (_securitySettings.sessionTimeout == SessionTimeout.never) {
      recommendations.add('Thiết lập thời gian tự động khóa để bảo vệ dữ liệu');
    }

    if (_securitySettings.lastPasswordChange != null) {
      final daysSinceChange = DateTime.now()
          .difference(_securitySettings.lastPasswordChange!)
          .inDays;
      if (daysSinceChange > 90) {
        recommendations.add(
          'Thay đổi mật khẩu định kỳ (đã $daysSinceChange ngày)',
        );
      }
    }

    if (!_securitySettings.isDataEncryptionEnabled) {
      recommendations.add('Bật mã hóa dữ liệu để bảo vệ thông tin cá nhân');
    }

    if (_securitySettings.activeSessions.length > 3) {
      recommendations.add(
        'Quản lý phiên đăng nhập - có ${_securitySettings.activeSessions.length} thiết bị đang hoạt động',
      );
    }

    return recommendations;
  }

  // Utility methods
  String calculatePasswordStrength(String password) {
    int strength = 0;

    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    if (strength <= 2) return 'Yếu';
    if (strength <= 4) return 'Trung bình';
    return 'Mạnh';
  }

  Color getPasswordStrengthColor(String strength) {
    switch (strength) {
      case 'Yếu':
        return Colors.red;
      case 'Trung bình':
        return Colors.orange;
      case 'Mạnh':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Helper method to convert SessionTimeout enum to minutes for API
  int _getSessionTimeoutInMinutes(SessionTimeout timeout) {
    switch (timeout) {
      case SessionTimeout.never:
        return 0; // 0 means never timeout
      case SessionTimeout.minutes5:
        return 5;
      case SessionTimeout.minutes15:
        return 15;
      case SessionTimeout.minutes30:
        return 30;
      case SessionTimeout.hour1:
        return 60;
      case SessionTimeout.hour4:
        return 240;
    }
  }
}
