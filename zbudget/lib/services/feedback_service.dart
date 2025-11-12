import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/secure_storage_manager.dart';

/// Service để xử lý feedback với backend API
class FeedbackService {
  // Sử dụng ApiConfig để quản lý URL theo environment
  static String get baseUrl {
    return ApiConfig.baseUrl + ApiConfig.feedbackEndpoint;
  }

  /// Safely decode JSON response body
  static Map<String, dynamic>? _safeJsonDecode(String body) {
    if (body.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ Response body is empty');
      }
      return null;
    }
    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ JSON decode error: $e');
        debugPrint(
          'Response body: ${body.substring(0, body.length > 200 ? 200 : body.length)}...',
        );
      }
      return null;
    }
  }

  /// Get authorization headers with token
  static Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);

    // Try to get token even if not required (for optional auth)
    final token = await SecureStorageManager.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Gửi feedback mới
  /// Không bắt buộc phải đăng nhập
  static Future<Map<String, dynamic>> submitFeedback({
    required String name,
    required String email,
    required String type,
    required int rating,
    required String content,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      debugPrint('🚀 Sending feedback to: $baseUrl');
      debugPrint('📧 Email: $email, Type: $type, Rating: $rating');

      // Try to get auth headers (optional)
      final headers = await _getHeaders(requireAuth: false);

      final requestBody = {
        'name': name,
        'email': email,
        'type': type,
        'rating': rating,
        'content': content,
        if (deviceInfo != null) 'deviceInfo': deviceInfo,
      };

      debugPrint('📦 Request body: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(ApiConfig.requestTimeout);

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      final responseData = _safeJsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData?['message'] ?? 'Gửi phản hồi thành công',
          'data': responseData?['data'],
        };
      } else {
        final errorMessage = responseData?['error'] ??
                           responseData?['message'] ??
                           'Không thể gửi phản hồi';
        debugPrint('❌ Error: $errorMessage');
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on SocketException catch (e) {
      debugPrint('❌ Network error: $e');
      return {
        'success': false,
        'message': 'Không có kết nối mạng. Vui lòng kiểm tra lại.',
      };
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout error: $e');
      return {
        'success': false,
        'message': 'Kết nối hết thời gian. Vui lòng thử lại.',
      };
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: ${e.toString()}',
      };
    }
  }

  /// Lấy danh sách feedback của user (yêu cầu đăng nhập)
  static Future<Map<String, dynamic>> getMyFeedbacks({
    int page = 1,
    int limit = 10,
    String? type,
    String? status,
    String sortBy = 'createdAt',
    String order = 'desc',
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: true);

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        'sortBy': sortBy,
        'order': order,
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.myFeedbacksEndpoint}')
          .replace(queryParameters: queryParams);

      debugPrint('🚀 Getting my feedbacks from: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);

      debugPrint('📥 Response status: ${response.statusCode}');

      final responseData = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData?['data'] ?? [],
          'pagination': responseData?['pagination'],
        };
      } else {
        final errorMessage = responseData?['error'] ??
                           responseData?['message'] ??
                           'Không thể lấy danh sách phản hồi';
        debugPrint('❌ Error: $errorMessage');
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on SocketException catch (e) {
      debugPrint('❌ Network error: $e');
      return {
        'success': false,
        'message': 'Không có kết nối mạng. Vui lòng kiểm tra lại.',
      };
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout error: $e');
      return {
        'success': false,
        'message': 'Kết nối hết thời gian. Vui lòng thử lại.',
      };
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: ${e.toString()}',
      };
    }
  }

  /// Lấy feedback theo ID (yêu cầu đăng nhập)
  static Future<Map<String, dynamic>> getFeedbackById(String feedbackId) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      final uri = Uri.parse('$baseUrl/$feedbackId');

      debugPrint('🚀 Getting feedback by ID: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);

      debugPrint('📥 Response status: ${response.statusCode}');

      final responseData = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData?['data'],
        };
      } else {
        final errorMessage = responseData?['error'] ??
                           responseData?['message'] ??
                           'Không thể lấy thông tin phản hồi';
        debugPrint('❌ Error: $errorMessage');
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on SocketException catch (e) {
      debugPrint('❌ Network error: $e');
      return {
        'success': false,
        'message': 'Không có kết nối mạng. Vui lòng kiểm tra lại.',
      };
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: ${e.toString()}',
      };
    }
  }

  /// Lấy tất cả feedback (public - không cần đăng nhập)
  static Future<Map<String, dynamic>> getAllFeedbacks({
    int page = 1,
    int limit = 20,
    String? type,
    String? status,
    String sortBy = 'createdAt',
    String order = 'desc',
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (type != null && type.isNotEmpty) 'type': type,
        if (status != null && status.isNotEmpty) 'status': status,
        'sortBy': sortBy,
        'order': order,
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.allFeedbacksEndpoint}')
          .replace(queryParameters: queryParams);

      debugPrint('🚀 Getting all feedbacks from: $uri');

      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.requestTimeout);

      debugPrint('📥 Response status: ${response.statusCode}');

      final responseData = _safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData?['data'] ?? [],
          'pagination': responseData?['pagination'],
        };
      } else {
        final errorMessage = responseData?['error'] ??
                           responseData?['message'] ??
                           'Không thể lấy danh sách phản hồi';
        debugPrint('❌ Error: $errorMessage');
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on SocketException catch (e) {
      debugPrint('❌ Network error: $e');
      return {
        'success': false,
        'message': 'Không có kết nối mạng. Vui lòng kiểm tra lại.',
      };
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout error: $e');
      return {
        'success': false,
        'message': 'Kết nối hết thời gian. Vui lòng thử lại.',
      };
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: ${e.toString()}',
      };
    }
  }

  /// Get device info để gửi cùng feedback
  static Map<String, dynamic> getDeviceInfo() {
    return {
      'platform': defaultTargetPlatform.name,
      'version': '1.0.0', // App version
      'osVersion': Platform.operatingSystemVersion,
    };
  }
}
