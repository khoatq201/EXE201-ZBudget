import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/savings_models.dart';
import '../utils/secure_storage_manager.dart';
import 'notification_sync_service.dart';
import '../main.dart';
import '../config/api_config.dart';

class SavingsService extends ChangeNotifier {
  // Base URL - sử dụng ApiConfig để quản lý theo environment
  static String get baseUrl {
    return ApiConfig.baseUrl + '/savings';
  }

  List<SavingsGoal> _savingsGoals = [];
  bool _isLoading = false;
  String? _error;
  SavingsStats? _stats;

  // Getters
  List<SavingsGoal> get savingsGoals => List.unmodifiable(_savingsGoals);
  List<SavingsGoal> get activeSavingsGoals => _savingsGoals
      .where((goal) => goal.status == SavingsStatus.active)
      .toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  SavingsStats? get stats => _stats;

  double get totalSaved =>
      _savingsGoals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
  double get totalTarget =>
      _savingsGoals.fold(0.0, (sum, goal) => sum + goal.targetAmount);
  double get overallProgress =>
      totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0;

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

  /// Safely decode JSON response body
  /// Returns null if body is empty or invalid JSON
  Map<String, dynamic>? _safeJsonDecode(String body) {
    if (body.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Response body is empty');
      }
      return null;
    }
    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ JSON decode error: $e');
        print('Response body: $body');
      }
      return null;
    }
  }

  /// Get all savings goals with filters
  Future<void> getSavingsGoals({
    String? status,
    String? category,
    String? priority,
    int page = 1,
    int limit = 50,
    String sort = '-targetDate',
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

      if (status != null) queryParams['status'] = status;
      if (category != null) queryParams['category'] = category;
      if (priority != null) queryParams['priority'] = priority;

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['success'] == true) {
          final goalsData = data['data']['goals'] as List;
          _savingsGoals = goalsData
              .map((g) => SavingsGoal.fromJson(g))
              .toList();
          _error = null;
        } else {
          _error = data?['message'] ?? 'Failed to load savings goals';
        }
      } else {
        final data = _safeJsonDecode(response.body);
        _error = data?['message'] ?? 'Failed to load savings goals';
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching savings goals: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get savings goal by ID
  Future<SavingsGoal?> getSavingsGoalById(String id) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/$id');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['success'] == true) {
          return SavingsGoal.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching savings goal: $e');
      }
      return null;
    }
  }

  /// Create new savings goal
  Future<Map<String, dynamic>> createSavingsGoal({
    required String name,
    String? description,
    required double targetAmount,
    required DateTime targetDate,
    required SavingsCategory category,
    SavingsPriority priority = SavingsPriority.medium,
    AutoSave? autoSave,
    String icon = 'piggy_bank',
    String color = '#4CAF50',
    List<String> tags = const [],
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(baseUrl);

      final body = {
        'name': name,
        'description': description,
        'targetAmount': targetAmount,
        'targetDate': targetDate.toIso8601String(),
        'category': category.value,
        'priority': priority.value,
        if (autoSave != null) 'autoSave': autoSave.toJson(),
        'icon': icon,
        'color': color,
        'tags': tags,
        'notes': notes,
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 201 && data != null && data['success'] == true) {
        final newGoal = SavingsGoal.fromJson(data['data']);
        _savingsGoals.add(newGoal);

        // ✅ KEY: Trigger notification refresh after successful creation
        await _refreshNotificationsAfterAction();

        notifyListeners();
        return {
          'success': true,
          'message': 'Savings goal created successfully',
          'limitInfo': data['limitInfo'],
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': data?['message'] ?? 'Đã đạt giới hạn mục tiêu tiết kiệm. Nâng cấp Premium để tạo thêm.',
          'upgradeRequired': true,
          'limitExceeded': true,
        };
      } else {
        return {
          'success': false,
          'message': data?['message'] ?? 'Failed to create savings goal',
          'upgradeRequired': data?['upgradeRequired'],
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating savings goal: $e');
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Update savings goal
  Future<Map<String, dynamic>> updateSavingsGoal({
    required String id,
    String? name,
    String? description,
    double? targetAmount,
    DateTime? targetDate,
    SavingsCategory? category,
    SavingsPriority? priority,
    SavingsStatus? status,
    AutoSave? autoSave,
    String? icon,
    String? color,
    List<String>? tags,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/$id');

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (targetAmount != null) body['targetAmount'] = targetAmount;
      if (targetDate != null) body['targetDate'] = targetDate.toIso8601String();
      if (category != null) body['category'] = category.value;
      if (priority != null) body['priority'] = priority.value;
      if (status != null) body['status'] = status.value;
      if (autoSave != null) body['autoSave'] = autoSave.toJson();
      if (icon != null) body['icon'] = icon;
      if (color != null) body['color'] = color;
      if (tags != null) body['tags'] = tags;
      if (notes != null) body['notes'] = notes;

      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(body),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null && data['success'] == true) {
        final updatedGoal = SavingsGoal.fromJson(data['data']);
        final index = _savingsGoals.indexWhere((g) => g.id == id);
        if (index != -1) {
          _savingsGoals[index] = updatedGoal;
          notifyListeners();
        }
        return {
          'success': true,
          'message': 'Savings goal updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data?['message'] ?? 'Failed to update savings goal',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating savings goal: $e');
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Delete savings goal
  Future<Map<String, dynamic>> deleteSavingsGoal(String id) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/$id');

      final response = await http.delete(uri, headers: headers);
      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null && data['success'] == true) {
        _savingsGoals.removeWhere((g) => g.id == id);
        notifyListeners();
        return {
          'success': true,
          'message': 'Savings goal deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data?['message'] ?? 'Failed to delete savings goal',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting savings goal: $e');
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Add contribution to savings goal
  Future<Map<String, dynamic>> addContribution({
    required String goalId,
    required double amount,
    String source = 'manual',
    String? incomeId,
    String? note,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/$goalId/contribute');

      final body = {
        'amount': amount,
        'source': source,
        if (incomeId != null) 'incomeId': incomeId,
        if (note != null) 'note': note,
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null && data['success'] == true) {
        final updatedGoal = SavingsGoal.fromJson(data['data']);
        final index = _savingsGoals.indexWhere((g) => g.id == goalId);
        if (index != -1) {
          _savingsGoals[index] = updatedGoal;
          notifyListeners();
        }
        return {'success': true, 'message': 'Contribution added successfully'};
      } else {
        // Parse error - could be 'message' or 'error' field
        final errorMsg =
            data?['message'] ?? data?['error'] ?? 'Failed to add contribution';
        if (kDebugMode) {
          print('❌ Add contribution failed: $errorMsg');
        }
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding contribution: $e');
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Withdraw from savings goal
  Future<Map<String, dynamic>> withdrawFromSavings({
    required String goalId,
    required double amount,
    String? reason,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/$goalId/withdraw');

      final body = {'amount': amount, if (reason != null) 'reason': reason};

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      );

      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data != null && data['success'] == true) {
        final updatedGoal = SavingsGoal.fromJson(data['data']);
        final index = _savingsGoals.indexWhere((g) => g.id == goalId);
        if (index != -1) {
          _savingsGoals[index] = updatedGoal;
          notifyListeners();
        }
        return {'success': true, 'message': 'Withdrawal successful'};
      } else {
        // Parse error - could be 'message' or 'error' field
        final errorMsg =
            data?['message'] ?? data?['error'] ?? 'Failed to withdraw';
        if (kDebugMode) {
          print('❌ Withdraw failed: $errorMsg');
        }
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error withdrawing: $e');
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get savings statistics
  Future<void> getSavingsStats() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/stats');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['success'] == true) {
          _stats = SavingsStats.fromJson(data['data']);
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching savings stats: $e');
      }
    }
  }

  /// Helper: Get savings goals sorted by priority
  List<SavingsGoal> getSortedGoalsByPriority() {
    final goals = List<SavingsGoal>.from(_savingsGoals);
    goals.sort((a, b) {
      final priorityOrder = {
        SavingsPriority.critical: 0,
        SavingsPriority.high: 1,
        SavingsPriority.medium: 2,
        SavingsPriority.low: 3,
      };
      return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
    });
    return goals;
  }

  /// Helper: Get goals nearing deadline
  List<SavingsGoal> getGoalsNearingDeadline({int daysThreshold = 30}) {
    final now = DateTime.now();
    return _savingsGoals.where((goal) {
      final daysRemaining = goal.targetDate.difference(now).inDays;
      return daysRemaining <= daysThreshold &&
          daysRemaining > 0 &&
          !goal.isCompleted;
    }).toList();
  }

  /// Clear error
  void clearError() {
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
      debugPrint('🔄 Notifications refreshed after savings goal creation');
    } catch (error) {
      debugPrint('❌ Failed to refresh notifications: $error');
    }
  }
}
