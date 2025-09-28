import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/auth_guard.dart';

/// RouteGuards - Configuration and utilities for route protection
/// Provides centralized route guard management
class RouteGuards {
  /// Apply authentication guard to a GoRoute
  static GoRoute protectedRoute({
    required String path,
    required Widget Function(BuildContext, GoRouterState) builder,
    List<RouteBase> routes = const <RouteBase>[],
    String? name,
    String? parentNavigatorKey,
  }) {
    return GoRoute(
      path: path,
      name: name,
      builder: builder,
      routes: routes,
      redirect: AuthGuard.checkAuthentication,
    );
  }

  /// Create a public route (no authentication required)
  static GoRoute publicRoute({
    required String path,
    required Widget Function(BuildContext, GoRouterState) builder,
    List<RouteBase> routes = const <RouteBase>[],
    String? name,
    String? parentNavigatorKey,
  }) {
    return GoRoute(
      path: path,
      name: name,
      builder: builder,
      routes: routes,
      // No redirect - public access
    );
  }

  /// Apply guards to ShellRoute
  static ShellRoute protectedShellRoute({
    required Widget Function(BuildContext, GoRouterState, Widget) builder,
    required List<RouteBase> routes,
    String? navigatorKey,
  }) {
    return ShellRoute(
      builder: builder,
      routes: routes.map((route) {
        if (route is GoRoute) {
          return GoRoute(
            path: route.path,
            name: route.name,
            builder: route.builder!,
            routes: route.routes,
            redirect: AuthGuard.checkAuthentication,
          );
        }
        return route;
      }).toList(),
    );
  }

  /// Configuration for different types of routes
  static const Map<String, RouteConfig> routeConfigs = {
    // Public routes - no authentication required
    '/': RouteConfig(requiresAuth: false, allowGuests: true),
    '/login': RouteConfig(requiresAuth: false, allowGuests: true),
    '/signup': RouteConfig(requiresAuth: false, allowGuests: true),
    '/verify-otp': RouteConfig(requiresAuth: false, allowGuests: true),
    '/forgot-password': RouteConfig(requiresAuth: false, allowGuests: true),
    '/onboarding': RouteConfig(requiresAuth: false, allowGuests: true),
    '/splash': RouteConfig(requiresAuth: false, allowGuests: true),
    '/result': RouteConfig(requiresAuth: false, allowGuests: true),

    // Protected routes - authentication required
    '/home': RouteConfig(requiresAuth: true, allowGuests: false),
    '/budget': RouteConfig(requiresAuth: true, allowGuests: false),
    '/groups': RouteConfig(requiresAuth: true, allowGuests: false),
    '/challenges': RouteConfig(requiresAuth: true, allowGuests: false),
    '/reports': RouteConfig(requiresAuth: true, allowGuests: false),
    '/settings': RouteConfig(requiresAuth: true, allowGuests: false),

    // Feature routes - authentication required
    '/add-expense': RouteConfig(requiresAuth: true, allowGuests: false),
    '/add-income': RouteConfig(requiresAuth: true, allowGuests: false),
    '/create-budget': RouteConfig(requiresAuth: true, allowGuests: false),
    '/create-group': RouteConfig(requiresAuth: true, allowGuests: false),

    // Profile routes - authentication required
    '/profile': RouteConfig(requiresAuth: true, allowGuests: false),
    '/edit-profile': RouteConfig(requiresAuth: true, allowGuests: false),
    '/security': RouteConfig(requiresAuth: true, allowGuests: false),
    '/notifications': RouteConfig(requiresAuth: true, allowGuests: false),
  };

  /// Get route configuration
  static RouteConfig? getRouteConfig(String path) {
    return routeConfigs[path];
  }

  /// Check if route requires authentication
  static bool requiresAuthentication(String path) {
    final config = getRouteConfig(path);
    return config?.requiresAuth ?? AuthGuard.isProtectedRoute(path);
  }

  /// Check if route allows guest access
  static bool allowsGuests(String path) {
    final config = getRouteConfig(path);
    return config?.allowGuests ?? AuthGuard.isPublicRoute(path);
  }

  /// Validate route access based on authentication status
  static bool canAccessRoute(String path, bool isAuthenticated) {
    if (requiresAuthentication(path)) {
      return isAuthenticated;
    }
    return true; // Public routes can always be accessed
  }

  /// Get recommended redirect for unauthorized access
  static String getUnauthorizedRedirect(String attemptedPath) {
    // Special cases for different attempted paths
    if (attemptedPath.startsWith('/settings')) {
      return '/login'; // Settings require full authentication
    }
    if (attemptedPath.startsWith('/profile')) {
      return '/login'; // Profile requires authentication
    }

    // Default redirect
    return '/login';
  }

  /// Log route access attempt
  static void logRouteAccess(
    String path,
    bool isAuthenticated,
    bool accessGranted,
  ) {
    final status = accessGranted ? '✅ GRANTED' : '❌ DENIED';
    final authStatus = isAuthenticated ? 'AUTHENTICATED' : 'UNAUTHENTICATED';

    debugPrint('🛣️ ROUTE ACCESS: $path | $authStatus | $status');
  }
}

/// Route configuration data class
class RouteConfig {
  final bool requiresAuth;
  final bool allowGuests;
  final List<String>? requiredPermissions;
  final String? redirectOnUnauthorized;

  const RouteConfig({
    required this.requiresAuth,
    required this.allowGuests,
    this.requiredPermissions,
    this.redirectOnUnauthorized,
  });
}
