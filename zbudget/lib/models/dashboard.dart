class DashboardData {
  final double currentBalance;
  final double totalIncome;
  final double totalExpenses;
  final double totalSavings;
  final double monthlyAllowance;
  final double readyToAssign; // ✅ NEW: Ready to Assign amount
  final double totalAssigned; // ✅ NEW: Total assigned to budgets
  final double totalSaved;    // ✅ NEW: Total saved in savings goals
  final PeriodStats period;
  final BudgetInfo? budget;
  final List<Transaction> recentTransactions;
  final List<CategoryBreakdown> categoryBreakdown;
  final List<Insight> insights;
  final UserStats userStats;
  final DateTime generatedAt;

  DashboardData({
    required this.currentBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalSavings,
    required this.monthlyAllowance,
    this.readyToAssign = 0.0,
    this.totalAssigned = 0.0,
    this.totalSaved = 0.0,
    required this.period,
    this.budget,
    required this.recentTransactions,
    required this.categoryBreakdown,
    required this.insights,
    required this.userStats,
    required this.generatedAt,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      totalSavings: (json['totalSavings'] as num?)?.toDouble() ?? 0.0,
      monthlyAllowance: (json['monthlyAllowance'] as num?)?.toDouble() ?? 0.0,
      readyToAssign: (json['readyToAssign'] as num?)?.toDouble() ?? 0.0,
      totalAssigned: (json['totalAssigned'] as num?)?.toDouble() ?? 0.0,
      totalSaved: (json['totalSaved'] as num?)?.toDouble() ?? 0.0,
      period: PeriodStats.fromJson(json['period'] as Map<String, dynamic>),
      budget: json['budget'] != null
          ? BudgetInfo.fromJson(json['budget'] as Map<String, dynamic>)
          : null,
      recentTransactions: (json['recentTransactions'] as List)
          .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
          .toList(),
      categoryBreakdown: (json['categoryBreakdown'] as List)
          .map((c) => CategoryBreakdown.fromJson(c as Map<String, dynamic>))
          .toList(),
      insights: (json['insights'] as List)
          .map((i) => Insight.fromJson(i as Map<String, dynamic>))
          .toList(),
      userStats: UserStats.fromJson(json['userStats'] as Map<String, dynamic>),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentBalance': currentBalance,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'totalSavings': totalSavings,
      'monthlyAllowance': monthlyAllowance,
      'period': period.toJson(),
      'budget': budget?.toJson(),
      'recentTransactions': recentTransactions.map((t) => t.toJson()).toList(),
      'categoryBreakdown': categoryBreakdown.map((c) => c.toJson()).toList(),
      'insights': insights.map((i) => i.toJson()).toList(),
      'userStats': userStats.toJson(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

class PeriodStats {
  final String type; // 'month', 'week', 'year'
  final DateTime startDate;
  final DateTime endDate;
  final double income;
  final double expense;
  final double balance;
  final int incomeCount;
  final int expenseCount;

  PeriodStats({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.income,
    required this.expense,
    required this.balance,
    required this.incomeCount,
    required this.expenseCount,
  });

  factory PeriodStats.fromJson(Map<String, dynamic> json) {
    return PeriodStats(
      type: json['type'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      incomeCount: json['incomeCount'] as int,
      expenseCount: json['expenseCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'income': income,
      'expense': expense,
      'balance': balance,
      'incomeCount': incomeCount,
      'expenseCount': expenseCount,
    };
  }
}

class BudgetInfo {
  final String id;
  final String name;
  final double totalAmount;
  final double spent;
  final double remaining;
  final int spentPercentage;
  final double dailyBudget;
  final int remainingDays;
  final bool isOverBudget;
  final String periodType;
  final DateTime startDate;
  final DateTime endDate;

  BudgetInfo({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.spent,
    required this.remaining,
    required this.spentPercentage,
    required this.dailyBudget,
    required this.remainingDays,
    required this.isOverBudget,
    required this.periodType,
    required this.startDate,
    required this.endDate,
  });

  factory BudgetInfo.fromJson(Map<String, dynamic> json) {
    return BudgetInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      spentPercentage: json['spentPercentage'] as int,
      dailyBudget: (json['dailyBudget'] as num).toDouble(),
      remainingDays: json['remainingDays'] as int,
      isOverBudget: json['isOverBudget'] as bool,
      periodType: json['periodType'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'spent': spent,
      'remaining': remaining,
      'spentPercentage': spentPercentage,
      'dailyBudget': dailyBudget,
      'remainingDays': remainingDays,
      'isOverBudget': isOverBudget,
      'periodType': periodType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}

class Transaction {
  final String id;
  final String title;
  final String? description;
  final double amount;
  final String category;
  final DateTime date;
  final String paymentMethod;
  final String type; // 'income' or 'expense'
  final bool isIncome;

  Transaction({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.paymentMethod,
    required this.type,
    required this.isIncome,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      paymentMethod: json['paymentMethod'] as String,
      type: json['type'] as String,
      isIncome: json['isIncome'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'type': type,
      'isIncome': isIncome,
    };
  }
}

class CategoryBreakdown {
  final String category;
  final double total;
  final int count;
  final int percentage;

  CategoryBreakdown({
    required this.category,
    required this.total,
    required this.count,
    required this.percentage,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      category: json['category'] as String,
      total: (json['total'] as num).toDouble(),
      count: json['count'] as int,
      percentage: json['percentage'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'total': total,
      'count': count,
      'percentage': percentage,
    };
  }
}

class Insight {
  final String type; // 'success', 'warning', 'info', 'alert'
  final String icon;
  final String title;
  final String message;
  final String? action;

  Insight({
    required this.type,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      type: json['type'] as String,
      icon: json['icon'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      action: json['action'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'icon': icon,
      'title': title,
      'message': message,
      'action': action,
    };
  }
}

class UserStats {
  final int level;
  final int points;
  final int currentStreak;
  final int longestStreak;

  UserStats({
    required this.level,
    required this.points,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      level: json['level'] as int,
      points: json['points'] as int,
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'points': points,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }
}
