/// Enums and models for currency-related settings
/// Provides comprehensive currency management with exchange rates, formatting options,
/// and display preferences for the budget tracking application

enum Currency {
  vnd('VND', 'đ', 'Vietnamese Dong', '🇻🇳', 'vi'),
  usd('USD', '\$', 'US Dollar', '🇺🇸', 'en'),
  eur('EUR', '€', 'Euro', '🇪🇺', 'en'),
  jpy('JPY', '¥', 'Japanese Yen', '🇯🇵', 'ja'),
  krw('KRW', '₩', 'South Korean Won', '🇰🇷', 'ko'),
  cny('CNY', '¥', 'Chinese Yuan', '🇨🇳', 'zh'),
  gbp('GBP', '£', 'British Pound', '🇬🇧', 'en'),
  aud('AUD', 'A\$', 'Australian Dollar', '🇦🇺', 'en'),
  cad('CAD', 'C\$', 'Canadian Dollar', '🇨🇦', 'en'),
  chf('CHF', 'CHF', 'Swiss Franc', '🇨🇭', 'de'),
  sgd('SGD', 'S\$', 'Singapore Dollar', '🇸🇬', 'en'),
  hkd('HKD', 'HK\$', 'Hong Kong Dollar', '🇭🇰', 'en'),
  nzd('NZD', 'NZ\$', 'New Zealand Dollar', '🇳🇿', 'en'),
  sek('SEK', 'kr', 'Swedish Krona', '🇸🇪', 'sv'),
  nok('NOK', 'kr', 'Norwegian Krone', '🇳🇴', 'no'),
  dkk('DKK', 'kr', 'Danish Krone', '🇩🇰', 'da'),
  inr('INR', '₹', 'Indian Rupee', '🇮🇳', 'hi'),
  thb('THB', '฿', 'Thai Baht', '🇹🇭', 'th'),
  myr('MYR', 'RM', 'Malaysian Ringgit', '🇲🇾', 'ms'),
  php('PHP', '₱', 'Philippine Peso', '🇵🇭', 'fil');

  const Currency(this.code, this.symbol, this.name, this.flag, this.locale);

  final String code;
  final String symbol;
  final String name;
  final String flag;
  final String locale;

  /// Get currency by code
  static Currency? fromCode(String code) {
    try {
      return Currency.values.firstWhere((c) => c.code == code.toUpperCase());
    } catch (e) {
      return null;
    }
  }

  /// Get major currencies (most commonly used)
  static List<Currency> get majorCurrencies => [
    Currency.usd,
    Currency.eur,
    Currency.jpy,
    Currency.gbp,
    Currency.aud,
    Currency.cad,
    Currency.chf,
  ];

  /// Get Asian currencies
  static List<Currency> get asianCurrencies => [
    Currency.vnd,
    Currency.jpy,
    Currency.krw,
    Currency.cny,
    Currency.sgd,
    Currency.hkd,
    Currency.inr,
    Currency.thb,
    Currency.myr,
    Currency.php,
  ];

  /// Get European currencies
  static List<Currency> get europeanCurrencies => [
    Currency.eur,
    Currency.gbp,
    Currency.chf,
    Currency.sek,
    Currency.nok,
    Currency.dkk,
  ];

  /// Get all currencies grouped by region
  static Map<String, List<Currency>> get currenciesByRegion => {
    'Major': majorCurrencies,
    'Asian': asianCurrencies,
    'European': europeanCurrencies,
    'Others': [Currency.nzd],
  };
}

enum CurrencyDisplayFormat {
  symbolBefore('\$1,234.56', 'Symbol Before'),
  symbolAfter('1,234.56 \$', 'Symbol After'),
  codeOnly('1,234.56 USD', 'Code Only'),
  codeBefore('USD 1,234.56', 'Code Before'),
  local('Depends on currency', 'Local Format');

  const CurrencyDisplayFormat(this.example, this.description);

  final String example;
  final String description;
}

enum NumberSeparator {
  comma('1,234.56', ',', '.'),
  period('1.234,56', '.', ','),
  space('1 234,56', ' ', ','),
  apostrophe('1\'234.56', '\'', '.');

  const NumberSeparator(this.example, this.thousands, this.decimal);

  final String example;
  final String thousands;
  final String decimal;
}

enum RoundingMode {
  none('No rounding', 'Show exact amounts'),
  cents('Round to cents', '1,234.56'),
  nearestUnit('Round to nearest unit', '1,235'),
  smart('Smart rounding', 'Round based on amount size');

  const RoundingMode(this.title, this.description);

  final String title;
  final String description;
}

/// Settings class for currency configuration
class CurrencySettings {
  final Currency primaryCurrency;
  final Currency? secondaryCurrency;
  final CurrencyDisplayFormat displayFormat;
  final NumberSeparator numberSeparator;
  final RoundingMode roundingMode;
  final bool showExchangeRate;
  final bool autoUpdateRates;
  final Map<String, double> exchangeRates;
  final DateTime? lastRateUpdate;
  final bool showCurrencyConverter;
  final bool enableMultiCurrency;

  const CurrencySettings({
    this.primaryCurrency = Currency.vnd,
    this.secondaryCurrency,
    this.displayFormat = CurrencyDisplayFormat.symbolBefore,
    this.numberSeparator = NumberSeparator.comma,
    this.roundingMode = RoundingMode.cents,
    this.showExchangeRate = true,
    this.autoUpdateRates = true,
    this.exchangeRates = const {},
    this.lastRateUpdate,
    this.showCurrencyConverter = false,
    this.enableMultiCurrency = false,
  });

  /// Create a copy with modified values
  CurrencySettings copyWith({
    Currency? primaryCurrency,
    Currency? secondaryCurrency,
    CurrencyDisplayFormat? displayFormat,
    NumberSeparator? numberSeparator,
    RoundingMode? roundingMode,
    bool? showExchangeRate,
    bool? autoUpdateRates,
    Map<String, double>? exchangeRates,
    DateTime? lastRateUpdate,
    bool? showCurrencyConverter,
    bool? enableMultiCurrency,
    bool clearSecondaryCurrency = false,
  }) {
    return CurrencySettings(
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      secondaryCurrency: clearSecondaryCurrency
          ? null
          : (secondaryCurrency ?? this.secondaryCurrency),
      displayFormat: displayFormat ?? this.displayFormat,
      numberSeparator: numberSeparator ?? this.numberSeparator,
      roundingMode: roundingMode ?? this.roundingMode,
      showExchangeRate: showExchangeRate ?? this.showExchangeRate,
      autoUpdateRates: autoUpdateRates ?? this.autoUpdateRates,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      lastRateUpdate: lastRateUpdate ?? this.lastRateUpdate,
      showCurrencyConverter:
          showCurrencyConverter ?? this.showCurrencyConverter,
      enableMultiCurrency: enableMultiCurrency ?? this.enableMultiCurrency,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'primaryCurrency': primaryCurrency.code,
      'secondaryCurrency': secondaryCurrency?.code,
      'displayFormat': displayFormat.name,
      'numberSeparator': numberSeparator.name,
      'roundingMode': roundingMode.name,
      'showExchangeRate': showExchangeRate,
      'autoUpdateRates': autoUpdateRates,
      'exchangeRates': exchangeRates,
      'lastRateUpdate': lastRateUpdate?.toIso8601String(),
      'showCurrencyConverter': showCurrencyConverter,
      'enableMultiCurrency': enableMultiCurrency,
    };
  }

  /// Create from JSON
  static CurrencySettings fromJson(Map<String, dynamic> json) {
    return CurrencySettings(
      primaryCurrency:
          Currency.fromCode(json['primaryCurrency'] ?? 'VND') ?? Currency.vnd,
      secondaryCurrency: json['secondaryCurrency'] != null
          ? Currency.fromCode(json['secondaryCurrency'])
          : null,
      displayFormat: CurrencyDisplayFormat.values.firstWhere(
        (e) => e.name == json['displayFormat'],
        orElse: () => CurrencyDisplayFormat.symbolBefore,
      ),
      numberSeparator: NumberSeparator.values.firstWhere(
        (e) => e.name == json['numberSeparator'],
        orElse: () => NumberSeparator.comma,
      ),
      roundingMode: RoundingMode.values.firstWhere(
        (e) => e.name == json['roundingMode'],
        orElse: () => RoundingMode.cents,
      ),
      showExchangeRate: json['showExchangeRate'] ?? true,
      autoUpdateRates: json['autoUpdateRates'] ?? true,
      exchangeRates: Map<String, double>.from(json['exchangeRates'] ?? {}),
      lastRateUpdate: json['lastRateUpdate'] != null
          ? DateTime.tryParse(json['lastRateUpdate'])
          : null,
      showCurrencyConverter: json['showCurrencyConverter'] ?? false,
      enableMultiCurrency: json['enableMultiCurrency'] ?? false,
    );
  }

  /// Format amount according to settings
  String formatAmount(double amount) {
    // Apply rounding
    double roundedAmount = amount;
    switch (roundingMode) {
      case RoundingMode.none:
        break;
      case RoundingMode.cents:
        roundedAmount = (amount * 100).round() / 100;
        break;
      case RoundingMode.nearestUnit:
        roundedAmount = amount.round().toDouble();
        break;
      case RoundingMode.smart:
        if (amount > 1000) {
          roundedAmount = amount.round().toDouble();
        } else {
          roundedAmount = (amount * 100).round() / 100;
        }
        break;
    }

    // Format number with separators
    String formattedNumber = _formatNumber(roundedAmount);

    // Apply currency display format
    switch (displayFormat) {
      case CurrencyDisplayFormat.symbolBefore:
        return '${primaryCurrency.symbol}$formattedNumber';
      case CurrencyDisplayFormat.symbolAfter:
        return '$formattedNumber ${primaryCurrency.symbol}';
      case CurrencyDisplayFormat.codeOnly:
        return '$formattedNumber ${primaryCurrency.code}';
      case CurrencyDisplayFormat.codeBefore:
        return '${primaryCurrency.code} $formattedNumber';
      case CurrencyDisplayFormat.local:
        return '${primaryCurrency.symbol}$formattedNumber';
    }
  }

  String _formatNumber(double amount) {
    String integerPart = amount.truncate().toString();
    String decimalPart = '';

    if (roundingMode != RoundingMode.nearestUnit) {
      double fractional = amount - amount.truncate();
      if (fractional > 0) {
        decimalPart = fractional.toStringAsFixed(2).substring(1);
      } else {
        decimalPart = '.00';
      }
    }

    // Add thousands separators
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += numberSeparator.thousands;
      }
      formattedInteger += integerPart[i];
    }

    if (decimalPart.isNotEmpty) {
      decimalPart = decimalPart.replaceFirst('.', numberSeparator.decimal);
      return formattedInteger + decimalPart;
    }

    return formattedInteger;
  }

  /// Get exchange rate to another currency
  double getExchangeRate(Currency toCurrency) {
    if (toCurrency == primaryCurrency) return 1.0;
    return exchangeRates[toCurrency.code] ?? 1.0;
  }

  /// Convert amount to another currency
  double convertAmount(double amount, Currency toCurrency) {
    if (toCurrency == primaryCurrency) return amount;
    return amount * getExchangeRate(toCurrency);
  }

  /// Check if rates need updating
  bool get needsRateUpdate {
    if (!autoUpdateRates) return false;
    if (lastRateUpdate == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastRateUpdate!);
    return difference.inHours >= 24; // Update daily
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CurrencySettings &&
        other.primaryCurrency == primaryCurrency &&
        other.secondaryCurrency == secondaryCurrency &&
        other.displayFormat == displayFormat &&
        other.numberSeparator == numberSeparator &&
        other.roundingMode == roundingMode &&
        other.showExchangeRate == showExchangeRate &&
        other.autoUpdateRates == autoUpdateRates &&
        other.showCurrencyConverter == showCurrencyConverter &&
        other.enableMultiCurrency == enableMultiCurrency;
  }

  @override
  int get hashCode {
    return Object.hash(
      primaryCurrency,
      secondaryCurrency,
      displayFormat,
      numberSeparator,
      roundingMode,
      showExchangeRate,
      autoUpdateRates,
      showCurrencyConverter,
      enableMultiCurrency,
    );
  }

  @override
  String toString() {
    return 'CurrencySettings(primary: $primaryCurrency, format: $displayFormat)';
  }
}
