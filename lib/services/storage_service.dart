import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';
import '../models/budget.dart';

class StorageService {
  static const String _expensesKey = 'expenses';
  static const String _budgetsKey = 'budgets';
  static const String _incomesKey = 'incomes';
  static const String _savingsGoalsKey = 'savings_goals';
  static const String _savingsPredictionsKey = 'savings_predictions';
  static const String _savingsSuggestionsKey = 'savings_suggestions';
  static const String _behavioralInsightsKey = 'behavioral_insights';

  // Expense management
  static Future<void> addExpense(Expense expense) async {
    final prefs = await SharedPreferences.getInstance();
    final expenses = await getExpenses();
    expenses.add(expense);
    await prefs.setString(
      _expensesKey,
      jsonEncode(expenses.map((e) => e.toJson()).toList()),
    );
  }

  static Future<List<Expense>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getString(_expensesKey);
    if (expensesJson != null) {
      final List<dynamic> expensesList = jsonDecode(expensesJson);
      return expensesList.map((e) => Expense.fromJson(e)).toList();
    }
    return [];
  }

  static Future<void> updateExpense(
    String expenseId,
    Map<String, dynamic> updates,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final expenses = await getExpenses();
    final index = expenses.indexWhere((e) => e.id == expenseId);
    if (index != -1) {
      final updatedExpense = expenses[index].copyWith(
        amount: updates['amount'],
        category: updates['category'],
        description: updates['description'],
        date: updates['date'],
        updatedAt: DateTime.now(),
      );
      expenses[index] = updatedExpense;
      await prefs.setString(
        _expensesKey,
        jsonEncode(expenses.map((e) => e.toJson()).toList()),
      );
    }
  }

  static Future<void> deleteExpense(String expenseId) async {
    final prefs = await SharedPreferences.getInstance();
    final expenses = await getExpenses();
    expenses.removeWhere((e) => e.id == expenseId);
    await prefs.setString(
      _expensesKey,
      jsonEncode(expenses.map((e) => e.toJson()).toList()),
    );
  }

  // Budget management
  static Future<void> addBudget(Budget budget) async {
    final prefs = await SharedPreferences.getInstance();
    final budgets = await getBudgets();
    budgets.add(budget);
    await prefs.setString(
      _budgetsKey,
      jsonEncode(budgets.map((b) => b.toJson()).toList()),
    );
  }

  static Future<List<Budget>> getBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final budgetsJson = prefs.getString(_budgetsKey);
    if (budgetsJson != null) {
      final List<dynamic> budgetsList = jsonDecode(budgetsJson);
      return budgetsList.map((b) => Budget.fromJson(b)).toList();
    }
    return [];
  }

  static Future<void> updateBudget(
    String budgetId,
    Map<String, dynamic> updates,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final budgets = await getBudgets();
    final index = budgets.indexWhere((b) => b.id == budgetId);
    if (index != -1) {
      final updatedBudget = budgets[index].copyWith(
        name: updates['name'],
        totalAmount: updates['totalAmount'],
        categories: updates['categories'],
        isActive: updates['isActive'],
        updatedAt: DateTime.now(),
      );
      budgets[index] = updatedBudget;
      await prefs.setString(
        _budgetsKey,
        jsonEncode(budgets.map((b) => b.toJson()).toList()),
      );
    }
  }

  static Future<void> deleteBudget(String budgetId) async {
    final prefs = await SharedPreferences.getInstance();
    final budgets = await getBudgets();
    budgets.removeWhere((b) => b.id == budgetId);
    await prefs.setString(
      _budgetsKey,
      jsonEncode(budgets.map((b) => b.toJson()).toList()),
    );
  }

  // Income management
  static Future<void> addIncome(Map<String, dynamic> income) async {
    final prefs = await SharedPreferences.getInstance();
    final incomes = await getIncomes();
    incomes.add(income);
    await prefs.setString(_incomesKey, jsonEncode(incomes));
  }

  static Future<List<Map<String, dynamic>>> getIncomes() async {
    final prefs = await SharedPreferences.getInstance();
    final incomesJson = prefs.getString(_incomesKey);
    if (incomesJson != null) {
      final List<dynamic> incomesList = jsonDecode(incomesJson);
      return incomesList.map((i) => Map<String, dynamic>.from(i)).toList();
    }
    return [];
  }

  static Future<void> updateIncome(
    String incomeId,
    Map<String, dynamic> updates,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final incomes = await getIncomes();
    final index = incomes.indexWhere((i) => i['id'] == incomeId);
    if (index != -1) {
      incomes[index].addAll(updates);
      incomes[index]['updatedAt'] = DateTime.now().toIso8601String();
      await prefs.setString(_incomesKey, jsonEncode(incomes));
    }
  }

  static Future<void> deleteIncome(String incomeId) async {
    final prefs = await SharedPreferences.getInstance();
    final incomes = await getIncomes();
    incomes.removeWhere((i) => i['id'] == incomeId);
    await prefs.setString(_incomesKey, jsonEncode(incomes));
  }

  // Savings Goals management
  static Future<void> addSavingsGoal(Map<String, dynamic> goal) async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await getSavingsGoals();
    goals.add(goal);
    await prefs.setString(_savingsGoalsKey, jsonEncode(goals));
  }

  static Future<List<Map<String, dynamic>>> getSavingsGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getString(_savingsGoalsKey);
    if (goalsJson != null) {
      final List<dynamic> goalsList = jsonDecode(goalsJson);
      return goalsList.map((g) => Map<String, dynamic>.from(g)).toList();
    }
    return [];
  }

  static Future<void> updateSavingsGoal(
    String goalId,
    Map<String, dynamic> updates,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await getSavingsGoals();
    final index = goals.indexWhere((g) => g['id'] == goalId);
    if (index != -1) {
      goals[index].addAll(updates);
      goals[index]['updatedAt'] = DateTime.now().toIso8601String();
      await prefs.setString(_savingsGoalsKey, jsonEncode(goals));
    }
  }

  static Future<void> deleteSavingsGoal(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await getSavingsGoals();
    goals.removeWhere((g) => g['id'] == goalId);
    await prefs.setString(_savingsGoalsKey, jsonEncode(goals));
  }

  // AI-powered savings methods
  static Future<List<Map<String, dynamic>>> getSavingsPredictions() async {
    final prefs = await SharedPreferences.getInstance();
    final predictionsJson = prefs.getString(_savingsPredictionsKey);
    if (predictionsJson != null) {
      final List<dynamic> predictionsList = jsonDecode(predictionsJson);
      return predictionsList.map((p) => Map<String, dynamic>.from(p)).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getSavingsSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    final suggestionsJson = prefs.getString(_savingsSuggestionsKey);
    if (suggestionsJson != null) {
      final List<dynamic> suggestionsList = jsonDecode(suggestionsJson);
      return suggestionsList.map((s) => Map<String, dynamic>.from(s)).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getBehavioralInsights() async {
    final prefs = await SharedPreferences.getInstance();
    final insightsJson = prefs.getString(_behavioralInsightsKey);
    if (insightsJson != null) {
      final List<dynamic> insightsList = jsonDecode(insightsJson);
      return insightsList.map((i) => Map<String, dynamic>.from(i)).toList();
    }
    return [];
  }
}
