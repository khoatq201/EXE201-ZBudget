import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'providers/app_provider.dart';
import 'services/auth_service.dart';
import 'services/expense_service.dart';
import 'services/savings_service.dart';
import 'services/budget_service.dart';
import 'services/group_service.dart';
import 'services/group_budget_service.dart';
import 'services/challenge_service.dart';
import 'services/profile_service.dart';
import 'services/currency_service.dart';
import 'services/dashboard_service.dart';
import 'services/income_service.dart';
import 'services/security_service.dart';
import 'services/notification_service.dart';
import 'services/notification_sync_service.dart';
import 'services/report_service.dart';
import 'services/theme_manager.dart';
import 'config/app_router.dart' as app_router;
import 'widgets/activity_detector.dart';

// Global navigation key for deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification handling
  _initializeNotificationHandling();

  runApp(const ZBudgetApp());
}

/// Initialize notification handling for deep linking
void _initializeNotificationHandling() {
  // Handle notification taps when app is in background/terminated
  FlutterLocalNotificationsPlugin().initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: _handleNotificationResponse,
  );
}

/// Handle notification tap responses
void _handleNotificationResponse(NotificationResponse response) {
  debugPrint('📱 Notification tapped: ${response.payload}');

  final payload = response.payload;
  if (payload != null) {
    _navigateFromNotification(payload);
  }
}

/// Navigate based on notification payload
void _navigateFromNotification(String payload) {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  debugPrint('🔗 Navigating from notification: $payload');

  switch (payload) {
    case '/add-expense':
      Navigator.of(context).pushNamed('/expenses/add');
      break;
    case '/dashboard':
      Navigator.of(context).pushNamed('/dashboard');
      break;
    case '/budget':
      Navigator.of(context).pushNamed('/budgets');
      break;
    case '/notifications':
      Navigator.of(context).pushNamed('/notifications');
      break;
    case '/reports':
      Navigator.of(context).pushNamed('/reports');
      break;
    case '/challenges':
      Navigator.of(context).pushNamed('/challenges');
      break;
    default:
      if (payload.startsWith('/budget/')) {
        final budgetId = payload.split('/').last;
        Navigator.of(context).pushNamed('/budget/$budgetId');
      } else if (payload.startsWith('/savings/')) {
        final goalId = payload.split('/').last;
        Navigator.of(context).pushNamed('/savings/$goalId');
      } else {
        // Default to dashboard
        Navigator.of(context).pushNamed('/dashboard');
      }
      break;
  }
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
        ChangeNotifierProvider(create: (_) => GroupBudgetService()),
        ChangeNotifierProvider(create: (_) => ChallengeService()),
        ChangeNotifierProvider(create: (_) => ProfileService()),
        ChangeNotifierProvider(create: (_) => CurrencyService()),
        ChangeNotifierProvider(create: (_) => DashboardService()),
        ChangeNotifierProvider(create: (_) => IncomeService()),
        ChangeNotifierProvider(create: (_) => SecurityService()),
        ChangeNotifierProvider(
          create: (_) => NotificationService()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => NotificationSyncService()),
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
