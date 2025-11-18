import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';
import '../utils/secure_storage_manager.dart';
import '../config/api_config.dart';

class PaymentService extends ChangeNotifier {
  static String get baseUrl => '${ApiConfig.baseUrl}/payment';

  List<Payment> _payments = [];
  Payment? _currentPayment;
  bool _isLoading = false;
  String? _error;

  List<Payment> get payments => _payments;
  Payment? get currentPayment => _currentPayment;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Create payment request
  Future<PaymentRequest?> createPayment(String planType) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await SecureStorageManager.getToken();
      if (token == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      debugPrint('💳 Creating payment with planType: "$planType"');
      debugPrint('💳 Request URL: $baseUrl/create');

      final response = await http.post(
        Uri.parse('$baseUrl/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'planType': planType}),
      );

      _isLoading = false;

      debugPrint('💳 Payment API Response: ${response.statusCode}');
      debugPrint('💳 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final paymentRequest = PaymentRequest.fromJson(data['data']);
          notifyListeners();
          return paymentRequest;
        }
      } else if (response.statusCode == 400 || response.statusCode == 500) {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Lỗi khi tạo thanh toán';
        debugPrint('💳 Payment error: $_error');
        notifyListeners();
        throw Exception(_error);
      }

      _error = 'Lỗi khi tạo thanh toán (Status: ${response.statusCode})';
      throw Exception(_error);
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Create payment error: $e');
      return null;
    }
  }

  /// Get user's payments
  Future<void> fetchMyPayments() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await SecureStorageManager.getToken();
      if (token == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/my-payments'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> paymentsJson = data['data']['payments'];
          _payments = paymentsJson.map((json) => Payment.fromJson(json)).toList();
          notifyListeners();
        }
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Fetch payments error: $e');
    }
  }

  /// Get payment details
  Future<Payment?> getPaymentDetails(String paymentId) async {
    try {
      final token = await SecureStorageManager.getToken();
      if (token == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/$paymentId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Payment.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Get payment details error: $e');
      return null;
    }
  }

  /// Cancel payment
  Future<bool> cancelPayment(String paymentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await SecureStorageManager.getToken();
      if (token == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/$paymentId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Refresh payments list
          await fetchMyPayments();
          notifyListeners();
          return true;
        }
      }

      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Cancel payment error: $e');
      return false;
    }
  }

  /// Clear current payment
  void clearCurrentPayment() {
    _currentPayment = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
