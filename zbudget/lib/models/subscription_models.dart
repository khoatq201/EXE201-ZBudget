/// Subscription Models for Premium/Free tier management
library;

import 'package:flutter/foundation.dart';

/// Subscription tiers
enum SubscriptionTier {
  free,
  premium;

  String get value {
    switch (this) {
      case SubscriptionTier.free:
        return 'free';
      case SubscriptionTier.premium:
        return 'premium';
    }
  }

  static SubscriptionTier fromString(String value) {
    switch (value.toLowerCase()) {
      case 'premium':
        return SubscriptionTier.premium;
      case 'free':
      default:
        return SubscriptionTier.free;
    }
  }
}

/// Subscription status
enum SubscriptionStatus {
  active,
  inactive,
  expired,
  trial;

  String get value {
    switch (this) {
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.inactive:
        return 'inactive';
      case SubscriptionStatus.expired:
        return 'expired';
      case SubscriptionStatus.trial:
        return 'trial';
    }
  }

  static SubscriptionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'trial':
        return SubscriptionStatus.trial;
      case 'inactive':
      default:
        return SubscriptionStatus.inactive;
    }
  }
}

/// Subscription model
class Subscription {
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final SubscriptionPrice? price;
  final SubscriptionFeatures features;
  final bool autoRenew;
  final String paymentMethod;
  final DateTime? lastUpdated;

  Subscription({
    required this.tier,
    required this.status,
    this.startDate,
    this.expiryDate,
    this.price,
    required this.features,
    this.autoRenew = false,
    this.paymentMethod = 'manual',
    this.lastUpdated,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      tier: SubscriptionTier.fromString(json['tier'] ?? 'free'),
      status: SubscriptionStatus.fromString(json['status'] ?? 'inactive'),
      startDate: json['startDate'] != null
          ? _parseDate(json['startDate'])
          : null,
      expiryDate: json['expiryDate'] != null
          ? _parseDate(json['expiryDate'])
          : null,
      price: json['price'] != null
          ? SubscriptionPrice.fromJson(json['price'])
          : null,
      features: json['features'] != null
          ? SubscriptionFeatures.fromJson(json['features'])
          : SubscriptionFeatures(
              maxBudgets: 2,
              maxSavingsGoals: 2,
              ocrScansPerDay: 10,
              aiAnalysisEnabled: false,
            ),
      autoRenew: json['autoRenew'] ?? false,
      paymentMethod: json['paymentMethod'] ?? 'manual',
      lastUpdated: json['lastUpdated'] != null
          ? _parseDate(json['lastUpdated'])
          : null,
    );
  }

  /// Parse date from various formats (ISO string or MongoDB date object)
  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is Map && dateValue.containsKey('\$date')) {
        return DateTime.parse(dateValue['\$date']);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to parse date: $dateValue');
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier.value,
      'status': status.value,
      'startDate': startDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'price': price?.toJson(),
      'features': features.toJson(),
      'autoRenew': autoRenew,
      'paymentMethod': paymentMethod,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Check if subscription is premium and active
  bool get isPremium =>
      tier == SubscriptionTier.premium &&
      status == SubscriptionStatus.active &&
      (expiryDate == null || expiryDate!.isAfter(DateTime.now()));

  /// Get days remaining until expiry
  int? get daysRemaining {
    if (expiryDate == null) return null;
    final diff = expiryDate!.difference(DateTime.now());
    return diff.inDays > 0 ? diff.inDays : 0;
  }

  /// Get display name for tier
  String get tierDisplayName =>
      tier == SubscriptionTier.premium ? 'Premium' : 'Miễn phí';

  /// Get display name for status
  String get statusDisplayName {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Đang hoạt động';
      case SubscriptionStatus.inactive:
        return 'Chưa kích hoạt';
      case SubscriptionStatus.expired:
        return 'Đã hết hạn';
      case SubscriptionStatus.trial:
        return 'Dùng thử';
    }
  }
}

/// Subscription price information
class SubscriptionPrice {
  final double amount;
  final String currency;
  final String duration; // 'monthly' or 'yearly'

  SubscriptionPrice({
    required this.amount,
    this.currency = 'VND',
    required this.duration,
  });

  factory SubscriptionPrice.fromJson(Map<String, dynamic> json) {
    return SubscriptionPrice(
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'VND',
      duration: json['duration'] ?? 'monthly',
    );
  }

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'currency': currency, 'duration': duration};
  }

  /// Format price for display
  String get formattedPrice {
    if (currency == 'VND') {
      return '${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
    }
    return '$amount $currency';
  }

  /// Get duration display name
  String get durationDisplayName {
    switch (duration) {
      case 'monthly':
        return 'tháng';
      case 'yearly':
        return 'năm';
      default:
        return duration;
    }
  }
}

/// Feature limits for subscription tiers
class SubscriptionFeatures {
  final int maxBudgets;
  final int maxSavingsGoals;
  final int ocrScansPerDay;
  final bool aiAnalysisEnabled;

  SubscriptionFeatures({
    required this.maxBudgets,
    required this.maxSavingsGoals,
    required this.ocrScansPerDay,
    required this.aiAnalysisEnabled,
  });

  factory SubscriptionFeatures.fromJson(Map<String, dynamic> json) {
    debugPrint('🔧 Parsing SubscriptionFeatures from: $json');
    final features = SubscriptionFeatures(
      maxBudgets: json['maxBudgets'] ?? 2,
      maxSavingsGoals: json['maxSavingsGoals'] ?? 2,
      ocrScansPerDay: json['ocrScansPerDay'] ?? 10,
      aiAnalysisEnabled: json['aiAnalysisEnabled'] ?? false,
    );
    debugPrint(
      '✅ Features parsed: maxBudgets=${features.maxBudgets}, aiEnabled=${features.aiAnalysisEnabled}',
    );
    return features;
  }

  Map<String, dynamic> toJson() {
    return {
      'maxBudgets': maxBudgets,
      'maxSavingsGoals': maxSavingsGoals,
      'ocrScansPerDay': ocrScansPerDay,
      'aiAnalysisEnabled': aiAnalysisEnabled,
    };
  }

  /// Check if OCR is unlimited
  bool get isOCRUnlimited => ocrScansPerDay == -1;

  /// Get OCR limit display text
  String get ocrLimitDisplay =>
      isOCRUnlimited ? 'Không giới hạn' : '$ocrScansPerDay lượt/ngày';
}

/// Usage statistics
class UsageStats {
  final SubscriptionTier tier;
  final bool isPremium;
  final OCRUsage ocr;
  final AIUsage aiAnalysis;
  final Map<String, int> limits;
  final ResetTime resetTime;

  UsageStats({
    required this.tier,
    required this.isPremium,
    required this.ocr,
    required this.aiAnalysis,
    required this.limits,
    required this.resetTime,
  });

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    final usage = json['usage'] as Map<String, dynamic>? ?? {};
    final limitsJson = json['limits'] as Map<String, dynamic>? ?? {};

    // Parse limits, handling both int and bool values
    final limits = <String, int>{};
    limitsJson.forEach((key, value) {
      if (value is int) {
        limits[key] = value;
      } else if (value is bool) {
        limits[key] = value ? 1 : 0; // Convert bool to int
      } else if (value != null) {
        limits[key] = int.tryParse(value.toString()) ?? 0;
      }
    });

    return UsageStats(
      tier: SubscriptionTier.fromString(json['tier'] ?? 'free'),
      isPremium: json['isPremium'] ?? false,
      ocr: OCRUsage.fromJson(usage['ocr'] ?? {}),
      aiAnalysis: AIUsage.fromJson(usage['aiAnalysis'] ?? {}),
      limits: limits,
      resetTime: ResetTime.fromJson(json['resetTime'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier.value,
      'isPremium': isPremium,
      'usage': {'ocr': ocr.toJson(), 'aiAnalysis': aiAnalysis.toJson()},
      'limits': limits,
      'resetTime': resetTime.toJson(),
    };
  }
}

/// OCR usage information
class OCRUsage {
  final int count;
  final int limit;
  final int remaining;
  final DateTime? lastUsedAt;
  final double? percentage;

  OCRUsage({
    required this.count,
    required this.limit,
    required this.remaining,
    this.lastUsedAt,
    this.percentage,
  });

  factory OCRUsage.fromJson(Map<String, dynamic> json) {
    return OCRUsage(
      count: json['count'] ?? 0,
      limit: json['limit'] ?? 10,
      remaining: json['remaining'] ?? 10,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'])
          : null,
      percentage: json['percentage']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'limit': limit,
      'remaining': remaining,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'percentage': percentage,
    };
  }

  /// Check if quota is exceeded
  bool get isExceeded => limit != -1 && count >= limit;

  /// Check if running low (>80%)
  bool get isRunningLow {
    if (limit == -1) return false;
    return (count / limit) > 0.8;
  }

  /// Get progress percentage (0-100)
  double get progress {
    if (limit == -1) return 0;
    return (count / limit * 100).clamp(0, 100);
  }
}

/// AI usage information
class AIUsage {
  final int count;
  final bool enabled;
  final DateTime? lastUsedAt;

  AIUsage({required this.count, required this.enabled, this.lastUsedAt});

  factory AIUsage.fromJson(Map<String, dynamic> json) {
    return AIUsage(
      count: json['count'] ?? 0,
      enabled: json['enabled'] ?? false,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'enabled': enabled,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }
}

/// Reset time information
class ResetTime {
  final String nextReset;
  final String timezone;
  final String description;
  final Countdown? countdown;

  ResetTime({
    required this.nextReset,
    required this.timezone,
    required this.description,
    this.countdown,
  });

  factory ResetTime.fromJson(Map<String, dynamic> json) {
    return ResetTime(
      nextReset: json['nextReset'] ?? '00:00',
      timezone: json['timezone'] ?? 'Asia/Ho_Chi_Minh',
      description: json['description'] ?? '',
      countdown: json['countdown'] != null
          ? Countdown.fromJson(json['countdown'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nextReset': nextReset,
      'timezone': timezone,
      'description': description,
      'countdown': countdown?.toJson(),
    };
  }
}

/// Countdown information
class Countdown {
  final int hours;
  final int minutes;
  final String formatted;
  final String timestamp;

  Countdown({
    required this.hours,
    required this.minutes,
    required this.formatted,
    required this.timestamp,
  });

  factory Countdown.fromJson(Map<String, dynamic> json) {
    return Countdown(
      hours: json['hours'] ?? 0,
      minutes: json['minutes'] ?? 0,
      formatted: json['formatted'] ?? '0h 0m',
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hours': hours,
      'minutes': minutes,
      'formatted': formatted,
      'timestamp': timestamp,
    };
  }
}

/// Pricing plan information
class PricingPlan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final int duration;
  final String durationLabel;
  final double pricePerMonth;
  final SubscriptionFeatures features;
  final double? savings;
  final String? savingsLabel;
  final bool? recommended;

  PricingPlan({
    required this.id,
    required this.name,
    required this.price,
    this.currency = 'VND',
    required this.duration,
    required this.durationLabel,
    required this.pricePerMonth,
    required this.features,
    this.savings,
    this.savingsLabel,
    this.recommended,
  });

  factory PricingPlan.fromJson(Map<String, dynamic> json) {
    return PricingPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'VND',
      duration: json['duration'] ?? 30,
      durationLabel: json['durationLabel'] ?? '',
      pricePerMonth: (json['pricePerMonth'] ?? 0).toDouble(),
      features: SubscriptionFeatures.fromJson(json['features'] ?? {}),
      savings: json['savings']?.toDouble(),
      savingsLabel: json['savingsLabel'],
      recommended: json['recommended'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'currency': currency,
      'duration': duration,
      'durationLabel': durationLabel,
      'pricePerMonth': pricePerMonth,
      'features': features.toJson(),
      'savings': savings,
      'savingsLabel': savingsLabel,
      'recommended': recommended,
    };
  }

  /// Format price for display
  String get formattedPrice {
    if (currency == 'VND') {
      return '${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
    }
    return '$price $currency';
  }

  /// Format price per month
  String get formattedPricePerMonth {
    if (currency == 'VND') {
      return '${pricePerMonth.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ/tháng';
    }
    return '$pricePerMonth $currency/month';
  }
}

/// Pricing information response
class PricingInfo {
  final List<PricingPlan> plans;
  final FreeTierInfo freeTier;

  PricingInfo({required this.plans, required this.freeTier});

  factory PricingInfo.fromJson(Map<String, dynamic> json) {
    return PricingInfo(
      plans:
          (json['plans'] as List<dynamic>?)
              ?.map((e) => PricingPlan.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      freeTier: FreeTierInfo.fromJson(json['freeTier'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plans': plans.map((e) => e.toJson()).toList(),
      'freeTier': freeTier.toJson(),
    };
  }

  /// Get monthly plan
  PricingPlan? get monthlyPlan {
    try {
      return plans.firstWhere((p) => p.id == 'monthly');
    } catch (e) {
      return plans.isNotEmpty ? plans.first : null;
    }
  }

  /// Get yearly plan
  PricingPlan? get yearlyPlan {
    try {
      return plans.firstWhere((p) => p.id == 'yearly');
    } catch (e) {
      return plans.length > 1 ? plans.last : null;
    }
  }
}

/// Free tier information
class FreeTierInfo {
  final String name;
  final double price;
  final String currency;
  final SubscriptionFeatures features;

  FreeTierInfo({
    required this.name,
    this.price = 0,
    this.currency = 'VND',
    required this.features,
  });

  factory FreeTierInfo.fromJson(Map<String, dynamic> json) {
    return FreeTierInfo(
      name: json['name'] ?? 'Miễn phí',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'VND',
      features: SubscriptionFeatures.fromJson(json['features'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'currency': currency,
      'features': features.toJson(),
    };
  }
}

/// Subscription status response
class SubscriptionStatusResponse {
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final bool isPremium;
  final DateTime? expiryDate;
  final int? daysRemaining;
  final SubscriptionFeatures features;

  SubscriptionStatusResponse({
    required this.tier,
    required this.status,
    required this.isPremium,
    this.expiryDate,
    this.daysRemaining,
    required this.features,
  });

  factory SubscriptionStatusResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusResponse(
      tier: SubscriptionTier.fromString(json['tier'] ?? 'free'),
      status: SubscriptionStatus.fromString(json['status'] ?? 'inactive'),
      isPremium: json['isPremium'] ?? false,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      daysRemaining: json['daysRemaining'],
      features: SubscriptionFeatures.fromJson(json['features'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier.value,
      'status': status.value,
      'isPremium': isPremium,
      'expiryDate': expiryDate?.toIso8601String(),
      'daysRemaining': daysRemaining,
      'features': features.toJson(),
    };
  }
}

/// Subscription history item
class SubscriptionHistory {
  final String action;
  final DateTime date;
  final String? previousTier;
  final String? newTier;
  final String? duration;
  final int? amount;
  final String? notes;

  SubscriptionHistory({
    required this.action,
    required this.date,
    this.previousTier,
    this.newTier,
    this.duration,
    this.amount,
    this.notes,
  });

  factory SubscriptionHistory.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistory(
      action: json['action'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      previousTier: json['previousTier'],
      newTier: json['newTier'],
      duration: json['duration'],
      amount: json['amount'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'date': date.toIso8601String(),
      'previousTier': previousTier,
      'newTier': newTier,
      'duration': duration,
      'amount': amount,
      'notes': notes,
    };
  }
}

/// API Response wrapper
class SubscriptionApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final bool? upgradeRequired;
  final bool? quotaExceeded;
  final int? currentUsage;
  final int? limit;

  SubscriptionApiResponse({
    required this.success,
    this.data,
    this.message,
    this.upgradeRequired,
    this.quotaExceeded,
    this.currentUsage,
    this.limit,
  });

  factory SubscriptionApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return SubscriptionApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      message: json['message'],
      upgradeRequired: json['upgradeRequired'],
      quotaExceeded: json['quotaExceeded'],
      currentUsage: json['currentUsage'],
      limit: json['limit'],
    );
  }

  Map<String, dynamic> toJson(dynamic Function(T)? toJsonT) {
    return {
      'success': success,
      'data': data != null && toJsonT != null ? toJsonT(data as T) : data,
      'message': message,
      'upgradeRequired': upgradeRequired,
      'quotaExceeded': quotaExceeded,
      'currentUsage': currentUsage,
      'limit': limit,
    };
  }
}
