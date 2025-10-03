enum Currency { vnd, usd, eur }

enum ExpenseCategory {
  food,
  transport,
  shopping,
  entertainment,
  healthcare,
  education,
  utilities,
  other,
}

enum PaymentMethod { cash, card, momo, banking, other }

class Expense {
  final String id;
  final String userId;
  final double amount;
  final Currency currency;
  final ExpenseCategory category;
  final String? description;
  final DateTime date;
  final String? receiptImage;
  final String? location;
  final PaymentMethod? paymentMethod;
  final String? groupId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.category,
    this.description,
    required this.date,
    this.receiptImage,
    this.location,
    this.paymentMethod,
    this.groupId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    // Handle both _id (MongoDB) and id formats
    final String expenseId = json['_id']?.toString() ?? json['id']?.toString() ?? '';

    // Handle Decimal128 from MongoDB
    double parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is Map && value.containsKey('\$numberDecimal')) {
        return double.parse(value['\$numberDecimal'].toString());
      }
      return double.parse(value.toString());
    }

    return Expense(
      id: expenseId,
      userId: json['userId']?.toString() ?? '',
      amount: parseAmount(json['amount']),
      currency: Currency.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == json['currency']?.toString().toLowerCase(),
        orElse: () => Currency.vnd,
      ),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      description: json['description'] as String? ?? json['title'] as String?,
      date: DateTime.parse(json['date'] as String),
      receiptImage: json['receiptImage'] as String? ?? json['receipt'] as String?,
      location: json['location'] is String ? json['location'] as String? : json['location']?['name'] as String?,
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.toString().split('.').last == json['paymentMethod'],
              orElse: () => PaymentMethod.cash,
            )
          : null,
      groupId: json['groupId']?.toString(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'currency': currency.toString().split('.').last,
      'category': category.toString().split('.').last,
      'description': description,
      'date': date.toIso8601String(),
      'receiptImage': receiptImage,
      'location': location,
      'paymentMethod': paymentMethod?.toString().split('.').last,
      'groupId': groupId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Expense copyWith({
    String? id,
    String? userId,
    double? amount,
    Currency? currency,
    ExpenseCategory? category,
    String? description,
    DateTime? date,
    String? receiptImage,
    String? location,
    PaymentMethod? paymentMethod,
    String? groupId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      receiptImage: receiptImage ?? this.receiptImage,
      location: location ?? this.location,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, amount: $amount, category: $category, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Pagination class for API responses
class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPrevPage;

  Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] as int,
      totalPages: json['totalPages'] as int,
      totalItems: json['totalItems'] as int,
      itemsPerPage: json['itemsPerPage'] as int,
      hasNextPage: json['hasNextPage'] as bool,
      hasPrevPage: json['hasPrevPage'] as bool,
    );
  }
}

// Expense list response from API
class ExpenseListResponse {
  final List<Expense> expenses;
  final Pagination pagination;

  ExpenseListResponse({
    required this.expenses,
    required this.pagination,
  });

  factory ExpenseListResponse.fromJson(Map<String, dynamic> json) {
    final expensesList = (json['expenses'] as List)
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();

    return ExpenseListResponse(
      expenses: expensesList,
      pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

// Expense statistics from API
class ExpenseStats {
  final double totalAmount;
  final int totalCount;
  final Map<String, dynamic>? groupedData;

  ExpenseStats({
    required this.totalAmount,
    required this.totalCount,
    this.groupedData,
  });

  factory ExpenseStats.fromJson(Map<String, dynamic> json) {
    return ExpenseStats(
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      totalCount: json['totalCount'] as int? ?? 0,
      groupedData: json['groupedData'] as Map<String, dynamic>?,
    );
  }
}
