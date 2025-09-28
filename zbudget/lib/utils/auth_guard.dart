import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

/// AuthGuard - Utility class for protecting routes
/// Provides non-intrusive authentication checking for GoRouter
class AuthGuard {
  /// List of routes that require authentication
  static const List<String> protectedRoutes = [
    '/home',
    '/budget',
    '/groups',
    '/challenges',
    '/reports',
    '/settings',
    '/add-expense',
    '/add-income',
    '/create-budget',
    '/create-group',
    '/profile',
    '/edit-profile',
    '/security',
    '/notifications',
  ];

  /// Public routes that don't require authentication
  static const List<String> publicRoutes = [
    '/',
    '/login',
    '/signup',
    '/verify-otp',
    '/forgot-password',
    '/onboarding',
    '/splash',
    '/result',
  ];

  /// Check if a route requires authentication
  static bool isProtectedRoute(String path) {
    return protectedRoutes.any((route) => path.startsWith(route));
  }

  /// Check if a route is public (doesn't require authentication)
  static bool isPublicRoute(String path) {
    return publicRoutes.contains(path) || path.startsWith('/result');
  }

  /// Main authentication guard function for GoRouter
  /// Returns redirect path if authentication required, null if access allowed
  static String? checkAuthentication(
    BuildContext context,
    GoRouterState state,
  ) {
    try {
      final authService = context.read<AuthService>();
      final currentPath = state.fullPath ?? state.matchedLocation;

      // Debug logging
      debugPrint('🔐 AuthGuard: Checking route: $currentPath');
      debugPrint(
        '🔐 AuthGuard: User authenticated: ${authService.isAuthenticated}',
      );

      // Allow access to public routes
      if (isPublicRoute(currentPath)) {
        debugPrint('🟢 AuthGuard: Public route, access allowed');
        return null;
      }

      // Check authentication for protected routes
      if (isProtectedRoute(currentPath)) {
        if (!authService.isAuthenticated) {
          debugPrint('🔴 AuthGuard: Protected route, redirecting to login');
          return '/login';
        }
        debugPrint(
          '🟢 AuthGuard: Protected route, user authenticated, access allowed',
        );
        return null;
      }

      // Default: allow access for unmatched routes
      debugPrint('🟡 AuthGuard: Unmatched route, allowing access');
      return null;
    } catch (e) {
      debugPrint('❌ AuthGuard: Error checking authentication: $e');
      // On error, redirect to login for safety
      return '/login';
    }
  }

  /// Helper method to check if user is authenticated
  static bool isAuthenticated(BuildContext context) {
    try {
      final authService = context.read<AuthService>();
      return authService.isAuthenticated;
    } catch (e) {
      debugPrint('❌ AuthGuard: Error checking auth status: $e');
      return false;
    }
  }

  /// Helper method to get current user
  static dynamic getCurrentUser(BuildContext context) {
    try {
      final authService = context.read<AuthService>();
      return authService.currentUser;
    } catch (e) {
      debugPrint('❌ AuthGuard: Error getting current user: $e');
      return null;
    }
  }

  /// Force logout and redirect to login
  static Future<void> forceLogout(BuildContext context) async {
    try {
      final authService = context.read<AuthService>();
      await authService.logout();

      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      debugPrint('❌ AuthGuard: Error during force logout: $e');
    }
  }
}
