import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../constants/colors.dart';

/// ProtectedRoute - Widget wrapper for routes requiring authentication
/// Provides additional layer of protection for sensitive screens
class ProtectedRoute extends StatefulWidget {
  final Widget child;
  final String? redirectTo;
  final bool showLoadingIndicator;
  final Widget? loadingWidget;
  final VoidCallback? onUnauthorized;

  const ProtectedRoute({
    super.key,
    required this.child,
    this.redirectTo = '/login',
    this.showLoadingIndicator = true,
    this.loadingWidget,
    this.onUnauthorized,
  });

  @override
  State<ProtectedRoute> createState() => _ProtectedRouteState();
}

class _ProtectedRouteState extends State<ProtectedRoute> {
  bool _hasCheckedAuth = false;

  @override
  void initState() {
    super.initState();
    // Check authentication after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  void _checkAuthentication() {
    if (!mounted) return;

    try {
      final authService = context.read<AuthService>();

      debugPrint('🔐 ProtectedRoute: Checking authentication...');
      debugPrint(
        '🔐 ProtectedRoute: User authenticated: ${authService.isAuthenticated}',
      );

      if (!authService.isAuthenticated) {
        debugPrint('🔴 ProtectedRoute: User not authenticated, redirecting...');

        // Call custom callback if provided
        if (widget.onUnauthorized != null) {
          widget.onUnauthorized!();
        }

        // Redirect to login or specified route
        if (widget.redirectTo != null) {
          context.go(widget.redirectTo!);
        }
      } else {
        debugPrint('🟢 ProtectedRoute: User authenticated, showing content');
      }

      setState(() {
        _hasCheckedAuth = true;
      });
    } catch (e) {
      debugPrint('❌ ProtectedRoute: Error checking authentication: $e');

      // On error, redirect to login for safety
      if (widget.redirectTo != null) {
        context.go(widget.redirectTo!);
      }

      setState(() {
        _hasCheckedAuth = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Show loading while checking authentication
        if (!_hasCheckedAuth && widget.showLoadingIndicator) {
          return widget.loadingWidget ?? _buildDefaultLoadingWidget();
        }

        // Show content if authenticated
        if (authService.isAuthenticated) {
          return widget.child;
        }

        // Show loading or empty container while redirecting
        return widget.loadingWidget ?? _buildDefaultLoadingWidget();
      },
    );
  }

  Widget _buildDefaultLoadingWidget() {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Đang xác thực...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// AuthCheck - Simple authentication checker widget
/// Use this for conditional rendering based on auth status
class AuthCheck extends StatelessWidget {
  final Widget authenticatedChild;
  final Widget? unauthenticatedChild;
  final bool redirectIfUnauthenticated;
  final String redirectTo;

  const AuthCheck({
    super.key,
    required this.authenticatedChild,
    this.unauthenticatedChild,
    this.redirectIfUnauthenticated = false,
    this.redirectTo = '/login',
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isAuthenticated) {
          return authenticatedChild;
        }

        // Redirect if specified
        if (redirectIfUnauthenticated) {
          Future.microtask(() => context.go(redirectTo));
          return const SizedBox.shrink();
        }

        // Show unauthenticated widget or empty container
        return unauthenticatedChild ?? const SizedBox.shrink();
      },
    );
  }
}

/// AuthBuilder - Builder pattern for authentication-dependent UI
class AuthBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    bool isAuthenticated,
    dynamic user,
  )
  builder;

  const AuthBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return builder(
          context,
          authService.isAuthenticated,
          authService.currentUser,
        );
      },
    );
  }
}
