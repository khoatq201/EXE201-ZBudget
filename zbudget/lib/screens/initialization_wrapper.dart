import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../providers/app_provider.dart';
import 'onboarding_screen.dart';
import 'auth/login_screen.dart';
import 'home/new_dashboard_screen.dart';

class InitializationWrapper extends StatefulWidget {
  const InitializationWrapper({super.key});

  @override
  State<InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends State<InitializationWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize AuthService FIRST
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.initialize();

      // Initialize ProfileService
      final profileService = Provider.of<ProfileService>(
        context,
        listen: false,
      );
      await profileService.initialize();

      // Initialize other services if needed

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing services: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer2<AppProvider, AuthService>(
      builder: (context, appProvider, authService, child) {
        // With GoRouter, we just return a simple loading state
        // The actual routing is handled by AppRouter
        if (appProvider.isFirstLaunch) {
          return const OnboardingScreen();
        } else if (authService.isAuthenticated) {
          return const NewDashboardScreen(); // Default authenticated screen
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
