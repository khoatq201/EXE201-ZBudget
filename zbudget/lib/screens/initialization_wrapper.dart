import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../providers/app_provider.dart';

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
        // Navigate to appropriate route based on state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (appProvider.isFirstLaunch) {
            context.go('/onboarding');
          } else if (authService.isAuthenticated) {
            context.go('/home'); // Navigate to home with bottom navbar
          } else {
            context.go('/login');
          }
        });

        // Show loading while navigation happens
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
