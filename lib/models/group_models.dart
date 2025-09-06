import 'package:flutter/material.dart';

enum GroupMemberRole { owner, admin, member }

enum TransactionType { expense, payment, settlement }

enum SplitMethod { equal, percentage, custom }

class GroupMember {
  final String id;
  final String name;
  final String avatar;
  final double balance;
  final GroupMemberRole role;
  final DateTime joinedAt;
  final double totalPaid;
  final double totalOwed;
  final bool isActive;

  GroupMember({
    required this.id,
    required this.name,
    required this.avatar,
    required this.balance,
    required this.role,
    required this.joinedAt,
    required this.totalPaid,
    required this.totalOwed,
    this.isActive = true,
  });

  bool get isOwner => role == GroupMemberRole.owner;
  bool get isAdmin => role == GroupMemberRole.admin || role == GroupMemberRole.owner;

  GroupMember copyWith({
    String? id,
    String? name,
    String? avatar,
    double? balance,
    GroupMemberRole? role,
    DateTime? joinedAt,
    double? totalPaid,
    double? totalOwed,
    bool? isActive,
  }) {
    return GroupMember(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      balance: balance ?? this.balance,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      totalPaid: totalPaid ?? this.totalPaid,
      totalOwed: totalOwed ?? this.totalOwed,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'balance': balance,
      'role': role.toString(),
      'joinedAt': joinedAt.toIso8601String(),
      'totalPaid': totalPaid,
      'totalOwed': totalOwed,
      'isActive': isActive,
    };
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      balance: json['balance'].toDouble(),
      role: GroupMemberRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => GroupMemberRole.member,
      ),
      joinedAt: DateTime.parse(json['joinedAt']),
      totalPaid: json['totalPaid'].toDouble(),
      totalOwed: json['totalOwed'].toDouble(),
      isActive: json['isActive'] ?? true,
    );
  }
}

class GroupTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final String paidBy; // Changed from paidById for consistency
  final String paidByName;
  final String paidByAvatar;
  final List<String> participants; // Changed from splitBetween
  final Map<String, double> splitDetails; // Changed from customSplit
  final DateTime date;
  final String category;
  final String categoryIcon;
  final String? receiptImage;
  final String? notes;
  final SplitMethod splitMethod;
  final bool isApproved;
  final String? approvedBy;

  GroupTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.paidBy,
    required this.paidByName,
    required this.paidByAvatar,
    required this.participants,
    required this.splitDetails,
    required this.date,
    required this.category,
    required this.categoryIcon,
    this.receiptImage,
    this.notes,
    this.splitMethod = SplitMethod.equal,
    this.isApproved = true,
    this.approvedBy,
  });

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hôm nay';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String get timeString {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  GroupTransaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? description,
    String? paidBy,
    String? paidByName,
    String? paidByAvatar,
    List<String>? participants,
    Map<String, double>? splitDetails,
    DateTime? date,
    String? category,
    String? categoryIcon,
    String? receiptImage,
    String? notes,
    SplitMethod? splitMethod,
    bool? isApproved,
    String? approvedBy,
  }) {
    return GroupTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      paidBy: paidBy ?? this.paidBy,
      paidByName: paidByName ?? this.paidByName,
      paidByAvatar: paidByAvatar ?? this.paidByAvatar,
      participants: participants ?? this.participants,
      splitDetails: splitDetails ?? this.splitDetails,
      date: date ?? this.date,
      category: category ?? this.category,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      receiptImage: receiptImage ?? this.receiptImage,
      notes: notes ?? this.notes,
      splitMethod: splitMethod ?? this.splitMethod,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'amount': amount,
      'description': description,
      'paidBy': paidBy,
      'paidByName': paidByName,
      'paidByAvatar': paidByAvatar,
      'participants': participants,
      'splitDetails': splitDetails,
      'date': date.toIso8601String(),
      'category': category,
      'categoryIcon': categoryIcon,
      'receiptImage': receiptImage,
      'notes': notes,
      'splitMethod': splitMethod.toString(),
      'isApproved': isApproved,
      'approvedBy': approvedBy,
    };
  }

  factory GroupTransaction.fromJson(Map<String, dynamic> json) {
    return GroupTransaction(
      id: json['id'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: json['amount'].toDouble(),
      description: json['description'],
      paidBy: json['paidBy'],
      paidByName: json['paidByName'],
      paidByAvatar: json['paidByAvatar'],
      participants: List<String>.from(json['participants']),
      splitDetails: Map<String, double>.from(json['splitDetails']),
      date: DateTime.parse(json['date']),
      category: json['category'],
      categoryIcon: json['categoryIcon'],
      receiptImage: json['receiptImage'],
      notes: json['notes'],
      splitMethod: SplitMethod.values.firstWhere(
        (e) => e.toString() == json['splitMethod'],
        orElse: () => SplitMethod.equal,
      ),
      isApproved: json['isApproved'] ?? true,
      approvedBy: json['approvedBy'],
    );
  }
}

class Group {
  final String id;
  final String name;
  final String description;
  final String coverEmoji;
  final double totalBudget;
  final double spent;
  final String currency;
  final DateTime createdAt;
  final DateTime? endDate;
  final List<GroupMember> members;
  final List<GroupTransaction> transactions;
  final String inviteCode;
  final SplitMethod defaultSplitMethod;
  final bool debtSimplification;
  final bool autoReminders;
  final bool receiptScanning;
  final bool expenseApproval;
  final Map<String, double> categoryBudgets;
  final bool isActive;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.coverEmoji,
    required this.totalBudget,
    required this.spent,
    this.currency = 'VND',
    required this.createdAt,
    this.endDate,
    required this.members,
    required this.transactions,
    required this.inviteCode,
    this.defaultSplitMethod = SplitMethod.equal,
    this.debtSimplification = true,
    this.autoReminders = true,
    this.receiptScanning = true,
    this.expenseApproval = false,
    this.categoryBudgets = const {},
    this.isActive = true,
  });

  double get balance => totalBudget - spent;
  double get spentPercentage => totalBudget > 0 ? (spent / totalBudget) * 100 : 0;
  int get memberCount => members.where((m) => m.isActive).length;
  
  String get lastActivity {
    if (transactions.isEmpty) return 'Chưa có hoạt động';
    
    final lastTransaction = transactions.last;
    final difference = DateTime.now().difference(lastTransaction.date);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${difference.inDays} ngày trước';
    }
  }

  GroupMember? get owner => members.firstWhere(
    (member) => member.isOwner,
    orElse: () => members.first,
  );

  Color get primaryColor {
    // Generate color based on group name hash
    final hash = name.hashCode;
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor();
  }

  List<GroupMember> get membersWithBalance => members.where((m) => m.balance != 0).toList();
  
  List<GroupMember> get membersOwing => members.where((m) => m.balance < 0).toList();
  
  List<GroupMember> get membersOwed => members.where((m) => m.balance > 0).toList();

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? coverEmoji,
    double? totalBudget,
    double? spent,
    String? currency,
    DateTime? createdAt,
    DateTime? endDate,
    List<GroupMember>? members,
    List<GroupTransaction>? transactions,
    String? inviteCode,
    SplitMethod? defaultSplitMethod,
    bool? debtSimplification,
    bool? autoReminders,
    bool? receiptScanning,
    bool? expenseApproval,
    Map<String, double>? categoryBudgets,
    bool? isActive,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverEmoji: coverEmoji ?? this.coverEmoji,
      totalBudget: totalBudget ?? this.totalBudget,
      spent: spent ?? this.spent,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      endDate: endDate ?? this.endDate,
      members: members ?? this.members,
      transactions: transactions ?? this.transactions,
      inviteCode: inviteCode ?? this.inviteCode,
      defaultSplitMethod: defaultSplitMethod ?? this.defaultSplitMethod,
      debtSimplification: debtSimplification ?? this.debtSimplification,
      autoReminders: autoReminders ?? this.autoReminders,
      receiptScanning: receiptScanning ?? this.receiptScanning,
      expenseApproval: expenseApproval ?? this.expenseApproval,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverEmoji': coverEmoji,
      'totalBudget': totalBudget,
      'spent': spent,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'members': members.map((m) => m.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'inviteCode': inviteCode,
      'defaultSplitMethod': defaultSplitMethod.toString(),
      'debtSimplification': debtSimplification,
      'autoReminders': autoReminders,
      'receiptScanning': receiptScanning,
      'expenseApproval': expenseApproval,
      'categoryBudgets': categoryBudgets,
      'isActive': isActive,
    };
  }
}
