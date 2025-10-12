import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/group_budget.dart';

/// Service for managing GroupBudget operations
class GroupBudgetService extends ChangeNotifier {
  List<GroupBudget> _budgets = [];
  GroupBudget? _currentBudget;
  bool _isLoading = false;
  String? _error;

  List<GroupBudget> get budgets => _budgets;
  GroupBudget? get currentBudget => _currentBudget;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<GroupBudget> get activeBudgets =>
      _budgets.where((b) => b.isActive).toList();
  List<GroupBudget> get settledBudgets =>
      _budgets.where((b) => b.isSettled).toList();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/group-budgets';
    } else {
      return 'http://10.0.2.2:3000/api/group-budgets';
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
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

  /// Create a new GroupBudget
  Future<Map<String, dynamic>> createGroupBudget({
    required String name,
    String? description,
    required double totalBudget,
    String currency = 'VND',
    DateTime? startDate,
    DateTime? endDate,
    required List<Map<String, dynamic>> members,
    bool autoSplitByContribution = true,
    bool allowPartialTag = true,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final body = {
        'name': name,
        'description': description,
        'totalBudget': totalBudget,
        'currency': currency,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'members': members,
        'autoSplitByContribution': autoSplitByContribution,
        'allowPartialTag': allowPartialTag,
      };

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Create budget response: ${response.body}');
        debugPrint('📦 Data type: ${data['data'].runtimeType}');

        try {
          final budget = GroupBudget.fromJson(data['data']);
          _budgets.add(budget);
          _currentBudget = budget;
          notifyListeners();
          return {'success': true, 'budget': budget};
        } catch (e, stackTrace) {
          debugPrint('❌ Error parsing budget: $e');
          debugPrint('Stack trace: $stackTrace');
          _setError('Error parsing response: $e');
          return {'success': false, 'message': 'Error parsing response: $e'};
        }
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Failed to create budget';
        _setError(error);
        return {'success': false, 'message': error};
      }
    } catch (e) {
      _setError(e.toString());
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  /// Get all GroupBudgets for the current user
  Future<void> getGroupBudgets({bool? isActive}) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final uri = isActive != null
          ? Uri.parse('$baseUrl?isActive=$isActive')
          : Uri.parse(baseUrl);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Get budgets response type: ${data['data'].runtimeType}');
        debugPrint('📦 Response: ${response.body.substring(0, 500)}...');

        // Handle both array and object response
        if (data['data'] is List) {
          final budgetsData = data['data'] as List;
          debugPrint('📋 Found ${budgetsData.length} budgets');

          try {
            _budgets = budgetsData.map((b) {
              debugPrint('Parsing budget: ${b.runtimeType}');
              return GroupBudget.fromJson(b);
            }).toList();
          } catch (e, stackTrace) {
            debugPrint('❌ Error parsing budget: $e');
            debugPrint('Stack: $stackTrace');
            _setError('Error parsing budgets: $e');
            return;
          }
        } else {
          debugPrint('⚠️ Data is not a list: ${data['data'].runtimeType}');
          // If data is a single object or null, create empty list
          _budgets = [];
        }
        notifyListeners();
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Failed to get budgets';
        _setError(error);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Get a specific GroupBudget by ID
  Future<GroupBudget?> getGroupBudgetById(String id) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final budget = GroupBudget.fromJson(data['data']);
        _currentBudget = budget;

        // Update in list if exists
        final index = _budgets.indexWhere((b) => b.id == id);
        if (index != -1) {
          _budgets[index] = budget;
        } else {
          _budgets.add(budget);
        }

        notifyListeners();
        return budget;
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Failed to get budget';
        _setError(error);
        return null;
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Join a GroupBudget using invite code
  Future<Map<String, dynamic>> joinByCode(
    String inviteCode, {
    double? contributionPercentage,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final body = {
        'inviteCode': inviteCode.toUpperCase(),
        if (contributionPercentage != null)
          'contributionPercentage': contributionPercentage,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/join'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final budget = GroupBudget.fromJson(data['data']);
        _budgets.add(budget);
        _currentBudget = budget;
        notifyListeners();
        return {'success': true, 'budget': budget};
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Failed to join budget';
        _setError(error);
        return {'success': false, 'message': error};
      }
    } catch (e) {
      _setError(e.toString());
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  /// Add an expense to a GroupBudget
  Future<Map<String, dynamic>> addExpense({
    required String budgetId,
    required String description,
    required double amount,
    String? category,
    DateTime? date,
    String splitType = 'auto',
    List<String>? participantUserIds,
    List<Map<String, dynamic>>? customSplits,
    String? notes,
    String? receiptUrl,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final body = {
        'description': description,
        'amount': amount,
        'category': category ?? 'other',
        'date': date?.toIso8601String(),
        'splitType': splitType,
        if (participantUserIds != null) 'participantUserIds': participantUserIds,
        if (customSplits != null) 'customSplits': customSplits,
        if (notes != null) 'notes': notes,
        if (receiptUrl != null) 'receiptUrl': receiptUrl,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/$budgetId/expenses'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final updatedBudget = GroupBudget.fromJson(data['data']['groupBudget']);

        // Update budget in list
        final index = _budgets.indexWhere((b) => b.id == budgetId);
        if (index != -1) {
          _budgets[index] = updatedBudget;
        }
        if (_currentBudget?.id == budgetId) {
          _currentBudget = updatedBudget;
        }

        notifyListeners();
        return {'success': true, 'budget': updatedBudget};
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Failed to add expense';
        _setError(error);
        return {'success': false, 'message': error};
      }
    } catch (e) {
      _setError(e.toString());
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  /// Record a payment between members
  Future<Map<String, dynamic>> recordPayment({
    required String budgetId,
    required String toUserId,
    required double amount,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final body = {
        'toUserId': toUserId,
        'amount': amount,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/$budgetId/payments'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedBudget = GroupBudget.fromJson(data['data']);

        // Update budget in list
        final index = _budgets.indexWhere((b) => b.id == budgetId);
        if (index != -1) {
          _budgets[index] = updatedBudget;
        }
        if (_currentBudget?.id == budgetId) {
          _currentBudget = updatedBudget;
        }

        notifyListeners();
        return {'success': true, 'budget': updatedBudget};
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Failed to record payment';
        _setError(error);
        return {'success': false, 'message': error};
      }
    } catch (e) {
      _setError(e.toString());
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  /// Get settlement plan (who owes whom)
  Future<List<Map<String, dynamic>>?> getSettlementPlan(String budgetId) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$budgetId/settlement-plan'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Failed to get settlement plan';
        _setError(error);
        return null;
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update a GroupBudget
  Future<Map<String, dynamic>> updateGroupBudget({
    required String budgetId,
    Map<String, dynamic>? updates,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$budgetId'),
        headers: headers,
        body: jsonEncode(updates ?? {}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedBudget = GroupBudget.fromJson(data['data']);

        // Update budget in list
        final index = _budgets.indexWhere((b) => b.id == budgetId);
        if (index != -1) {
          _budgets[index] = updatedBudget;
        }
        if (_currentBudget?.id == budgetId) {
          _currentBudget = updatedBudget;
        }

        notifyListeners();
        return {'success': true, 'budget': updatedBudget};
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Failed to update budget';
        _setError(error);
        return {'success': false, 'message': error};
      }
    } catch (e) {
      _setError(e.toString());
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a GroupBudget
  Future<Map<String, dynamic>> deleteGroupBudget(String budgetId) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$budgetId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        _budgets.removeWhere((b) => b.id == budgetId);
        if (_currentBudget?.id == budgetId) {
          _currentBudget = null;
        }
        notifyListeners();
        return {'success': true};
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Failed to delete budget';
        _setError(error);
        return {'success': false, 'message': error};
      }
    } catch (e) {
      _setError(e.toString());
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _budgets = [];
    _currentBudget = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Refresh current budget
  Future<void> refreshCurrentBudget() async {
    if (_currentBudget != null) {
      await getGroupBudgetById(_currentBudget!.id);
    }
  }
}
