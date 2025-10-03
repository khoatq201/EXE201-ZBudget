import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'services/auth_service.dart';
import 'services/expense_service.dart';
import 'services/savings_service.dart';
import 'services/group_service.dart';
import 'services/challenge_service.dart';
import 'services/profile_service.dart';
import 'services/currency_service.dart';
import 'services/dashboard_service.dart';
import 'services/income_service.dart';
import 'constants/colors.dart';
import 'constants/typography.dart';
import 'config/app_router.dart' as app_router;

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
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ExpenseService()),
        ChangeNotifierProvider(create: (_) => SavingsService()),
        ChangeNotifierProvider(create: (_) => GroupService()),
        ChangeNotifierProvider(create: (_) => ChallengeService()),
        ChangeNotifierProvider(create: (_) => ProfileService()),
        ChangeNotifierProvider(create: (_) => CurrencyService()),
        ChangeNotifierProvider(create: (_) => DashboardService()),
        ChangeNotifierProvider(create: (_) => IncomeService()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp.router(
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
            routerConfig: app_router.router,
          );
        },
      ),
    );
  }
}

// Loading screen component
