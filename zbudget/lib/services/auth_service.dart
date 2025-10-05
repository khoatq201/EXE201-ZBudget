import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../services/session_manager.dart';
import '../utils/device_info_helper.dart';

/// Service để xử lý authentication với backend API
class AuthService extends ChangeNotifier {
  // Sử dụng URL khác nhau cho web và mobile để tránh CORS
  static String get baseUrl {
    if (kIsWeb) {
      // Cho Flutter web, sử dụng localhost
      return 'http://localhost:3000/api/auth';
    } else {
      // Cho Android emulator, sử dụng 10.0.2.2 thay vì localhost
      // 10.0.2.2 là địa chỉ đặc biệt trong Android emulator để truy cập host machine
      return 'http://10.0.2.2:3000/api/auth';
    }
  }

  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  String? _accessToken;
  String? _refreshToken;
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Add configuration to improve performance
    forceCodeForRefreshToken: false, // Disable if not needed
  );

  // Getters
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  /// Initialize auth service và check existing token
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_tokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);

      if (_accessToken != null) {
        final userData = prefs.getString(_userKey);
        if (userData != null) {
          _currentUser = User.fromJson(jsonDecode(userData));
          _isAuthenticated = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
    }
  }

  /// Đăng ký user mới
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    try {
      debugPrint('🚀 Sending register request to: $baseUrl/register');
      debugPrint(
        '📧 Email: $email, 👤 FullName: $fullName, 📱 Phone: $phoneNumber',
      );

      Map<String, dynamic> requestBody = {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
      };

      if (dateOfBirth != null) {
        requestBody['dateOfBirth'] = dateOfBirth.toIso8601String();
      }

      if (gender != null && gender.isNotEmpty) {
        requestBody['gender'] = gender;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: await DeviceInfoHelper.getEnhancedHeaders(),
        body: jsonEncode(requestBody),
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Check if this is OTP flow or direct login
        if (responseData['data'] != null &&
            responseData['data']['otpSent'] == true) {
          // OTP flow - return success without login
          return {
            'success': true,
            'message':
                responseData['message'] ?? 'OTP đã được gửi đến email của bạn',
            'data': responseData['data'],
          };
        } else if (responseData['accessToken'] != null &&
            responseData['user'] != null) {
          // Direct login flow (old behavior)
          _accessToken = responseData['accessToken'];
          _refreshToken = responseData['refreshToken'];

          final userData = responseData['user'];
          _currentUser = User.fromJson(userData);
          _isAuthenticated = true;

          // Lưu vào SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, _accessToken!);
          await prefs.setString(_refreshTokenKey, _refreshToken!);
          await prefs.setString(_userKey, jsonEncode(userData));

          notifyListeners();
          return {
            'success': true,
            'message': responseData['message'] ?? 'Đăng ký thành công',
            'user': _currentUser,
          };
        } else {
          // Unknown success format
          return {
            'success': true,
            'message': responseData['message'] ?? 'Đăng ký thành công',
          };
        }
      } else {
        // Đăng ký thất bại
        return {
          'success': false,
          'message': responseData['message'] ?? 'Đăng ký thất bại',
        };
      }
    } catch (e) {
      debugPrint('Error during registration: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối. Vui lòng thử lại sau.',
      };
    }
  }

  /// Đăng nhập user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      // ✅ DEVICE TRACKING: Sử dụng enhanced headers với device info
      final headers = await DeviceInfoHelper.getEnhancedHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'rememberMe': rememberMe,
        }),
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✅ FIX: Match với backend response structure
        final data = responseData['data'];
        if (data != null && data['tokens'] != null && data['user'] != null) {
          _accessToken = data['tokens']['accessToken'];
          _refreshToken = data['tokens']['refreshToken'];

          final userData = data['user'];
          _currentUser = User.fromJson(userData);
          _isAuthenticated = true;

          // Lưu vào SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, _accessToken!);
          if (_refreshToken != null) {
            await prefs.setString(_refreshTokenKey, _refreshToken!);
          }
          await prefs.setString(_userKey, jsonEncode(userData));

          notifyListeners();
          debugPrint('✅ Login successful with device tracking, tokens saved');
          return {
            'success': true,
            'message': responseData['message'] ?? 'Đăng nhập thành công',
            'user': _currentUser,
          };
        } else {
          debugPrint('❌ Invalid response structure: $responseData');
          return {
            'success': false,
            'message': 'Phản hồi từ server không hợp lệ',
          };
        }
      } else {
        // Đăng nhập thất bại
        debugPrint('❌ Login failed with status: ${response.statusCode}');
        return {
          'success': false,
          'message':
              responseData['error'] ??
              responseData['message'] ??
              'Đăng nhập thất bại',
        };
      }
    } catch (e) {
      debugPrint('Error during login: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối. Vui lòng thử lại sau.',
      };
    }
  }

  /// Xác thực OTP
  Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      debugPrint('🔍 Verifying OTP for email: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      debugPrint('📥 OTP Verification response status: ${response.statusCode}');
      debugPrint('📥 OTP Verification response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // OTP verification thành công - lưu tokens và user data
        final data = responseData['data'];
        final tokens = data['tokens'];
        final userData = data['user'];

        _accessToken = tokens['accessToken'];
        _refreshToken = tokens['refreshToken'];
        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;

        // Lưu vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _accessToken!);
        await prefs.setString(_refreshTokenKey, _refreshToken!);
        await prefs.setString(_userKey, jsonEncode(userData));

        notifyListeners();
        return {
          'success': true,
          'message': responseData['message'] ?? 'Xác thực OTP thành công',
          'user': _currentUser,
        };
      } else {
        // OTP verification thất bại
        return {
          'success': false,
          'message': responseData['message'] ?? 'Mã OTP không chính xác',
        };
      }
    } catch (e) {
      debugPrint('Error during OTP verification: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối. Vui lòng thử lại sau.',
      };
    }
  }

  /// Đăng xuất user
  Future<Map<String, dynamic>> logout() async {
    debugPrint('🚀 Starting logout process...');
    debugPrint(
      '🔍 Current tokens - Access: ${_accessToken != null ? "exists" : "null"}, Refresh: ${_refreshToken != null ? "exists" : "null"}',
    );

    try {
      if (_refreshToken != null && _accessToken != null) {
        debugPrint('🌐 Making logout API call to: $baseUrl/logout');

        // Gọi API logout để invalidate token trên server
        final response = await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
          body: jsonEncode({'refreshToken': _refreshToken}),
        );

        debugPrint('🔐 Logout API response: ${response.statusCode}');
        debugPrint('🔐 Response body: ${response.body}');

        if (response.statusCode == 200) {
          debugPrint('✅ Server logout successful');
        } else {
          debugPrint(
            '⚠️ Server logout failed but continuing with local cleanup',
          );
        }
      } else {
        debugPrint('⚠️ No tokens available, skipping server logout call');
      }
    } catch (e) {
      debugPrint('❌ Error during logout API call: $e');
      // Continue với local cleanup dù API có lỗi
    }

    try {
      debugPrint('🧹 Starting local cleanup...');

      // Sign out from Google if signed in
      await signOutFromGoogle();

      // Xóa dữ liệu local
      _accessToken = null;
      _refreshToken = null;
      _currentUser = null;
      _isAuthenticated = false;

      // Xóa khỏi SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userKey);

      debugPrint('✅ Local logout cleanup completed');
      notifyListeners();

      return {'success': true, 'message': 'Đăng xuất thành công'};
    } catch (e) {
      debugPrint('❌ Error during local logout cleanup: $e');
      return {'success': false, 'message': 'Có lỗi xảy ra khi đăng xuất: $e'};
    }
  }

  /// Force logout with immediate navigation to login
  Future<Map<String, dynamic>> forceLogoutWithNavigation() async {
    debugPrint('🚨 Force logout with navigation triggered');

    final result = await logout();

    // Force immediate state update
    _isAuthenticated = false;
    notifyListeners();

    debugPrint('🚨 Force logout completed, isAuthenticated: $_isAuthenticated');
    return result;
  }

  /// Refresh access token khi hết hạn
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _accessToken = responseData['accessToken'];
        _refreshToken = responseData['refreshToken'];

        // Lưu token mới
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _accessToken!);
        await prefs.setString(_refreshTokenKey, _refreshToken!);

        return true;
      } else {
        // Refresh token hết hạn - logout
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      await logout();
      return false;
    }
  }

  /// Get headers với authorization token
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  /// Xác thực OTP reset password
  Future<Map<String, dynamic>> verifyPasswordResetOTP(
    String email,
    String otp,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-password-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Xác thực OTP thành công',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Mã OTP không hợp lệ hoặc đã hết hạn',
        };
      }
    } catch (e) {
      debugPrint('Error in verifyPasswordResetOTP: $e');
      return {
        'success': false,
        'message': 'Không thể kết nối đến server. Vui lòng thử lại sau.',
      };
    }
  }

  /// Gửi email reset password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Email reset password đã được gửi',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Có lỗi xảy ra khi gửi email reset password',
        };
      }
    } catch (e) {
      debugPrint('Error in forgotPassword: $e');
      return {
        'success': false,
        'message': 'Không thể kết nối đến server. Vui lòng thử lại sau.',
      };
    }
  }

  /// Reset password với OTP
  Future<Map<String, dynamic>> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
          'confirmNewPassword': newPassword,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Đặt lại mật khẩu thành công',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Mã OTP không hợp lệ hoặc đã hết hạn',
        };
      }
    } catch (e) {
      debugPrint('Error in resetPassword: $e');
      return {
        'success': false,
        'message': 'Không thể kết nối đến server. Vui lòng thử lại sau.',
      };
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Google Sign-In method
  Future<Map<String, dynamic>> signInWithGoogle() async {
    /// 🚀 DEVELOPMENT WORKAROUND: Test backend Google Sign-In without Google Services
    Future<Map<String, dynamic>> signInWithGoogleDev() async {
      try {
        _setLoading(true);
        debugPrint('🔧 DEV MODE: Testing backend Google Sign-In directly');

        // Send mock request to backend to test integration
        final response = await http
            .post(
              Uri.parse('$baseUrl/google-signin'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({
                'idToken':
                    'mock_dev_id_token_${DateTime.now().millisecondsSinceEpoch}',
                'accessToken': 'mock_dev_access_token',
                'email': 'developer@test.com',
                'displayName': 'Test Developer',
                'photoUrl': 'https://via.placeholder.com/150',
              }),
            )
            .timeout(
              Duration(seconds: 10),
              onTimeout: () {
                throw Exception(
                  'Backend timeout - vui lòng kiểm tra kết nối mạng',
                );
              },
            );

        debugPrint('📦 DEV Backend response: ${response.statusCode}');
        debugPrint('📦 DEV Response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          if (responseData['success'] == true) {
            // Save tokens and user info
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_tokenKey, responseData['accessToken']);
            await prefs.setString(
              _refreshTokenKey,
              responseData['refreshToken'] ?? '',
            );
            await prefs.setString(_userKey, jsonEncode(responseData['user']));

            _accessToken = responseData['accessToken'];
            _refreshToken = responseData['refreshToken'];
            _currentUser = User.fromJson(responseData['user']);
            _isAuthenticated = true;

            debugPrint('✅ DEV Google Sign-In completed successfully');
            _setLoading(false);
            return {
              'success': true,
              'message':
                  responseData['message'] ??
                  'Google Sign-In thành công (DEV MODE)',
              'user': _currentUser?.toJson(),
            };
          } else {
            _setLoading(false);
            return {
              'success': false,
              'message':
                  responseData['message'] ??
                  'Backend từ chối request (DEV MODE)',
            };
          }
        } else {
          _setLoading(false);
          return {
            'success': false,
            'message': 'Backend error ${response.statusCode} (DEV MODE)',
          };
        }
      } catch (e) {
        _setLoading(false);
        debugPrint('❌ DEV Google Sign-In Error: $e');
        return {
          'success': false,
          'message': 'DEV MODE: Backend connection error - $e',
        };
      }
    }

    try {
      _setLoading(true);
      debugPrint('🚀 Starting Google Sign-In process');

      // Pre-check if Google Services are available to fail fast
      final bool isAvailable = await _googleSignIn.isSignedIn();
      debugPrint('📱 Google Services available: $isAvailable');

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ User cancelled Google Sign-In');
        _setLoading(false);
        return {'success': false, 'message': 'Đăng nhập đã bị hủy'};
      }

      debugPrint('✅ Google user obtained: ${googleUser.email}');

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        debugPrint('❌ No ID token received');
        _setLoading(false);
        return {
          'success': false,
          'message': 'Không thể lấy token từ Google. Vui lòng thử lại.',
        };
      }

      debugPrint('� Sending to backend for verification');

      // Send to backend for verification
      final response = await http
          .post(
            Uri.parse('$baseUrl/google-signin'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'idToken': googleAuth.idToken,
              'email': googleUser.email,
              'displayName': googleUser.displayName,
              'photoUrl': googleUser.photoUrl,
            }),
          )
          .timeout(
            Duration(seconds: 10), // Add timeout for backend calls
            onTimeout: () {
              throw Exception(
                'Backend timeout - vui lòng kiểm tra kết nối mạng',
              );
            },
          );

      debugPrint('📥 Backend response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          // Save tokens and user info
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, responseData['accessToken']);
          await prefs.setString(
            _refreshTokenKey,
            responseData['refreshToken'] ?? '',
          );
          await prefs.setString(_userKey, jsonEncode(responseData['user']));

          _accessToken = responseData['accessToken'];
          _refreshToken = responseData['refreshToken'];
          _currentUser = User.fromJson(responseData['user']);
          _isAuthenticated = true;

          debugPrint('✅ Google Sign-In completed successfully');
          _setLoading(false);
          return {
            'success': true,
            'message': responseData['message'] ?? 'Đăng nhập Google thành công',
            'user': _currentUser?.toJson(),
          };
        } else {
          _setLoading(false);
          return {
            'success': false,
            'message': responseData['message'] ?? 'Đăng nhập Google thất bại',
          };
        }
      } else {
        _setLoading(false);
        return {'success': false, 'message': 'Lỗi server. Vui lòng thử lại.'};
      }
    } catch (e) {
      _setLoading(false);
      debugPrint('❌ Google Sign-In Error: $e');

      // Provide specific error messages
      String errorMessage = 'Không thể đăng nhập với Google.';
      if (e.toString().contains('network_error') ||
          e.toString().contains('ApiException: 7')) {
        errorMessage = 'Lỗi kết nối. Vui lòng kiểm tra mạng và thử lại.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Quá thời gian chờ. Vui lòng thử lại.';
      } else if (e.toString().contains('ApiException: 10')) {
        errorMessage = 'Lỗi cấu hình Google Sign-In.';
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  /// Sign out from Google
  Future<void> signOutFromGoogle() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
  }

  /// Complete user profile after Google Sign-In
  Future<Map<String, dynamic>> completeProfile({
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? city,
    String? country = 'Vietnam',
  }) async {
    try {
      _setLoading(true);

      if (_accessToken == null) {
        throw Exception('Bạn cần đăng nhập trước');
      }

      final Map<String, dynamic> requestBody = {};

      if (phone != null && phone.isNotEmpty) {
        requestBody['phone'] = phone;
      }

      if (dateOfBirth != null) {
        requestBody['dateOfBirth'] = dateOfBirth.toIso8601String();
      }

      if (gender != null && gender.isNotEmpty) {
        requestBody['gender'] = gender;
      }

      if (city != null && city.isNotEmpty) {
        requestBody['city'] = city;
      }

      if (country != null && country.isNotEmpty) {
        requestBody['country'] = country;
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/complete-profile'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Update current user data
        if (responseData['user'] != null) {
          _currentUser = User.fromJson(responseData['user']);
          // Lưu vào SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, jsonEncode(responseData['user']));
        }

        notifyListeners();

        return {
          'success': true,
          'message': responseData['message'] ?? 'Cập nhật thông tin thành công',
          'user': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Cập nhật thông tin thất bại',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      debugPrint('Complete profile error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối. Vui lòng thử lại sau.',
      };
    } finally {
      _setLoading(false);
    }
  }
}
