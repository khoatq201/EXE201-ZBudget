import 'group_budget_member.dart';
import 'group_budget_expense.dart';

/// Helper function to parse ID fields that might be populated
String parseIdField(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is Map) {
    return value['_id']?.toString() ?? value['id']?.toString() ?? '';
  }
  return value.toString();
}

/// Represents a shared budget among multiple members
class GroupBudget {
  final String id;
  final String name;
  final String? description;
  final double totalBudget;
  final double totalSpent;
  final double totalFunded;
  final double remaining;
  final String currency;
  final String inviteCode;
  final String inviteLink;
  final DateTime startDate;
  final DateTime? endDate;
  final List<GroupBudgetMember> members;
  final List<GroupBudgetExpense> expenses;
  final bool isActive;
  final bool isSettled;
  final bool autoSplitByContribution;
  final bool allowPartialTag;
  final String? createdBy; // User ID of the creator (may be populated)
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupBudget({
    required this.id,
    required this.name,
    this.description,
    required this.totalBudget,
    required this.totalSpent,
    required this.totalFunded,
    required this.remaining,
    required this.currency,
    required this.inviteCode,
    required this.inviteLink,
    required this.startDate,
    this.endDate,
    required this.members,
    required this.expenses,
    required this.isActive,
    required this.isSettled,
    required this.autoSplitByContribution,
    required this.allowPartialTag,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupBudget.fromJson(Map<String, dynamic> json) {
    return GroupBudget(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      totalBudget: parseDecimal(json['totalBudget']),
      totalSpent: parseDecimal(json['totalSpent']),
      totalFunded: parseDecimal(json['totalFunded']),
      remaining: parseDecimal(json['remaining']),
      currency: json['currency'] ?? 'VND',
      inviteCode: json['inviteCode'] ?? '',
      inviteLink: json['inviteLink'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate:
          json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      members: (json['members'] as List?)
              ?.map((m) => GroupBudgetMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      expenses: (json['expenses'] as List?)
              ?.map((e) => GroupBudgetExpense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: json['isActive'] ?? true,
      isSettled: json['isSettled'] ?? false,
      autoSplitByContribution: json['autoSplitByContribution'] ?? true,
      allowPartialTag: json['allowPartialTag'] ?? true,
      createdBy: json['createdBy'] != null ? parseIdField(json['createdBy']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'totalFunded': totalFunded,
      'remaining': remaining,
      'currency': currency,
      'inviteCode': inviteCode,
      'inviteLink': inviteLink,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'members': members.map((m) => m.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'isActive': isActive,
      'isSettled': isSettled,
      'autoSplitByContribution': autoSplitByContribution,
      'allowPartialTag': allowPartialTag,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  double get spentPercentage =>
      totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;

  bool get isOverBudget => totalSpent > totalBudget;

  int get memberCount => members.length;

  int get expenseCount => expenses.length;

  // Get members who owe money
  List<GroupBudgetMember> get membersWhoOwe =>
      members.where((m) => m.owesOthers).toList();

  // Get members who are owed money
  List<GroupBudgetMember> get membersWhoAreOwed =>
      members.where((m) => m.isOwedByOthers).toList();

  // Get members with settled balance
  List<GroupBudgetMember> get settledMembers =>
      members.where((m) => m.balance == 0).toList();

  // Budget status for UI
  String get statusDisplay {
    if (isSettled) return 'Đã thanh toán';
    if (!isActive) return 'Không hoạt động';
    if (isOverBudget) return 'Vượt ngân sách';
    return 'Đang hoạt động';
  }

  // Get member by userId
  GroupBudgetMember? getMemberByUserId(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (e) {
      return null;
    }
  }

  // Check if user is a member
  bool isMember(String userId) {
    return members.any((m) => m.userId == userId);
  }
}
