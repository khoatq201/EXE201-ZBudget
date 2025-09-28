import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../utils/auth_interceptor.dart';

/// AuthServiceExtension - Extends AuthService với additional utilities
/// Không thay đổi AuthService gốc, chỉ thêm helper methods
extension AuthServiceExtension on AuthService {
  /// Get authenticated HTTP headers for API calls
  Map<String, String> get authHeaders => AuthInterceptor.getAuthHeaders(this);

  /// Check if user has specific permission (future enhancement)
  bool hasPermission(String permission) {
    // Placeholder for future permission system
    return isAuthenticated;
  }

  /// Get user display name safely
  String get userDisplayName {
    return currentUser?.name ?? 'User';
  }

  /// Get user email safely
  String get userEmail {
    return currentUser?.email ?? '';
  }

  /// Check if user profile is complete
  bool get isProfileComplete {
    if (!isAuthenticated || currentUser == null) return false;

    // Add your profile completion logic here
    final user = currentUser!;
    return user.name.isNotEmpty && user.email.isNotEmpty;
  }

  /// Force refresh authentication state
  Future<void> forceRefresh() async {
    await initialize();
  }
}

/// AuthHelper - Static utilities for authentication
class AuthHelper {
  /// Quick check if context has authenticated user
  static bool isAuthenticated(BuildContext context) {
    try {
      final authService = context.read<AuthService>();
      return authService.isAuthenticated;
    } catch (e) {
      debugPrint('AuthHelper: Error checking authentication: $e');
      return false;
    }
  }

  /// Get current user from context
  static dynamic getCurrentUser(BuildContext context) {
    try {
      final authService = context.read<AuthService>();
      return authService.currentUser;
    } catch (e) {
      debugPrint('AuthHelper: Error getting user: $e');
      return null;
    }
  }

  /// Safe logout with error handling
  static Future<bool> safeLogout(BuildContext context) async {
    try {
      final authService = context.read<AuthService>();
      await authService.logout();
      return true;
    } catch (e) {
      debugPrint('AuthHelper: Error during logout: $e');
      return false;
    }
  }

  /// Show authentication required dialog
  static void showAuthRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu đăng nhập'),
        content: const Text('Bạn cần đăng nhập để sử dụng tính năng này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }
}
