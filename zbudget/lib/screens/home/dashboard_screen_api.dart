import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/dashboard_service.dart';
import '../../services/auth_service.dart';
import '../../services/budget_service.dart';
import '../../models/dashboard.dart';
import '../../models/budget.dart';
import '../../constants/typography.dart';
import '../../utils/formatters.dart';
import '../../utils/theme_extensions.dart';
import '../../widgets/floating_ai_button.dart';

class DashboardScreenApi extends StatefulWidget {
  const DashboardScreenApi({super.key});

  @override
  State<DashboardScreenApi> createState() => _DashboardScreenApiState();
}

class _DashboardScreenApiState extends State<DashboardScreenApi>
    with AutomaticKeepAliveClientMixin {
  DateTime? _lastLoadTime;
  Budget? _selectedBudget;
  List<Budget> _activeBudgets = [];
  bool _loadingBudgets = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load budgets first, then dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadActiveBudgets();
      await _loadDashboardData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-reload if coming back after 5 seconds
    if (_lastLoadTime != null) {
      final timeSinceLastLoad = DateTime.now().difference(_lastLoadTime!);
      if (timeSinceLastLoad.inSeconds > 5) {
        _loadDashboardData();
      }
    }
  }

  Future<void> _loadActiveBudgets() async {
    setState(() => _loadingBudgets = true);
    try {
      final budgetService = Provider.of<BudgetService>(context, listen: false);
      await budgetService.getBudgets(status: 'active');
      if (mounted) {
        setState(() {
          _activeBudgets = budgetService.budgets;
          // Auto-select first budget if available and no budget selected
          if (_selectedBudget == null && _activeBudgets.isNotEmpty) {
            _selectedBudget = _activeBudgets.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading budgets: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingBudgets = false);
      }
    }
  }

  Future<void> _loadDashboardData() async {
    _lastLoadTime = DateTime.now();
    final dashboardService = Provider.of<DashboardService>(
      context,
      listen: false,
    );
    try {
      await dashboardService.getDashboardSummary(
        period: 'month',
        budgetId: _selectedBudget?.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    }
  }

  Future<void> _refreshDashboard() async {
    return _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final authService = Provider.of<AuthService>(context);
    final dashboardService = Provider.of<DashboardService>(context);

    return Stack(
      children: [
        Container(
          color: context.screenBackground,
          child: dashboardService.isLoading
              ? const Center(child: CircularProgressIndicator())
              : dashboardService.error != null
              ? _buildErrorView(dashboardService.error!)
              : dashboardService.dashboardData == null
              ? Center(
                  child: Text(
                    'Không có dữ liệu',
                    style: TextStyle(color: context.settingsItemTitleColor),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshDashboard,
                  child: _buildDashboardContent(
                    dashboardService.dashboardData!,
                    authService,
                  ),
                ),
        ),
        const FloatingAiButton(),
      ],
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: context.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: AppTypography.h2.copyWith(
              color: context.settingsItemTitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.settingsItemSubtitleColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadDashboardData,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(DashboardData data, AuthService authService) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(authService),
          _buildBalanceCard(data),
          _buildBudgetSelector(),
          _buildInsights(data.insights),
          _buildBudgetCard(data.budget),
          _buildQuickStats(data),
          const SizedBox(height: 20),
          _buildQuickActions(),
          const SizedBox(height: 20),
          _buildSpendingChart(data.categoryBreakdown, data.period.expense),
          _buildCategoryBreakdown(data.categoryBreakdown),
          _buildRecentTransactions(data.recentTransactions),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeader(AuthService authService) {
    return Container(
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
            children: [
              Text(
                'Xin chào! 👋',
                style: AppTypography.h3.copyWith(
                  color: context.headerTextColor,
                ),
              ),
              Text(
                authService.currentUser?.email ?? '',
                style: AppTypography.bodySmall.copyWith(
                  color: context.headerSubtitleColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colorScheme.onPrimary.withOpacity(0.24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: context.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(DashboardData data) {
    final periodLabel = _getPeriodLabel(data.period.type);
    final periodBalance = data.period.balance;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.headerGradientStart, context.headerGradientEnd],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số dư hiện tại',
            style: AppTypography.bodyMedium.copyWith(
              color: context.headerSubtitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.currentBalance.toVND(),
            style: AppTypography.h1.copyWith(
              color: context.headerTextColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Period Stats Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colorScheme.onPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Thống kê $periodLabel',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.headerSubtitleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thu nhập',
                          style: AppTypography.bodySmall.copyWith(
                            color: context.headerSubtitleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.period.income.toVND(),
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.headerTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Chi tiêu',
                          style: AppTypography.bodySmall.copyWith(
                            color: context.headerSubtitleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.period.expense.toVND(),
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.headerTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      periodBalance >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: periodBalance >= 0
                          ? context.incomeColor
                          : context.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      periodBalance >= 0
                          ? CurrencyFormatter.formatIncome(periodBalance)
                          : CurrencyFormatter.formatExpense(
                              periodBalance.abs(),
                            ),
                      style: AppTypography.bodyLarge.copyWith(
                        color: context.headerTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceItem(
                'Tổng thu',
                data.totalIncome,
                Icons.arrow_downward,
                context.incomeColor,
              ),
              _buildBalanceItem(
                'Tổng chi',
                data.totalExpenses,
                Icons.arrow_upward,
                context.colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'week':
        return 'tuần này';
      case 'year':
        return 'năm nay';
      case 'month':
      default:
        return 'tháng này';
    }
  }

  Widget _buildBalanceItem(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: context.headerSubtitleColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: context.headerSubtitleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount.toVND(),
          style: AppTypography.bodyLarge.copyWith(
            color: context.headerTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSelector() {
    // Don't show selector if still loading or no budgets available
    if (_loadingBudgets || _activeBudgets.isEmpty) {
      return const SizedBox.shrink();
    }

    // Also check if _selectedBudget is valid
    // If selectedBudget is not null but not in the list, reset it
    if (_selectedBudget != null &&
        !_activeBudgets.any((b) => b.id == _selectedBudget!.id)) {
      _selectedBudget = null;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 20,
                color: context.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Ngân sách hiển thị',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.settingsItemTitleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
              color: context.colorScheme.surfaceContainerHighest,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBudget?.id ?? 'none',
                isExpanded: true,
                items: [
                  DropdownMenuItem<String>(
                    value: 'none',
                    child: Text(
                      'Không hiển thị ngân sách',
                      style: AppTypography.body.copyWith(
                        color: context.settingsItemSubtitleColor,
                      ),
                    ),
                  ),
                  ..._activeBudgets.map((budget) {
                    return DropdownMenuItem<String>(
                      value: budget.id,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              budget.name,
                              style: AppTypography.body.copyWith(
                                color: context.settingsItemTitleColor,
                              ),
                            ),
                          ),
                          Text(
                            budget.totalAmount.toVND(),
                            style: AppTypography.bodySmall.copyWith(
                              color: context.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (String? newBudgetId) {
                  setState(() {
                    if (newBudgetId == null || newBudgetId == 'none') {
                      _selectedBudget = null;
                    } else {
                      _selectedBudget = _activeBudgets.firstWhere(
                        (b) => b.id == newBudgetId,
                        orElse: () => _activeBudgets.first,
                      );
                    }
                  });
                  _loadDashboardData(); // Reload dashboard with new budget
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(List<Insight> insights) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin chi tiêu', style: AppTypography.h3),
          const SizedBox(height: 12),
          ...insights.map((insight) => _buildInsightCard(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Insight insight) {
    Color bgColor;
    Color textColor;

    switch (insight.type) {
      case 'success':
        bgColor = context.infoRowBackground;
        textColor = context.incomeColor.withOpacity(0.95);
        break;
      case 'warning':
        bgColor = context.infoRowBackground;
        textColor = context.colorScheme.secondary;
        break;
      case 'alert':
        bgColor = context.infoRowBackground;
        textColor = context.colorScheme.error;
        break;
      default:
        bgColor = context.infoRowBackground;
        textColor = context.colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(insight.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(insight.message, style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          if (insight.action != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleInsightAction(insight.action!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: textColor,
                  foregroundColor: context.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  insight.action!,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleInsightAction(String action) {
    switch (action) {
      case 'Giảm chi tiêu':
      case 'Xem chi tiết':
      case 'Điều chỉnh':
        context.go('/budget');
        break;
      case 'Xem gợi ý':
        context.go('/reports');
        break;
      default:
        // Default action - go to budget page
        context.go('/budget');
    }
  }

  Widget _buildBudgetCard(BudgetInfo? budget) {
    if (budget == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkTheme ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(budget.name, style: AppTypography.h3),
              Text(
                '${budget.spentPercentage}%',
                style: AppTypography.h3.copyWith(
                  color: budget.isOverBudget
                      ? context.colorScheme.error
                      : context.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: budget.spentPercentage / 100,
            backgroundColor: context.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              budget.isOverBudget
                  ? context.colorScheme.error
                  : context.colorScheme.primary,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã chi: ${budget.spent.toVND()}',
                style: AppTypography.bodySmall,
              ),
              Text(
                'Còn lại: ${budget.remaining.toVND()}',
                style: AppTypography.bodySmall.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ngân sách hàng ngày: ${budget.dailyBudget.toVND()}',
            style: AppTypography.bodySmall.copyWith(
              color: context.settingsItemSubtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(DashboardData data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Level',
              data.userStats.level.toString(),
              Icons.star,
              context.colorScheme.secondaryContainer, // accent for stat icon
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Streak',
              '${data.userStats.currentStreak} ngày',
              Icons.local_fire_department,
              context.colorScheme.tertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkTheme ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.h3),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: context.settingsItemSubtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingChart(
    List<CategoryBreakdown> categories,
    double totalExpense,
  ) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkTheme ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chi tiêu theo danh mục', style: AppTypography.h3),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sections: categories.take(5).map((cat) {
                        return PieChartSectionData(
                          value: cat.total,
                          title: '${cat.percentage}%',
                          color: _getCategoryColor(cat.category),
                          radius: 60,
                          titleStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.colorScheme.onSurface,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categories.take(5).map((cat) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(cat.category),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getCategoryName(cat.category),
                                style: AppTypography.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    const categoryColors = {
      'food': Color(0xFFFF6B6B),
      'transport': Color(0xFF4ECDC4),
      'shopping': Color(0xFFFFBE0B),
      'entertainment': Color(0xFFFF006E),
      'healthcare': Color(0xFF8338EC),
      'education': Color(0xFF3A86FF),
      'utilities': Color(0xFFFB5607),
      'other': Color(0xFF6C757D),
    };
    return categoryColors[category] ?? context.colorScheme.onSurfaceVariant;
  }

  Widget _buildCategoryBreakdown(List<CategoryBreakdown> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chi tiêu theo danh mục', style: AppTypography.h3),
          const SizedBox(height: 12),
          ...categories.map((cat) => _buildCategoryItem(cat)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(CategoryBreakdown category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getCategoryName(category.category),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${category.count} giao dịch',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.settingsItemSubtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                category.total.toVND(),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${category.percentage}%',
                style: AppTypography.bodySmall.copyWith(
                  color: context.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<Transaction> transactions) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giao dịch gần đây', style: AppTypography.h3),
              TextButton(
                onPressed: () {
                  // Navigate to all transactions page
                  context.go('/transactions/all');
                },
                child: Text(
                  'Xem tất cả',
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...transactions.map((txn) => _buildTransactionItem(txn)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: transaction.isIncome
                  ? context.incomeColor.withOpacity(0.12)
                  : context.infoRowBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: transaction.isIncome
                  ? context.incomeColor
                  : context.colorScheme.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${transaction.date.day.toString().padLeft(2, '0')}/${transaction.date.month.toString().padLeft(2, '0')}/${transaction.date.year}',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.settingsItemSubtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction.isIncome
                ? CurrencyFormatter.formatIncome(transaction.amount)
                : CurrencyFormatter.formatExpense(transaction.amount),
            style: AppTypography.bodyMedium.copyWith(
              color: transaction.isIncome
                  ? context.incomeColor
                  : context.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thao tác nhanh', style: AppTypography.h3),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Thêm chi tiêu',
                  Icons.add,
                  context.colorScheme.primary,
                  context.primaryTextColor,
                  () async {
                    final result = await context.push('/add-expense');
                    // Refresh dashboard if expense was created successfully
                    if (result == true) {
                      _loadDashboardData();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Thu nhập',
                  Icons.trending_up,
                  context.incomeColor,
                  context.primaryTextColor,
                  () => context.push('/add-income'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Ngân sách',
                  Icons.pie_chart,
                  context.colorScheme.primary,
                  context.primaryTextColor,
                  () => context.go('/budget'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(context.isDarkTheme ? 0.20 : 0.10),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      context.isDarkTheme ? 0.25 : 0.04,
                    ),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 22)),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: context.primaryTextColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(String category) {
    const categoryNames = {
      'food': 'Ăn uống',
      'transport': 'Di chuyển',
      'shopping': 'Mua sắm',
      'entertainment': 'Giải trí',
      'healthcare': 'Sức khỏe',
      'education': 'Giáo dục',
      'utilities': 'Hóa đơn',
      'other': 'Khác',
    };
    return categoryNames[category] ?? category;
  }
}
