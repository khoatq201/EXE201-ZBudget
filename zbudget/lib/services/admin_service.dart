import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/admin_models.dart';
import '../utils/secure_storage_manager.dart';
import '../config/api_config.dart';

class AdminService extends ChangeNotifier {
  static String get baseUrl => '${ApiConfig.baseUrl}/admin';

  List<AdminPayment> _pendingPayments = [];
  List<AdminPayment> _allPayments = [];
  List<AdminUser> _users = [];
  AdminStats? _stats;
  bool _isLoading = false;
  String? _error;

  List<AdminPayment> get pendingPayments => _pendingPayments;
  List<AdminPayment> get allPayments => _allPayments;
  List<AdminUser> get users => _users;
  AdminStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingCount => _pendingPayments.length;

  /// Get pending payments
  Future<void> fetchPendingPayments() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await SecureStorageManager.getToken();
      if (token == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/payments/pending'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> paymentsJson = data['data']['payments'];
          _pendingPayments = paymentsJson.map((json) => AdminPayment.fromJson(json)).toList();
          notifyListeners();
        }
      } else if (response.statusCode == 403) {
        throw Exception('Bạn không có quyền admin');
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Fetch pending payments error: $e');
    }
  }

  /// Get all payments
  Future<void> fetchAllPayments({String? status, int page = 1}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await SecureStorageManager.getToken();
      if (token == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      queryParams['page'] = page.toString();

      final uri = Uri.parse('$baseUrl/payments').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> paymentsJson = data['data']['payments'];
          _allPayments = paymentsJson.map((json) => AdminPayment.fromJson(json)).toList();
          notifyListeners();
        }
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Fetch all payments error: $e');
    }
  }

  /// Approve payment
  Future<bool> approvePayment(String paymentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await SecureStorageManager.getToken();
      if (token == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/payments/$paymentId/approve'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Refresh pending payments
          await fetchPendingPayments();
          notifyListeners();
          return true;
        }
      }

      final data = jsonDecode(response.body);
      _error = data['message'] ?? 'Lỗi khi duyệt thanh toán';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Approve payment error: $e');
      return false;
    }
  }

  /// Reject payment
  Future<bool> rejectPayment(String paymentId, {String? reason}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await SecureStorageManager.getToken();
      if (token == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/payments/$paymentId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason}),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Refresh pending payments
          await fetchPendingPayments();
          notifyListeners();
          return true;
        }
      }

      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Reject payment error: $e');
      return false;
    }
  }

  /// Get dashboard stats
  Future<void> fetchDashboardStats() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await SecureStorageManager.getToken();
      if (token == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _stats = AdminStats.fromJson(data['data']);
          notifyListeners();
        }
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Fetch dashboard stats error: $e');
    }
  }

  /// Get all users
  Future<void> fetchUsers({String? tier, int page = 1, String? search}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await SecureStorageManager.getToken();
      if (token == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final queryParams = <String, String>{};
      if (tier != null) queryParams['tier'] = tier;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      queryParams['page'] = page.toString();

      final uri = Uri.parse('$baseUrl/users').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> usersJson = data['data']['users'];
          _users = usersJson.map((json) => AdminUser.fromJson(json)).toList();
          notifyListeners();
        }
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Fetch users error: $e');
    }
  }

  /// Manually activate premium for user
  Future<bool> manualActivatePremium(String userId, String duration) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await SecureStorageManager.getToken();
      if (token == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/activate-premium'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'duration': duration}),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Refresh users list
          await fetchUsers();
          notifyListeners();
          return true;
        }
      }

      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Manual activate premium error: $e');
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
