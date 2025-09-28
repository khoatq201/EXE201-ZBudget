import 'package:flutter/material.dart';

enum SavingsCategory {
  emergency,
  purchase,
  travel,
  education,
  investment,
  home,
  vehicle,
  health,
  wedding,
  other,
}

enum SavingsPriority { low, medium, high, urgent }

class SavingsGoal {
  final String id;
  final String name;
  final String description;
  final int targetAmount;
  final int currentAmount;
  final DateTime targetDate;
  final DateTime createdAt;
  final SavingsCategory category;
  final SavingsPriority priority;
  final Color color;
  final bool isActive;
  final bool autoSaveEnabled;
  final int monthlyContribution;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.createdAt,
    required this.category,
    required this.priority,
    required this.color,
    this.isActive = true,
    this.autoSaveEnabled = false,
    this.monthlyContribution = 0,
  });

  double get progressPercentage => (currentAmount / targetAmount) * 100;
  int get remainingAmount => targetAmount - currentAmount;
  bool get isCompleted => currentAmount >= targetAmount;

  int get remainingDays {
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    return difference.inDays > 0 ? difference.inDays : 0;
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    String? description,
    int? targetAmount,
    int? currentAmount,
    DateTime? targetDate,
    DateTime? createdAt,
    SavingsCategory? category,
    SavingsPriority? priority,
    Color? color,
    bool? isActive,
    bool? autoSaveEnabled,
    int? monthlyContribution,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
    );
  }
}

class SavingsContribution {
  final String id;
  final String goalId;
  final int amount;
  final DateTime date;
  final String note;
  final String type; // 'manual', 'auto', 'interest'

  SavingsContribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note = '',
    this.type = 'manual',
  });

  SavingsContribution copyWith({
    String? id,
    String? goalId,
    int? amount,
    DateTime? date,
    String? note,
    String? type,
  }) {
    return SavingsContribution(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      type: type ?? this.type,
    );
  }
}
