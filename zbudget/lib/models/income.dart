class Income {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final double amount;
  final String category;
  final DateTime date;
  final String paymentMethod;
  final String? source;
  final bool isConfirmed;
  final bool isRecurring;
  final RecurringDetails? recurringDetails;
  final TaxInfo? taxInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Income({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.paymentMethod,
    this.source,
    required this.isConfirmed,
    required this.isRecurring,
    this.recurringDetails,
    this.taxInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      paymentMethod: json['paymentMethod'] as String,
      source: json['source'] as String?,
      isConfirmed: json['isConfirmed'] as bool? ?? true,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringDetails: json['recurringDetails'] != null
          ? RecurringDetails.fromJson(
              json['recurringDetails'] as Map<String, dynamic>)
          : null,
      taxInfo: json['taxInfo'] != null
          ? TaxInfo.fromJson(json['taxInfo'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'source': source,
      'isConfirmed': isConfirmed,
      'isRecurring': isRecurring,
      'recurringDetails': recurringDetails?.toJson(),
      'taxInfo': taxInfo?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class RecurringDetails {
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime? endDate;
  final int? occurrences;

  RecurringDetails({
    required this.frequency,
    this.endDate,
    this.occurrences,
  });

  factory RecurringDetails.fromJson(Map<String, dynamic> json) {
    return RecurringDetails(
      frequency: json['frequency'] as String,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      occurrences: json['occurrences'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency,
      'endDate': endDate?.toIso8601String(),
      'occurrences': occurrences,
    };
  }
}

class TaxInfo {
  final bool isTaxable;
  final double? taxRate;
  final double? taxAmount;

  TaxInfo({
    required this.isTaxable,
    this.taxRate,
    this.taxAmount,
  });

  factory TaxInfo.fromJson(Map<String, dynamic> json) {
    return TaxInfo(
      isTaxable: json['isTaxable'] as bool,
      taxRate: json['taxRate'] != null
          ? (json['taxRate'] as num).toDouble()
          : null,
      taxAmount: json['taxAmount'] != null
          ? (json['taxAmount'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isTaxable': isTaxable,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
    };
  }
}

class IncomeListResponse {
  final List<Income> incomes;
  final Pagination pagination;

  IncomeListResponse({
    required this.incomes,
    required this.pagination,
  });

  factory IncomeListResponse.fromJson(Map<String, dynamic> json) {
    return IncomeListResponse(
      incomes: (json['incomes'] as List)
          .map((i) => Income.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int pages;

  Pagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      pages: json['pages'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'page': page,
      'limit': limit,
      'pages': pages,
    };
  }
}

class IncomeStats {
  final List<IncomeStat> stats;
  final IncomeTotal total;

  IncomeStats({
    required this.stats,
    required this.total,
  });

  factory IncomeStats.fromJson(Map<String, dynamic> json) {
    return IncomeStats(
      stats: (json['stats'] as List)
          .map((s) => IncomeStat.fromJson(s as Map<String, dynamic>))
          .toList(),
      total: IncomeTotal.fromJson(json['total'] as Map<String, dynamic>),
    );
  }
}

class IncomeStat {
  final String id;
  final double total;
  final int count;
  final double avgAmount;

  IncomeStat({
    required this.id,
    required this.total,
    required this.count,
    required this.avgAmount,
  });

  factory IncomeStat.fromJson(Map<String, dynamic> json) {
    return IncomeStat(
      id: json['_id'].toString(),
      total: (json['total'] as num).toDouble(),
      count: json['count'] as int,
      avgAmount: (json['avgAmount'] as num).toDouble(),
    );
  }
}

class IncomeTotal {
  final double total;
  final int count;

  IncomeTotal({
    required this.total,
    required this.count,
  });

  factory IncomeTotal.fromJson(Map<String, dynamic> json) {
    return IncomeTotal(
      total: (json['total'] as num).toDouble(),
      count: json['count'] as int,
    );
  }
}
