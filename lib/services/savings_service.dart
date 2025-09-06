import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/savings_models.dart';

class SavingsService extends ChangeNotifier {
  final List<SavingsGoal> _savingsGoals = [
    // Sample data
    SavingsGoal(
      id: '1',
      name: 'Quỹ khẩn cấp',
      description: 'Tiết kiệm cho các tình huống khẩn cấp',
      targetAmount: 50000000,
      currentAmount: 15000000,
      targetDate: DateTime.now().add(const Duration(days: 365)),
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      category: SavingsCategory.emergency,
      priority: SavingsPriority.high,
      color: Colors.red.shade400,
      autoSaveEnabled: true,
      monthlyContribution: 2000000,
    ),
    SavingsGoal(
      id: '2',
      name: 'Du lịch Đà Lạt',
      description: 'Chuyến du lịch gia đình cuối năm',
      targetAmount: 20000000,
      currentAmount: 8500000,
      targetDate: DateTime.now().add(const Duration(days: 180)),
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      category: SavingsCategory.travel,
      priority: SavingsPriority.medium,
      color: Colors.blue.shade400,
      autoSaveEnabled: false,
      monthlyContribution: 1500000,
    ),
    SavingsGoal(
      id: '3',
      name: 'Mua laptop mới',
      description: 'Laptop cho công việc và học tập',
      targetAmount: 30000000,
      currentAmount: 12000000,
      targetDate: DateTime.now().add(const Duration(days: 120)),
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      category: SavingsCategory.purchase,
      priority: SavingsPriority.medium,
      color: Colors.green.shade400,
      autoSaveEnabled: true,
      monthlyContribution: 3000000,
    ),
  ];

  final List<SavingsContribution> _contributions = [
    SavingsContribution(
      id: '1',
      goalId: '1',
      amount: 2000000,
      date: DateTime.now().subtract(const Duration(days: 30)),
      note: 'Tiền lương tháng 12',
      type: 'auto',
    ),
    SavingsContribution(
      id: '2',
      goalId: '1',
      amount: 1000000,
      date: DateTime.now().subtract(const Duration(days: 15)),
      note: 'Tiền thưởng',
      type: 'manual',
    ),
    SavingsContribution(
      id: '3',
      goalId: '2',
      amount: 1500000,
      date: DateTime.now().subtract(const Duration(days: 20)),
      note: 'Tiết kiệm tháng 12',
      type: 'manual',
    ),
    SavingsContribution(
      id: '4',
      goalId: '3',
      amount: 3000000,
      date: DateTime.now().subtract(const Duration(days: 10)),
      note: 'Tiết kiệm tháng 1',
      type: 'auto',
    ),
  ];

  List<SavingsGoal> get savingsGoals => List.unmodifiable(_savingsGoals);
  List<SavingsGoal> get activeSavingsGoals => 
      _savingsGoals.where((goal) => goal.isActive).toList();

  int get totalSaved => _savingsGoals.fold(0, (sum, goal) => sum + goal.currentAmount);
  int get totalTarget => _savingsGoals.fold(0, (sum, goal) => sum + goal.targetAmount);
  double get overallProgress => totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0;

  List<SavingsContribution> getContributionsForGoal(String goalId) {
    return _contributions
        .where((contribution) => contribution.goalId == goalId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<SavingsContribution> getRecentContributions({int limit = 10}) {
    final sortedContributions = List<SavingsContribution>.from(_contributions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedContributions.take(limit).toList();
  }

  SavingsGoal? getSavingsGoalById(String id) {
    try {
      return _savingsGoals.firstWhere((goal) => goal.id == id);
    } catch (e) {
      return null;
    }
  }

  // CRUD Operations for Savings Goals
  void addSavingsGoal(SavingsGoal goal) {
    _savingsGoals.add(goal);
    notifyListeners();
  }

  void updateSavingsGoal(SavingsGoal updatedGoal) {
    final index = _savingsGoals.indexWhere((goal) => goal.id == updatedGoal.id);
    if (index != -1) {
      _savingsGoals[index] = updatedGoal;
      notifyListeners();
    }
  }

  void deleteSavingsGoal(String goalId) {
    _savingsGoals.removeWhere((goal) => goal.id == goalId);
    _contributions.removeWhere((contribution) => contribution.goalId == goalId);
    notifyListeners();
  }

  // Contribution Operations
  void addContribution(SavingsContribution contribution) {
    _contributions.add(contribution);
    
    // Update goal's current amount
    final goalIndex = _savingsGoals.indexWhere((goal) => goal.id == contribution.goalId);
    if (goalIndex != -1) {
      final updatedGoal = _savingsGoals[goalIndex].copyWith(
        currentAmount: _savingsGoals[goalIndex].currentAmount + contribution.amount,
      );
      _savingsGoals[goalIndex] = updatedGoal;
    }
    
    notifyListeners();
  }

  void updateContribution(SavingsContribution updatedContribution) {
    final index = _contributions.indexWhere((c) => c.id == updatedContribution.id);
    if (index != -1) {
      final oldAmount = _contributions[index].amount;
      _contributions[index] = updatedContribution;
      
      // Update goal's current amount
      final goalIndex = _savingsGoals.indexWhere((goal) => goal.id == updatedContribution.goalId);
      if (goalIndex != -1) {
        final difference = updatedContribution.amount - oldAmount;
        final updatedGoal = _savingsGoals[goalIndex].copyWith(
          currentAmount: _savingsGoals[goalIndex].currentAmount + difference,
        );
        _savingsGoals[goalIndex] = updatedGoal;
      }
      
      notifyListeners();
    }
  }

  void deleteContribution(String contributionId) {
    final contributionIndex = _contributions.indexWhere((c) => c.id == contributionId);
    if (contributionIndex != -1) {
      final contribution = _contributions[contributionIndex];
      _contributions.removeAt(contributionIndex);
      
      // Update goal's current amount
      final goalIndex = _savingsGoals.indexWhere((goal) => goal.id == contribution.goalId);
      if (goalIndex != -1) {
        final updatedGoal = _savingsGoals[goalIndex].copyWith(
          currentAmount: _savingsGoals[goalIndex].currentAmount - contribution.amount,
        );
        _savingsGoals[goalIndex] = updatedGoal;
      }
      
      notifyListeners();
    }
  }

  // Statistics and Analytics
  Map<SavingsCategory, int> getCategoryBreakdown() {
    final breakdown = <SavingsCategory, int>{};
    for (final goal in _savingsGoals) {
      breakdown[goal.category] = (breakdown[goal.category] ?? 0) + goal.currentAmount;
    }
    return breakdown;
  }

  Map<String, int> getMonthlyContributions() {
    final monthly = <String, int>{};
    for (final contribution in _contributions) {
      final monthKey = '${contribution.date.year}-${contribution.date.month.toString().padLeft(2, '0')}';
      monthly[monthKey] = (monthly[monthKey] ?? 0) + contribution.amount;
    }
    return monthly;
  }

  List<SavingsGoal> getSortedGoalsByPriority() {
    final goals = List<SavingsGoal>.from(_savingsGoals);
    goals.sort((a, b) {
      final priorityOrder = {
        SavingsPriority.urgent: 0,
        SavingsPriority.high: 1,
        SavingsPriority.medium: 2,
        SavingsPriority.low: 3,
      };
      return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
    });
    return goals;
  }

  List<SavingsGoal> getGoalsNearingDeadline({int daysThreshold = 30}) {
    final now = DateTime.now();
    return _savingsGoals.where((goal) {
      final daysRemaining = goal.targetDate.difference(now).inDays;
      return daysRemaining <= daysThreshold && daysRemaining > 0 && !goal.isCompleted;
    }).toList();
  }

  // Helper methods for formatting
  String getCategoryDisplayName(SavingsCategory category) {
    switch (category) {
      case SavingsCategory.emergency:
        return 'Khẩn cấp';
      case SavingsCategory.purchase:
        return 'Mua sắm';
      case SavingsCategory.travel:
        return 'Du lịch';
      case SavingsCategory.education:
        return 'Giáo dục';
      case SavingsCategory.investment:
        return 'Đầu tư';
      case SavingsCategory.home:
        return 'Nhà cửa';
      case SavingsCategory.vehicle:
        return 'Xe cộ';
      case SavingsCategory.health:
        return 'Sức khỏe';
      case SavingsCategory.wedding:
        return 'Đám cưới';
      case SavingsCategory.other:
        return 'Khác';
    }
  }

  String getPriorityDisplayName(SavingsPriority priority) {
    switch (priority) {
      case SavingsPriority.urgent:
        return 'Khẩn cấp';
      case SavingsPriority.high:
        return 'Cao';
      case SavingsPriority.medium:
        return 'Trung bình';
      case SavingsPriority.low:
        return 'Thấp';
    }
  }

  Color getPriorityColor(SavingsPriority priority) {
    switch (priority) {
      case SavingsPriority.urgent:
        return Colors.red.shade600;
      case SavingsPriority.high:
        return Colors.orange.shade600;
      case SavingsPriority.medium:
        return Colors.blue.shade600;
      case SavingsPriority.low:
        return Colors.green.shade600;
    }
  }

  IconData getCategoryIcon(SavingsCategory category) {
    switch (category) {
      case SavingsCategory.emergency:
        return Icons.emergency;
      case SavingsCategory.purchase:
        return Icons.shopping_bag;
      case SavingsCategory.travel:
        return Icons.flight;
      case SavingsCategory.education:
        return Icons.school;
      case SavingsCategory.investment:
        return Icons.trending_up;
      case SavingsCategory.home:
        return Icons.home;
      case SavingsCategory.vehicle:
        return Icons.directions_car;
      case SavingsCategory.health:
        return Icons.health_and_safety;
      case SavingsCategory.wedding:
        return Icons.favorite;
      case SavingsCategory.other:
        return Icons.category;
    }
  }
}
