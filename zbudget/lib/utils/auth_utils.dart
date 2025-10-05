import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';

/// Utility class for handling authentication tokens and state
class AuthUtils {
  static const String _tokenKey = 'access_token'; // Match AuthService key
  static const String _userKey = 'user_data'; // Match AuthService key
  static const String _refreshTokenKey =
      'refresh_token'; // Match AuthService key

  /// Check if user is currently authenticated
  static Future<bool> isAuthenticated() async {
    try {
      final token = await getToken();
      if (token == null) {
        return false;
      }

      // Check if token is expired
      if (Jwt.isExpired(token)) {
        await logout();
        return false;
      }

      return true;
    } catch (e) {
      // If any error occurs, consider not authenticated
      return false;
    }
  }

  /// Get the stored authentication token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      return token;
    } catch (e) {
      print('AuthUtils.getToken: Error getting token: $e');
      return null;
    }
  }

  /// Store authentication token
  static Future<bool> setToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_tokenKey, token);
    } catch (e) {
      return false;
    }
  }

  /// Get the stored refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Store refresh token
  static Future<bool> setRefreshToken(String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_refreshTokenKey, refreshToken);
    } catch (e) {
      return false;
    }
  }

  /// Get stored user information
  static Future<Map<String, dynamic>?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        return json.decode(userJson);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Store user information
  static Future<bool> setUser(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user);
      return await prefs.setString(_userKey, userJson);
    } catch (e) {
      return false;
    }
  }

  /// Get user ID from token
  static Future<String?> getUserId() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final payload = Jwt.parseJwt(token);
      return payload['userId'] ?? payload['id'] ?? payload['sub'];
    } catch (e) {
      return null;
    }
  }

  /// Get user email from stored user data
  static Future<String?> getUserEmail() async {
    try {
      final user = await getUser();
      return user?['email'];
    } catch (e) {
      return null;
    }
  }

  /// Check if token is about to expire (within 5 minutes)
  static Future<bool> isTokenExpiringSoon() async {
    try {
      final token = await getToken();
      if (token == null) return true;

      final expiryDate = Jwt.getExpiryDate(token);
      if (expiryDate == null) return true;

      final now = DateTime.now();
      final timeUntilExpiry = expiryDate.difference(now);

      // Consider token expiring soon if less than 5 minutes remain
      return timeUntilExpiry.inMinutes < 5;
    } catch (e) {
      return true;
    }
  }

  /// Login with tokens and user data
  static Future<bool> login({
    required String token,
    String? refreshToken,
    Map<String, dynamic>? user,
  }) async {
    try {
      // Store token
      final tokenSet = await setToken(token);
      if (!tokenSet) return false;

      // Store refresh token if provided
      if (refreshToken != null) {
        await setRefreshToken(refreshToken);
      }

      // Store user data if provided
      if (user != null) {
        await setUser(user);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Logout and clear all stored data
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      // Ignore errors during logout
    }
  }

  /// Clear all authentication data
  static Future<void> clearAll() async {
    await logout();
  }

  /// Get authorization header value
  static Future<String?> getAuthorizationHeader() async {
    final token = await getToken();
    if (token == null) return null;
    return 'Bearer $token';
  }

  /// Update user data
  static Future<bool> updateUser(Map<String, dynamic> userData) async {
    try {
      final currentUser = await getUser();
      if (currentUser == null) return false;

      // Merge with existing user data
      final updatedUser = {...currentUser, ...userData};
      return await setUser(updatedUser);
    } catch (e) {
      return false;
    }
  }

  /// Check if specific permission exists in token
  static Future<bool> hasPermission(String permission) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final payload = Jwt.parseJwt(token);
      final permissions = payload['permissions'] as List<dynamic>?;

      return permissions?.contains(permission) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get all permissions from token
  static Future<List<String>> getPermissions() async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final payload = Jwt.parseJwt(token);
      final permissions = payload['permissions'] as List<dynamic>?;

      return permissions?.cast<String>() ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Get token expiry date
  static Future<DateTime?> getTokenExpiryDate() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      return Jwt.getExpiryDate(token);
    } catch (e) {
      return null;
    }
  }
}
