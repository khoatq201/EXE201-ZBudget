import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/budget.dart';
import '../utils/secure_storage_manager.dart';
import 'notification_sync_service.dart';
import '../main.dart';

class BudgetService extends ChangeNotifier {
  List<Budget> _budgets = [];
  Budget? _currentBudget;
  BudgetStats? _stats;
  double _readyToAssign = 0;
  bool _isLoading = false;
  String? _error;

  List<Budget> get budgets => _budgets;
  Budget? get currentBudget => _currentBudget;
  BudgetStats? get stats => _stats;
  double get readyToAssign => _readyToAssign;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Budget> get activeBudgets => _budgets.where((b) => b.isActive).toList();
  List<Budget> get inactiveBudgets =>
      _budgets.where((b) => !b.isActive).toList();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/budgets';
    } else {
      return 'http://10.0.2.2:3000/api/budgets';
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorageManager.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Get all budgets with optional filters
  Future<void> getBudgets({
    String? status,
    String? period,
    int? year,
    int? month,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (period != null) queryParams['period'] = period;
      if (year != null) queryParams['year'] = year.toString();
      if (month != null) queryParams['month'] = month.toString();

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint(
          '✅ getBudgets response: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
        );

        if (data['success'] == true) {
          // Safe handling of budgets array
          try {
            final budgetsData = data['data']?['budgets'];
            if (budgetsData is List) {
              _budgets = budgetsData
                  .map((b) {
                    try {
                      return Budget.fromJson(b);
                    } catch (e) {
                      debugPrint('❌ Error parsing budget: $e');
                      return null;
                    }
                  })
                  .whereType<Budget>()
                  .toList();
            } else {
              debugPrint(
                '⚠️ budgets is not a List: ${budgetsData.runtimeType}',
              );
              _budgets = [];
            }
          } catch (e) {
            debugPrint('❌ Error parsing budgets: $e');
            _budgets = [];
          }

          // Safe handling of readyToAssign
          final rta = data['data']?['readyToAssign'];
          if (rta is num) {
            _readyToAssign = rta.toDouble();
          } else if (rta is String) {
            _readyToAssign = double.tryParse(rta) ?? 0;
          } else if (rta is Map) {
            // Nếu backend trả về kiểu Map (Decimal128), lấy giá trị
            final value = rta.values.isNotEmpty ? rta.values.first : 0;
            if (value is num) {
              _readyToAssign = value.toDouble();
            } else if (value is String) {
              _readyToAssign = double.tryParse(value) ?? 0;
            } else {
              _readyToAssign = 0;
            }
          } else {
            _readyToAssign = 0;
          }
        } else {
          _setError(data['message'] ?? 'Lỗi khi tải ngân sách');
        }
      } else {
        final data = json.decode(response.body);
        _setError(data['message'] ?? 'Lỗi khi tải ngân sách');
      }
    } catch (e) {
      _setError('Lỗi kết nối: ${e.toString()}');
      debugPrint('Error in getBudgets: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get budget by ID
  Future<Budget?> getBudgetById(String id) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Budget.fromJson(data['data']);
        } else {
          _setError(data['message'] ?? 'Lỗi khi tải ngân sách');
          return null;
        }
      } else {
        final data = json.decode(response.body);
        _setError(data['message'] ?? 'Lỗi khi tải ngân sách');
        return null;
      }
    } catch (e) {
      _setError('Lỗi kết nối: ${e.toString()}');
      debugPrint('Error in getBudgetById: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get current active budget
  Future<void> getCurrentBudget() async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/current');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _currentBudget = Budget.fromJson(data['data']);
        } else {
          _currentBudget = null;
        }
      } else if (response.statusCode == 404) {
        _currentBudget = null;
      } else {
        final data = json.decode(response.body);
        _setError(data['message'] ?? 'Lỗi khi tải ngân sách hiện tại');
      }
    } catch (e) {
      _setError('Lỗi kết nối: ${e.toString()}');
      debugPrint('Error in getCurrentBudget: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create new budget
  Future<Map<String, dynamic>> createBudget({
    required String name,
    required double totalAmount,
    String currency = 'VND',
    required BudgetPeriod period,
    required List<CategoryAllocation> categoryAllocations,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final body = json.encode({
        'name': name,
        'totalAmount': totalAmount,
        'currency': currency,
        'period': period.toJson(),
        'categoryAllocations': categoryAllocations
            .map((c) => c.toJson())
            .toList(),
      });

      final uri = Uri.parse(baseUrl);
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final newBudget = Budget.fromJson(data['data']);
          _budgets.insert(0, newBudget);
          notifyListeners();
          return {'success': true, 'message': data['message']};
        } else {
          _setError(data['message'] ?? 'Lỗi khi tạo ngân sách');
          return {'success': false, 'message': data['message']};
        }
      } else {
        final data = json.decode(response.body);
        _setError(data['message'] ?? 'Lỗi khi tạo ngân sách');
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      _setError('Lỗi kết nối: ${e.toString()}');
      debugPrint('Error in createBudget: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    } finally {
      _setLoading(false);
    }
  }

  /// Update budget
  Future<Map<String, dynamic>> updateBudget({
    required String id,
    String? name,
    double? totalAmount,
    String? currency,
    BudgetPeriod? period,
    List<CategoryAllocation>? categoryAllocations,
    bool? isActive,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (totalAmount != null) updates['totalAmount'] = totalAmount;
      if (currency != null) updates['currency'] = currency;
      if (period != null) updates['period'] = period.toJson();
      if (categoryAllocations != null) {
        updates['categoryAllocations'] = categoryAllocations
            .map((c) => c.toJson())
            .toList();
      }
      if (isActive != null) updates['isActive'] = isActive;

      final body = json.encode(updates);
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.put(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final updatedBudget = Budget.fromJson(data['data']);
          final index = _budgets.indexWhere((b) => b.id == id);
          if (index != -1) {
            _budgets[index] = updatedBudget;
          }

          // ✅ KEY: Trigger notification refresh after successful update
          await _refreshNotificationsAfterAction();

          notifyListeners();
          return {'success': true, 'message': data['message']};
        } else {
          _setError(data['message'] ?? 'Lỗi khi cập nhật ngân sách');
          return {'success': false, 'message': data['message']};
        }
      } else {
        final data = json.decode(response.body);
        _setError(data['message'] ?? 'Lỗi khi cập nhật ngân sách');
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      _setError('Lỗi kết nối: ${e.toString()}');
      debugPrint('Error in updateBudget: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    } finally {
      _setLoading(false);
    }
  }

  /// Delete budget
  Future<Map<String, dynamic>> deleteBudget(String id) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _budgets.removeWhere((b) => b.id == id);
          notifyListeners();
          return {'success': true, 'message': data['message']};
        } else {
          _setError(data['message'] ?? 'Lỗi khi xóa ngân sách');
          return {'success': false, 'message': data['message']};
        }
      } else {
        final data = json.decode(response.body);
        _setError(data['message'] ?? 'Lỗi khi xóa ngân sách');
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      _setError('Lỗi kết nối: ${e.toString()}');
      debugPrint('Error in deleteBudget: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    } finally {
      _setLoading(false);
    }
  }

  /// YNAB-style: Fund a budget category from Ready to Assign
  Future<Map<String, dynamic>> fundBudgetCategory({
    required String budgetId,
    required String category,
    required double amount,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final body = json.encode({'category': category, 'amount': amount});

      final uri = Uri.parse('$baseUrl/$budgetId/fund');
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ fundBudgetCategory response: ${response.body}');

        if (data['success'] == true) {
          try {
            // Safe handling of budget object
            final budgetData = data['data']?['budget'];
            if (budgetData == null) {
              throw Exception('Missing budget data in response');
            }

            final updatedBudget = Budget.fromJson(budgetData);

            // Safe handling of readyToAssign
            final rta = data['data']?['readyToAssign'];
            double newReadyToAssign = 0;
            if (rta is num) {
              newReadyToAssign = rta.toDouble();
            } else if (rta is String) {
              newReadyToAssign = double.tryParse(rta) ?? 0;
            } else if (rta is Map) {
              final value = rta.values.isNotEmpty ? rta.values.first : 0;
              if (value is num) {
                newReadyToAssign = value.toDouble();
              } else if (value is String) {
                newReadyToAssign = double.tryParse(value) ?? 0;
              }
            }

            // Update local state
            final index = _budgets.indexWhere((b) => b.id == budgetId);
            if (index != -1) {
              _budgets[index] = updatedBudget;
            }
            _readyToAssign = newReadyToAssign;

            notifyListeners();
            return {'success': true, 'message': data['message']};
          } catch (e) {
            debugPrint('❌ Error parsing fund response: $e');
            _setError('Lỗi xử lý dữ liệu: ${e.toString()}');
            return {'success': false, 'message': 'Lỗi xử lý dữ liệu'};
          }
        } else {
          _setError(data['message'] ?? 'Lỗi khi fund ngân sách');
          return {'success': false, 'message': data['message']};
        }
      } else {
        final data = json.decode(response.body);
        _setError(data['message'] ?? 'Lỗi khi fund ngân sách');
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      _setError('Lỗi kết nối: ${e.toString()}');
      debugPrint('Error in fundBudgetCategory: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    } finally {
      _setLoading(false);
    }
  }

  /// Get budget statistics
  Future<void> getBudgetStats({int? year, int? month}) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final queryParams = <String, String>{};
      if (year != null) queryParams['year'] = year.toString();
      if (month != null) queryParams['month'] = month.toString();

      final uri = Uri.parse(
        '$baseUrl/stats/summary',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _stats = BudgetStats.fromJson(data['data']);
        } else {
          _setError(data['message'] ?? 'Lỗi khi tải thống kê');
        }
      } else {
        final data = json.decode(response.body);
        _setError(data['message'] ?? 'Lỗi khi tải thống kê');
      }
    } catch (e) {
      _setError('Lỗi kết nối: ${e.toString()}');
      debugPrint('Error in getBudgetStats: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _budgets = [];
    _currentBudget = null;
    _stats = null;
    _readyToAssign = 0;
    _error = null;
    notifyListeners();
  }

  /// ✅ NEW: Refresh notifications after action
  Future<void> _refreshNotificationsAfterAction() async {
    try {
      final notificationService = Provider.of<NotificationSyncService>(
        navigatorKey.currentContext!,
        listen: false,
      );

      await notificationService.fetchNotifications();
      debugPrint('🔄 Notifications refreshed after budget update');
    } catch (error) {
      debugPrint('❌ Failed to refresh notifications: $error');
    }
  }
}
