import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Helper class để thu thập và xử lý thông tin device
/// Cung cấp device info chi tiết cho API calls và security tracking
class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Lấy thông tin device chi tiết dựa trên platform
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (kIsWeb) {
        return await _getWebDeviceInfo();
      } else if (Platform.isAndroid) {
        return await _getAndroidDeviceInfo();
      } else if (Platform.isIOS) {
        return await _getIOSDeviceInfo();
      } else if (Platform.isWindows) {
        return await _getWindowsDeviceInfo();
      } else if (Platform.isMacOS) {
        return await _getMacOSDeviceInfo();
      } else if (Platform.isLinux) {
        return await _getLinuxDeviceInfo();
      } else {
        return _getDefaultDeviceInfo();
      }
    } catch (e) {
      debugPrint('❌ Error getting device info: $e');
      return _getDefaultDeviceInfo();
    }
  }

  /// Tạo custom User-Agent cho Flutter app
  static Future<String> buildCustomUserAgent() async {
    try {
      final deviceInfo = await getDeviceInfo();
      final platform = deviceInfo['platform'] ?? 'Unknown';
      final version = deviceInfo['version'] ?? 'Unknown';
      final model = deviceInfo['model'] ?? 'Unknown';

      return 'ZBudget-Flutter/1.0.0 ($platform $version; $model) Dart/3.9.0';
    } catch (e) {
      debugPrint('❌ Error building user agent: $e');
      return 'ZBudget-Flutter/1.0.0 (Unknown Device) Dart/3.9.0';
    }
  }

  /// Chuyển device info thành JSON string cho API header
  static Future<String> getDeviceInfoJson() async {
    try {
      final deviceInfo = await getDeviceInfo();
      return jsonEncode(deviceInfo);
    } catch (e) {
      debugPrint('❌ Error encoding device info: $e');
      return jsonEncode(_getDefaultDeviceInfo());
    }
  }

  /// Tạo enhanced headers bao gồm device info cho API calls
  static Future<Map<String, String>> getEnhancedHeaders({
    String? token,
    bool includeAuth = false,
  }) async {
    try {
      final deviceInfoJson = await getDeviceInfoJson();
      final customUserAgent = await buildCustomUserAgent();

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'User-Agent': customUserAgent,
        'x-device-info': deviceInfoJson,
      };

      // Thêm authorization header nếu có token
      if (includeAuth && token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      return headers;
    } catch (e) {
      debugPrint('❌ Error creating enhanced headers: $e');
      final defaultHeaders = <String, String>{
        'Content-Type': 'application/json',
        'User-Agent': 'ZBudget-Flutter/1.0.0 (Unknown Device)',
        'x-device-info': jsonEncode(_getDefaultDeviceInfo()),
      };

      // Thêm auth header ngay cả khi có lỗi
      if (includeAuth && token != null) {
        defaultHeaders['Authorization'] = 'Bearer $token';
      }

      return defaultHeaders;
    }
  }

  /// Lấy thông tin Android device
  static Future<Map<String, dynamic>> _getAndroidDeviceInfo() async {
    final androidInfo = await _deviceInfo.androidInfo;

    return {
      'platform': 'Android',
      'browser': 'Flutter',
      'deviceName': '${androidInfo.manufacturer} ${androidInfo.model}',
      'deviceType': 'mobile',
      'version': androidInfo.version.release,
      'manufacturer': androidInfo.manufacturer,
      'model': androidInfo.model,
      'isPhysicalDevice': androidInfo.isPhysicalDevice,
      'androidId': androidInfo.id,
      'sdkInt': androidInfo.version.sdkInt,
    };
  }

  /// Lấy thông tin iOS device
  static Future<Map<String, dynamic>> _getIOSDeviceInfo() async {
    final iosInfo = await _deviceInfo.iosInfo;

    return {
      'platform': 'iOS',
      'browser': 'Flutter',
      'deviceName': iosInfo.name,
      'deviceType': iosInfo.model.toLowerCase().contains('ipad')
          ? 'tablet'
          : 'mobile',
      'version': iosInfo.systemVersion,
      'manufacturer': 'Apple',
      'model': iosInfo.model,
      'isPhysicalDevice': iosInfo.isPhysicalDevice,
      'identifierForVendor': iosInfo.identifierForVendor,
      'systemName': iosInfo.systemName,
    };
  }

  /// Lấy thông tin Web device
  static Future<Map<String, dynamic>> _getWebDeviceInfo() async {
    final webInfo = await _deviceInfo.webBrowserInfo;

    // Map browser name to valid enum values
    String browserName = 'Unknown';
    switch (webInfo.browserName.name.toLowerCase()) {
      case 'chrome':
        browserName = 'Chrome';
        break;
      case 'safari':
        browserName = 'Safari';
        break;
      case 'firefox':
        browserName = 'Firefox';
        break;
      case 'edge':
        browserName = 'Edge';
        break;
      case 'opera':
        browserName = 'Opera';
        break;
      default:
        browserName = 'Unknown';
    }

    // Detect platform from user agent
    String platform = _getPlatformFromUserAgent(webInfo.userAgent ?? '');
    if (!['Windows', 'macOS', 'Linux'].contains(platform)) {
      platform = 'Unknown';
    }

    return {
      'platform': platform, // Should be Windows/macOS/Linux/Unknown
      'browser': browserName, // Should match Session model enum
      'deviceName': '$platform - $browserName',
      'deviceType': 'desktop',
      'version': webInfo.appVersion ?? 'Unknown',
      'manufacturer': 'Unknown',
      'model': 'Web Browser',
      'isPhysicalDevice': true,
      'userAgent': webInfo.userAgent,
      'language': webInfo.language,
    };
  }

  /// Lấy thông tin Windows device
  static Future<Map<String, dynamic>> _getWindowsDeviceInfo() async {
    final windowsInfo = await _deviceInfo.windowsInfo;

    return {
      'platform': 'Windows',
      'browser': 'Flutter',
      'deviceName': windowsInfo.computerName,
      'deviceType': 'desktop',
      'version': '${windowsInfo.majorVersion}.${windowsInfo.minorVersion}',
      'manufacturer': 'Microsoft',
      'model': 'Windows PC',
      'isPhysicalDevice': true,
      'computerName': windowsInfo.computerName,
      'numberOfCores': windowsInfo.numberOfCores,
    };
  }

  /// Lấy thông tin macOS device
  static Future<Map<String, dynamic>> _getMacOSDeviceInfo() async {
    final macInfo = await _deviceInfo.macOsInfo;

    return {
      'platform': 'macOS',
      'browser': 'Flutter',
      'deviceName': macInfo.computerName,
      'deviceType': 'desktop',
      'version': macInfo.osRelease,
      'manufacturer': 'Apple',
      'model': macInfo.model,
      'isPhysicalDevice': true,
      'computerName': macInfo.computerName,
      'kernelVersion': macInfo.kernelVersion,
    };
  }

  /// Lấy thông tin Linux device
  static Future<Map<String, dynamic>> _getLinuxDeviceInfo() async {
    final linuxInfo = await _deviceInfo.linuxInfo;

    return {
      'platform': 'Linux',
      'browser': 'Flutter',
      'deviceName': linuxInfo.name,
      'deviceType': 'desktop',
      'version': linuxInfo.version ?? 'Unknown',
      'manufacturer': 'Unknown',
      'model': 'Linux PC',
      'isPhysicalDevice': true,
      'name': linuxInfo.name,
      'id': linuxInfo.id,
    };
  }

  /// Thông tin device mặc định khi không thể detect
  static Map<String, dynamic> _getDefaultDeviceInfo() {
    return {
      'platform': 'Unknown',
      'browser': 'Flutter',
      'deviceName': 'Unknown Device',
      'deviceType': 'desktop',
      'version': 'Unknown',
      'manufacturer': 'Unknown',
      'model': 'Unknown',
      'isPhysicalDevice': true,
    };
  }

  /// Extract platform từ web user agent
  static String _getPlatformFromUserAgent(String userAgent) {
    if (userAgent.toLowerCase().contains('windows')) {
      return 'Windows';
    } else if (userAgent.toLowerCase().contains('mac')) {
      return 'macOS';
    } else if (userAgent.toLowerCase().contains('linux')) {
      return 'Linux';
    } else if (userAgent.toLowerCase().contains('android')) {
      return 'Android';
    } else if (userAgent.toLowerCase().contains('iphone') ||
        userAgent.toLowerCase().contains('ipad')) {
      return 'iOS';
    } else {
      return 'Unknown';
    }
  }

  /// Tạo device fingerprint để identify device uniquely
  static Future<String> generateDeviceFingerprint() async {
    try {
      final deviceInfo = await getDeviceInfo();
      final platform = deviceInfo['platform'] ?? 'Unknown';
      final model = deviceInfo['model'] ?? 'Unknown';
      final manufacturer = deviceInfo['manufacturer'] ?? 'Unknown';
      final version = deviceInfo['version'] ?? 'Unknown';

      final fingerprint = '$platform-$manufacturer-$model-$version';

      // Simple hash để tạo short fingerprint
      return fingerprint.hashCode.toString();
    } catch (e) {
      debugPrint('❌ Error generating device fingerprint: $e');
      return 'unknown-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Debug method để in device info ra console
  static Future<void> debugPrintDeviceInfo() async {
    try {
      final deviceInfo = await getDeviceInfo();
      final userAgent = await buildCustomUserAgent();
      final fingerprint = await generateDeviceFingerprint();

      debugPrint('📱 === DEVICE INFO DEBUG ===');
      debugPrint('Platform: ${deviceInfo['platform']}');
      debugPrint('Device Name: ${deviceInfo['deviceName']}');
      debugPrint('Type: ${deviceInfo['deviceType']}');
      debugPrint('Version: ${deviceInfo['version']}');
      debugPrint('User Agent: $userAgent');
      debugPrint('Fingerprint: $fingerprint');
      debugPrint('JSON: ${await getDeviceInfoJson()}');
      debugPrint('📱 === END DEVICE INFO ===');
    } catch (e) {
      debugPrint('❌ Error in debug device info: $e');
    }
  }
}
