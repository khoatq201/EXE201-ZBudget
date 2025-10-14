import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/expense.dart';
import '../models/budget_models.dart';
import '../utils/date_formatter.dart';
import '../utils/secure_storage_manager.dart';

class ExpenseService extends ChangeNotifier {
  // Base URL - different for web and mobile
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/expenses';
    } else {
      return 'http://10.0.2.2:3000/api/expenses';
    }
  }

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;
  Pagination? _pagination;

  // Legacy: Local budgets for old screens
  final Map<String, BudgetData> _budgets = {};

  // Getters
  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get isLoading => _isLoading;
  String? get error => _error;
  Pagination? get pagination => _pagination;
  Map<String, BudgetData> get budgets => Map.unmodifiable(_budgets);

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

  /// Get all expenses with filters
  Future<void> getExpenses({
    String? category,
    String? subcategory,
    String? startDate,
    String? endDate,
    double? minAmount,
    double? maxAmount,
    String? paymentMethod,
    List<String>? tags,
    String? budgetId,
    String? groupId,
    String? search,
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
      if (subcategory != null) queryParams['subcategory'] = subcategory;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (minAmount != null) queryParams['minAmount'] = minAmount.toString();
      if (maxAmount != null) queryParams['maxAmount'] = maxAmount.toString();
      if (paymentMethod != null) queryParams['paymentMethod'] = paymentMethod;
      if (budgetId != null) queryParams['budgetId'] = budgetId;
      if (groupId != null) queryParams['groupId'] = groupId;
      if (search != null) queryParams['search'] = search;
      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags.join(',');
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      debugPrint('📥 Fetching expenses from: $uri');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final expenseListResponse = ExpenseListResponse.fromJson(jsonResponse['data']);
          _expenses = expenseListResponse.expenses;
          _pagination = expenseListResponse.pagination;
          _error = null;
          debugPrint('✅ Loaded ${_expenses.length} expenses');
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load expenses');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to load expenses');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Get expenses error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get single expense by ID
  Future<Expense> getExpenseById(String id) async {
    try {
      final headers = await _getHeaders();
      debugPrint('📥 Fetching expense: $id');

      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return Expense.fromJson(jsonResponse['data']['expense']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load expense');
        }
      } else {
        throw Exception('Failed to load expense');
      }
    } catch (e) {
      debugPrint('❌ Get expense error: $e');
      rethrow;
    }
  }

  /// Create new expense
  Future<Expense> createExpense({
    required String title,
    String? description,
    required double amount,
    required String category,
    String? subcategory,
    DateTime? date,
    required String paymentMethod,
    Map<String, dynamic>? location,
    List<String>? tags,
    String? receipt,
    String? budgetId,
    String? groupId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();

      final body = {
        'title': title,
        'amount': amount,
        'category': category,
        'paymentMethod': paymentMethod,
      };

      if (description != null) body['description'] = description;
      if (subcategory != null) body['subcategory'] = subcategory;
      if (date != null) {
        // Use standardized date formatter to avoid timezone issues
        body['date'] = DateFormatter.toApiFormat(date);
      }
      if (location != null) body['location'] = location;
      if (tags != null && tags.isNotEmpty) body['tags'] = tags;
      if (receipt != null) body['receipt'] = receipt;
      if (budgetId != null) body['budgetId'] = budgetId;
      if (groupId != null) body['groupId'] = groupId;

      debugPrint('➕ Creating expense: $title');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final newExpense = Expense.fromJson(jsonResponse['data']['expense']);
          _expenses.insert(0, newExpense); // Add to beginning
          debugPrint('✅ Expense created: ${newExpense.id}');
          notifyListeners();
          return newExpense;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to create expense');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        // Parse error message - could be 'error' or 'message' field
        final errorMessage = errorBody['error'] ?? errorBody['message'] ?? 'Failed to create expense';
        debugPrint('❌ Create expense failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Create expense error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update expense
  Future<Expense> updateExpense(
    String id, {
    String? title,
    String? description,
    double? amount,
    String? category,
    String? subcategory,
    DateTime? date,
    String? paymentMethod,
    Map<String, dynamic>? location,
    List<String>? tags,
  }) async {
    try {
      final headers = await _getHeaders();

      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (amount != null) body['amount'] = amount;
      if (category != null) body['category'] = category;
      if (subcategory != null) body['subcategory'] = subcategory;
      if (date != null) {
        // Use standardized date formatter to avoid timezone issues
        body['date'] = DateFormatter.toApiFormat(date);
      }
      if (paymentMethod != null) body['paymentMethod'] = paymentMethod;
      if (location != null) body['location'] = location;
      if (tags != null) body['tags'] = tags;

      debugPrint('✏️ Updating expense: $id');

      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final updatedExpense = Expense.fromJson(jsonResponse['data']['expense']);

          // Update in local list
          final index = _expenses.indexWhere((e) => e.id == id);
          if (index != -1) {
            _expenses[index] = updatedExpense;
            notifyListeners();
          }

          debugPrint('✅ Expense updated: $id');
          return updatedExpense;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to update expense');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to update expense');
      }
    } catch (e) {
      debugPrint('❌ Update expense error: $e');
      rethrow;
    }
  }

  /// Delete expense
  Future<void> deleteExpense(String id) async {
    try {
      final headers = await _getHeaders();
      debugPrint('🗑️ Deleting expense: $id');

      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Remove from local list
        _expenses.removeWhere((e) => e.id == id);
        notifyListeners();
        debugPrint('✅ Expense deleted: $id');
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to delete expense');
      }
    } catch (e) {
      debugPrint('❌ Delete expense error: $e');
      rethrow;
    }
  }

  /// Get expense statistics
  Future<ExpenseStats> getExpenseStats({
    String? startDate,
    String? endDate,
    String groupBy = 'category', // 'day', 'week', 'month', 'year', 'category', 'paymentMethod'
    String? category,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = {'groupBy': groupBy};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (category != null) queryParams['category'] = category;

      final uri = Uri.parse('$baseUrl/stats').replace(queryParameters: queryParams);
      debugPrint('📊 Fetching expense stats');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return ExpenseStats.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load stats');
        }
      } else {
        throw Exception('Failed to load expense statistics');
      }
    } catch (e) {
      debugPrint('❌ Get expense stats error: $e');
      rethrow;
    }
  }

  /// Refresh expenses list
  Future<void> refresh() async {
    return getExpenses();
  }

  /// Clear cached data
  void clearData() {
    _expenses = [];
    _pagination = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // ============================================================================
  // LEGACY METHODS - For compatibility with old budget screens
  // ============================================================================

  /// Initialize sample budget (legacy - for old screens)
  void initializeSampleBudget() {
    final sampleBudget = BudgetData(
      id: '1',
      name: 'Ngân sách tháng ${DateTime.now().month}',
      totalAmount: 15000000,
      spentAmount: 0,
      period: BudgetPeriod.monthly,
      categories: [
        BudgetCategoryData(
          category: ExpenseCategory.food,
          allocatedAmount: 5000000,
          spentAmount: 0,
          color: const Color(0xFFFF6B6B),
        ),
        BudgetCategoryData(
          category: ExpenseCategory.transport,
          allocatedAmount: 2000000,
          spentAmount: 0,
          color: const Color(0xFF4ECDC4),
        ),
        BudgetCategoryData(
          category: ExpenseCategory.shopping,
          allocatedAmount: 3000000,
          spentAmount: 0,
          color: const Color(0xFF45B7D1),
        ),
        BudgetCategoryData(
          category: ExpenseCategory.entertainment,
          allocatedAmount: 2000000,
          spentAmount: 0,
          color: const Color(0xFF96CEB4),
        ),
        BudgetCategoryData(
          category: ExpenseCategory.utilities,
          allocatedAmount: 1500000,
          spentAmount: 0,
          color: const Color(0xFFFFD700),
        ),
        BudgetCategoryData(
          category: ExpenseCategory.healthcare,
          allocatedAmount: 1000000,
          spentAmount: 0,
          color: const Color(0xFFFF8C42),
        ),
        BudgetCategoryData(
          category: ExpenseCategory.other,
          allocatedAmount: 500000,
          spentAmount: 0,
          color: const Color(0xFF6C5CE7),
        ),
      ],
    );

    _budgets[sampleBudget.id] = sampleBudget;
    notifyListeners();
  }

  /// Get budget by ID (legacy)
  BudgetData? getBudgetById(String budgetId) {
    return _budgets[budgetId];
  }

  /// Add expense (legacy - for old budget screens)
  /// This is a wrapper for createExpense() but with old signature
  Future<void> addExpense({
    required ExpenseCategory category,
    required int amount,
    required String description,
    required DateTime date,
    String? budgetId,
    String? receipt,
  }) async {
    try {
      // Call new API method
      await createExpense(
        title: description,
        amount: amount.toDouble(),
        category: category.toString().split('.').last,
        date: date,
        paymentMethod: 'cash', // Default
        description: description,
        budgetId: budgetId,
        receipt: receipt,
      );

      // Update local budget (legacy behavior)
      if (budgetId != null && _budgets.containsKey(budgetId)) {
        await _updateBudgetSpentAmount(budgetId, category, amount);
      }
    } catch (e) {
      debugPrint('❌ Legacy addExpense error: $e');
      rethrow;
    }
  }

  /// Update budget spent amount (legacy - local only)
  Future<void> _updateBudgetSpentAmount(
    String budgetId,
    ExpenseCategory category,
    int amount,
  ) async {
    final budget = _budgets[budgetId];
    if (budget == null) return;

    // Update categories
    final updatedCategories = budget.categories.map((cat) {
      if (cat.category == category) {
        return BudgetCategoryData(
          category: cat.category,
          allocatedAmount: cat.allocatedAmount,
          spentAmount: cat.spentAmount + amount,
          color: cat.color,
        );
      }
      return cat;
    }).toList();

    // Calculate total spent
    final totalSpent = updatedCategories.fold<int>(
      0,
      (sum, cat) => sum + cat.spentAmount,
    );

    // Update budget
    final updatedBudget = BudgetData(
      id: budget.id,
      name: budget.name,
      totalAmount: budget.totalAmount,
      spentAmount: totalSpent,
      period: budget.period,
      categories: updatedCategories,
    );

    _budgets[budgetId] = updatedBudget;
    notifyListeners();
  }

  /// Get expenses by budget (legacy)
  List<Expense> getExpensesByBudget(String budgetId) {
    return _expenses.where((expense) => expense.groupId == budgetId).toList();
  }

  /// Get expenses by category (legacy)
  List<Expense> getExpensesByCategory(ExpenseCategory category) {
    final categoryStr = category.toString().split('.').last;
    return _expenses.where((expense) {
      return expense.category.toString().split('.').last == categoryStr;
    }).toList();
  }

  /// Get expenses by date range (legacy)
  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return _expenses.where((expense) {
      return expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
}
