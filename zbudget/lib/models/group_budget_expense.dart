import 'group_budget_member.dart';

/// Helper function to parse ID fields that might be populated
String parseIdField(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is Map) {
    return value['_id']?.toString() ?? value['id']?.toString() ?? '';
  }
  return value.toString();
}

/// Represents how an expense is split among participants
class ExpenseSplit {
  final String userId;
  final String userName;
  final double amount;
  final double percentage;

  ExpenseSplit({
    required this.userId,
    required this.userName,
    required this.amount,
    required this.percentage,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      userId: parseIdField(json['userId']),
      userName: json['userName'] ?? '',
      amount: parseDecimal(json['amount']),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'percentage': percentage,
    };
  }
}

/// Represents an expense within a GroupBudget
class GroupBudgetExpense {
  final String id;
  final String? expenseId; // Link to personal expense record
  final String description;
  final double amount;
  final String paidBy;
  final String paidByName;
  final String splitType; // 'auto', 'equal', 'custom'
  final List<String> participants;
  final List<ExpenseSplit> splits;
  final String category;
  final DateTime date;
  final String? notes;
  final String? receiptUrl;

  GroupBudgetExpense({
    required this.id,
    this.expenseId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.paidByName,
    required this.splitType,
    required this.participants,
    required this.splits,
    required this.category,
    required this.date,
    this.notes,
    this.receiptUrl,
  });

  factory GroupBudgetExpense.fromJson(Map<String, dynamic> json) {
    return GroupBudgetExpense(
      id: json['_id'] ?? json['id'] ?? '',
      expenseId: json['expenseId'],
      description: json['description'] ?? '',
      amount: parseDecimal(json['amount']),
      paidBy: parseIdField(json['paidBy']),
      paidByName: json['paidByName'] ?? '',
      splitType: json['splitType'] ?? 'auto',
      participants: List<String>.from(json['participants'] ?? []),
      splits: (json['splits'] as List?)
              ?.map((s) => ExpenseSplit.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      category: json['category'] ?? 'other',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      notes: json['notes'],
      receiptUrl: json['receiptUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expenseId': expenseId,
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'paidByName': paidByName,
      'splitType': splitType,
      'participants': participants,
      'splits': splits.map((s) => s.toJson()).toList(),
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
      'receiptUrl': receiptUrl,
    };
  }

  // Helper getters
  String get splitTypeDisplay {
    switch (splitType) {
      case 'auto':
        return 'Theo tỉ lệ đóng góp';
      case 'equal':
        return 'Chia đều';
      case 'custom':
        return 'Tùy chỉnh';
      default:
        return splitType;
    }
  }

  bool get hasReceipt => receiptUrl != null && receiptUrl!.isNotEmpty;
}
