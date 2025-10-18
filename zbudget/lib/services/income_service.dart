import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/income.dart';
import '../utils/date_formatter.dart';
import '../utils/secure_storage_manager.dart';
import 'notification_sync_service.dart';
import '../main.dart';

class IncomeService extends ChangeNotifier {
  // Base URL - different for web and mobile
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/income';
    } else {
      return 'http://10.0.2.2:3000/api/income';
    }
  }

  List<Income> _incomes = [];
  bool _isLoading = false;
  String? _error;
  Pagination? _pagination;

  // Getters
  List<Income> get incomes => List.unmodifiable(_incomes);
  bool get isLoading => _isLoading;
  String? get error => _error;
  Pagination? get pagination => _pagination;

  /// Get authorization header
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorageManager.getToken();

    if (token == null) {
      throw Exception('No access token found. Please login again.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Get all incomes with filters
  Future<void> getIncomes({
    String? category,
    String? startDate,
    String? endDate,
    bool? isRecurring,
    int page = 1,
    int limit = 50,
    String sort = '-date',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();

      // Build query parameters
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': sort,
      };

      if (category != null) queryParams['category'] = category;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (isRecurring != null)
        queryParams['isRecurring'] = isRecurring.toString();

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      debugPrint('📥 Fetching incomes from: $uri');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final incomeListResponse = IncomeListResponse.fromJson(
            jsonResponse['data'],
          );
          _incomes = incomeListResponse.incomes;
          _pagination = incomeListResponse.pagination;
          _error = null;
          debugPrint('✅ Loaded ${_incomes.length} incomes');
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load incomes');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to load incomes');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Get incomes error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get single income by ID
  Future<Income> getIncomeById(String id) async {
    try {
      final headers = await _getHeaders();
      debugPrint('📥 Fetching income: $id');

      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return Income.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load income');
        }
      } else {
        throw Exception('Failed to load income');
      }
    } catch (e) {
      debugPrint('❌ Get income error: $e');
      rethrow;
    }
  }

  /// Create new income
  Future<Income> createIncome({
    required String title,
    String? description,
    required double amount,
    required String category,
    DateTime? date,
    String? paymentMethod,
    String? source,
    bool? isRecurring,
    Map<String, dynamic>? recurringDetails,
    Map<String, dynamic>? taxInfo,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();

      final body = {'title': title, 'amount': amount, 'category': category};

      if (description != null) body['description'] = description;
      if (date != null) {
        // Use standardized date formatter to avoid timezone issues
        body['date'] = DateFormatter.toApiFormat(date);
      }
      if (paymentMethod != null) body['paymentMethod'] = paymentMethod;
      if (source != null) body['source'] = source;
      if (isRecurring != null) body['isRecurring'] = isRecurring;
      if (recurringDetails != null) body['recurringDetails'] = recurringDetails;
      if (taxInfo != null) body['taxInfo'] = taxInfo;

      debugPrint('➕ Creating income: $title');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final newIncome = Income.fromJson(jsonResponse['data']);
          _incomes.insert(0, newIncome); // Add to beginning

          // ✅ KEY: Trigger notification refresh after successful creation
          await _refreshNotificationsAfterAction();

          debugPrint('✅ Income created: ${newIncome.id}');
          notifyListeners();
          return newIncome;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to create income');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to create income');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Create income error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update income
  Future<Income> updateIncome(
    String id, {
    String? title,
    String? description,
    double? amount,
    String? category,
    DateTime? date,
    String? paymentMethod,
    String? source,
  }) async {
    try {
      final headers = await _getHeaders();

      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (amount != null) body['amount'] = amount;
      if (category != null) body['category'] = category;
      if (date != null) {
        // Use standardized date formatter to avoid timezone issues
        body['date'] = DateFormatter.toApiFormat(date);
      }
      if (paymentMethod != null) body['paymentMethod'] = paymentMethod;
      if (source != null) body['source'] = source;

      debugPrint('✏️ Updating income: $id');

      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final updatedIncome = Income.fromJson(jsonResponse['data']);

          // Update in local list
          final index = _incomes.indexWhere((i) => i.id == id);
          if (index != -1) {
            _incomes[index] = updatedIncome;
            notifyListeners();
          }

          debugPrint('✅ Income updated: $id');
          return updatedIncome;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to update income');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to update income');
      }
    } catch (e) {
      debugPrint('❌ Update income error: $e');
      rethrow;
    }
  }

  /// Delete income
  Future<void> deleteIncome(String id) async {
    try {
      final headers = await _getHeaders();
      debugPrint('🗑️ Deleting income: $id');

      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Remove from local list
        _incomes.removeWhere((i) => i.id == id);
        notifyListeners();
        debugPrint('✅ Income deleted: $id');
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to delete income');
      }
    } catch (e) {
      debugPrint('❌ Delete income error: $e');
      rethrow;
    }
  }

  /// Get income statistics
  Future<IncomeStats> getIncomeStats({
    String? startDate,
    String? endDate,
    String groupBy = 'category', // 'category', 'month', 'paymentMethod'
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = {'groupBy': groupBy};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse(
        '$baseUrl/stats',
      ).replace(queryParameters: queryParams);
      debugPrint('📊 Fetching income stats');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return IncomeStats.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load stats');
        }
      } else {
        throw Exception('Failed to load income statistics');
      }
    } catch (e) {
      debugPrint('❌ Get income stats error: $e');
      rethrow;
    }
  }

  /// Refresh incomes list
  Future<void> refresh() async {
    return getIncomes();
  }

  /// Clear cached data
  void clearData() {
    _incomes = [];
    _pagination = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// ✅ NEW: Refresh notifications after action
  Future<void> _refreshNotificationsAfterAction() async {
    try {
      // Get notification service from context
      final notificationService = Provider.of<NotificationSyncService>(
        navigatorKey.currentContext!,
        listen: false,
      );

      // Refresh notifications
      await notificationService.fetchNotifications();

      debugPrint('🔄 Notifications refreshed after income creation');
    } catch (error) {
      debugPrint('❌ Failed to refresh notifications: $error');
    }
  }
}
