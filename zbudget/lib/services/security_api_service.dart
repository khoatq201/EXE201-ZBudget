import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/device_info_helper.dart';
import '../utils/secure_storage_manager.dart';

/// API service for security-related operations
class SecurityApiService {
  // Base URL - different for web and mobile
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/security';
    } else {
      return 'http://10.0.2.2:3000/api/security';
    }
  }

  /// Get authorization headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorageManager.getToken();

    if (token == null) {
      throw Exception('No access token found. Please login again.');
    }

    return await DeviceInfoHelper.getEnhancedHeaders(
      token: token,
      includeAuth: true,
    );
  }

  /// Setup Two-Factor Authentication
  static Future<Map<String, dynamic>> setup2FA() async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/2fa/setup'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return {
            'success': true,
            'data': responseData['data'],
            'message': responseData['message'] ?? 'Thiết lập 2FA thành công',
          };
        } else {
          throw Exception(responseData['message'] ?? 'Không thể thiết lập 2FA');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Lỗi server khi thiết lập 2FA');
      }
    } catch (e) {
      debugPrint('❌ Setup 2FA error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối. Vui lòng thử lại sau.',
      };
    }
  }

  /// Enable Two-Factor Authentication with OTP
  static Future<Map<String, dynamic>> enable2FA(String otp) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/2fa/enable'),
        headers: headers,
        body: jsonEncode({'otp': otp}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'Kích hoạt 2FA thành công',
          };
        } else {
          throw Exception(responseData['message'] ?? 'Mã OTP không hợp lệ');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Lỗi khi kích hoạt 2FA');
      }
    } catch (e) {
      debugPrint('❌ Enable 2FA error: $e');
      return {
        'success': false,
        'message': e.toString().contains('Exception:')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Lỗi kết nối. Vui lòng thử lại sau.',
      };
    }
  }

  /// Disable Two-Factor Authentication
  static Future<Map<String, dynamic>> disable2FA() async {
    try {
      final headers = await _getHeaders();
      debugPrint('🚫 Disabling 2FA');

      final response = await http.post(
        Uri.parse('$baseUrl/2fa/disable'),
        headers: headers,
      );

      debugPrint('📡 2FA Disable response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'Tắt 2FA thành công',
          };
        } else {
          throw Exception(responseData['message'] ?? 'Không thể tắt 2FA');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Lỗi server khi tắt 2FA');
      }
    } catch (e) {
      debugPrint('❌ Disable 2FA error: $e');
      return {
        'success': false,
        'message': e.toString().contains('Exception:')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Lỗi kết nối. Vui lòng thử lại sau.',
      };
    }
  }

  /// Change password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final headers = await _getHeaders();
      debugPrint('🔑 Changing password');

      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: headers,
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      debugPrint('📡 Change password response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'Đổi mật khẩu thành công',
          };
        } else {
          throw Exception(responseData['message'] ?? 'Không thể đổi mật khẩu');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Lỗi server khi đổi mật khẩu');
      }
    } catch (e) {
      debugPrint('❌ Change password error: $e');
      return {
        'success': false,
        'message': e.toString().contains('Exception:')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Lỗi kết nối. Vui lòng thử lại sau.',
      };
    }
  }

  /// Update security settings
  static Future<Map<String, dynamic>> updateSecuritySettings({
    // New frontend fields
    bool? isBiometricEnabled,
    bool? isTwoFactorEnabled,
    bool? isAutoLockEnabled,
    int? sessionTimeout,
    bool? isLoginNotificationEnabled,
    bool? isDataEncryptionEnabled,
    int? maxFailedAttempts,
    bool? isScreenshotBlocked,
    bool? isAppPinEnabled,
    String? primaryAuthMethod,

    // Legacy fields for backward compatibility
    bool? sessionPersistence,
    bool? keepSessionsAcrossDevices,
    bool? enablePrivacyMode,
    bool? enhancedProtection,
    bool? biometricAuth,
  }) async {
    try {
      final headers = await _getHeaders();

      final body = <String, dynamic>{};

      // Map new frontend fields to backend expected names
      if (isBiometricEnabled != null)
        body['biometricEnabled'] = isBiometricEnabled;
      if (isTwoFactorEnabled != null)
        body['isTwoFactorEnabled'] = isTwoFactorEnabled;
      if (isAutoLockEnabled != null)
        body['autoLockEnabled'] = isAutoLockEnabled;
      if (sessionTimeout != null) body['sessionTimeout'] = sessionTimeout;
      if (isLoginNotificationEnabled != null)
        body['loginNotificationEnabled'] = isLoginNotificationEnabled;
      if (isDataEncryptionEnabled != null)
        body['dataEncryptionEnabled'] = isDataEncryptionEnabled;
      if (maxFailedAttempts != null)
        body['maxFailedAttempts'] = maxFailedAttempts;
      if (isScreenshotBlocked != null)
        body['screenshotBlocked'] = isScreenshotBlocked;
      if (isAppPinEnabled != null) body['appPinEnabled'] = isAppPinEnabled;
      if (primaryAuthMethod != null)
        body['primaryAuthMethod'] = primaryAuthMethod;

      // Legacy fields for backward compatibility
      if (sessionPersistence != null)
        body['sessionPersistence'] = sessionPersistence;
      if (keepSessionsAcrossDevices != null)
        body['keepSessionsAcrossDevices'] = keepSessionsAcrossDevices;
      if (enablePrivacyMode != null)
        body['enablePrivacyMode'] = enablePrivacyMode;
      if (enhancedProtection != null)
        body['enhancedProtection'] = enhancedProtection;
      if (biometricAuth != null) body['biometricAuth'] = biometricAuth;

      final response = await http.put(
        Uri.parse('$baseUrl/settings'),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('📡 Security settings response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          return {
            'success': true,
            'data': responseData['data'],
            'message':
                responseData['message'] ??
                'Cập nhật cài đặt bảo mật thành công',
          };
        } else {
          throw Exception(
            responseData['message'] ?? 'Không thể cập nhật cài đặt',
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          errorBody['error'] ?? 'Lỗi server khi cập nhật cài đặt',
        );
      }
    } catch (e) {
      debugPrint('❌ Update security settings error: $e');
      return {
        'success': false,
        'message': e.toString().contains('Exception:')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Lỗi kết nối. Vui lòng thử lại sau.',
      };
    }
  }

  /// Get user security settings
  static Future<Map<String, dynamic>> getSecuritySettings() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/settings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return {'success': true, 'data': responseData['data']};
        } else {
          throw Exception(
            responseData['message'] ?? 'Không thể lấy cài đặt bảo mật',
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Lỗi server');
      }
    } catch (e) {
      debugPrint('❌ Get security settings error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối. Vui lòng thử lại sau.',
      };
    }
  }

  /// Terminate specific session
  static Future<Map<String, dynamic>> terminateSession(String sessionId) async {
    try {
      final headers = await _getHeaders();
      debugPrint('🔄 Terminating session: $sessionId');

      final response = await http.delete(
        Uri.parse('$baseUrl/sessions/$sessionId'),
        headers: headers,
      );

      debugPrint('📡 Terminate session response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'Kết thúc phiên thành công',
          };
        } else {
          throw Exception(
            responseData['message'] ?? 'Không thể kết thúc phiên',
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Lỗi server khi kết thúc phiên');
      }
    } catch (e) {
      debugPrint('❌ Terminate session error: $e');
      return {
        'success': false,
        'message': e.toString().contains('Exception:')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Lỗi kết nối. Vui lòng thử lại sau.',
      };
    }
  }

  /// Terminate all sessions
  static Future<Map<String, dynamic>> terminateAllSessions() async {
    try {
      final headers = await _getHeaders();
      debugPrint('🔄 Terminating all sessions');

      final response = await http.delete(
        Uri.parse('$baseUrl/sessions'),
        headers: headers,
      );

      debugPrint('📡 Terminate all sessions response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          return {
            'success': true,
            'message':
                responseData['message'] ?? 'Kết thúc tất cả phiên thành công',
          };
        } else {
          throw Exception(
            responseData['message'] ?? 'Không thể kết thúc phiên',
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Lỗi server khi kết thúc phiên');
      }
    } catch (e) {
      debugPrint('❌ Terminate all sessions error: $e');
      return {
        'success': false,
        'message': e.toString().contains('Exception:')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Lỗi kết nối. Vui lòng thử lại sau.',
      };
    }
  }

  /// Get active sessions
  static Future<Map<String, dynamic>> getActiveSessions() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/sessions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return {'success': true, 'data': responseData['data']};
        } else {
          return {'success': true, 'data': []};
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Lỗi server');
      }
    } catch (e) {
      debugPrint('❌ Get active sessions error: $e');
      return {
        'success': false,
        'data': [],
        'message': 'Lỗi kết nối. Vui lòng thử lại sau.',
      };
    }
  }
}
