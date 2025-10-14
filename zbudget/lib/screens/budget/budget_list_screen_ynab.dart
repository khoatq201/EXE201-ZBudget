import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/budget.dart';
import '../../services/budget_service.dart';
import '../../constants/typography.dart';
import '../../utils/theme_extensions.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';

class BudgetListScreenYNAB extends StatefulWidget {
  const BudgetListScreenYNAB({super.key});

  @override
  State<BudgetListScreenYNAB> createState() => _BudgetListScreenYNABState();
}

class _BudgetListScreenYNABState extends State<BudgetListScreenYNAB>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedFilter = 'active'; // active, all, inactive

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBudgets();
    });
  }

  Future<void> _loadBudgets() async {
    final budgetService = Provider.of<BudgetService>(context, listen: false);
    await budgetService.getBudgets(
      status: _selectedFilter == 'all' ? null : _selectedFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadBudgets,
        child: Consumer<BudgetService>(
          builder: (context, budgetService, child) {
            if (budgetService.isLoading && budgetService.budgets.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (budgetService.error != null) {
              return _buildErrorState(budgetService.error!);
            }

            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(budgetService),
                // Show Ready to Assign card when no budgets exist at all, otherwise show budget summary
                // Hide Ready to Assign card completely in inactive tab
                if (_selectedFilter == 'inactive')
                  // Don't show any card in inactive tab
                  const SliverToBoxAdapter(child: SizedBox.shrink())
                else if (budgetService.budgets.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildReadyToAssignCard(budgetService),
                  )
                else
                  SliverToBoxAdapter(
                    child: _buildBudgetSummaryCard(budgetService),
                  ),
                SliverToBoxAdapter(child: _buildFilterTabs()),
                _buildBudgetList(budgetService),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/budget/create');
          // Refresh list if budget was created
          if (result == true) {
            _loadBudgets();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSliverAppBar(BudgetService budgetService) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        background: Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [context.headerGradientStart, context.headerGradientEnd],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Ngân sách',
                    style: AppTypography.h2.copyWith(
                      color: context.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quản lý chi tiêu hiệu quả',
                    style: AppTypography.bodySmall.copyWith(
                      color: context.colorScheme.onPrimary.withValues(
                        alpha: 0.9,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadyToAssignCard(BudgetService budgetService) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colorScheme.secondary,
            context.colorScheme.secondary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.secondary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to Assign',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: CurrencyFormatter.format(
                              budgetService.readyToAssign,
                            ).replaceAll(' ₫', ''),
                            style: AppTypography.h2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ' ₫',
                            style: AppTypography.h2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Số tiền từ thu nhập chưa được phân bổ. Hãy fund vào các ngân sách!',
            style: AppTypography.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSummaryCard(BudgetService budgetService) {
    final activeBudgets = budgetService.activeBudgets;
    final totalAmount = activeBudgets.fold(
      0.0,
      (sum, budget) => sum + budget.totalAmount,
    );
    final totalAllocated = activeBudgets.fold(
      0.0,
      (sum, budget) => sum + budget.totalAllocated,
    );
    final totalFunded = activeBudgets.fold(
      0.0,
      (sum, budget) => sum + budget.totalFunded,
    );
    final totalSpent = activeBudgets.fold(
      0.0,
      (sum, budget) => sum + budget.status.totalSpent,
    );
    final totalRemaining = totalAllocated - totalSpent;
    final fundingPercentage = totalAllocated > 0
        ? (totalFunded / totalAllocated) * 100
        : 0;
    final spendingPercentage = totalAllocated > 0
        ? (totalSpent / totalAllocated) * 100
        : 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colorScheme.primary,
            context.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pie_chart,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng quan ngân sách',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${activeBudgets.length} ngân sách đang hoạt động',
                      style: AppTypography.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Funding Status
          _buildSummaryRow(
            'Tổng phân bổ',
            CurrencyFormatter.formatVND(totalAmount),
            Icons.pie_chart_outline,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Đã fund',
            CurrencyFormatter.formatVND(totalFunded),
            Icons.account_balance_wallet,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Đã chi',
            CurrencyFormatter.formatVND(totalSpent),
            Icons.payments_outlined,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Còn lại',
            CurrencyFormatter.formatVND(totalRemaining),
            Icons.savings_outlined,
          ),
          const SizedBox(height: 16),
          // Progress indicators
          _buildProgressIndicator(
            'Funding',
            fundingPercentage.toDouble(),
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildProgressIndicator(
            'Spending',
            spendingPercentage.toDouble(),
            spendingPercentage > 80 ? Colors.orange : Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: Colors.white70),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(color: Colors.white70),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (percentage / 100).clamp(0.0, 1.0),
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          color: color,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('active', 'Đang hoạt động'),
            const SizedBox(width: 8),
            _buildFilterChip('all', 'Tất cả'),
            const SizedBox(width: 8),
            _buildFilterChip('inactive', 'Không hoạt động'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        _loadBudgets();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colorScheme.primary
              : context.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? context.colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? Colors.white : context.primaryTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetList(BudgetService budgetService) {
    final budgets = budgetService.budgets;

    if (budgets.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(_getEmptyStateTitle(), style: AppTypography.h4),
              const SizedBox(height: 8),
              Text(
                _getEmptyStateMessage(),
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final budget = budgets[index];
          return _buildBudgetCard(budget);
        }, childCount: budgets.length),
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    return GestureDetector(
      onTap: () async {
        await context.push('/budget/${budget.id}');
        // Reload data when returning from detail screen
        if (mounted) {
          _loadBudgets();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(budget.name, style: AppTypography.h4),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormatter.toDisplayFormat(budget.period.startDate)} - ${DateFormatter.toDisplayFormat(budget.period.endDate)}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  if (!budget.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Không hoạt động',
                        style: AppTypography.caption,
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // YNAB Funding Status
                  _buildYNABStatus(budget),
                  const SizedBox(height: 16),

                  // Spending Status
                  _buildSpendingStatus(budget),
                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(
                        'Phân bổ',
                        CurrencyFormatter.formatVND(budget.totalAllocated),
                        Icons.pie_chart_outline,
                      ),
                      _buildStatItem(
                        'Đã chi',
                        CurrencyFormatter.formatVND(budget.status.totalSpent),
                        Icons.payments_outlined,
                      ),
                      _buildStatItem(
                        'Còn lại',
                        '${budget.period.daysRemaining} ngày',
                        Icons.calendar_today,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYNABStatus(Budget budget) {
    final fundingStatus = budget.fundingStatus;
    final isFullyFunded = budget.isFullyFunded;

    // Calculate percentage based on local logic for consistency
    final percentage = budget.totalAllocated > 0
        ? (budget.totalFunded / budget.totalAllocated) * 100
        : 0;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isFullyFunded) {
      statusColor = Colors.green;
      statusText = 'Fully Funded';
      statusIcon = Icons.check_circle;
    } else if (fundingStatus.underfunded) {
      statusColor = context.warningColor;
      statusText = 'Underfunded';
      statusIcon = Icons.warning_amber;
    } else {
      statusColor = Colors.grey;
      statusText = 'Not Funded';
      statusIcon = Icons.info_outline;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: AppTypography.bodySmall.copyWith(color: statusColor),
                ),
              ],
            ),
            Text(
              '${CurrencyFormatter.formatVND(budget.totalFunded)} / ${CurrencyFormatter.formatVND(budget.totalAllocated)}',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (percentage / 100).clamp(0.0, 1.0),
          backgroundColor: Colors.grey.shade200,
          color: statusColor,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(
          '${percentage.toStringAsFixed(1)}% funded',
          style: AppTypography.caption,
        ),
      ],
    );
  }

  Widget _buildSpendingStatus(Budget budget) {
    final status = budget.status;
    // Calculate percentage based on totalAmount instead of totalAllocated
    final percentage = budget.totalAmount > 0
        ? (status.totalSpent / budget.totalAmount) * 100
        : 0;
    final isOverBudget = status.isOverBudget;

    Color progressColor;
    if (isOverBudget) {
      progressColor = context.errorColor;
    } else if (percentage >= 80) {
      progressColor = context.warningColor;
    } else {
      progressColor = context.colorScheme.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Đã chi', style: AppTypography.bodySmall),
            Text(
              '${CurrencyFormatter.formatVND(status.totalSpent)} / ${CurrencyFormatter.formatVND(budget.totalAmount)}',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (percentage / 100).clamp(0.0, 1.0),
          backgroundColor: Colors.grey.shade200,
          color: progressColor,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(
          '${percentage.toStringAsFixed(1)}% spent',
          style: AppTypography.caption.copyWith(
            color: isOverBudget ? context.errorColor : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: context.colorScheme.primary),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.bodySmall),
      ],
    );
  }

  String _getEmptyStateTitle() {
    switch (_selectedFilter) {
      case 'active':
        return 'Chưa có ngân sách đang hoạt động';
      case 'inactive':
        return 'Chưa có ngân sách không hoạt động';
      case 'all':
      default:
        return 'Chưa có ngân sách nào';
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedFilter) {
      case 'active':
        return 'Tạo ngân sách đầu tiên để bắt đầu quản lý chi tiêu!';
      case 'inactive':
        return 'Tất cả ngân sách của bạn đang hoạt động.';
      case 'all':
      default:
        return 'Tạo ngân sách đầu tiên của bạn!';
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: context.errorColor),
          const SizedBox(height: 16),
          Text('Đã xảy ra lỗi', style: AppTypography.h4),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadBudgets, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
