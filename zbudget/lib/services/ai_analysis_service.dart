import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/ai_analysis_models.dart';
import '../utils/auth_utils.dart';

/// Exception thrown when premium subscription is required
class PremiumRequiredException implements Exception {
  final String message;
  PremiumRequiredException(this.message);

  @override
  String toString() => message;
}

class AiAnalysisService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthUtils.getToken();

    if (token == null) {
      throw Exception('No access token found. Please login again.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Helper method to check if error is premium required
  PremiumRequiredException? _checkPremiumRequired(int statusCode, Map<String, dynamic>? data) {
    if (statusCode == 403) {
      return PremiumRequiredException(
        data?['message'] ?? 'Tính năng này yêu cầu Premium. Vui lòng nâng cấp để sử dụng.',
      );
    }
    return null;
  }

  /// Get deep financial analysis with AI insights
  Future<FinancialAnalysis> getDeepAnalysis({String period = 'month'}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.aiAnalysisDeep}?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('Deep Analysis Data: ${data['data']}');
          return FinancialAnalysis.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Failed to get deep analysis');
        }
      } else {
        final data = json.decode(response.body);
        final premiumError = _checkPremiumRequired(response.statusCode, data);
        if (premiumError != null) throw premiumError;
        throw Exception(data['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Deep Analysis Error: $e');
      rethrow;
    }
  }

  /// Get AI-powered financial forecast
  Future<AIForecast> getForecast({
    int months = 3,
    String period = 'month',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
          '$baseUrl${ApiConfig.aiAnalysisForecast}?months=$months&period=$period',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('Forecast Data: ${data['data']}');
          return AIForecast.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Failed to get forecast');
        }
      } else {
        final data = json.decode(response.body);
        final premiumError = _checkPremiumRequired(response.statusCode, data);
        if (premiumError != null) throw premiumError;
        throw Exception(data['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Forecast Error: $e');
      rethrow;
    }
  }

  /// Get spending anomalies and alerts
  Future<List<Anomaly>> getAnomalies({String period = 'month'}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.aiAnalysisAnomalies}?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('Anomalies Data: ${data['data']}');
          return (data['data']['anomalies'] as List)
              .map((a) => Anomaly.fromJson(a))
              .toList();
        } else {
          throw Exception(data['error'] ?? 'Failed to get anomalies');
        }
      } else {
        final data = json.decode(response.body);
        final premiumError = _checkPremiumRequired(response.statusCode, data);
        if (premiumError != null) throw premiumError;
        throw Exception(data['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Anomalies Error: $e');
      rethrow;
    }
  }

  /// Get smart financial recommendations
  Future<List<Recommendation>> getRecommendations({
    String period = 'month',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
          '$baseUrl${ApiConfig.aiAnalysisRecommendations}?period=$period',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('Recommendations Data: ${data['data']}');
          return (data['data']['recommendations'] as List)
              .map((r) => Recommendation.fromJson(r))
              .toList();
        } else {
          throw Exception(data['error'] ?? 'Failed to get recommendations');
        }
      } else {
        final data = json.decode(response.body);
        final premiumError = _checkPremiumRequired(response.statusCode, data);
        if (premiumError != null) throw premiumError;
        throw Exception(data['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Recommendations Error: $e');
      rethrow;
    }
  }

  /// Get quick insights summary
  Future<QuickInsights> getQuickInsights({String period = 'month'}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.aiAnalysisInsights}?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('Quick Insights Data: ${data['data']}');
          return QuickInsights.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Failed to get quick insights');
        }
      } else {
        final data = json.decode(response.body);
        final premiumError = _checkPremiumRequired(response.statusCode, data);
        if (premiumError != null) throw premiumError;
        throw Exception(data['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Quick Insights Error: $e');
      rethrow;
    }
  }

  /// Get spending patterns analysis
  Future<SpendingPatterns> getSpendingPatterns({
    String period = 'month',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.aiAnalysisPatterns}?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('Spending Patterns Data: ${data['data']}');
          return SpendingPatterns.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Failed to get spending patterns');
        }
      } else {
        final data = json.decode(response.body);
        final premiumError = _checkPremiumRequired(response.statusCode, data);
        if (premiumError != null) throw premiumError;
        throw Exception(data['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Spending Patterns Error: $e');
      rethrow;
    }
  }

  /// Clear AI analysis cache
  Future<void> clearCache() async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl${ApiConfig.aiAnalysisCache}'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to clear cache');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  /// Get comprehensive AI analysis (all data in one call)
  Future<Map<String, dynamic>> getComprehensiveAnalysis({
    int forecastMonths = 3,
    String period = 'month',
  }) async {
    try {
      print('🔄 Starting comprehensive analysis for period: $period');

      // Run all analysis in parallel for better performance
      final results = await Future.wait([
        getDeepAnalysis(period: period),
        getForecast(months: forecastMonths, period: period),
        getAnomalies(period: period),
        getRecommendations(period: period),
        getQuickInsights(period: period),
        getSpendingPatterns(period: period),
      ]);

      print('✅ All API calls completed successfully');

      return {
        'financialAnalysis': results[0] as FinancialAnalysis,
        'forecast': results[1] as AIForecast,
        'anomalies': results[2] as List<Anomaly>,
        'recommendations': results[3] as List<Recommendation>,
        'quickInsights': results[4] as QuickInsights,
        'spendingPatterns': results[5] as SpendingPatterns,
        'generatedAt': DateTime.now(),
      };
    } catch (e) {
      print('AI Analysis Error: $e');
      print('Error type: ${e.runtimeType}');
      if (e.toString().contains('type cast')) {
        throw Exception(
          'Dữ liệu từ server không đúng định dạng. Vui lòng thử lại sau.',
        );
      }
      throw Exception('Không thể tải phân tích AI: $e');
    }
  }
}
