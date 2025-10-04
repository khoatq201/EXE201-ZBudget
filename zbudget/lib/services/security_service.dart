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
    try {
      // Load active sessions from API
      final sessions = await SecurityApiService.getActiveSessions();
      if (sessions != null && sessions.isNotEmpty) {
        final updatedSettings = _securitySettings.copyWith(
          activeSessions: sessions,
        );
        _securitySettings = updatedSettings;
        await _saveSecuritySettings();
      }
    } catch (e) {
      debugPrint('Failed to load active sessions from API: $e');
      // Continue with local/demo sessions
    }
  }

  Future<void> updateSecuritySettings(SecuritySettings newSettings) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Store original settings for rollback if needed
      final originalSettings = _securitySettings;

      // Update settings via API first
      final success = await SecurityApiService.updateSecuritySettings(
        newSettings,
      );

      if (success) {
        // Only update local settings if API call succeeded
        _securitySettings = newSettings;

        // Save locally for offline access
        await _saveSecuritySettings();

        // Trigger any necessary system-level changes
        await _applySecurityChanges();

        debugPrint('Security settings updated successfully');
      } else {
        // API failed, keep original settings
        _securitySettings = originalSettings;
        throw Exception('Failed to update security settings via API');
      }
    } catch (e) {
      debugPrint('Error updating security settings: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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
  Future<Map<String, dynamic>?> setupTwoFactor() async {
    try {
      // Setup 2FA via API - this will generate QR code and secret
      final result = await SecurityApiService.setup2FA();
      return result;
    } catch (e) {
      debugPrint('Error setting up 2FA: $e');
      rethrow;
    }
  }

  Future<bool> enableTwoFactor(String verificationCode) async {
    try {
      // Verify and enable 2FA via API
      final success = await SecurityApiService.enable2FA(verificationCode);

      if (success) {
        // Update local settings
        final updatedSettings = _securitySettings.copyWith(
          isTwoFactorEnabled: true,
        );
        await updateSecuritySettings(updatedSettings);
      }

      return success;
    } catch (e) {
      debugPrint('Error enabling 2FA: $e');
      return false;
    }
  }

  Future<bool> disableTwoFactor(String password) async {
    try {
      // Disable 2FA via API with password verification
      final success = await SecurityApiService.disable2FA(password);

      if (success) {
        // Update local settings
        final updatedSettings = _securitySettings.copyWith(
          isTwoFactorEnabled: false,
        );
        await updateSecuritySettings(updatedSettings);
      }

      return success;
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
      // Basic validation
      if (currentPassword.isEmpty || newPassword.isEmpty) {
        throw Exception('Vui lòng nhập đầy đủ thông tin');
      }

      if (newPassword.length < 8) {
        throw Exception('Mật khẩu mới phải có ít nhất 8 ký tự');
      }

      // Call API to change password
      final success = await SecurityApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (success) {
        // Update local settings to reflect password change
        final updatedSettings = _securitySettings.copyWith(
          lastPasswordChange: DateTime.now(),
        );
        await updateSecuritySettings(updatedSettings);
      }

      return success;
    } catch (e) {
      debugPrint('Error changing password: $e');
      return false;
    }
  }

  // Session Management
  Future<bool> terminateSession(String sessionId) async {
    try {
      // Terminate session via API
      final success = await SecurityApiService.terminateSession(sessionId);

      if (success) {
        // Update local state
        final updatedSessions = _securitySettings.activeSessions
            .where((session) => session.id != sessionId)
            .toList();

        final updatedSettings = _securitySettings.copyWith(
          activeSessions: updatedSessions,
        );

        await updateSecuritySettings(updatedSettings);
      }

      return success;
    } catch (e) {
      debugPrint('Error terminating session: $e');
      return false;
    }
  }

  Future<bool> terminateAllOtherSessions() async {
    try {
      // Terminate all other sessions via API
      final success = await SecurityApiService.terminateAllOtherSessions();

      if (success) {
        // Update local state to keep only current session
        final currentSession = _securitySettings.activeSessions
            .where((session) => session.isCurrent)
            .toList();

        final updatedSettings = _securitySettings.copyWith(
          activeSessions: currentSession,
        );

        await updateSecuritySettings(updatedSettings);
      }

      return success;
    } catch (e) {
      debugPrint('Error terminating sessions: $e');
      return false;
    }
  }

  // Security Toggles
  Future<void> toggleAutoLock(bool enabled) async {
    final updatedSettings = _securitySettings.copyWith(
      isAutoLockEnabled: enabled,
    );
    await updateSecuritySettings(updatedSettings);
  }

  Future<void> updateSessionTimeout(SessionTimeout timeout) async {
    final updatedSettings = _securitySettings.copyWith(sessionTimeout: timeout);
    await updateSecuritySettings(updatedSettings);
  }

  Future<void> toggleLoginNotifications(bool enabled) async {
    final updatedSettings = _securitySettings.copyWith(
      isLoginNotificationEnabled: enabled,
    );
    await updateSecuritySettings(updatedSettings);
  }

  Future<void> toggleScreenshotBlocking(bool enabled) async {
    final updatedSettings = _securitySettings.copyWith(
      isScreenshotBlocked: enabled,
    );
    await updateSecuritySettings(updatedSettings);
  }

  Future<void> updateMaxFailedAttempts(int attempts) async {
    final updatedSettings = _securitySettings.copyWith(
      maxFailedAttempts: attempts,
    );
    await updateSecuritySettings(updatedSettings);
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
}
