import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/secure_storage_manager.dart';
import '../config/api_config.dart';

class BackendOCRService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<String?> _getAuthToken() async {
    return await SecureStorageManager.getToken();
  }

  static Future<BackendOCRResult> processReceipt(String imagePath) async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        return BackendOCRResult(
          success: false,
          error: 'Không tìm thấy token xác thực',
        );
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/ocr/process-receipt'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add image file
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return BackendOCRResult(
          success: false,
          error: 'File ảnh không tồn tại',
        );
      }

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          return BackendOCRResult(
            success: true,
            data: ReceiptData(
              amount: data['amount']?.toDouble() ?? 0.0,
              description: data['description'] ?? '',
              storeName: data['storeName'] ?? '',
              category: data['category'] ?? 'other',
              date:
                  DateTime.tryParse(data['date']?.toString() ?? '') ??
                  DateTime.now(),
              rawText: data['rawText'] ?? '',
              confidence: responseData['confidence']?.toDouble() ?? 0.0,
              items: List<String>.from(data['items'] ?? []),
            ),
            confidence: responseData['confidence']?.toDouble() ?? 0.0,
            provider: responseData['provider'] ?? 'Backend OCR',
            usageInfo: responseData['usageInfo'] != null
                ? OCRUsageInfo.fromJson(responseData['usageInfo'])
                : null,
          );
        } else {
          return BackendOCRResult(
            success: false,
            error: responseData['message'] ?? 'Lỗi không xác định từ backend',
            quotaExceeded: responseData['quotaExceeded'] ?? false,
            upgradeRequired: responseData['upgradeRequired'] ?? false,
          );
        }
      } else if (response.statusCode == 403) {
        final responseData = json.decode(responseBody);
        return BackendOCRResult(
          success: false,
          error: responseData['message'] ?? 'Đã vượt quá giới hạn quét hóa đơn',
          quotaExceeded: true,
          upgradeRequired: true,
        );
      } else {
        return BackendOCRResult(
          success: false,
          error: 'Lỗi server: ${response.statusCode}',
        );
      }
    } catch (e) {
      return BackendOCRResult(
        success: false,
        error: 'Lỗi kết nối: ${e.toString()}',
      );
    }
  }

  static Future<BackendOCRResult> processReceiptFromUrl(String imageUrl) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return BackendOCRResult(
          success: false,
          error: 'Không tìm thấy token xác thực',
        );
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/ocr/process-receipt-url'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'imageUrl': imageUrl}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          return BackendOCRResult(
            success: true,
            data: ReceiptData(
              amount: data['amount']?.toDouble() ?? 0.0,
              description: data['description'] ?? '',
              storeName: data['storeName'] ?? '',
              category: data['category'] ?? 'other',
              date:
                  DateTime.tryParse(data['date']?.toString() ?? '') ??
                  DateTime.now(),
              rawText: data['rawText'] ?? '',
              confidence: responseData['confidence']?.toDouble() ?? 0.0,
              items: List<String>.from(data['items'] ?? []),
            ),
            confidence: responseData['confidence']?.toDouble() ?? 0.0,
            provider: responseData['provider'] ?? 'Backend OCR',
          );
        } else {
          return BackendOCRResult(
            success: false,
            error: responseData['message'] ?? 'Lỗi không xác định từ backend',
          );
        }
      } else {
        return BackendOCRResult(
          success: false,
          error: 'Lỗi server: ${response.statusCode}',
        );
      }
    } catch (e) {
      return BackendOCRResult(
        success: false,
        error: 'Lỗi kết nối: ${e.toString()}',
      );
    }
  }

  static Future<bool> checkServiceStatus() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$_baseUrl/ocr/status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class BackendOCRResult {
  final bool success;
  final String? error;
  final ReceiptData? data;
  final double confidence;
  final String provider;
  final bool quotaExceeded;
  final bool upgradeRequired;
  final OCRUsageInfo? usageInfo;

  BackendOCRResult({
    required this.success,
    this.error,
    this.data,
    this.confidence = 0.0,
    this.provider = 'Backend OCR',
    this.quotaExceeded = false,
    this.upgradeRequired = false,
    this.usageInfo,
  });
}

/// Receipt data structure
class ReceiptData {
  final double amount;
  final String description;
  final String storeName;
  final String category;
  final DateTime date;
  final String rawText;
  final double confidence;
  final List<String> items;

  ReceiptData({
    required this.amount,
    required this.description,
    required this.storeName,
    required this.category,
    required this.date,
    required this.rawText,
    this.confidence = 0.0,
    this.items = const [],
  });

  bool get hasValidAmount => amount > 0;
  bool get hasStoreName => storeName.isNotEmpty;
  bool get hasItems => items.isNotEmpty;
}

/// OCR Usage Information
class OCRUsageInfo {
  final int used;
  final int limit;
  final int remaining;

  OCRUsageInfo({
    required this.used,
    required this.limit,
    required this.remaining,
  });

  factory OCRUsageInfo.fromJson(Map<String, dynamic> json) {
    return OCRUsageInfo(
      used: json['used'] ?? 0,
      limit: json['limit'] ?? 10,
      remaining: json['remaining'] ?? 0,
    );
  }

  double get percentage => limit > 0 ? (used / limit) * 100 : 0.0;
  bool get isExceeded => used >= limit;
}
