import 'expense.dart';

enum BudgetPeriod { weekly, monthly, quarterly, yearly }

class BudgetCategory {
  final ExpenseCategory category;
  final double allocatedAmount;
  final double spentAmount;
  final double percentage;

  BudgetCategory({
    required this.category,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.percentage,
  });

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      category: ExpenseCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      allocatedAmount: (json['allocatedAmount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category.toString().split('.').last,
      'allocatedAmount': allocatedAmount,
      'spentAmount': spentAmount,
      'percentage': percentage,
    };
  }

  BudgetCategory copyWith({
    ExpenseCategory? category,
    double? allocatedAmount,
    double? spentAmount,
    double? percentage,
  }) {
    return BudgetCategory(
      category: category ?? this.category,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      percentage: percentage ?? this.percentage,
    );
  }
}

class Budget {
  final String id;
  final String userId;
  final String name;
  final double totalAmount;
  final Currency currency;
  final List<BudgetCategory> categories;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.userId,
    required this.name,
    required this.totalAmount,
    required this.currency,
    required this.categories,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      currency: Currency.values.firstWhere(
        (e) => e.toString().split('.').last == json['currency'],
        orElse: () => Currency.vnd,
      ),
      categories: (json['categories'] as List<dynamic>)
          .map((e) => BudgetCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      period: BudgetPeriod.values.firstWhere(
        (e) => e.toString().split('.').last == json['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'totalAmount': totalAmount,
      'currency': currency.toString().split('.').last,
      'categories': categories.map((e) => e.toJson()).toList(),
      'period': period.toString().split('.').last,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Budget copyWith({
    String? id,
    String? userId,
    String? name,
    double? totalAmount,
    Currency? currency,
    List<BudgetCategory>? categories,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      categories: categories ?? this.categories,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Budget(id: $id, name: $name, totalAmount: $totalAmount, period: $period)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
