import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage manager with automatic migration from SharedPreferences
///
/// This manager provides secure token storage using flutter_secure_storage
/// with automatic migration from old SharedPreferences storage.
///
/// Features:
/// - Automatic migration from SharedPreferences to SecureStorage
/// - Fallback mechanism if secure storage fails
/// - Backward compatible with existing tokens
class SecureStorageManager {
  // Secure storage instance (encrypted)
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Keys for token storage
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  /// Get access token with automatic migration
  ///
  /// Tries to read from secure storage first.
  /// If not found, checks SharedPreferences and migrates the token.
  static Future<String?> getToken() async {
    try {
      // Try secure storage first
      String? token = await _secureStorage.read(key: _accessTokenKey);

      // If not in secure storage, check SharedPreferences (migration)
      if (token == null) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString(_accessTokenKey);

        if (token != null) {
          // Migrate to secure storage
          await _secureStorage.write(key: _accessTokenKey, value: token);
          // Clean up old storage
          await prefs.remove(_accessTokenKey);
        }
      }

      return token;
    } catch (e) {
      // Fallback to SharedPreferences if secure storage fails
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_accessTokenKey);
      } catch (_) {
        return null;
      }
    }
  }

  /// Set access token (always uses secure storage)
  static Future<void> setToken(String token) async {
    try {
      await _secureStorage.write(key: _accessTokenKey, value: token);
    } catch (e) {
      // Fallback to SharedPreferences if secure storage fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, token);
    }
  }

  /// Get refresh token with automatic migration
  static Future<String?> getRefreshToken() async {
    try {
      String? token = await _secureStorage.read(key: _refreshTokenKey);

      if (token == null) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString(_refreshTokenKey);

        if (token != null) {
          await _secureStorage.write(key: _refreshTokenKey, value: token);
          await prefs.remove(_refreshTokenKey);
        }
      }

      return token;
    } catch (e) {
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_refreshTokenKey);
      } catch (_) {
        return null;
      }
    }
  }

  /// Set refresh token
  static Future<void> setRefreshToken(String token) async {
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshTokenKey, token);
    }
  }

  /// Get user data with automatic migration
  static Future<String?> getUserData() async {
    try {
      String? userData = await _secureStorage.read(key: _userDataKey);

      if (userData == null) {
        final prefs = await SharedPreferences.getInstance();
        userData = prefs.getString(_userDataKey);

        if (userData != null) {
          await _secureStorage.write(key: _userDataKey, value: userData);
          await prefs.remove(_userDataKey);
        }
      }

      return userData;
    } catch (e) {
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_userDataKey);
      } catch (_) {
        return null;
      }
    }
  }

  /// Set user data
  static Future<void> setUserData(String userData) async {
    try {
      await _secureStorage.write(key: _userDataKey, value: userData);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, userData);
    }
  }

  /// Delete access token
  static Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: _accessTokenKey);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
    }
  }

  /// Delete refresh token
  static Future<void> deleteRefreshToken() async {
    try {
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_refreshTokenKey);
    }
  }

  /// Delete user data
  static Future<void> deleteUserData() async {
    try {
      await _secureStorage.delete(key: _userDataKey);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
    }
  }

  /// Clear all secure data (logout)
  static Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      // Fallback: clear from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userDataKey);
    }
  }

  /// Check if token exists
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
