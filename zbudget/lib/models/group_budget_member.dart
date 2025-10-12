/// Helper function to parse MongoDB Decimal128 values
double parseDecimal(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is Map && value.containsKey('\$numberDecimal')) {
    return double.parse(value['\$numberDecimal'].toString());
  }
  return double.parse(value.toString());
}

/// Helper function to parse ID fields that might be populated
String parseIdField(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is Map) {
    return value['_id']?.toString() ?? value['id']?.toString() ?? '';
  }
  return value.toString();
}

/// Represents a debt relationship between members
class Debt {
  final String toUserId;
  final String toUserName;
  final double amount;

  Debt({
    required this.toUserId,
    required this.toUserName,
    required this.amount,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      toUserId: json['toUserId'] ?? '',
      toUserName: json['toUserName'] ?? '',
      amount: parseDecimal(json['amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toUserId': toUserId,
      'toUserName': toUserName,
      'amount': amount,
    };
  }
}

/// Represents a member in a GroupBudget
class GroupBudgetMember {
  final String userId;
  final String name;
  final double contributionPercentage;
  final double contributionAmount;
  final double amountFunded;
  final double amountPaidOut;
  final double shareSpent;
  final double balance;
  final bool isPaid;
  final List<Debt> debts;
  final DateTime lastUpdated;

  GroupBudgetMember({
    required this.userId,
    required this.name,
    required this.contributionPercentage,
    required this.contributionAmount,
    required this.amountFunded,
    required this.amountPaidOut,
    required this.shareSpent,
    required this.balance,
    required this.isPaid,
    required this.debts,
    required this.lastUpdated,
  });

  factory GroupBudgetMember.fromJson(Map<String, dynamic> json) {
    return GroupBudgetMember(
      userId: parseIdField(json['userId']),
      name: json['name'] ?? '',
      contributionPercentage: (json['contributionPercentage'] ?? 0).toDouble(),
      contributionAmount: parseDecimal(json['contributionAmount']),
      amountFunded: parseDecimal(json['amountFunded']),
      amountPaidOut: parseDecimal(json['amountPaidOut']),
      shareSpent: parseDecimal(json['shareSpent']),
      balance: parseDecimal(json['balance']),
      isPaid: json['isPaid'] ?? false,
      debts: (json['debts'] as List?)
              ?.map((d) => Debt.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'contributionPercentage': contributionPercentage,
      'contributionAmount': contributionAmount,
      'amountFunded': amountFunded,
      'amountPaidOut': amountPaidOut,
      'shareSpent': shareSpent,
      'balance': balance,
      'isPaid': isPaid,
      'debts': debts.map((d) => d.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Helper getters
  bool get owesOthers => balance < 0;
  bool get isOwedByOthers => balance > 0;
  double get absBalance => balance.abs();

  // Balance status for UI
  String get balanceStatus {
    if (balance > 0) return 'owed'; // Others owe this member
    if (balance < 0) return 'owes'; // This member owes others
    return 'settled'; // All settled
  }
}
