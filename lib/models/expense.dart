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
    return Expense(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: Currency.values.firstWhere(
        (e) => e.toString().split('.').last == json['currency'],
        orElse: () => Currency.vnd,
      ),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      receiptImage: json['receiptImage'] as String?,
      location: json['location'] as String?,
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.toString().split('.').last == json['paymentMethod'],
              orElse: () => PaymentMethod.cash,
            )
          : null,
      groupId: json['groupId'] as String?,
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
