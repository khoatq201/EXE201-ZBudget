import 'package:flutter/material.dart';
import '../models/budget_models.dart';

class Expense {
  final String id;
  final ExpenseCategory category;
  final int amount;
  final String description;
  final DateTime date;
  final String? budgetId;
  final String? receipt;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    this.budgetId,
    this.receipt,
  });
}

class ExpenseService extends ChangeNotifier {
  final List<Expense> _expenses = [];
  final Map<String, BudgetData> _budgets = {};

  List<Expense> get expenses => List.unmodifiable(_expenses);
  Map<String, BudgetData> get budgets => Map.unmodifiable(_budgets);

  // Khởi tạo budget mẫu
  void initializeSampleBudget() {
    final sampleBudget = BudgetData(
      id: '1',
      name: 'Ngân sách tháng 9',
      totalAmount: 15000000,
      spentAmount: 0,
      period: BudgetPeriod.monthly,
      categories: [
        BudgetCategoryData(
          category: ExpenseCategory.food,
          allocatedAmount: 5000000,
          spentAmount: 0,
          color: const Color(0xFFFF6B6B),
        ),
        BudgetCategoryData(
          category: ExpenseCategory.transport,
          allocatedAmount: 2000000,
          spentAmount: 0,
          color: const Color(0xFF4ECDC4),
        ),
        BudgetCategoryData(
          category: ExpenseCategory.shopping,
          allocatedAmount: 3000000,
          spentAmount: 0,
          color: const Color(0xFF45B7D1),
        ),
        BudgetCategoryData(
          category: ExpenseCategory.entertainment,
          allocatedAmount: 2000000,
          spentAmount: 0,
          color: const Color(0xFF96CEB4),
        ),
        BudgetCategoryData(
          category: ExpenseCategory.utilities,
          allocatedAmount: 1500000,
          spentAmount: 0,
          color: const Color(0xFFFFD700),
        ),
        BudgetCategoryData(
          category: ExpenseCategory.healthcare,
          allocatedAmount: 1000000,
          spentAmount: 0,
          color: const Color(0xFFFF8C42),
        ),
        BudgetCategoryData(
          category: ExpenseCategory.other,
          allocatedAmount: 500000,
          spentAmount: 0,
          color: const Color(0xFF6C5CE7),
        ),
      ],
    );

    _budgets[sampleBudget.id] = sampleBudget;
  }

  // Thêm chi tiêu mới
  Future<void> addExpense({
    required ExpenseCategory category,
    required int amount,
    required String description,
    required DateTime date,
    String? budgetId,
    String? receipt,
  }) async {
    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: category,
      amount: amount,
      description: description,
      date: date,
      budgetId: budgetId,
      receipt: receipt,
    );

    _expenses.add(expense);

    // Cập nhật ngân sách nếu có
    if (budgetId != null && _budgets.containsKey(budgetId)) {
      await _updateBudgetSpentAmount(budgetId, category, amount);
    }

    notifyListeners();
  }

  // Cập nhật số tiền đã chi trong ngân sách
  Future<void> _updateBudgetSpentAmount(
    String budgetId,
    ExpenseCategory category,
    int amount,
  ) async {
    final budget = _budgets[budgetId];
    if (budget == null) return;

    // Tạo danh sách categories mới với thông tin cập nhật
    final updatedCategories = budget.categories.map((cat) {
      if (cat.category == category) {
        return BudgetCategoryData(
          category: cat.category,
          allocatedAmount: cat.allocatedAmount,
          spentAmount: cat.spentAmount + amount,
          color: cat.color,
        );
      }
      return cat;
    }).toList();

    // Tính tổng số tiền đã chi
    final totalSpent = updatedCategories.fold<int>(
      0,
      (sum, cat) => sum + cat.spentAmount,
    );

    // Tạo budget mới với thông tin cập nhật
    final updatedBudget = BudgetData(
      id: budget.id,
      name: budget.name,
      totalAmount: budget.totalAmount,
      spentAmount: totalSpent,
      period: budget.period,
      categories: updatedCategories,
    );

    _budgets[budgetId] = updatedBudget;
  }

  // Lấy chi tiêu theo ngân sách
  List<Expense> getExpensesByBudget(String budgetId) {
    return _expenses.where((expense) => expense.budgetId == budgetId).toList();
  }

  // Lấy chi tiêu theo danh mục
  List<Expense> getExpensesByCategory(ExpenseCategory category) {
    return _expenses.where((expense) => expense.category == category).toList();
  }

  // Lấy chi tiêu trong khoảng thời gian
  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return _expenses
        .where(
          (expense) =>
              expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
              expense.date.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }

  // Lấy ngân sách theo ID
  BudgetData? getBudgetById(String budgetId) {
    return _budgets[budgetId];
  }

  // Xóa chi tiêu
  Future<void> deleteExpense(String expenseId) async {
    final expenseIndex = _expenses.indexWhere((e) => e.id == expenseId);
    if (expenseIndex == -1) return;

    final expense = _expenses[expenseIndex];
    _expenses.removeAt(expenseIndex);

    // Cập nhật lại ngân sách nếu có
    if (expense.budgetId != null && _budgets.containsKey(expense.budgetId!)) {
      await _updateBudgetSpentAmount(
        expense.budgetId!,
        expense.category,
        -expense.amount,
      );
    }

    notifyListeners();
  }

  // Cập nhật chi tiêu
  Future<void> updateExpense({
    required String expenseId,
    ExpenseCategory? category,
    int? amount,
    String? description,
    DateTime? date,
  }) async {
    final expenseIndex = _expenses.indexWhere((e) => e.id == expenseId);
    if (expenseIndex == -1) return;

    final oldExpense = _expenses[expenseIndex];

    // Tạo chi tiêu mới với thông tin cập nhật
    final updatedExpense = Expense(
      id: oldExpense.id,
      category: category ?? oldExpense.category,
      amount: amount ?? oldExpense.amount,
      description: description ?? oldExpense.description,
      date: date ?? oldExpense.date,
      budgetId: oldExpense.budgetId,
      receipt: oldExpense.receipt,
    );

    _expenses[expenseIndex] = updatedExpense;

    // Cập nhật ngân sách nếu có thay đổi
    if (oldExpense.budgetId != null &&
        _budgets.containsKey(oldExpense.budgetId!)) {
      // Trừ số tiền cũ
      await _updateBudgetSpentAmount(
        oldExpense.budgetId!,
        oldExpense.category,
        -oldExpense.amount,
      );
      // Cộng số tiền mới
      await _updateBudgetSpentAmount(
        oldExpense.budgetId!,
        updatedExpense.category,
        updatedExpense.amount,
      );
    }

    notifyListeners();
  }
}
