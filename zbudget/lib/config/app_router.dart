import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/password_reset_otp_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/main_navigator.dart';
import '../screens/home/dashboard_screen_api.dart';
import '../screens/home/add_expense_screen.dart';
import '../screens/home/add_income_screen.dart';
import '../screens/home/all_transactions_screen.dart';
import '../screens/budget/budget_list_screen.dart';
import '../screens/budget/create_budget_screen.dart';
import '../screens/group/group_list_screen.dart';
import '../screens/group/create_group_screen.dart';
import '../screens/challenge_screen.dart';
import '../screens/challenge_detail_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/settings/profile/profile_screen.dart';
import '../screens/settings/profile/edit_profile_screen.dart';
import '../screens/settings/security/security_screen.dart';
import '../screens/settings/notifications/notifications_screen.dart';
import '../screens/settings/theme/theme_screen.dart';
import '../screens/settings/language/language_screen.dart';
import '../screens/settings/currency/currency_screen.dart';
import '../screens/settings/about/about_screen.dart';
import '../screens/settings/help/help_screen.dart';
import '../screens/settings/feedback/feedback_screen.dart';
import '../screens/auth/result_screen.dart';
import '../screens/auth/complete_profile_screen.dart';
import '../utils/auth_guard.dart';
import '../screens/initialization_wrapper.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const InitializationWrapper(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OTPVerificationScreen(
          email: extra?['email'] ?? '',
          fullName: extra?['fullName'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/password-reset-otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PasswordResetOTPScreen(email: extra?['email'] ?? '');
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ResetPasswordScreen(
          email: extra?['email'] ?? '',
          otp: extra?['otp'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) => const CompleteProfileScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ResultScreen(
          isSuccess: extra?['isSuccess'] ?? false,
          title: extra?['title'] ?? '',
          message: extra?['message'] ?? '',
          buttonText: extra?['buttonText'] ?? 'OK',
          onButtonPressed: () {
            final nextRoute = extra?['nextRoute'] ?? '/home';
            context.go(nextRoute);
          },
        );
      },
    ),
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    // Main app shell với bottom navigation
    ShellRoute(
      builder: (context, state, child) => MainNavigator(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardScreenApi(),
          redirect: AuthGuard.checkAuthentication, // ✅ Route protection
        ),
        GoRoute(
          path: '/budget',
          builder: (context, state) => const BudgetListScreen(),
          redirect: AuthGuard.checkAuthentication, // ✅ Route protection
        ),
        GoRoute(
          path: '/groups',
          builder: (context, state) => const GroupListScreen(),
          redirect: AuthGuard.checkAuthentication, // ✅ Route protection
        ),
        GoRoute(
          path: '/challenges',
          builder: (context, state) => const ChallengeScreen(),
          redirect: AuthGuard.checkAuthentication, // ✅ Route protection
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
          redirect: AuthGuard.checkAuthentication, // ✅ Route protection
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
          redirect: AuthGuard.checkAuthentication, // ✅ Route protection
        ),
        // Detail screens
        GoRoute(
          path: '/add-expense',
          builder: (context, state) => const AddExpenseScreen(),
          redirect: AuthGuard.checkAuthentication, // ✅ Route protection
        ),
        GoRoute(
          path: '/add-income',
          builder: (context, state) => const AddIncomeScreen(),
        ),
        GoRoute(
          path: '/transactions/all',
          builder: (context, state) => const AllTransactionsScreen(),
          redirect: AuthGuard.checkAuthentication,
        ),
        GoRoute(
          path: '/create-budget',
          builder: (context, state) => const CreateBudgetScreen(),
        ),
        GoRoute(
          path: '/create-group',
          builder: (context, state) => const CreateGroupScreen(),
        ),
        GoRoute(
          path: '/challenge-detail',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ChallengeDetailScreen(
              challengeId: extra?['challengeId'] ?? '',
            );
          },
        ),
        // Settings sub-screens
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/security',
          builder: (context, state) => const SecurityScreen(),
        ),
        GoRoute(
          path: '/notifications-settings',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/theme',
          builder: (context, state) => const ThemeScreen(),
        ),
        GoRoute(
          path: '/language',
          builder: (context, state) => const LanguageScreen(),
        ),
        GoRoute(
          path: '/currency',
          builder: (context, state) => const CurrencyScreen(),
        ),
        GoRoute(
          path: '/about',
          builder: (context, state) => const AboutScreen(),
        ),
        GoRoute(path: '/help', builder: (context, state) => const HelpScreen()),
        GoRoute(
          path: '/feedback',
          builder: (context, state) => const FeedbackScreen(),
        ),
      ],
    ),
  ],
);
