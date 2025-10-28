import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../utils/secure_storage_manager.dart';

class ImageUploadService {
  static Future<String?> _getToken() async {
    return await SecureStorageManager.getToken();
  }

  /// Upload avatar image
  static Future<Map<String, dynamic>?> uploadAvatar(File imageFile) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/upload/avatar'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add the image file with explicit content type
      var multipartFile = await http.MultipartFile.fromPath(
        'avatar',
        imageFile.path,
        contentType: _getContentType(imageFile.path),
      );
      request.files.add(multipartFile);

      print('🔄 Uploading avatar...');
      print('📤 File path: ${imageFile.path}');
      print('📤 File size: ${await imageFile.length()} bytes');
      print('📤 Content-Type: ${_getContentType(imageFile.path)}');

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('📤 Upload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = json.decode(responseBody);
        print('✅ Avatar uploaded successfully');
        return result;
      } else {
        print('❌ Upload failed: ${response.statusCode} - $responseBody');
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Upload error: $e');
      rethrow;
    }
  }

  /// Get current user avatar
  static Future<Map<String, dynamic>?> getUserAvatar() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/upload/avatar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get avatar: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get avatar error: $e');
      rethrow;
    }
  }

  /// Delete user avatar
  static Future<bool> deleteAvatar() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/upload/avatar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🗑️ Delete avatar response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Delete avatar error: $e');
      return false;
    }
  }

  /// Upload receipt image (for expense tracking)
  static Future<Map<String, dynamic>?> uploadReceipt(File imageFile) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/upload/receipt'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add the image file
      var multipartFile = await http.MultipartFile.fromPath(
        'receipt',
        imageFile.path,
      );
      request.files.add(multipartFile);

      print('🔄 Uploading receipt...');

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final result = json.decode(responseBody);
        print('✅ Receipt uploaded successfully');
        return result;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Receipt upload error: $e');
      rethrow;
    }
  }

  /// Get content type based on file extension
  static MediaType? _getContentType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'bmp':
        return MediaType('image', 'bmp');
      default:
        return MediaType('image', 'jpeg'); // Default fallback
    }
  }
}
