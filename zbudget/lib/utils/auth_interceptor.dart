import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

/// AuthInterceptor - Utility class for API authentication
/// Provides automatic token injection and response handling
class AuthInterceptor {
  /// Add authentication headers to HTTP requests
  static Map<String, String> getAuthHeaders(AuthService authService) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add authorization header if token exists
    if (authService.accessToken != null) {
      headers['Authorization'] = 'Bearer ${authService.accessToken}';
      debugPrint('🔐 AuthInterceptor: Added auth header');
    } else {
      debugPrint('⚠️ AuthInterceptor: No access token available');
    }

    return headers;
  }

  /// Enhanced HTTP GET with automatic auth headers
  static Future<http.Response> authenticatedGet(
    String url,
    AuthService authService, {
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = getAuthHeaders(authService);
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    debugPrint('🌐 AuthInterceptor: GET $url');
    final response = await http.get(Uri.parse(url), headers: headers);

    return _handleResponse(response, authService);
  }

  /// Enhanced HTTP POST with automatic auth headers
  static Future<http.Response> authenticatedPost(
    String url,
    AuthService authService, {
    Map<String, String>? additionalHeaders,
    dynamic body,
  }) async {
    final headers = getAuthHeaders(authService);
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    debugPrint('🌐 AuthInterceptor: POST $url');
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body is String ? body : jsonEncode(body),
    );

    return _handleResponse(response, authService);
  }

  /// Enhanced HTTP PUT with automatic auth headers
  static Future<http.Response> authenticatedPut(
    String url,
    AuthService authService, {
    Map<String, String>? additionalHeaders,
    dynamic body,
  }) async {
    final headers = getAuthHeaders(authService);
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    debugPrint('🌐 AuthInterceptor: PUT $url');
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: body is String ? body : jsonEncode(body),
    );

    return _handleResponse(response, authService);
  }

  /// Enhanced HTTP DELETE with automatic auth headers
  static Future<http.Response> authenticatedDelete(
    String url,
    AuthService authService, {
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = getAuthHeaders(authService);
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    debugPrint('🌐 AuthInterceptor: DELETE $url');
    final response = await http.delete(Uri.parse(url), headers: headers);

    return _handleResponse(response, authService);
  }

  /// Handle HTTP response and check for authentication errors
  static Future<http.Response> _handleResponse(
    http.Response response,
    AuthService authService,
  ) async {
    debugPrint('🔍 AuthInterceptor: Response status: ${response.statusCode}');

    // Handle authentication errors
    if (response.statusCode == 401) {
      debugPrint(
        '🔴 AuthInterceptor: 401 Unauthorized - Token expired or invalid',
      );

      // Try to refresh token first
      final refreshSuccess = await authService.refreshAccessToken();

      if (!refreshSuccess) {
        debugPrint(
          '🔴 AuthInterceptor: Token refresh failed, logging out user',
        );
        await authService.logout();
        // Note: Navigation should be handled by the calling widget/service
      }
    } else if (response.statusCode == 403) {
      debugPrint(
        '🔴 AuthInterceptor: 403 Forbidden - Insufficient permissions',
      );
    } else if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint('🟢 AuthInterceptor: Request successful');
    } else {
      debugPrint(
        '⚠️ AuthInterceptor: Request failed with status: ${response.statusCode}',
      );
    }

    return response;
  }

  /// Check if response indicates authentication failure
  static bool isAuthenticationError(http.Response response) {
    return response.statusCode == 401 || response.statusCode == 403;
  }

  /// Extract error message from response
  static String getErrorMessage(http.Response response) {
    try {
      final responseData = jsonDecode(response.body);
      return responseData['message'] ??
          responseData['error'] ??
          'Unknown error';
    } catch (e) {
      return 'Failed to parse error response';
    }
  }

  /// Create a standardized error response
  static Map<String, dynamic> createErrorResponse(String message) {
    return {'success': false, 'message': message, 'error': true};
  }

  /// Create a standardized success response
  static Map<String, dynamic> createSuccessResponse(
    String message, {
    dynamic data,
  }) {
    return {
      'success': true,
      'message': message,
      if (data != null) 'data': data,
    };
  }
}
