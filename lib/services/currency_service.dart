import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/settings/currency_settings.dart';

/// Service for managing currency settings and exchange rates
/// Handles currency selection, formatting, exchange rates, and multi-currency features
class CurrencyService extends ChangeNotifier {
  static const String _settingsKey = 'currency_settings';
  static const String _favoritesKey = 'favorite_currencies';

  CurrencySettings _settings = const CurrencySettings();
  List<Currency> _favoriteCurrencies = [];
  bool _isLoading = false;
  bool _isUpdatingRates = false;
  String? _errorMessage;

  // Getters
  CurrencySettings get settings => _settings;
  List<Currency> get favoriteCurrencies => _favoriteCurrencies;
  bool get isLoading => _isLoading;
  bool get isUpdatingRates => _isUpdatingRates;
  String? get errorMessage => _errorMessage;

  /// Initialize the service
  Future<void> initialize() async {
    _isLoading = true;
    // Defer notifyListeners to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      await _loadSettings();
      await _loadFavorites();

      // Check if exchange rates need updating
      if (_settings.needsRateUpdate && _settings.autoUpdateRates) {
        await updateExchangeRates();
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize currency service: $e';
      if (kDebugMode) {
        print('CurrencyService initialization error: $e');
      }
    } finally {
      _isLoading = false;
      // Defer notifyListeners to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        _settings = CurrencySettings.fromJson(settingsMap);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading currency settings: $e');
      }
    }
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(_settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      _errorMessage = 'Failed to save currency settings: $e';
      if (kDebugMode) {
        print('Error saving currency settings: $e');
      }
    }
  }

  /// Load favorite currencies
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = prefs.getStringList(_favoritesKey) ?? [];
      _favoriteCurrencies = favoritesList
          .map((code) => Currency.fromCode(code))
          .where((currency) => currency != null)
          .cast<Currency>()
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading favorite currencies: $e');
      }
    }
  }

  /// Save favorite currencies
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = _favoriteCurrencies.map((c) => c.code).toList();
      await prefs.setStringList(_favoritesKey, favoritesList);
    } catch (e) {
      _errorMessage = 'Failed to save favorite currencies: $e';
      if (kDebugMode) {
        print('Error saving favorite currencies: $e');
      }
    }
  }

  /// Update primary currency
  Future<void> updatePrimaryCurrency(Currency currency) async {
    if (_settings.primaryCurrency == currency) return;

    _settings = _settings.copyWith(primaryCurrency: currency);
    await _saveSettings();

    HapticFeedback.selectionClick();
    notifyListeners();

    // Update exchange rates if auto-update is enabled
    if (_settings.autoUpdateRates) {
      await updateExchangeRates();
    }
  }

  /// Update secondary currency
  Future<void> updateSecondaryCurrency(Currency? currency) async {
    if (_settings.secondaryCurrency == currency) return;

    _settings = _settings.copyWith(
      secondaryCurrency: currency,
      clearSecondaryCurrency: currency == null,
    );
    await _saveSettings();

    HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Update display format
  Future<void> updateDisplayFormat(CurrencyDisplayFormat format) async {
    if (_settings.displayFormat == format) return;

    _settings = _settings.copyWith(displayFormat: format);
    await _saveSettings();

    HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Update number separator
  Future<void> updateNumberSeparator(NumberSeparator separator) async {
    if (_settings.numberSeparator == separator) return;

    _settings = _settings.copyWith(numberSeparator: separator);
    await _saveSettings();

    HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Update rounding mode
  Future<void> updateRoundingMode(RoundingMode mode) async {
    if (_settings.roundingMode == mode) return;

    _settings = _settings.copyWith(roundingMode: mode);
    await _saveSettings();

    HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Toggle exchange rate display
  Future<void> toggleExchangeRateDisplay(bool show) async {
    if (_settings.showExchangeRate == show) return;

    _settings = _settings.copyWith(showExchangeRate: show);
    await _saveSettings();

    HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Toggle auto-update rates
  Future<void> toggleAutoUpdateRates(bool autoUpdate) async {
    if (_settings.autoUpdateRates == autoUpdate) return;

    _settings = _settings.copyWith(autoUpdateRates: autoUpdate);
    await _saveSettings();

    HapticFeedback.selectionClick();
    notifyListeners();

    // Update rates immediately if enabled
    if (autoUpdate && _settings.needsRateUpdate) {
      await updateExchangeRates();
    }
  }

  /// Toggle currency converter
  Future<void> toggleCurrencyConverter(bool show) async {
    if (_settings.showCurrencyConverter == show) return;

    _settings = _settings.copyWith(showCurrencyConverter: show);
    await _saveSettings();

    HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Toggle multi-currency support
  Future<void> toggleMultiCurrency(bool enable) async {
    if (_settings.enableMultiCurrency == enable) return;

    _settings = _settings.copyWith(enableMultiCurrency: enable);
    await _saveSettings();

    HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Add currency to favorites
  Future<void> addToFavorites(Currency currency) async {
    if (_favoriteCurrencies.contains(currency)) return;

    _favoriteCurrencies.add(currency);
    await _saveFavorites();

    HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Remove currency from favorites
  Future<void> removeFromFavorites(Currency currency) async {
    if (!_favoriteCurrencies.contains(currency)) return;

    _favoriteCurrencies.remove(currency);
    await _saveFavorites();

    HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(Currency currency) async {
    if (_favoriteCurrencies.contains(currency)) {
      await removeFromFavorites(currency);
    } else {
      await addToFavorites(currency);
    }
  }

  /// Update exchange rates (mock implementation)
  Future<void> updateExchangeRates() async {
    if (_isUpdatingRates) return;

    _isUpdatingRates = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Mock exchange rates (in real app, fetch from API)
      await Future.delayed(const Duration(seconds: 2));

      final newRates = <String, double>{};
      final random = Random();

      // Generate mock exchange rates relative to primary currency
      for (final currency in Currency.values) {
        if (currency != _settings.primaryCurrency) {
          // Generate realistic exchange rates with some variation
          double baseRate = _getMockExchangeRate(
            _settings.primaryCurrency,
            currency,
          );
          double variation =
              (random.nextDouble() - 0.5) * 0.02; // ±1% variation
          newRates[currency.code] = baseRate * (1 + variation);
        }
      }

      _settings = _settings.copyWith(
        exchangeRates: newRates,
        lastRateUpdate: DateTime.now(),
      );

      await _saveSettings();

      HapticFeedback.lightImpact();
    } catch (e) {
      _errorMessage = 'Failed to update exchange rates: $e';
      if (kDebugMode) {
        print('Error updating exchange rates: $e');
      }
    } finally {
      _isUpdatingRates = false;
      notifyListeners();
    }
  }

  /// Get mock exchange rate between currencies
  double _getMockExchangeRate(Currency from, Currency to) {
    // Mock exchange rates (simplified)
    const baseRates = {
      'VND': 1.0,
      'USD': 24000.0,
      'EUR': 26000.0,
      'JPY': 160.0,
      'KRW': 18.0,
      'CNY': 3300.0,
      'GBP': 30000.0,
      'AUD': 16000.0,
      'CAD': 17500.0,
      'CHF': 27000.0,
      'SGD': 18000.0,
      'HKD': 3000.0,
      'NZD': 14500.0,
      'SEK': 2300.0,
      'NOK': 2200.0,
      'DKK': 3500.0,
      'INR': 290.0,
      'THB': 670.0,
      'MYR': 5200.0,
      'PHP': 430.0,
    };

    final fromRate = baseRates[from.code] ?? 1.0;
    final toRate = baseRates[to.code] ?? 1.0;

    return toRate / fromRate;
  }

  /// Format amount using current settings
  String formatAmount(double amount, {Currency? currency}) {
    final targetCurrency = currency ?? _settings.primaryCurrency;

    if (targetCurrency != _settings.primaryCurrency) {
      // Convert amount if different currency
      amount = _settings.convertAmount(amount, targetCurrency);
    }

    return _settings.formatAmount(amount);
  }

  /// Get formatted exchange rate
  String getFormattedExchangeRate(Currency from, Currency to) {
    final rate = _settings.getExchangeRate(to);
    return '1 ${from.code} = ${rate.toStringAsFixed(4)} ${to.code}';
  }

  /// Search currencies
  List<Currency> searchCurrencies(String query) {
    if (query.isEmpty) return Currency.values;

    final lowercaseQuery = query.toLowerCase();
    return Currency.values.where((currency) {
      return currency.code.toLowerCase().contains(lowercaseQuery) ||
          currency.name.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get popular currencies
  List<Currency> get popularCurrencies {
    final popular = <Currency>[
      Currency.usd,
      Currency.eur,
      Currency.vnd,
    ];

    // Add favorites if not already included
    for (final favorite in _favoriteCurrencies) {
      if (!popular.contains(favorite)) {
        popular.add(favorite);
      }
    }

    return popular;
  }

  /// Get recent currencies (mock)
  List<Currency> get recentCurrencies {
    // In real app, track recently used currencies
    return [
      _settings.primaryCurrency,
      if (_settings.secondaryCurrency != null) _settings.secondaryCurrency!,
      ...Currency.majorCurrencies.take(3),
    ].toSet().toList();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get currency statistics
  Map<String, dynamic> getCurrencyStats() {
    return {
      'totalCurrencies': Currency.values.length,
      'favoritesCount': _favoriteCurrencies.length,
      'lastUpdate': _settings.lastRateUpdate,
      'autoUpdate': _settings.autoUpdateRates,
      'multiCurrency': _settings.enableMultiCurrency,
      'converter': _settings.showCurrencyConverter,
    };
  }

  /// Get example amounts for preview
  List<double> get previewAmounts => [
    12.50,
    123.45,
    1234.56,
    12345.67,
    123456.78,
  ];

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    _settings = const CurrencySettings();
    _favoriteCurrencies = [];

    await _saveSettings();
    await _saveFavorites();

    HapticFeedback.heavyImpact();
    notifyListeners();
  }
}
