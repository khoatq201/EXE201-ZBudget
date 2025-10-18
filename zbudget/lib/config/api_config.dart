import 'package:flutter/foundation.dart';

/// API Configuration for ZBudget App
class ApiConfig {
  // Base URLs for different environments
  static const String _devBaseUrlWeb = 'http://localhost:3000/api';
  static const String _devBaseUrlAndroid = 'http://10.0.2.2:3000/api';
  static const String _prodBaseUrl = 'https://your-production-api.com/api';
  static const String _stagingBaseUrl = 'https://your-staging-api.com/api';

  // Current environment
  static const bool _isDevelopment =
      true; // Change this based on build configuration
  static const bool _isProduction = false;

  /// Get the base URL based on the current environment
  static String get baseUrl {
    if (_isDevelopment) {
      // Different URLs for web and mobile
      if (kIsWeb) {
        // Running on web
        return _devBaseUrlWeb;
      } else {
        // Running on mobile (Android emulator needs 10.0.2.2)
        return _devBaseUrlAndroid;
      }
    } else if (_isProduction) {
      return _prodBaseUrl;
    } else {
      return _stagingBaseUrl;
    }
  }

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh-token';
  static const String profileEndpoint = '/auth/profile';

  // Settings endpoints
  static const String settingsEndpoint = '/settings';
  static const String currencySettingsEndpoint = '/settings/currency';
  static const String notificationSettingsEndpoint = '/settings/notifications';
  static const String securitySettingsEndpoint = '/settings/security';
  static const String themeSettingsEndpoint = '/settings/theme';
  static const String languageSettingsEndpoint = '/settings/language';
  static const String resetSettingsEndpoint = '/settings/reset';

  // Expense endpoints
  static const String expensesEndpoint = '/expenses';

  // Income endpoints
  static const String incomeEndpoint = '/income';

  // Dashboard endpoints
  static const String dashboardEndpoint = '/dashboard';

  // AI Endpoints
  static const String aiChatStart = '/ai/chat/start';
  static const String aiChatMessage = '/ai/chat/message';
  static const String aiChatHistory = '/ai/chat/history';
  static const String aiChatEnd = '/ai/chat/end';
  static const String aiChatSessions = '/ai/chat/sessions';

  // AI Analysis Endpoints
  static const String aiAnalysisDeep = '/ai/analysis/deep';
  static const String aiAnalysisForecast = '/ai/analysis/forecast';
  static const String aiAnalysisAnomalies = '/ai/analysis/anomalies';
  static const String aiAnalysisRecommendations =
      '/ai/analysis/recommendations';
  static const String aiAnalysisInsights = '/ai/analysis/insights';
  static const String aiAnalysisPatterns = '/ai/analysis/patterns';
  static const String aiAnalysisCache = '/ai/analysis/cache';

  // Request timeout settings
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);

  // API Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Get authorization headers with token
  static Map<String, String> getAuthHeaders(String token) {
    return {...defaultHeaders, 'Authorization': 'Bearer $token'};
  }
}
