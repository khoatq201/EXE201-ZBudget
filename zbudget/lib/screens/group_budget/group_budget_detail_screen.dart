import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/group_budget_service.dart';
import '../../models/group_budget.dart';
import '../../constants/typography.dart';
import '../../constants/spacing.dart';
import '../../utils/theme_extensions.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/common_header.dart';

class GroupBudgetDetailScreen extends StatefulWidget {
  final String budgetId;

  const GroupBudgetDetailScreen({
    super.key,
    required this.budgetId,
  });

  @override
  State<GroupBudgetDetailScreen> createState() =>
      _GroupBudgetDetailScreenState();
}

class _GroupBudgetDetailScreenState extends State<GroupBudgetDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBudget();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBudget() async {
    final service = Provider.of<GroupBudgetService>(context, listen: false);
    await service.getGroupBudgetById(widget.budgetId);
  }

  Future<void> _refreshBudget() async {
    return _loadBudget();
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    SnackBarUtils.showSuccess(context, 'Đã sao chép mã: $code');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<GroupBudgetService>(
        builder: (context, service, child) {
          if (service.isLoading && service.currentBudget == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final budget = service.currentBudget;
          if (budget == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('Không tìm thấy ngân sách'),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Quay lại'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshBudget,
            child: Column(
              children: [
                _buildHeader(budget),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(budget),
                      _buildExpensesTab(budget),
                      _buildMembersTab(budget),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/group-budgets/${widget.budgetId}/add-expense'),
        icon: const Icon(Icons.add),
        label: const Text('Thêm chi tiêu'),
      ),
    );
  }

  Widget _buildHeader(GroupBudget budget) {
    return CommonHeader(
      title: budget.name,
      subtitle: budget.description ?? '${budget.members.length} thành viên',
      variant: HeaderVariant.gradient,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      trailing: GestureDetector(
        onTap: () => _copyInviteCode(budget.inviteCode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.copy, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                budget.inviteCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn(
              'Tổng ngân sách',
              CurrencyFormatter.format(budget.totalBudget),
              Icons.account_balance_wallet,
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            _buildStatColumn(
              'Đã chi',
              CurrencyFormatter.format(budget.totalSpent),
              Icons.trending_down,
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            _buildStatColumn(
              'Còn lại',
              CurrencyFormatter.format(budget.remaining),
              Icons.savings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: context.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Tổng quan'),
          Tab(text: 'Chi tiêu'),
          Tab(text: 'Thành viên'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(GroupBudget budget) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildBudgetProgress(budget),
        const SizedBox(height: AppSpacing.lg),
        _buildQuickStats(budget),
        const SizedBox(height: AppSpacing.lg),
        if (budget.membersWhoOwe.isNotEmpty || budget.membersWhoAreOwed.isNotEmpty) ...[
          _buildBalanceSection(budget),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => context.push('/group-budgets/${budget.id}/settlement'),
            icon: const Icon(Icons.account_balance),
            label: const Text('Xem phương án thanh toán'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBudgetProgress(GroupBudget budget) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đã chi', style: AppTypography.bodySmall),
                Text(
                  CurrencyFormatter.format(budget.totalSpent),
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: budget.spentPercentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  budget.isOverBudget ? Colors.red : context.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng ngân sách', style: AppTypography.caption),
                Text(
                  CurrencyFormatter.format(budget.totalBudget),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(GroupBudget budget) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Thành viên',
            budget.memberCount.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Chi tiêu',
            budget.expenseCount.toString(),
            Icons.receipt,
            Colors.orange,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            'Còn lại',
            CurrencyFormatter.format(budget.remaining).replaceAll('₫', ''),
            Icons.savings,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(label, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSection(GroupBudget budget) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cân đối thanh toán',
              style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            if (budget.membersWhoAreOwed.isNotEmpty) ...[
              Text('Người được nợ:', style: AppTypography.caption),
              ...budget.membersWhoAreOwed.map((m) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.arrow_upward, color: Colors.green),
                    title: Text(m.name),
                    trailing: Text(
                      '+${CurrencyFormatter.format(m.balance)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
            ],
            if (budget.membersWhoOwe.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Người đang nợ:', style: AppTypography.caption),
              ...budget.membersWhoOwe.map((m) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.arrow_downward, color: Colors.red),
                    title: Text(m.name),
                    trailing: Text(
                      CurrencyFormatter.format(m.balance),
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesTab(GroupBudget budget) {
    if (budget.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: AppSpacing.lg),
            const Text('Chưa có chi tiêu nào'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: budget.expenses.length,
      itemBuilder: (context, index) {
        final expense = budget.expenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: context.colorScheme.primaryContainer,
              child: Icon(
                Icons.receipt,
                color: context.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(expense.description),
            subtitle: Text(
              '${expense.paidByName} • ${expense.splitTypeDisplay}',
              style: AppTypography.caption,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(expense.amount),
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  expense.date.toString().split(' ')[0],
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMembersTab(GroupBudget budget) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: budget.members.length,
      itemBuilder: (context, index) {
        final member = budget.members[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: member.balanceStatus == 'owed'
                  ? Colors.green.shade100
                  : member.balanceStatus == 'owes'
                      ? Colors.red.shade100
                      : Colors.grey.shade200,
              child: Text(
                member.name[0].toUpperCase(),
                style: TextStyle(
                  color: member.balanceStatus == 'owed'
                      ? Colors.green.shade700
                      : member.balanceStatus == 'owes'
                          ? Colors.red.shade700
                          : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(member.name),
            subtitle: Text(
              'Đóng góp: ${member.contributionPercentage}% • Đã chi: ${CurrencyFormatter.format(member.shareSpent)}',
              style: AppTypography.caption,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  member.balance >= 0 ? '+${CurrencyFormatter.format(member.balance)}' : CurrencyFormatter.format(member.balance),
                  style: TextStyle(
                    color: member.balance > 0
                        ? Colors.green
                        : member.balance < 0
                            ? Colors.red
                            : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
