import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/auth_utils.dart';
import '../models/settings/security_settings.dart';

class SecurityApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/security';

  /// Get security statistics and overview
  static Future<Map<String, dynamic>?> getSecurityStats() async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        'SecurityApiService: getSecurityStats response: ${response.statusCode}',
      );
      print('SecurityApiService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('SecurityApiService: Error getting security stats: $e');
      return null;
    }
  }

  /// Change user password
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final requestBody = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': newPassword, // Frontend handles confirmation
      };

      print('SecurityApiService: changePassword request');
      print('SecurityApiService: Request body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print(
        'SecurityApiService: changePassword response: ${response.statusCode}',
      );
      print('SecurityApiService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('SecurityApiService: Error changing password: $e');
      return false;
    }
  }

  /// Get active sessions
  static Future<List<LoginSession>?> getActiveSessions() async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        'SecurityApiService: getActiveSessions response: ${response.statusCode}',
      );
      print('SecurityApiService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final sessions = data['data']['sessions'] as List;
          return sessions
              .map((session) => LoginSession.fromJson(session))
              .toList();
        }
      }
      return null;
    } catch (e) {
      print('SecurityApiService: Error getting active sessions: $e');
      return null;
    }
  }

  /// Terminate a specific session
  static Future<bool> terminateSession(String sessionId) async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/sessions/$sessionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        'SecurityApiService: terminateSession response: ${response.statusCode}',
      );
      print('SecurityApiService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('SecurityApiService: Error terminating session: $e');
      return false;
    }
  }

  /// Terminate all other sessions
  static Future<bool> terminateAllOtherSessions() async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        'SecurityApiService: terminateAllOtherSessions response: ${response.statusCode}',
      );
      print('SecurityApiService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('SecurityApiService: Error terminating all sessions: $e');
      return false;
    }
  }

  /// Setup Two-Factor Authentication (get QR code)
  static Future<Map<String, dynamic>?> setup2FA() async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/setup-2fa'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('SecurityApiService: setup2FA response: ${response.statusCode}');
      print('SecurityApiService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('SecurityApiService: Error setting up 2FA: $e');
      return null;
    }
  }

  /// Enable Two-Factor Authentication
  static Future<bool> enable2FA(String token) async {
    try {
      final authToken = await AuthUtils.getToken();
      if (authToken == null) {
        throw Exception('No authentication token found');
      }

      final requestBody = {'token': token};

      final response = await http.post(
        Uri.parse('$baseUrl/enable-2fa'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print('SecurityApiService: enable2FA response: ${response.statusCode}');
      print('SecurityApiService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('SecurityApiService: Error enabling 2FA: $e');
      return false;
    }
  }

  /// Disable Two-Factor Authentication
  static Future<bool> disable2FA(String token) async {
    try {
      final authToken = await AuthUtils.getToken();
      if (authToken == null) {
        throw Exception('No authentication token found');
      }

      final requestBody = {'token': token};

      final response = await http.post(
        Uri.parse('$baseUrl/disable-2fa'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print('SecurityApiService: disable2FA response: ${response.statusCode}');
      print('SecurityApiService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('SecurityApiService: Error disabling 2FA: $e');
      return false;
    }
  }

  /// Verify Two-Factor Authentication token
  static Future<bool> verify2FA(String token) async {
    try {
      final authToken = await AuthUtils.getToken();
      if (authToken == null) {
        throw Exception('No authentication token found');
      }

      final requestBody = {'token': token};

      final response = await http.post(
        Uri.parse('$baseUrl/verify-2fa'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print('SecurityApiService: verify2FA response: ${response.statusCode}');
      print('SecurityApiService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data']['verified'] == true;
        }
      }
      return false;
    } catch (e) {
      print('SecurityApiService: Error verifying 2FA: $e');
      return false;
    }
  }

  /// Update security settings
  static Future<bool> updateSecuritySettings(SecuritySettings settings) async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final requestBody = {'security': settings.toBackendJson()};

      print('SecurityApiService: updateSecuritySettings request');
      print('SecurityApiService: Request body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/api/settings/security'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print(
        'SecurityApiService: updateSecuritySettings response: ${response.statusCode}',
      );
      print('SecurityApiService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        print(
          'SecurityApiService: Error ${response.statusCode}: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('SecurityApiService: Exception updating security settings: $e');
      return false;
    }
  }
}
