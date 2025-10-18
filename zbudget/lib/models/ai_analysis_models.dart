class FinancialAnalysis {
  final String healthScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> risks;
  final List<String> opportunities;
  final List<Recommendation> recommendations;
  final String summary;

  FinancialAnalysis({
    required this.healthScore,
    required this.strengths,
    required this.weaknesses,
    required this.risks,
    required this.opportunities,
    required this.recommendations,
    required this.summary,
  });

  factory FinancialAnalysis.fromJson(Map<String, dynamic> json) {
    return FinancialAnalysis(
      healthScore: json['healthScore'] ?? 'N/A',
      strengths: json['strengths'] != null
          ? List<String>.from(json['strengths'])
          : [],
      weaknesses: json['weaknesses'] != null
          ? List<String>.from(json['weaknesses'])
          : [],
      risks: json['risks'] != null ? List<String>.from(json['risks']) : [],
      opportunities: json['opportunities'] != null
          ? List<String>.from(json['opportunities'])
          : [],
      recommendations: json['recommendations'] != null
          ? (json['recommendations'] as List)
                .map((r) => Recommendation.fromJson(r))
                .toList()
          : [],
      summary: json['summary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'healthScore': healthScore,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'risks': risks,
      'opportunities': opportunities,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'summary': summary,
    };
  }
}

class AIForecast {
  final String method;
  final List<ForecastMonth> forecast;
  final List<HistoricalData>? historicalData;
  final String? message;

  AIForecast({
    required this.method,
    required this.forecast,
    this.historicalData,
    this.message,
  });

  factory AIForecast.fromJson(Map<String, dynamic> json) {
    return AIForecast(
      method: json['method'] ?? 'unknown',
      forecast: json['forecast'] != null
          ? (json['forecast'] as List)
                .map((f) => ForecastMonth.fromJson(f))
                .toList()
          : [],
      historicalData: json['historicalData'] != null
          ? (json['historicalData'] as List)
                .map((h) => HistoricalData.fromJson(h))
                .toList()
          : null,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'forecast': forecast.map((f) => f.toJson()).toList(),
      'historicalData': historicalData?.map((h) => h.toJson()).toList(),
      'message': message,
    };
  }
}

class ForecastMonth {
  final String month;
  final double predictedExpense;
  final double predictedIncome;
  final double lower80;
  final double upper80;
  final double confidence;

  ForecastMonth({
    required this.month,
    required this.predictedExpense,
    required this.predictedIncome,
    required this.lower80,
    required this.upper80,
    required this.confidence,
  });

  factory ForecastMonth.fromJson(Map<String, dynamic> json) {
    return ForecastMonth(
      month: json['month'] ?? '',
      predictedExpense: (json['predictedExpense'] ?? 0).toDouble(),
      predictedIncome: (json['predictedIncome'] ?? 0).toDouble(),
      lower80: (json['lower80'] ?? 0).toDouble(),
      upper80: (json['upper80'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'predictedExpense': predictedExpense,
      'predictedIncome': predictedIncome,
      'lower80': lower80,
      'upper80': upper80,
      'confidence': confidence,
    };
  }
}

class HistoricalData {
  final String month;
  final double income;
  final double expense;

  HistoricalData({
    required this.month,
    required this.income,
    required this.expense,
  });

  factory HistoricalData.fromJson(Map<String, dynamic> json) {
    return HistoricalData(
      month: json['month'] ?? '',
      income: (json['income'] ?? 0).toDouble(),
      expense: (json['expense'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'month': month, 'income': income, 'expense': expense};
  }
}

class Anomaly {
  final DateTime date;
  final String category;
  final double amount;
  final String description;
  final String expectedRange;
  final String severity;

  Anomaly({
    required this.date,
    required this.category,
    required this.amount,
    required this.description,
    required this.expectedRange,
    required this.severity,
  });

  factory Anomaly.fromJson(Map<String, dynamic> json) {
    // Handle amount field - could be double, int, or Map with $numberDecimal
    double amountValue = 0;
    if (json['amount'] != null) {
      if (json['amount'] is Map) {
        // Handle MongoDB Decimal128 format: { $numberDecimal: "100000" }
        final amountMap = json['amount'] as Map<String, dynamic>;
        if (amountMap.containsKey('\$numberDecimal')) {
          amountValue = double.parse(amountMap['\$numberDecimal'].toString());
        } else {
          amountValue = (amountMap.values.first ?? 0).toDouble();
        }
      } else {
        amountValue = (json['amount'] ?? 0).toDouble();
      }
    }

    return Anomaly(
      date: DateTime.parse(json['date']),
      category: json['category'] ?? '',
      amount: amountValue,
      description: json['description'] ?? '',
      expectedRange: json['expectedRange'] ?? '',
      severity: json['severity'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'category': category,
      'amount': amount,
      'description': description,
      'expectedRange': expectedRange,
      'severity': severity,
    };
  }
}

class Recommendation {
  final String title;
  final String description;
  final String priority;
  final double estimatedSavings;

  Recommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.estimatedSavings,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'medium',
      estimatedSavings: (json['estimatedSavings'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'estimatedSavings': estimatedSavings,
    };
  }
}

class QuickInsights {
  final String healthScore;
  final Map<String, dynamic> summary;
  final int alerts;
  final String? topIssue;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> opportunities;

  QuickInsights({
    required this.healthScore,
    required this.summary,
    required this.alerts,
    this.topIssue,
    required this.strengths,
    required this.weaknesses,
    required this.opportunities,
  });

  factory QuickInsights.fromJson(Map<String, dynamic> json) {
    return QuickInsights(
      healthScore: json['healthScore'] ?? 'N/A',
      summary: json['summary'] != null
          ? Map<String, dynamic>.from(json['summary'])
          : {},
      alerts: json['alerts'] ?? 0,
      topIssue: json['topIssue'],
      strengths: json['strengths'] != null
          ? List<String>.from(json['strengths'])
          : [],
      weaknesses: json['weaknesses'] != null
          ? List<String>.from(json['weaknesses'])
          : [],
      opportunities: json['opportunities'] != null
          ? List<String>.from(json['opportunities'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'healthScore': healthScore,
      'summary': summary,
      'alerts': alerts,
      'topIssue': topIssue,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'opportunities': opportunities,
    };
  }
}

class SpendingPatterns {
  final WeeklyPattern weeklyPattern;
  final CategoryPattern categoryPattern;
  final AmountPattern amountPattern;

  SpendingPatterns({
    required this.weeklyPattern,
    required this.categoryPattern,
    required this.amountPattern,
  });

  factory SpendingPatterns.fromJson(Map<String, dynamic> json) {
    return SpendingPatterns(
      weeklyPattern: WeeklyPattern.fromJson(json['weeklyPattern'] ?? {}),
      categoryPattern: CategoryPattern.fromJson(json['categoryPattern'] ?? {}),
      amountPattern: AmountPattern.fromJson(json['amountPattern'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weeklyPattern': weeklyPattern.toJson(),
      'categoryPattern': categoryPattern.toJson(),
      'amountPattern': amountPattern.toJson(),
    };
  }
}

class WeeklyPattern {
  final String highestSpendingDay;
  final List<double> distribution;

  WeeklyPattern({required this.highestSpendingDay, required this.distribution});

  factory WeeklyPattern.fromJson(Map<String, dynamic> json) {
    return WeeklyPattern(
      highestSpendingDay: json['highestSpendingDay'] ?? '',
      distribution:
          (json['distribution'] as List?)
              ?.map((e) => (e ?? 0).toDouble())
              .toList()
              .cast<double>() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'highestSpendingDay': highestSpendingDay,
      'distribution': distribution,
    };
  }
}

class CategoryPattern {
  final List<CategoryAmount> topCategories;
  final int totalCategories;

  CategoryPattern({required this.topCategories, required this.totalCategories});

  factory CategoryPattern.fromJson(Map<String, dynamic> json) {
    return CategoryPattern(
      topCategories: json['topCategories'] != null
          ? (json['topCategories'] as List)
                .map((c) => CategoryAmount.fromJson(c))
                .toList()
          : [],
      totalCategories: json['totalCategories'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topCategories': topCategories.map((c) => c.toJson()).toList(),
      'totalCategories': totalCategories,
    };
  }
}

class CategoryAmount {
  final String category;
  final double amount;

  CategoryAmount({required this.category, required this.amount});

  factory CategoryAmount.fromJson(Map<String, dynamic> json) {
    return CategoryAmount(
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'category': category, 'amount': amount};
  }
}

class AmountPattern {
  final double average;
  final double median;
  final double min;
  final double max;
  final String range;

  AmountPattern({
    required this.average,
    required this.median,
    required this.min,
    required this.max,
    required this.range,
  });

  factory AmountPattern.fromJson(Map<String, dynamic> json) {
    return AmountPattern(
      average: (json['average'] ?? 0).toDouble(),
      median: (json['median'] ?? 0).toDouble(),
      min: (json['min'] ?? 0).toDouble(),
      max: (json['max'] ?? 0).toDouble(),
      range: json['range'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average': average,
      'median': median,
      'min': min,
      'max': max,
      'range': range,
    };
  }
}
