import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'services/auth_service.dart';
import 'services/expense_service.dart';
import 'services/savings_service.dart';
import 'services/budget_service.dart';
import 'services/group_service.dart';
import 'services/challenge_service.dart';
import 'services/profile_service.dart';
import 'services/currency_service.dart';
import 'services/dashboard_service.dart';
import 'services/income_service.dart';
import 'services/security_service.dart';
import 'services/notification_service.dart';
import 'services/report_service.dart';
import 'services/theme_manager.dart';
import 'config/app_router.dart' as app_router;
import 'widgets/activity_detector.dart';

void main() {
  runApp(const ZBudgetApp());
}

class ZBudgetApp extends StatelessWidget {
  const ZBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AppProvider vẫn giữ để quản lý user authentication
        ChangeNotifierProvider(create: (_) => AppProvider()),
        // ThemeManager quản lý theme đơn giản
        ChangeNotifierProvider(create: (_) => ThemeManager()..initialize()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ExpenseService()),
        ChangeNotifierProvider(create: (_) => SavingsService()),
        ChangeNotifierProvider(create: (_) => BudgetService()),
        ChangeNotifierProvider(create: (_) => GroupService()),
        ChangeNotifierProvider(create: (_) => ChallengeService()),
        ChangeNotifierProvider(create: (_) => ProfileService()),
        ChangeNotifierProvider(create: (_) => CurrencyService()),
        ChangeNotifierProvider(create: (_) => DashboardService()),
        ChangeNotifierProvider(create: (_) => IncomeService()),
        ChangeNotifierProvider(create: (_) => SecurityService()),
        ChangeNotifierProvider(
          create: (_) => NotificationService()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => ReportService()),
      ],
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          debugPrint(
            '🎨 App rebuilding with theme: ${themeManager.currentTheme}',
          );
          debugPrint('🎨 ThemeMode: ${themeManager.themeMode}');

          return ActivityDetector(
            child: MaterialApp.router(
              title: 'ZBudget',
              debugShowCheckedModeBanner: false,
              theme: ThemeManager.lightTheme,
              darkTheme: ThemeManager.darkTheme,
              themeMode: themeManager.themeMode,
              routerConfig: app_router.router,
            ),
          );
        },
      ),
    );
  }
}

// Loading screen component
