import 'package:flutter/material.dart';
import 'expense.dart';

enum BudgetPeriod { daily, weekly, monthly, yearly }

class BudgetCategoryData {
  final ExpenseCategory category;
  final int allocatedAmount;
  final int spentAmount;
  final Color color;

  BudgetCategoryData({
    required this.category,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.color,
  });
}

class BudgetData {
  final String id;
  final String name;
  final int totalAmount;
  final int spentAmount;
  final BudgetPeriod period;
  final List<BudgetCategoryData> categories;

  BudgetData({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.spentAmount,
    required this.period,
    required this.categories,
  });
}
