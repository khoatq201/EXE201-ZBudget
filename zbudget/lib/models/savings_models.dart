import 'package:flutter/material.dart';

enum SavingsCategory {
  emergencyFund('emergency_fund', 'Quỹ khẩn cấp', Icons.emergency),
  vacation('vacation', 'Du lịch', Icons.flight),
  house('house', 'Mua nhà', Icons.home),
  car('car', 'Mua xe', Icons.directions_car),
  education('education', 'Học tập', Icons.school),
  wedding('wedding', 'Đám cưới', Icons.favorite),
  retirement('retirement', 'Hưu trí', Icons.elderly),
  gadget('gadget', 'Thiết bị', Icons.devices),
  investment('investment', 'Đầu tư', Icons.trending_up),
  other('other', 'Khác', Icons.category);

  final String value;
  final String displayName;
  final IconData icon;

  const SavingsCategory(this.value, this.displayName, this.icon);

  static SavingsCategory fromString(String value) {
    return SavingsCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SavingsCategory.other,
    );
  }
}

enum SavingsPriority {
  low('low', 'Thấp'),
  medium('medium', 'Trung bình'),
  high('high', 'Cao'),
  critical('critical', 'Khẩn cấp');

  final String value;
  final String displayName;

  const SavingsPriority(this.value, this.displayName);

  static SavingsPriority fromString(String value) {
    return SavingsPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SavingsPriority.medium,
    );
  }
}

enum SavingsStatus {
  active('active', 'Đang hoạt động'),
  paused('paused', 'Tạm dừng'),
  completed('completed', 'Hoàn thành'),
  cancelled('cancelled', 'Đã hủy');

  final String value;
  final String displayName;

  const SavingsStatus(this.value, this.displayName);

  static SavingsStatus fromString(String value) {
    return SavingsStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SavingsStatus.active,
    );
  }
}

class Contribution {
  final String id;
  final double amount;
  final String source; // 'income_allocation', 'manual', 'transfer'
  final String? incomeId;
  final String? note;
  final DateTime date;

  Contribution({
    required this.id,
    required this.amount,
    required this.source,
    this.incomeId,
    this.note,
    required this.date,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['_id'] ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      source: json['source'] ?? 'manual',
      incomeId: json['incomeId'],
      note: json['note'],
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'source': source,
      'incomeId': incomeId,
      'note': note,
      'date': date.toIso8601String(),
    };
  }
}

class Withdrawal {
  final String id;
  final double amount;
  final String? reason;
  final DateTime date;

  Withdrawal({
    required this.id,
    required this.amount,
    this.reason,
    required this.date,
  });

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: json['_id'] ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      reason: json['reason'],
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'reason': reason,
      'date': date.toIso8601String(),
    };
  }
}

class AutoSave {
  final bool enabled;
  final double? amount;
  final String? frequency; // 'daily', 'weekly', 'monthly'
  final DateTime? nextAutoSaveDate;

  AutoSave({
    this.enabled = false,
    this.amount,
    this.frequency,
    this.nextAutoSaveDate,
  });

  factory AutoSave.fromJson(Map<String, dynamic> json) {
    return AutoSave(
      enabled: json['enabled'] ?? false,
      amount: json['amount'] != null
          ? (json['amount'] is num ? (json['amount'] as num).toDouble() : 0.0)
          : null,
      frequency: json['frequency'],
      nextAutoSaveDate: json['nextAutoSaveDate'] != null
          ? DateTime.parse(json['nextAutoSaveDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'amount': amount,
      'frequency': frequency,
      'nextAutoSaveDate': nextAutoSaveDate?.toIso8601String(),
    };
  }
}

class SavingsGoal {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final String currency;
  final DateTime startDate;
  final DateTime targetDate;
  final SavingsCategory category;
  final SavingsPriority priority;
  final List<Contribution> contributions;
  final List<Withdrawal> withdrawals;
  final SavingsStatus status;
  final DateTime? completedDate;
  final AutoSave autoSave;
  final String icon;
  final String color;
  final List<String> tags;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Virtuals (calculated fields from backend)
  final double? progressPercentage;
  final double? remainingAmount;
  final int? daysRemaining;
  final double? suggestedMonthlyContribution;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0,
    this.currency = 'VND',
    required this.startDate,
    required this.targetDate,
    required this.category,
    this.priority = SavingsPriority.medium,
    this.contributions = const [],
    this.withdrawals = const [],
    this.status = SavingsStatus.active,
    this.completedDate,
    AutoSave? autoSave,
    this.icon = 'piggy_bank',
    this.color = '#4CAF50',
    this.tags = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.progressPercentage,
    this.remainingAmount,
    this.daysRemaining,
    this.suggestedMonthlyContribution,
  }) : autoSave = autoSave ?? AutoSave();

  // Calculate progress locally if not provided
  double get progress => progressPercentage ?? (targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0);
  double get remaining => remainingAmount ?? (targetAmount - currentAmount);
  bool get isCompleted => status == SavingsStatus.completed || currentAmount >= targetAmount;

  int get remainingDaysLocal {
    if (daysRemaining != null) return daysRemaining!;
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    return difference.inDays > 0 ? difference.inDays : 0;
  }

  Color get colorValue {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.green;
    }
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      targetAmount: (json['targetAmount'] is num)
          ? (json['targetAmount'] as num).toDouble()
          : 0.0,
      currentAmount: (json['currentAmount'] is num)
          ? (json['currentAmount'] as num).toDouble()
          : 0.0,
      currency: json['currency'] ?? 'VND',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'])
          : DateTime.now().add(const Duration(days: 365)),
      category: SavingsCategory.fromString(json['category'] ?? 'other'),
      priority: SavingsPriority.fromString(json['priority'] ?? 'medium'),
      contributions: json['contributions'] != null
          ? (json['contributions'] as List)
              .map((c) => Contribution.fromJson(c))
              .toList()
          : [],
      withdrawals: json['withdrawals'] != null
          ? (json['withdrawals'] as List)
              .map((w) => Withdrawal.fromJson(w))
              .toList()
          : [],
      status: SavingsStatus.fromString(json['status'] ?? 'active'),
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'])
          : null,
      autoSave: json['autoSave'] != null
          ? AutoSave.fromJson(json['autoSave'])
          : AutoSave(),
      icon: json['icon'] ?? 'piggy_bank',
      color: json['color'] ?? '#4CAF50',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      progressPercentage: json['progressPercentage'] != null
          ? (json['progressPercentage'] as num).toDouble()
          : null,
      remainingAmount: json['remainingAmount'] != null
          ? (json['remainingAmount'] as num).toDouble()
          : null,
      daysRemaining: json['daysRemaining'],
      suggestedMonthlyContribution:
          json['suggestedMonthlyContribution'] != null
              ? (json['suggestedMonthlyContribution'] as num).toDouble()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'targetDate': targetDate.toIso8601String(),
      'category': category.value,
      'priority': priority.value,
      'autoSave': autoSave.toJson(),
      'icon': icon,
      'color': color,
      'tags': tags,
      'notes': notes,
    };
  }

  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    String? currency,
    DateTime? startDate,
    DateTime? targetDate,
    SavingsCategory? category,
    SavingsPriority? priority,
    List<Contribution>? contributions,
    List<Withdrawal>? withdrawals,
    SavingsStatus? status,
    DateTime? completedDate,
    AutoSave? autoSave,
    String? icon,
    String? color,
    List<String>? tags,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? progressPercentage,
    double? remainingAmount,
    int? daysRemaining,
    double? suggestedMonthlyContribution,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      contributions: contributions ?? this.contributions,
      withdrawals: withdrawals ?? this.withdrawals,
      status: status ?? this.status,
      completedDate: completedDate ?? this.completedDate,
      autoSave: autoSave ?? this.autoSave,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      suggestedMonthlyContribution:
          suggestedMonthlyContribution ?? this.suggestedMonthlyContribution,
    );
  }
}

class SavingsStats {
  final int total;
  final int active;
  final int completed;
  final int paused;
  final double totalSaved;
  final double totalTarget;
  final double overallProgress;

  SavingsStats({
    required this.total,
    required this.active,
    required this.completed,
    required this.paused,
    required this.totalSaved,
    required this.totalTarget,
    required this.overallProgress,
  });

  factory SavingsStats.fromJson(Map<String, dynamic> json) {
    return SavingsStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      completed: json['completed'] ?? 0,
      paused: json['paused'] ?? 0,
      totalSaved: (json['totalSaved'] is num)
          ? (json['totalSaved'] as num).toDouble()
          : 0.0,
      totalTarget: (json['totalTarget'] is num)
          ? (json['totalTarget'] as num).toDouble()
          : 0.0,
      overallProgress: (json['overallProgress'] is num)
          ? (json['overallProgress'] as num).toDouble()
          : 0.0,
    );
  }
}
