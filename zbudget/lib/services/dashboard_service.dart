import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/dashboard.dart';
import '../utils/secure_storage_manager.dart';

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
      final token = await SecureStorageManager.getToken();

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
      final token = await SecureStorageManager.getToken();

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
        debugPrint('✅ Quick stats response: ${response.body}');

        // Safe handling of data
        final data = jsonResponse['data'];
        if (data is! Map<String, dynamic>) {
          throw Exception('Invalid data format from server');
        }

        // Safe number parsing with fallbacks
        double parseNum(dynamic value) {
          if (value == null) return 0.0;
          if (value is num) return value.toDouble();
          if (value is String) return double.tryParse(value) ?? 0.0;
          if (value is Map) {
            // Handle Decimal128 from MongoDB
            final val = value.values.isNotEmpty ? value.values.first : 0;
            if (val is num) return val.toDouble();
            if (val is String) return double.tryParse(val) ?? 0.0;
          }
          return 0.0;
        }

        return {
          'currentBalance': parseNum(data['currentBalance']),
          'totalIncome': parseNum(data['totalIncome']),
          'totalExpenses': parseNum(data['totalExpenses']),
          'totalSavings': parseNum(data['totalSavings']),
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
      final token = await SecureStorageManager.getToken();

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
        debugPrint('✅ Transactions response: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];

          // Safe handling of transactions array
          List<Transaction> transactionsList = [];
          try {
            final txnData = data['transactions'];
            if (txnData is List) {
              transactionsList = txnData
                  .map((txn) {
                    try {
                      return Transaction.fromJson(txn);
                    } catch (e) {
                      debugPrint('❌ Error parsing transaction: $e');
                      return null;
                    }
                  })
                  .whereType<Transaction>()
                  .toList();
            } else {
              debugPrint('⚠️ transactions is not a List: ${txnData.runtimeType}');
            }
          } catch (e) {
            debugPrint('❌ Error parsing transactions list: $e');
          }

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
