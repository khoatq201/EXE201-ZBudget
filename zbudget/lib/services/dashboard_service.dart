import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard.dart';

class DashboardService extends ChangeNotifier {
  // Base URL - different for web and mobile
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/dashboard';
    } else {
      // For Android emulator: 10.0.2.2 maps to host machine's localhost
      return 'http://10.0.2.2:3000/api/dashboard';
    }
  }

  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _error;

  // Getters
  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get dashboard summary data
  /// [period] can be 'month', 'week', or 'year'
  Future<void> getDashboardSummary({String period = 'month'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No access token found. Please login again.');
      }

      debugPrint('🎯 Fetching dashboard summary for period: $period');

      final response = await http.get(
        Uri.parse('$baseUrl/summary?period=$period'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📡 Dashboard API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          _dashboardData = DashboardData.fromJson(jsonResponse['data']);
          _error = null;
          debugPrint('✅ Dashboard data loaded successfully');
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load dashboard data');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to load dashboard data');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Dashboard error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get quick stats (lightweight version)
  Future<Map<String, double>> getQuickStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No access token found');
      }

      debugPrint('📊 Fetching quick stats');

      final response = await http.get(
        Uri.parse('$baseUrl/quick-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final data = jsonResponse['data'] as Map<String, dynamic>;

        return {
          'currentBalance': (data['currentBalance'] as num).toDouble(),
          'totalIncome': (data['totalIncome'] as num).toDouble(),
          'totalExpenses': (data['totalExpenses'] as num).toDouble(),
          'totalSavings': (data['totalSavings'] as num).toDouble(),
        };
      } else {
        throw Exception('Failed to load quick stats');
      }
    } catch (e) {
      debugPrint('❌ Quick stats error: $e');
      rethrow;
    }
  }

  /// Refresh dashboard data
  Future<void> refresh({String period = 'month'}) async {
    return getDashboardSummary(period: period);
  }

  /// Clear cached data
  void clearData() {
    _dashboardData = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
