import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'services/expense_service.dart';
import 'services/savings_service.dart';
import 'services/group_service.dart';
import 'constants/colors.dart';
import 'constants/typography.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_navigator.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const ZBudgetApp());
}

class ZBudgetApp extends StatelessWidget {
  const ZBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseService()),
        ChangeNotifierProvider(create: (_) => SavingsService()),
        ChangeNotifierProvider(create: (_) => GroupService()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'ZBudget',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.green,
              primaryColor: AppColors.primary500,
              scaffoldBackgroundColor: AppColors.backgroundPrimary,
              fontFamily: 'System',
              textTheme: AppTypography.textTheme,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary500,
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.green,
              primaryColor: AppColors.primary400,
              scaffoldBackgroundColor: AppColors.backgroundDark,
              fontFamily: 'System',
              textTheme: AppTypography.textTheme,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary400,
                brightness: Brightness.dark,
              ),
            ),
            themeMode: appProvider.themeMode,
            home: appProvider.isFirstLaunch
                ? const OnboardingScreen()
                : (appProvider.isAuthenticated
                      ? const MainNavigator()
                      : const LoginScreen()),
          );
        },
      ),
    );
  }
}

// Loading screen component
