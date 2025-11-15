import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import '../models/subscription_models.dart';
import '../config/api_config.dart';
import '../utils/secure_storage_manager.dart';

/// Service để quản lý subscription và premium features
class SubscriptionService extends ChangeNotifier {
  // Sử dụng ApiConfig để quản lý URL theo environment
  static String get baseUrl {
    return '${ApiConfig.baseUrl}/subscription';
  }

  Subscription? _subscription;
  UsageStats? _usageStats;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  Subscription? get subscription => _subscription;
  UsageStats? get usageStats => _usageStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium => _subscription?.isPremium ?? false;

  /// Initialize the service and load subscription data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final token = await SecureStorageManager.getToken();
      if (token != null) {
        // User is logged in, load subscription data
        await getStatus();
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to initialize subscription service: $e');
    }
  }

  /// Safe notify listeners - defers to post-frame callback if during build
  void _safeNotifyListeners() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // We're in the build phase, defer notification
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  /// Get auth headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await SecureStorageManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _safeNotifyListeners();
    }
  }

  /// Set error state
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      _safeNotifyListeners();
    }
  }

  /// Safely decode JSON response body
  Map<String, dynamic>? _safeJsonDecode(String body) {
    if (body.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ Response body is empty');
      }
      return null;
    }
    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ JSON decode error: $e');
        debugPrint(
          'Response body: ${body.substring(0, body.length > 200 ? 200 : body.length)}...',
        );
      }
      return null;
    }
  }

  /// Lấy subscription status của user hiện tại
  Future<SubscriptionApiResponse<Subscription>> getStatus() async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/status'),
        headers: headers,
      );

      debugPrint('📥 Subscription status response: ${response.statusCode}');

      final responseData = _safeJsonDecode(response.body);
      if (responseData == null) {
        return SubscriptionApiResponse(
          success: false,
          message: 'Không thể đọc dữ liệu từ server',
        );
      }

      debugPrint('📊 Response data: ${responseData.toString()}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        debugPrint('🔍 Subscription data: ${data?.toString()}');

        if (data != null) {
          // Parse subscription directly from data, not data['subscription']
          _subscription = Subscription.fromJson(data);
          debugPrint(
            '✅ Subscription loaded: tier=${_subscription?.tier}, status=${_subscription?.status}, isPremium=${_subscription?.isPremium}',
          );
          _safeNotifyListeners();
          return SubscriptionApiResponse(
            success: true,
            message: responseData['message'] ?? 'Lấy thông tin thành công',
            data: _subscription,
          );
        }
      }

      debugPrint('❌ Failed to parse subscription data');
      return SubscriptionApiResponse(
        success: false,
        message:
            responseData['message'] ?? 'Không thể lấy thông tin subscription',
      );
    } catch (e) {
      debugPrint('Error getting subscription status: $e');
      _setError('Lỗi kết nối. Vui lòng thử lại sau.');
      return SubscriptionApiResponse(
        success: false,
        message: 'Lỗi kết nối. Vui lòng thử lại sau.',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy feature limits của user hiện tại
  Future<SubscriptionApiResponse<SubscriptionFeatures>> getFeatures() async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/features'),
        headers: headers,
      );

      debugPrint('📥 Features response: ${response.statusCode}');

      final responseData = _safeJsonDecode(response.body);
      if (responseData == null) {
        return SubscriptionApiResponse(
          success: false,
          message: 'Không thể đọc dữ liệu từ server',
        );
      }

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        if (data != null && data['features'] != null) {
          final features = SubscriptionFeatures.fromJson(data['features']);
          return SubscriptionApiResponse(
            success: true,
            message: responseData['message'] ?? 'Lấy thông tin thành công',
            data: features,
          );
        }
      }

      return SubscriptionApiResponse(
        success: false,
        message: responseData['message'] ?? 'Không thể lấy thông tin features',
      );
    } catch (e) {
      debugPrint('Error getting features: $e');
      _setError('Lỗi kết nối. Vui lòng thử lại sau.');
      return SubscriptionApiResponse(
        success: false,
        message: 'Lỗi kết nối. Vui lòng thử lại sau.',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy usage statistics của user hiện tại
  Future<SubscriptionApiResponse<UsageStats>> getUsage() async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/usage'),
        headers: headers,
      );

      debugPrint('📥 Usage stats response: ${response.statusCode}');

      final responseData = _safeJsonDecode(response.body);
      if (responseData == null) {
        return SubscriptionApiResponse(
          success: false,
          message: 'Không thể đọc dữ liệu từ server',
        );
      }

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        if (data != null) {
          debugPrint('📊 Usage data structure: $data');
          _usageStats = UsageStats.fromJson(data);
          _safeNotifyListeners();
          return SubscriptionApiResponse(
            success: true,
            message: responseData['message'] ?? 'Lấy thông tin thành công',
            data: _usageStats,
          );
        }
      }

      return SubscriptionApiResponse(
        success: false,
        message: responseData['message'] ?? 'Không thể lấy thông tin usage',
      );
    } catch (e) {
      debugPrint('Error getting usage stats: $e');
      _setError('Lỗi kết nối. Vui lòng thử lại sau.');
      return SubscriptionApiResponse(
        success: false,
        message: 'Lỗi kết nối. Vui lòng thử lại sau.',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy pricing information (public endpoint, không cần auth)
  Future<SubscriptionApiResponse<PricingInfo>> getPricing() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await http.get(
        Uri.parse('$baseUrl/pricing'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('📥 Pricing response: ${response.statusCode}');
      debugPrint('📥 Pricing body: ${response.body}');

      final responseData = _safeJsonDecode(response.body);
      if (responseData == null) {
        return SubscriptionApiResponse(
          success: false,
          message: 'Không thể đọc dữ liệu từ server',
        );
      }

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        debugPrint('📥 Pricing data: $data');

        if (data != null) {
          // Backend returns data directly, not nested in 'pricing'
          final pricing = PricingInfo.fromJson(data);
          debugPrint(
            '✅ Pricing parsed successfully: ${pricing.plans.length} plans',
          );
          return SubscriptionApiResponse(
            success: true,
            message: responseData['message'] ?? 'Lấy thông tin thành công',
            data: pricing,
          );
        }
      }

      return SubscriptionApiResponse(
        success: false,
        message: responseData['message'] ?? 'Không thể lấy thông tin pricing',
      );
    } catch (e) {
      debugPrint('Error getting pricing: $e');
      _setError('Lỗi kết nối. Vui lòng thử lại sau.');
      return SubscriptionApiResponse(
        success: false,
        message: 'Lỗi kết nối. Vui lòng thử lại sau.',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Upgrade to Premium
  /// duration: 'monthly' hoặc 'yearly'
  Future<SubscriptionApiResponse<Subscription>> upgradeToPremium({
    required String duration,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/upgrade'),
        headers: headers,
        body: jsonEncode({'duration': duration}),
      );

      debugPrint('📥 Upgrade response: ${response.statusCode}');

      final responseData = _safeJsonDecode(response.body);
      if (responseData == null) {
        return SubscriptionApiResponse(
          success: false,
          message: 'Không thể đọc dữ liệu từ server',
        );
      }

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        if (data != null && data['subscription'] != null) {
          _subscription = Subscription.fromJson(data['subscription']);
          _safeNotifyListeners();
          return SubscriptionApiResponse(
            success: true,
            message: responseData['message'] ?? 'Nâng cấp Premium thành công',
            data: _subscription,
          );
        }
      }

      return SubscriptionApiResponse(
        success: false,
        message: responseData['message'] ?? 'Không thể nâng cấp Premium',
      );
    } catch (e) {
      debugPrint('Error upgrading to premium: $e');
      _setError('Lỗi kết nối. Vui lòng thử lại sau.');
      return SubscriptionApiResponse(
        success: false,
        message: 'Lỗi kết nối. Vui lòng thử lại sau.',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Downgrade to Free
  Future<SubscriptionApiResponse<Subscription>> downgradeToFree() async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/downgrade'),
        headers: headers,
      );

      debugPrint('📥 Downgrade response: ${response.statusCode}');

      final responseData = _safeJsonDecode(response.body);
      if (responseData == null) {
        return SubscriptionApiResponse(
          success: false,
          message: 'Không thể đọc dữ liệu từ server',
        );
      }

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        if (data != null && data['subscription'] != null) {
          _subscription = Subscription.fromJson(data['subscription']);
          _safeNotifyListeners();
          return SubscriptionApiResponse(
            success: true,
            message: responseData['message'] ?? 'Hạ cấp xuống Free thành công',
            data: _subscription,
          );
        }
      }

      return SubscriptionApiResponse(
        success: false,
        message: responseData['message'] ?? 'Không thể hạ cấp',
      );
    } catch (e) {
      debugPrint('Error downgrading to free: $e');
      _setError('Lỗi kết nối. Vui lòng thử lại sau.');
      return SubscriptionApiResponse(
        success: false,
        message: 'Lỗi kết nối. Vui lòng thử lại sau.',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy subscription history
  Future<SubscriptionApiResponse<List<SubscriptionHistory>>>
  getHistory() async {
    try {
      _setLoading(true);
      _setError(null);

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: headers,
      );

      debugPrint('📥 History response: ${response.statusCode}');

      final responseData = _safeJsonDecode(response.body);
      if (responseData == null) {
        return SubscriptionApiResponse(
          success: false,
          message: 'Không thể đọc dữ liệu từ server',
        );
      }

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        if (data != null && data['history'] != null) {
          final historyList = (data['history'] as List)
              .map((item) => SubscriptionHistory.fromJson(item))
              .toList();
          return SubscriptionApiResponse(
            success: true,
            message: responseData['message'] ?? 'Lấy lịch sử thành công',
            data: historyList,
          );
        }
      }

      return SubscriptionApiResponse(
        success: false,
        message:
            responseData['message'] ?? 'Không thể lấy lịch sử subscription',
      );
    } catch (e) {
      debugPrint('Error getting history: $e');
      _setError('Lỗi kết nối. Vui lòng thử lại sau.');
      return SubscriptionApiResponse(
        success: false,
        message: 'Lỗi kết nối. Vui lòng thử lại sau.',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Kiểm tra xem user có thể tạo budget mới không
  Future<bool> canCreateBudget() async {
    if (_subscription == null) {
      await getStatus();
    }

    // Premium users có thể tạo không giới hạn (trong limit 20)
    if (_subscription?.isPremium ?? false) {
      return true;
    }

    // Free users cần check limit
    // Sẽ được xác thực trên server khi gọi API create budget
    return true;
  }

  /// Kiểm tra xem user có thể tạo savings goal mới không
  Future<bool> canCreateSavingsGoal() async {
    if (_subscription == null) {
      await getStatus();
    }

    // Premium users có thể tạo không giới hạn (trong limit 10)
    if (_subscription?.isPremium ?? false) {
      return true;
    }

    // Free users cần check limit
    // Sẽ được xác thực trên server khi gọi API create savings goal
    return true;
  }

  /// Kiểm tra xem user có thể dùng OCR không
  Future<bool> canUseOCR() async {
    if (_subscription == null) {
      await getStatus();
    }

    // Premium users unlimited
    if (_subscription?.isPremium ?? false) {
      return true;
    }

    // Free users cần check daily quota
    if (_usageStats == null) {
      await getUsage();
    }

    return !(_usageStats?.ocr.isExceeded ?? false);
  }

  /// Kiểm tra xem user có thể dùng AI Analysis không
  Future<bool> canUseAIAnalysis() async {
    if (_subscription == null) {
      await getStatus();
    }

    // AI Analysis chỉ dành cho Premium
    return _subscription?.isPremium ?? false;
  }

  /// Refresh tất cả thông tin subscription và usage
  Future<void> refresh() async {
    await Future.wait([getStatus(), getUsage()]);
  }

  /// Clear local data (khi logout)
  void clear() {
    _subscription = null;
    _usageStats = null;
    _error = null;
    _safeNotifyListeners();
  }
}
