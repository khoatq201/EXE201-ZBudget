import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/user.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

enum AppTheme { light, dark, system }

class AppProvider extends ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;
  bool _isFirstLaunch = true;
  AppTheme _theme = AppTheme.system;
  bool _isLoading = true;

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isFirstLaunch => _isFirstLaunch;
  AppTheme get theme => _theme;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode {
    switch (_theme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }

  AppProvider() {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      _setLoading(true);

      // Check if it's first launch
      final prefs = await SharedPreferences.getInstance();
      final hasLaunched = prefs.getBool('hasLaunched') ?? false;
      _isFirstLaunch = !hasLaunched;

      // Load theme preference
      final savedTheme = prefs.getString('theme');
      if (savedTheme != null) {
        _theme = AppTheme.values.firstWhere(
          (e) => e.toString().split('.').last == savedTheme,
          orElse: () => AppTheme.system,
        );
      }
    } catch (error) {
      debugPrint('Error initializing app: $error');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> login(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userToken', 'dummy-token');
      await prefs.setString('userData', jsonEncode(user.toJson()));

      _user = user;
      _isAuthenticated = true;
      notifyListeners();
    } catch (error) {
      debugPrint('Login failed: $error');
      rethrow;
    }
  }

  Future<void> logout(BuildContext context) async {
    debugPrint('🎯 AppProvider.logout() called');

    try {
      _setLoading(true);

      // Use the provided AuthService instance from Provider (has tokens!)
      final authService = Provider.of<AuthService>(context, listen: false);
      debugPrint('🔧 Calling AuthService.forceLogoutWithNavigation()...');

      final result = await authService.forceLogoutWithNavigation();
      debugPrint('🔧 AuthService.forceLogoutWithNavigation() result: $result');

      if (result['success']) {
        debugPrint('✅ AuthService logout successful');

        // Clear AppProvider state immediately
        _user = null;
        _isAuthenticated = false;

        // Force immediate UI update
        notifyListeners();
        debugPrint(
          '✅ AppProvider logout completed, isAuthenticated: $_isAuthenticated',
        );
      } else {
        throw Exception(result['message']);
      }
    } catch (error) {
      debugPrint('❌ Logout failed: $error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasLaunched', true);
      _isFirstLaunch = false;
      notifyListeners();
    } catch (error) {
      debugPrint('Error completing onboarding: $error');
      rethrow;
    }
  }

  Future<void> updateTheme(AppTheme theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme', theme.toString().split('.').last);
      _theme = theme;
      notifyListeners();
    } catch (error) {
      debugPrint('Error updating theme: $error');
      rethrow;
    }
  }

  // Data management methods
  Future<void> addExpense(Expense expense) async {
    try {
      await StorageService.addExpense(expense);
    } catch (error) {
      debugPrint('Error adding expense: $error');
      rethrow;
    }
  }

  Future<List<Expense>> getExpenses() async {
    try {
      return await StorageService.getExpenses();
    } catch (error) {
      debugPrint('Error getting expenses: $error');
      return [];
    }
  }

  Future<void> updateExpense(
    String expenseId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await StorageService.updateExpense(expenseId, updates);
    } catch (error) {
      debugPrint('Error updating expense: $error');
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await StorageService.deleteExpense(expenseId);
    } catch (error) {
      debugPrint('Error deleting expense: $error');
      rethrow;
    }
  }

  Future<void> addBudget(Budget budget) async {
    try {
      await StorageService.addBudget(budget);
    } catch (error) {
      debugPrint('Error adding budget: $error');
      rethrow;
    }
  }

  Future<List<Budget>> getBudgets() async {
    try {
      return await StorageService.getBudgets();
    } catch (error) {
      debugPrint('Error getting budgets: $error');
      return [];
    }
  }

  Future<void> updateBudget(
    String budgetId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await StorageService.updateBudget(budgetId, updates);
    } catch (error) {
      debugPrint('Error updating budget: $error');
      rethrow;
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      await StorageService.deleteBudget(budgetId);
    } catch (error) {
      debugPrint('Error deleting budget: $error');
      rethrow;
    }
  }
}
