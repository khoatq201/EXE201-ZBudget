import 'payment_model.dart';

/// Admin-specific models

class AdminPayment {
  final Payment payment;
  final AdminUserInfo? user;

  AdminPayment({
    required this.payment,
    this.user,
  });

  factory AdminPayment.fromJson(Map<String, dynamic> json) {
    return AdminPayment(
      payment: Payment.fromJson(json),
      user: json['userId'] != null && json['userId'] is Map
          ? AdminUserInfo.fromJson(json['userId'])
          : null,
    );
  }
}

class AdminUserInfo {
  final String id;
  final String email;
  final String? name;
  final String tier;
  final String? status;

  AdminUserInfo({
    required this.id,
    required this.email,
    this.name,
    required this.tier,
    this.status,
  });

  factory AdminUserInfo.fromJson(Map<String, dynamic> json) {
    return AdminUserInfo(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['profile']?['name'],
      tier: json['subscription']?['tier'] ?? 'free',
      status: json['subscription']?['status'],
    );
  }

  bool get isPremium => tier == 'premium';
}

class AdminStats {
  final UserStats users;
  final PaymentStats payments;
  final SubscriptionStats? subscriptions;
  final DateTime timestamp;

  AdminStats({
    required this.users,
    required this.payments,
    this.subscriptions,
    required this.timestamp,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      users: UserStats.fromJson(json['users'] ?? {}),
      payments: PaymentStats.fromJson(json['payments'] ?? {}),
      subscriptions: json['subscriptions'] != null
          ? SubscriptionStats.fromJson(json['subscriptions'])
          : null,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class UserStats {
  final int total;
  final int premium;
  final int free;

  UserStats({
    required this.total,
    required this.premium,
    required this.free,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      total: json['total'] ?? 0,
      premium: json['premium'] ?? 0,
      free: json['free'] ?? 0,
    );
  }

  double get premiumPercentage => total > 0 ? (premium / total) * 100 : 0;
}

class PaymentStats {
  final int totalPayments;
  final int pending;
  final int completed;
  final int cancelled;
  final int rejected;
  final int totalRevenue;

  PaymentStats({
    required this.totalPayments,
    required this.pending,
    required this.completed,
    required this.cancelled,
    required this.rejected,
    required this.totalRevenue,
  });

  factory PaymentStats.fromJson(Map<String, dynamic> json) {
    return PaymentStats(
      totalPayments: json['totalPayments'] ?? 0,
      pending: json['pending'] ?? 0,
      completed: json['completed'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
      rejected: json['rejected'] ?? 0,
      totalRevenue: json['totalRevenue'] ?? 0,
    );
  }

  String get formattedRevenue {
    return '${totalRevenue.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} VND';
  }
}

class SubscriptionStats {
  final int totalUsers;
  final int freeUsers;
  final int premiumUsers;
  final double conversionRate;

  SubscriptionStats({
    required this.totalUsers,
    required this.freeUsers,
    required this.premiumUsers,
    required this.conversionRate,
  });

  factory SubscriptionStats.fromJson(Map<String, dynamic> json) {
    return SubscriptionStats(
      totalUsers: json['totalUsers'] ?? 0,
      freeUsers: json['freeUsers'] ?? 0,
      premiumUsers: json['premiumUsers'] ?? 0,
      conversionRate: (json['conversionRate'] ?? 0).toDouble(),
    );
  }
}

class AdminUser {
  final String id;
  final String email;
  final String? name;
  final String? avatar;
  final String tier;
  final String? subscriptionStatus;
  final DateTime? subscriptionExpiryDate;
  final DateTime createdAt;
  final DateTime? lastLogin;

  AdminUser({
    required this.id,
    required this.email,
    this.name,
    this.avatar,
    required this.tier,
    this.subscriptionStatus,
    this.subscriptionExpiryDate,
    required this.createdAt,
    this.lastLogin,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['profile']?['name'],
      avatar: json['profile']?['avatar'],
      tier: json['subscription']?['tier'] ?? 'free',
      subscriptionStatus: json['subscription']?['status'],
      subscriptionExpiryDate: json['subscription']?['expiryDate'] != null
          ? DateTime.parse(json['subscription']['expiryDate'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
    );
  }

  bool get isPremium => tier == 'premium';
  bool get isActive => subscriptionStatus == 'active';
}
