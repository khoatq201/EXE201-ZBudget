import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/secure_storage_manager.dart';

/// Report Service - Handles all report-related API calls
/// Manages trend, category, comparison, pattern, and forecast reports
class ReportService extends ChangeNotifier {
  // Base URL - different for web and mobile
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/reports';
    } else {
      return 'http://10.0.2.2:3000/api/reports';
    }
  }

  // State management
  bool _isLoading = false;
  String? _error;

  // Report data
  TrendReportData? _trendReport;
  CategoryReportData? _categoryReport;
  ComparisonReportData? _comparisonReport;
  PatternsReportData? _patternsReport;
  ForecastReportData? _forecastReport;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  TrendReportData? get trendReport => _trendReport;
  CategoryReportData? get categoryReport => _categoryReport;
  ComparisonReportData? get comparisonReport => _comparisonReport;
  PatternsReportData? get patternsReport => _patternsReport;
  ForecastReportData? get forecastReport => _forecastReport;

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

  /// Handle API errors
  void _handleError(dynamic error, String context) {
    debugPrint('❌ Error in $context: $error');
    _error = error.toString();
    _isLoading = false;
    notifyListeners();
  }

  /// Get Trend Report - Income vs Expense trends
  Future<void> getTrendReport({
    String period = 'month', // month, week, year
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();

      final queryParams = {'period': period};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('$baseUrl/trend').replace(queryParameters: queryParams);
      debugPrint('📈 Fetching trend report: $uri');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _trendReport = TrendReportData.fromJson(data['data']);
          _isLoading = false;
          _error = null;
          notifyListeners();
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch trend report');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e, 'getTrendReport');
    }
  }

  /// Get Category Report - Category breakdown
  Future<void> getCategoryReport({
    String period = 'month',
    String type = 'expense', // income or expense
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();

      final queryParams = {
        'period': period,
        'type': type,
      };
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('$baseUrl/categories').replace(queryParameters: queryParams);
      debugPrint('📊 Fetching category report: $uri');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _categoryReport = CategoryReportData.fromJson(data['data']);
          _isLoading = false;
          _error = null;
          notifyListeners();
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch category report');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e, 'getCategoryReport');
    }
  }

  /// Get Comparison Report - Period over period comparison
  Future<void> getComparisonReport({
    String period = 'month',
    int compareCount = 3,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();

      final queryParams = {
        'period': period,
        'compareCount': compareCount.toString(),
      };

      final uri = Uri.parse('$baseUrl/comparison').replace(queryParameters: queryParams);
      debugPrint('🔄 Fetching comparison report: $uri');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _comparisonReport = ComparisonReportData.fromJson(data['data']);
          _isLoading = false;
          _error = null;
          notifyListeners();
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch comparison report');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e, 'getComparisonReport');
    }
  }

  /// Get Spending Patterns - Day of week and payment method analysis
  Future<void> getSpendingPatterns({
    String period = 'month',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();

      final queryParams = {'period': period};

      final uri = Uri.parse('$baseUrl/patterns').replace(queryParameters: queryParams);
      debugPrint('🔍 Fetching spending patterns: $uri');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _patternsReport = PatternsReportData.fromJson(data['data']);
          _isLoading = false;
          _error = null;
          notifyListeners();
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch patterns report');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e, 'getSpendingPatterns');
    }
  }

  /// Get Forecast Report - Predictive analytics
  Future<void> getForecastReport({
    int months = 3,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();

      final queryParams = {'months': months.toString()};

      final uri = Uri.parse('$baseUrl/forecast').replace(queryParameters: queryParams);
      debugPrint('🔮 Fetching forecast report: $uri');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _forecastReport = ForecastReportData.fromJson(data['data']);
          _isLoading = false;
          _error = null;
          notifyListeners();
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch forecast report');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e, 'getForecastReport');
    }
  }

  /// Clear all report data
  void clearReports() {
    _trendReport = null;
    _categoryReport = null;
    _comparisonReport = null;
    _patternsReport = null;
    _forecastReport = null;
    _error = null;
    notifyListeners();
  }

  /// Refresh all reports (useful for pull-to-refresh)
  Future<void> refreshAllReports({String period = 'month'}) async {
    await Future.wait([
      getTrendReport(period: period),
      getCategoryReport(period: period),
      getComparisonReport(period: period),
      getSpendingPatterns(period: period),
      getForecastReport(),
    ]);
  }
}

// ============================================================================
// Data Models for Reports
// ============================================================================

/// Trend Report Data
class TrendReportData {
  final String periodType;
  final DateTime startDate;
  final DateTime endDate;
  final String format;
  final TrendSummary summary;
  final List<TrendDataPoint> trendData;

  TrendReportData({
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.summary,
    required this.trendData,
  });

  factory TrendReportData.fromJson(Map<String, dynamic> json) {
    return TrendReportData(
      periodType: json['period']['type'],
      startDate: DateTime.parse(json['period']['startDate']),
      endDate: DateTime.parse(json['period']['endDate']),
      format: json['period']['format'],
      summary: TrendSummary.fromJson(json['summary']),
      trendData: (json['trendData'] as List)
          .map((item) => TrendDataPoint.fromJson(item))
          .toList(),
    );
  }
}

class TrendSummary {
  final double totalIncome;
  final double totalExpense;
  final double totalBalance;
  final double avgIncome;
  final double avgExpense;
  final double savingsRate;

  TrendSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
    required this.avgIncome,
    required this.avgExpense,
    required this.savingsRate,
  });

  factory TrendSummary.fromJson(Map<String, dynamic> json) {
    return TrendSummary(
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpense: (json['totalExpense'] ?? 0).toDouble(),
      totalBalance: (json['totalBalance'] ?? 0).toDouble(),
      avgIncome: (json['avgIncome'] ?? 0).toDouble(),
      avgExpense: (json['avgExpense'] ?? 0).toDouble(),
      savingsRate: (json['savingsRate'] ?? 0).toDouble(),
    );
  }
}

class TrendDataPoint {
  final String date;
  final double income;
  final int incomeCount;
  final double expense;
  final int expenseCount;
  final double balance;

  TrendDataPoint({
    required this.date,
    required this.income,
    required this.incomeCount,
    required this.expense,
    required this.expenseCount,
    required this.balance,
  });

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      date: json['date'],
      income: (json['income'] ?? 0).toDouble(),
      incomeCount: json['incomeCount'] ?? 0,
      expense: (json['expense'] ?? 0).toDouble(),
      expenseCount: json['expenseCount'] ?? 0,
      balance: (json['balance'] ?? 0).toDouble(),
    );
  }
}

/// Category Report Data
class CategoryReportData {
  final String periodType;
  final String type; // income or expense
  final CategorySummary summary;
  final List<CategoryDataPoint> categories;
  final List<CategoryDataPoint> topCategories;

  CategoryReportData({
    required this.periodType,
    required this.type,
    required this.summary,
    required this.categories,
    required this.topCategories,
  });

  factory CategoryReportData.fromJson(Map<String, dynamic> json) {
    return CategoryReportData(
      periodType: json['period']['type'],
      type: json['type'],
      summary: CategorySummary.fromJson(json['summary']),
      categories: (json['categories'] as List)
          .map((item) => CategoryDataPoint.fromJson(item))
          .toList(),
      topCategories: (json['topCategories'] as List)
          .map((item) => CategoryDataPoint.fromJson(item))
          .toList(),
    );
  }
}

class CategorySummary {
  final double grandTotal;
  final int categoryCount;
  final int transactionCount;

  CategorySummary({
    required this.grandTotal,
    required this.categoryCount,
    required this.transactionCount,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
      categoryCount: json['categoryCount'] ?? 0,
      transactionCount: json['transactionCount'] ?? 0,
    );
  }
}

class CategoryDataPoint {
  final String category;
  final double total;
  final int count;
  final double avgAmount;
  final double percentage;

  CategoryDataPoint({
    required this.category,
    required this.total,
    required this.count,
    required this.avgAmount,
    required this.percentage,
  });

  factory CategoryDataPoint.fromJson(Map<String, dynamic> json) {
    return CategoryDataPoint(
      category: json['category'],
      total: (json['total'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
      avgAmount: (json['avgAmount'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

/// Comparison Report Data
class ComparisonReportData {
  final String periodType;
  final List<ComparisonPeriod> comparisons;
  final List<PeriodChange> changes;

  ComparisonReportData({
    required this.periodType,
    required this.comparisons,
    required this.changes,
  });

  factory ComparisonReportData.fromJson(Map<String, dynamic> json) {
    return ComparisonReportData(
      periodType: json['periodType'],
      comparisons: (json['comparisons'] as List)
          .map((item) => ComparisonPeriod.fromJson(item))
          .toList(),
      changes: (json['changes'] as List)
          .map((item) => PeriodChange.fromJson(item))
          .toList(),
    );
  }
}

class ComparisonPeriod {
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final double income;
  final double expense;
  final double balance;
  final double savingsRate;
  final int incomeCount;
  final int expenseCount;
  final bool isCurrent;

  ComparisonPeriod({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.income,
    required this.expense,
    required this.balance,
    required this.savingsRate,
    required this.incomeCount,
    required this.expenseCount,
    required this.isCurrent,
  });

  factory ComparisonPeriod.fromJson(Map<String, dynamic> json) {
    return ComparisonPeriod(
      period: json['period'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      income: (json['income'] ?? 0).toDouble(),
      expense: (json['expense'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      savingsRate: (json['savingsRate'] ?? 0).toDouble(),
      incomeCount: json['incomeCount'] ?? 0,
      expenseCount: json['expenseCount'] ?? 0,
      isCurrent: json['isCurrent'] ?? false,
    );
  }
}

class PeriodChange {
  final String period;
  final double incomeChange;
  final double expenseChange;
  final double balanceChange;

  PeriodChange({
    required this.period,
    required this.incomeChange,
    required this.expenseChange,
    required this.balanceChange,
  });

  factory PeriodChange.fromJson(Map<String, dynamic> json) {
    return PeriodChange(
      period: json['period'],
      incomeChange: (json['incomeChange'] ?? 0).toDouble(),
      expenseChange: (json['expenseChange'] ?? 0).toDouble(),
      balanceChange: (json['balanceChange'] ?? 0).toDouble(),
    );
  }
}

/// Patterns Report Data
class PatternsReportData {
  final String periodType;
  final SpendingPatterns patterns;
  final PatternInsights insights;

  PatternsReportData({
    required this.periodType,
    required this.patterns,
    required this.insights,
  });

  factory PatternsReportData.fromJson(Map<String, dynamic> json) {
    return PatternsReportData(
      periodType: json['period']['type'],
      patterns: SpendingPatterns.fromJson(json['patterns']),
      insights: PatternInsights.fromJson(json['insights']),
    );
  }
}

class SpendingPatterns {
  final List<DayOfWeekPattern> dayOfWeek;
  final List<PaymentMethodPattern> paymentMethods;
  final List<FrequentCategory> frequentCategories;

  SpendingPatterns({
    required this.dayOfWeek,
    required this.paymentMethods,
    required this.frequentCategories,
  });

  factory SpendingPatterns.fromJson(Map<String, dynamic> json) {
    return SpendingPatterns(
      dayOfWeek: (json['dayOfWeek'] as List)
          .map((item) => DayOfWeekPattern.fromJson(item))
          .toList(),
      paymentMethods: (json['paymentMethods'] as List)
          .map((item) => PaymentMethodPattern.fromJson(item))
          .toList(),
      frequentCategories: (json['frequentCategories'] as List)
          .map((item) => FrequentCategory.fromJson(item))
          .toList(),
    );
  }
}

class DayOfWeekPattern {
  final int dayOfWeek;
  final String dayName;
  final double total;
  final int count;
  final double avgAmount;

  DayOfWeekPattern({
    required this.dayOfWeek,
    required this.dayName,
    required this.total,
    required this.count,
    required this.avgAmount,
  });

  factory DayOfWeekPattern.fromJson(Map<String, dynamic> json) {
    return DayOfWeekPattern(
      dayOfWeek: json['dayOfWeek'],
      dayName: json['dayName'],
      total: (json['total'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
      avgAmount: (json['avgAmount'] ?? 0).toDouble(),
    );
  }
}

class PaymentMethodPattern {
  final String id;
  final double total;
  final int count;

  PaymentMethodPattern({
    required this.id,
    required this.total,
    required this.count,
  });

  factory PaymentMethodPattern.fromJson(Map<String, dynamic> json) {
    return PaymentMethodPattern(
      id: json['_id'],
      total: (json['total'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class FrequentCategory {
  final String id;
  final int count;
  final double total;

  FrequentCategory({
    required this.id,
    required this.count,
    required this.total,
  });

  factory FrequentCategory.fromJson(Map<String, dynamic> json) {
    return FrequentCategory(
      id: json['_id'],
      count: json['count'] ?? 0,
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

class PatternInsights {
  final String mostExpensiveDay;
  final String mostFrequentDay;
  final String preferredPaymentMethod;

  PatternInsights({
    required this.mostExpensiveDay,
    required this.mostFrequentDay,
    required this.preferredPaymentMethod,
  });

  factory PatternInsights.fromJson(Map<String, dynamic> json) {
    return PatternInsights(
      mostExpensiveDay: json['mostExpensiveDay'],
      mostFrequentDay: json['mostFrequentDay'],
      preferredPaymentMethod: json['preferredPaymentMethod'],
    );
  }
}

/// Forecast Report Data
class ForecastReportData {
  final List<HistoricalDataPoint> historicalData;
  final ForecastAverages averages;
  final ForecastTrends trends;
  final List<ForecastDataPoint> forecast;

  ForecastReportData({
    required this.historicalData,
    required this.averages,
    required this.trends,
    required this.forecast,
  });

  factory ForecastReportData.fromJson(Map<String, dynamic> json) {
    return ForecastReportData(
      historicalData: (json['historicalData'] as List)
          .map((item) => HistoricalDataPoint.fromJson(item))
          .toList(),
      averages: ForecastAverages.fromJson(json['averages']),
      trends: ForecastTrends.fromJson(json['trends']),
      forecast: (json['forecast'] as List)
          .map((item) => ForecastDataPoint.fromJson(item))
          .toList(),
    );
  }
}

class HistoricalDataPoint {
  final String month;
  final double income;
  final double expense;

  HistoricalDataPoint({
    required this.month,
    required this.income,
    required this.expense,
  });

  factory HistoricalDataPoint.fromJson(Map<String, dynamic> json) {
    return HistoricalDataPoint(
      month: json['month'],
      income: (json['income'] ?? 0).toDouble(),
      expense: (json['expense'] ?? 0).toDouble(),
    );
  }
}

class ForecastAverages {
  final double avgIncome;
  final double avgExpense;
  final double avgBalance;

  ForecastAverages({
    required this.avgIncome,
    required this.avgExpense,
    required this.avgBalance,
  });

  factory ForecastAverages.fromJson(Map<String, dynamic> json) {
    return ForecastAverages(
      avgIncome: (json['avgIncome'] ?? 0).toDouble(),
      avgExpense: (json['avgExpense'] ?? 0).toDouble(),
      avgBalance: (json['avgBalance'] ?? 0).toDouble(),
    );
  }
}

class ForecastTrends {
  final String incomeTrend;
  final String expenseTrend;

  ForecastTrends({
    required this.incomeTrend,
    required this.expenseTrend,
  });

  factory ForecastTrends.fromJson(Map<String, dynamic> json) {
    return ForecastTrends(
      incomeTrend: json['incomeTrend'],
      expenseTrend: json['expenseTrend'],
    );
  }
}

class ForecastDataPoint {
  final String month;
  final double forecastIncome;
  final double forecastExpense;
  final double forecastBalance;
  final double confidence;

  ForecastDataPoint({
    required this.month,
    required this.forecastIncome,
    required this.forecastExpense,
    required this.forecastBalance,
    required this.confidence,
  });

  factory ForecastDataPoint.fromJson(Map<String, dynamic> json) {
    return ForecastDataPoint(
      month: json['month'],
      forecastIncome: (json['forecastIncome'] ?? 0).toDouble(),
      forecastExpense: (json['forecastExpense'] ?? 0).toDouble(),
      forecastBalance: (json['forecastBalance'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}
