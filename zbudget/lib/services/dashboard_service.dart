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
  /// [budgetId] optional budget ID to display specific budget info
  Future<void> getDashboardSummary({
    String period = 'month',
    String? budgetId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No access token found. Please login again.');
      }

      debugPrint('🎯 Fetching dashboard summary for period: $period, budgetId: $budgetId');

      // Build query parameters
      final queryParams = {'period': period};
      if (budgetId != null) {
        queryParams['budgetId'] = budgetId;
      }

      final uri = Uri.parse('$baseUrl/summary').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
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

  /// Get all transactions with filtering
  /// [type] can be 'all', 'income', or 'expense'
  /// [startDate] and [endDate] are optional date filters
  /// [limit] and [skip] are for pagination
  Future<Map<String, dynamic>> getAllTransactions({
    String type = 'all',
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? skip,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No access token found. Please login again.');
      }

      // Build query parameters
      final queryParams = <String, String>{
        'type': type,
      };

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }
      if (skip != null) {
        queryParams['skip'] = skip.toString();
      }

      final uri = Uri.parse('$baseUrl/transactions').replace(queryParameters: queryParams);
      debugPrint('📋 Fetching all transactions: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📡 Transactions API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          final transactionsList = (data['transactions'] as List)
              .map((txn) => Transaction.fromJson(txn))
              .toList();

          debugPrint('✅ Loaded ${transactionsList.length} transactions');

          return {
            'transactions': transactionsList,
            'total': data['total'] ?? transactionsList.length,
            'hasMore': data['hasMore'] ?? false,
          };
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load transactions');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to load transactions');
      }
    } catch (e) {
      debugPrint('❌ Get all transactions error: $e');
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
