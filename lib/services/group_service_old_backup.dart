import 'package:flutter/material.dart';
import '../models/group_models.dart';

class GroupService extends ChangeNotifier {
  List<Group> _groups = [];
  String _currentUserId = 'user1';
  String _currentUserName = 'Bạn';

  List<Group> get groups => _groups;
  List<Group> get myGroups => _groups.where((g) => 
    g.members.any((m) => m.id == _currentUserId && m.isOwner)).toList();
  List<Group> get sharedGroups => _groups.where((g) => 
    g.members.any((m) => m.id == _currentUserId && !m.isOwner)).toList();

  String get currentUserId => _currentUserId;
  String get currentUserName => _currentUserName;

  GroupService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    _groups = [
      Group(
        id: '1',
        name: 'Du lịch Đà Lạt',
        description: 'Chuyến đi cuối tuần với bạn bè - Tết Dương lịch 2025',
        coverEmoji: '🏔️',
        totalBudget: 5000000,
        spent: 2850000,
        currency: 'VND',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        inviteCode: 'DALAT2025',
        members: [
          GroupMember(
            id: 'user1',
            name: 'Bạn',
            avatar: '👤',
            balance: -50000,
            role: GroupMemberRole.owner,
            joinedAt: DateTime.now().subtract(const Duration(days: 7)),
            totalPaid: 1200000,
            totalOwed: 1250000,
          ),
          GroupMember(
            id: 'user2',
            name: 'Minh',
            avatar: '🧑',
            balance: -350000,
            role: GroupMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 6)),
            totalPaid: 800000,
            totalOwed: 1150000,
          ),
          GroupMember(
            id: 'user3',
            name: 'Linh',
            avatar: '👩',
            balance: 250000,
            role: GroupMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 6)),
            totalPaid: 850000,
            totalOwed: 600000,
          ),
          GroupMember(
            id: 'user4',
            name: 'Tuấn',
            avatar: '👨',
            balance: 150000,
            role: GroupMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 5)),
            totalPaid: 600000,
            totalOwed: 450000,
          ),
        ],
        transactions: [
          GroupTransaction(
            id: 't1',
            type: TransactionType.expense,
            amount: 800000,
            description: 'Đặt khách sạn Đà Lạt',
            paidBy: 'user1',
            paidByName: 'Bạn',
            paidByAvatar: '👤',
            participants: ['user1', 'user2', 'user3', 'user4'],
            splitDetails: {'user1': 200000, 'user2': 200000, 'user3': 200000, 'user4': 200000},
            date: DateTime.now().subtract(const Duration(hours: 2)),
            category: 'accommodation',
            categoryIcon: '🏨',
            splitMethod: SplitMethod.equal,
          ),
          GroupTransaction(
            id: 't2',
            type: TransactionType.expense,
            amount: 450000,
            description: 'Vé máy bay đi Đà Lạt',
            paidBy: 'user3',
            paidByName: 'Linh',
            paidByAvatar: '👩',
            participants: ['user1', 'user2', 'user3', 'user4'],
            splitDetails: {'user1': 112500, 'user2': 112500, 'user3': 112500, 'user4': 112500},
            date: DateTime.now().subtract(const Duration(days: 1)),
            category: 'transport',
            categoryIcon: '✈️',
            splitMethod: SplitMethod.equal,
          ),
          GroupTransaction(
            id: 't3',
            type: TransactionType.expense,
            amount: 320000,
            description: 'Ăn tối nhà hàng',
            paidBy: 'user2',
            paidByName: 'Minh',
            paidByAvatar: '🧑',
            participants: ['user1', 'user2', 'user3', 'user4'],
            splitDetails: {'user1': 80000, 'user2': 80000, 'user3': 80000, 'user4': 80000},
            date: DateTime.now().subtract(const Duration(days: 2)),
            category: 'food',
            categoryIcon: '🍽️',
            splitMethod: SplitMethod.equal,
          ),
        ],
      ),
      Group(
        id: '2',
        name: 'Nhà trọ Quận 3',
        description: 'Chi phí sinh hoạt: điện, nước, internet, dọn dẹp',
        coverEmoji: '🏠',
        totalBudget: 4500000,
        spent: 2100000,
        currency: 'VND',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        inviteCode: 'TRONHQ3',
        members: [
          GroupMember(
            id: 'user1',
            name: 'Bạn',
            avatar: '👤',
            balance: 150000,
            role: GroupMemberRole.owner,
            joinedAt: DateTime.now().subtract(const Duration(days: 30)),
            totalPaid: 850000,
            totalOwed: 700000,
          ),
          GroupMember(
            id: 'user5',
            name: 'Hương',
            avatar: '👩',
            balance: -80000,
            role: GroupMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 25)),
            totalPaid: 620000,
            totalOwed: 700000,
          ),
          GroupMember(
            id: 'user6',
            name: 'Nam',
            avatar: '👨',
            balance: -70000,
            role: GroupMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 20)),
            totalPaid: 630000,
            totalOwed: 700000,
          ),
        ],
        transactions: [
          GroupTransaction(
            id: 't4',
            type: TransactionType.expense,
            amount: 800000,
            description: 'Tiền điện tháng 12',
            paidById: 'user1',
            paidByName: 'Bạn',
            paidByAvatar: '👤',
            splitBetween: ['user1', 'user5', 'user6'],
            date: DateTime.now().subtract(const Duration(days: 5)),
            category: 'Hóa đơn',
            categoryIcon: '⚡',
          ),
          GroupTransaction(
            id: 't5',
            type: TransactionType.expense,
            amount: 600000,
            description: 'Tiền nước tháng 12',
            paidById: 'user5',
            paidByName: 'Hương',
            paidByAvatar: '👩',
            splitBetween: ['user1', 'user5', 'user6'],
            date: DateTime.now().subtract(const Duration(days: 8)),
            category: 'Hóa đơn',
            categoryIcon: '💧',
          ),
        ],
      ),
      Group(
        id: '3',
        name: 'Cưới Tuấn & Linh',
        description: 'Mừng cưới anh Tuấn - chị Linh 💍',
        coverEmoji: '💒',
        totalBudget: 15000000,
        spent: 8500000,
        currency: 'VND',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        inviteCode: 'WEDDING2025',
        members: [
          GroupMember(
            id: 'user7',
            name: 'Tuấn',
            avatar: '👨',
            balance: 0,
            role: GroupMemberRole.owner,
            joinedAt: DateTime.now().subtract(const Duration(days: 14)),
            totalPaid: 2500000,
            totalOwed: 2500000,
          ),
          GroupMember(
            id: 'user1',
            name: 'Bạn',
            avatar: '👤',
            balance: -200000,
            role: GroupMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 12)),
            totalPaid: 500000,
            totalOwed: 700000,
          ),
        ],
        transactions: [
          GroupTransaction(
            id: 't6',
            type: TransactionType.expense,
            amount: 5000000,
            description: 'Đặt tiệc cưới',
            paidById: 'user7',
            paidByName: 'Tuấn',
            paidByAvatar: '👨',
            splitBetween: ['user7', 'user1'],
            date: DateTime.now().subtract(const Duration(days: 10)),
            category: 'Tiệc',
            categoryIcon: '🎉',
          ),
        ],
      ),
    ];
    notifyListeners();
  }

  // CRUD Operations
  Future<void> createGroup(Group group) async {
    _groups.add(group);
    notifyListeners();
  }

  Future<void> updateGroup(Group group) async {
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = group;
      notifyListeners();
    }
  }

  Future<void> deleteGroup(String groupId) async {
    _groups.removeWhere((g) => g.id == groupId);
    notifyListeners();
  }

  Group? getGroupById(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  // Member Operations
  Future<void> addMemberToGroup(String groupId, GroupMember member) async {
    final group = getGroupById(groupId);
    if (group != null) {
      final updatedMembers = [...group.members, member];
      final updatedGroup = group.copyWith(members: updatedMembers);
      await updateGroup(updatedGroup);
    }
  }

  Future<void> removeMemberFromGroup(String groupId, String memberId) async {
    final group = getGroupById(groupId);
    if (group != null) {
      final updatedMembers = group.members.where((m) => m.id != memberId).toList();
      final updatedGroup = group.copyWith(members: updatedMembers);
      await updateGroup(updatedGroup);
    }
  }

  // Transaction Operations
  Future<void> addTransaction(String groupId, GroupTransaction transaction) async {
    final group = getGroupById(groupId);
    if (group != null) {
      final updatedTransactions = [...group.transactions, transaction];
      final updatedSpent = group.spent + transaction.amount;
      
      // Calculate balance changes
      final updatedMembers = _calculateBalanceChanges(
        group.members, 
        transaction,
      );

      final updatedGroup = group.copyWith(
        transactions: updatedTransactions,
        spent: updatedSpent,
        members: updatedMembers,
      );
      
      await updateGroup(updatedGroup);
    }
  }

  List<GroupMember> _calculateBalanceChanges(
    List<GroupMember> members, 
    GroupTransaction transaction,
  ) {
    final splitAmount = transaction.amount / transaction.splitBetween.length;
    
    return members.map((member) {
      double newBalance = member.balance;
      double newTotalPaid = member.totalPaid;
      double newTotalOwed = member.totalOwed;

      // If member paid for the transaction
      if (member.id == transaction.paidById) {
        newTotalPaid += transaction.amount;
        newBalance += transaction.amount;
      }

      // If member is part of the split
      if (transaction.splitBetween.contains(member.id)) {
        newTotalOwed += splitAmount;
        newBalance -= splitAmount;
      }

      return member.copyWith(
        balance: newBalance,
        totalPaid: newTotalPaid,
        totalOwed: newTotalOwed,
      );
    }).toList();
  }

  // Utility Functions
  String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(8, (index) => chars[random % chars.length]).join();
  }

  List<String> getCategoryOptions() {
    return [
      'Ăn uống',
      'Giao thông',
      'Lưu trú',
      'Giải trí',
      'Hóa đơn',
      'Mua sắm',
      'Y tế',
      'Giáo dục',
      'Tiệc',
      'Du lịch',
      'Khác',
    ];
  }

  Map<String, String> getCategoryIcons() {
    return {
      'Ăn uống': '🍽️',
      'Giao thông': '🚗',
      'Lưu trú': '🏨',
      'Giải trí': '🎬',
      'Hóa đơn': '⚡',
      'Mua sắm': '🛍️',
      'Y tế': '🏥',
      'Giáo dục': '📚',
      'Tiệc': '🎉',
      'Du lịch': '✈️',
      'Khác': '💰',
    };
  }

  List<String> getCoverEmojiOptions() {
    return [
      '🎯', '🏠', '✈️', '🍕', '🎉', '💰', '📚', '🏥', '🚗', '🎬',
      '🏔️', '🏖️', '🎪', '🎨', '🎵', '⚽', '🏊', '🎮', '📱', '💻',
      '💒', '🎂', '🍰', '🍻', '☕', '🌮', '🍜', '🍱', '🥘', '🍷',
    ];
  }

  // Settlement calculations
  List<Settlement> calculateSettlements(String groupId) {
    final group = getGroupById(groupId);
    if (group == null) return [];

    final settlements = <Settlement>[];
    final balances = Map.fromEntries(
      group.members.map((m) => MapEntry(m.id, m.balance))
    );

    // Simple debt settlement algorithm
    while (balances.values.any((balance) => balance.abs() > 0.01)) {
      final creditor = balances.entries
          .where((e) => e.value > 0.01)
          .reduce((a, b) => a.value > b.value ? a : b);
      
      final debtor = balances.entries
          .where((e) => e.value < -0.01)
          .reduce((a, b) => a.value < b.value ? a : b);

      final amount = [creditor.value, -debtor.value].reduce((a, b) => a < b ? a : b);
      
      settlements.add(Settlement(
        fromId: debtor.key,
        toId: creditor.key,
        amount: amount,
        fromName: group.members.firstWhere((m) => m.id == debtor.key).name,
        toName: group.members.firstWhere((m) => m.id == creditor.key).name,
      ));

      balances[creditor.key] = creditor.value - amount;
      balances[debtor.key] = debtor.value + amount;
    }

    return settlements;
  }

  // CRUD Operations for Groups
  Future<void> addExpenseToGroup(String groupId, GroupTransaction transaction) async {
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) throw Exception('Group not found');
    
    final group = _groups[groupIndex];
    
    // Add transaction to group
    final updatedTransactions = [...group.transactions, transaction];
    
    // Update member balances
    final updatedMembers = group.members.map((member) {
      if (member.id == transaction.paidBy) {
        // Person who paid gets credited
        final newTotalPaid = member.totalPaid + transaction.amount;
        final splitAmount = transaction.splitDetails[member.id] ?? 0;
        final newBalance = member.balance + transaction.amount - splitAmount;
        
        return member.copyWith(
          totalPaid: newTotalPaid,
          balance: newBalance,
        );
      } else if (transaction.splitDetails.containsKey(member.id)) {
        // Person who owes money gets debited
        final splitAmount = transaction.splitDetails[member.id]!;
        final newTotalOwed = member.totalOwed + splitAmount;
        final newBalance = member.balance - splitAmount;
        
        return member.copyWith(
          totalOwed: newTotalOwed,
          balance: newBalance,
        );
      }
      return member;
    }).toList();
    
    // Update group spent amount
    final updatedSpent = group.spent + transaction.amount;
    
    // Create updated group
    final updatedGroup = group.copyWith(
      transactions: updatedTransactions,
      members: updatedMembers,
      spent: updatedSpent,
    );
    
    _groups[groupIndex] = updatedGroup;
    notifyListeners();
  }

  Future<void> updateExpense(String groupId, GroupTransaction updatedTransaction) async {
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) throw Exception('Group not found');
    
    final group = _groups[groupIndex];
    final transactionIndex = group.transactions.indexWhere((t) => t.id == updatedTransaction.id);
    if (transactionIndex == -1) throw Exception('Transaction not found');
    
    // Remove old transaction impact and add new one
    final oldTransaction = group.transactions[transactionIndex];
    await _removeTransactionImpact(groupId, oldTransaction);
    await addExpenseToGroup(groupId, updatedTransaction);
  }

  Future<void> deleteExpense(String groupId, String transactionId) async {
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) throw Exception('Group not found');
    
    final group = _groups[groupIndex];
    final transaction = group.transactions.firstWhere((t) => t.id == transactionId);
    
    await _removeTransactionImpact(groupId, transaction);
  }

  Future<void> _removeTransactionImpact(String groupId, GroupTransaction transaction) async {
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    final group = _groups[groupIndex];
    
    // Remove transaction from list
    final updatedTransactions = group.transactions.where((t) => t.id != transaction.id).toList();
    
    // Reverse balance changes
    final updatedMembers = group.members.map((member) {
      if (member.id == transaction.paidBy) {
        final newTotalPaid = member.totalPaid - transaction.amount;
        final splitAmount = transaction.splitDetails[member.id] ?? 0;
        final newBalance = member.balance - transaction.amount + splitAmount;
        
        return member.copyWith(
          totalPaid: newTotalPaid,
          balance: newBalance,
        );
      } else if (transaction.splitDetails.containsKey(member.id)) {
        final splitAmount = transaction.splitDetails[member.id]!;
        final newTotalOwed = member.totalOwed - splitAmount;
        final newBalance = member.balance + splitAmount;
        
        return member.copyWith(
          totalOwed: newTotalOwed,
          balance: newBalance,
        );
      }
      return member;
    }).toList();
    
    // Update group spent amount
    final updatedSpent = group.spent - transaction.amount;
    
    // Create updated group
    final updatedGroup = group.copyWith(
      transactions: updatedTransactions,
      members: updatedMembers,
      spent: updatedSpent,
    );
    
    _groups[groupIndex] = updatedGroup;
    notifyListeners();
  }

  Future<void> updateGroup(Group updatedGroup) async {
    final index = _groups.indexWhere((g) => g.id == updatedGroup.id);
    if (index != -1) {
      _groups[index] = updatedGroup;
      notifyListeners();
    }
  }

  Future<void> deleteGroup(String groupId) async {
    _groups.removeWhere((g) => g.id == groupId);
    notifyListeners();
  }

  Future<void> addMemberToGroup(String groupId, GroupMember member) async {
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final group = _groups[groupIndex];
      final updatedMembers = [...group.members, member];
      _groups[groupIndex] = group.copyWith(members: updatedMembers);
      notifyListeners();
    }
  }

  Future<void> removeMemberFromGroup(String groupId, String memberId) async {
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final group = _groups[groupIndex];
      final updatedMembers = group.members.where((m) => m.id != memberId).toList();
      _groups[groupIndex] = group.copyWith(members: updatedMembers);
      notifyListeners();
    }
  }
}

class Settlement {
  final String fromId;
  final String toId;
  final double amount;
  final String fromName;
  final String toName;

  Settlement({
    required this.fromId,
    required this.toId,
    required this.amount,
    required this.fromName,
    required this.toName,
  });
}
