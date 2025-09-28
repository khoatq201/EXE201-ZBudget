import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/group_service.dart';
import '../../models/group_models.dart';
import '../../constants/colors.dart';
import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with TickerProviderStateMixin {
  String activeTab = 'overview';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        backgroundColor: widget.group.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareGroup),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showGroupSettings,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [_buildGroupHeader(), _buildTabBar(), _buildTabContent()],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        backgroundColor: AppColors.primary500,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGroupHeader() {
    final progressPercentage = widget.group.spentPercentage / 100;
    final remaining = widget.group.totalBudget - widget.group.spent;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji và mô tả
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: widget.group.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    widget.group.coverEmoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.description,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.group.members.length} thành viên',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Thống kê ngân sách
          Row(
            children: [
              Expanded(
                child: _buildBudgetStat(
                  'Tổng ngân sách',
                  formatCurrency(widget.group.totalBudget),
                  AppColors.primary500,
                ),
              ),
              Expanded(
                child: _buildBudgetStat(
                  'Đã chi',
                  formatCurrency(widget.group.spent),
                  AppColors.error,
                ),
              ),
              Expanded(
                child: _buildBudgetStat(
                  'Còn lại',
                  formatCurrency(remaining),
                  remaining > 0 ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tiến độ chi tiêu',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    '${(progressPercentage * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPercentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressPercentage > 0.8
                        ? AppColors.error
                        : progressPercentage > 0.6
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabItem('overview', 'Tổng quan')),
          Expanded(child: _buildTabItem('transactions', 'Giao dịch')),
          Expanded(child: _buildTabItem('members', 'Thành viên')),
        ],
      ),
    );
  }

  Widget _buildTabItem(String tab, String label) {
    final isActive = activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => activeTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary500 : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (activeTab) {
      case 'transactions':
        return _buildTransactionsTab();
      case 'members':
        return _buildMembersTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalancesSection(),
          const SizedBox(height: 24),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildBalancesSection() {
    final membersWithBalance =
        widget.group.members.where((m) => m.balance != 0).toList()
          ..sort((a, b) => b.balance.compareTo(a.balance));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cân bằng thanh toán',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        const SizedBox(height: 16),
        if (membersWithBalance.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Tất cả đã thanh toán!',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Không ai nợ ai cả',
                  style: TextStyle(color: AppColors.success, fontSize: 14),
                ),
              ],
            ),
          )
        else
          ...membersWithBalance.map((member) => _buildBalanceItem(member)),
      ],
    );
  }

  Widget _buildBalanceItem(GroupMember member) {
    final isPositive = member.balance > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPositive ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isPositive ? AppColors.success : AppColors.error,
            child: Text(member.avatar, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isPositive ? 'Được nợ' : 'Đang nợ',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(member.balance.abs()),
            style: TextStyle(
              color: isPositive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final recentTransactions = widget.group.transactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Giao dịch gần đây',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            TextButton(
              onPressed: () => setState(() => activeTab = 'transactions'),
              child: Text(
                'Xem tất cả',
                style: TextStyle(color: AppColors.primary500, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentTransactions.isEmpty)
          const Center(
            child: Text(
              'Chưa có giao dịch nào',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...recentTransactions.map(
            (transaction) => _buildTransactionItem(transaction),
          ),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tất cả giao dịch',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(height: 16),
          if (widget.group.transactions.isEmpty)
            const Center(
              child: Text(
                'Chưa có giao dịch nào',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...widget.group.transactions.map(
              (transaction) => _buildTransactionItem(transaction),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(GroupTransaction transaction) {
    final isExpense = transaction.type == TransactionType.expense;
    final isPayment = transaction.type == TransactionType.payment;
    final currentUserId = Provider.of<GroupService>(
      context,
      listen: false,
    ).currentUserId;
    final canEdit =
        transaction.paidBy == currentUserId; // Only who paid can edit

    return Dismissible(
      key: Key(transaction.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.primary500,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.edit, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Chỉnh sửa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Xóa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (!canEdit) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Chỉ người trả tiền mới có thể chỉnh sửa/xóa giao dịch này',
              ),
            ),
          );
          return false;
        }

        if (direction == DismissDirection.startToEnd) {
          // Edit
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditExpenseScreen(
                group: widget.group,
                transaction: transaction,
              ),
            ),
          );
          return false; // Don't dismiss
        } else {
          // Delete
          return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa giao dịch'),
                  content: const Text(
                    'Bạn có chắc chắn muốn xóa giao dịch này không?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              ) ??
              false;
        }
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete transaction
          try {
            final groupService = Provider.of<GroupService>(
              context,
              listen: false,
            );
            await groupService.deleteExpense(widget.group.id, transaction.id);

            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Giao dịch đã được xóa!')),
              );
            }
          } catch (e) {
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Lỗi xóa giao dịch: $e')));
            }
          }
        }
      },
      child: InkWell(
        onTap: canEdit
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditExpenseScreen(
                      group: widget.group,
                      transaction: transaction,
                    ),
                  ),
                );
              }
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: canEdit
                ? Border.all(color: AppColors.primary200, width: 1)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPayment ? Colors.green[100] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    transaction.categoryIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transaction.description,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (canEdit)
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: AppColors.primary500,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.paidByName} • ${transaction.formattedDate}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (transaction.notes != null &&
                        transaction.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        transaction.notes!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isExpense
                        ? '-${formatCurrency(transaction.amount)}'
                        : '+${formatCurrency(transaction.amount)}',
                    style: TextStyle(
                      color: isExpense ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    transaction.category,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thành viên (${widget.group.members.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              IconButton(
                onPressed: _inviteMembers,
                icon: Icon(Icons.person_add, color: AppColors.primary500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.group.members.map((member) => _buildMemberItem(member)),
        ],
      ),
    );
  }

  Widget _buildMemberItem(GroupMember member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary500,
                child: Text(
                  member.avatar,
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              if (member.isOwner)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.star, size: 8, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã trả: ${formatCurrency(member.totalPaid)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                member.balance >= 0
                    ? '+${formatCurrency(member.balance)}'
                    : formatCurrency(member.balance),
                style: TextStyle(
                  color: member.balance >= 0
                      ? AppColors.success
                      : AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                member.balance >= 0 ? 'Được nợ' : 'Đang nợ',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(group: widget.group),
      ),
    );
  }

  void _shareGroup() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mã mời: ${widget.group.inviteCode}')),
    );
  }

  void _showGroupSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Chỉnh sửa nhóm'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Cài đặt nhóm'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Rời khỏi nhóm'),
              onTap: () {
                Navigator.pop(context);
                _showLeaveGroupDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _inviteMembers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mời thành viên'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mã mời nhóm: ${widget.group.inviteCode}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.group.inviteCode));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép mã mời')),
                );
              },
              child: const Text('Sao chép mã'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rời khỏi nhóm'),
        content: const Text('Bạn có chắc chắn muốn rời khỏi nhóm này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Đã rời khỏi nhóm')));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Rời nhóm'),
          ),
        ],
      ),
    );
  }
}
