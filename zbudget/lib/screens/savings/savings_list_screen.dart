import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/savings_service.dart';
import '../../services/subscription_service.dart';
import '../../models/savings_models.dart';
import '../../widgets/premium/upgrade_dialog.dart';
import '../../widgets/premium/premium_paywall.dart';
import '../../constants/typography.dart';
import '../../utils/theme_extensions.dart';
import '../../utils/currency_formatter.dart';

class SavingsListScreen extends StatefulWidget {
  const SavingsListScreen({super.key});

  @override
  State<SavingsListScreen> createState() => _SavingsListScreenState();
}

class _SavingsListScreenState extends State<SavingsListScreen>
    with AutomaticKeepAliveClientMixin {
  String selectedFilter = 'all'; // all, active, completed

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavingsGoals();
    });
  }

  Future<void> _loadSavingsGoals() async {
    final savingsService = Provider.of<SavingsService>(context, listen: false);
    await savingsService.getSavingsGoals();
    await savingsService.getSavingsStats();
  }

  Future<void> _refreshSavings() async {
    return _loadSavingsGoals();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshSavings,
        child: CustomScrollView(
          slivers: [
            // App Bar Header
            _buildHeader(),

            // Stats Overview
            SliverToBoxAdapter(child: _buildStatsOverview()),

            // Filter Tabs
            SliverToBoxAdapter(child: _buildFilterTabs()),

            // Savings Goals List
            _buildSavingsGoalsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Check if user can create savings goal
          final subscriptionService = context.read<SubscriptionService>();
          final savingsService = context.read<SavingsService>();

          // Get current savings goal count
          final goals = savingsService.savingsGoals;
          final activeGoals = goals.where((g) => g.status == 'active').length;

          // Get limits
          final subscription = subscriptionService.subscription;
          final isPremium = subscription?.isPremium ?? false;
          final limit = subscription?.features.maxSavingsGoals ?? 2;

          // Check if can create
          if (!isPremium && activeGoals >= limit) {
            // Show upgrade dialog
            showUpgradeDialog(
              context,
              feature: 'Tạo mục tiêu tiết kiệm',
              reason:
                  'Bạn đã có $activeGoals/$limit mục tiêu đang hoạt động. Nâng cấp Premium để tạo tối đa 10 mục tiêu!',
              onUpgrade: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PremiumPaywallScreen(
                      feature: 'Tạo tối đa 10 mục tiêu tiết kiệm',
                      reason: 'Theo dõi nhiều mục tiêu cùng lúc',
                    ),
                  ),
                );
              },
            );
            return;
          }

          await context.push('/savings/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm mục tiêu'),
        backgroundColor: context.headerGradientStart,
      ),
    );
  }

  Widget _buildHeader() {
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
                    'Tiết kiệm',
                    style: AppTypography.h2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mục tiêu tài chính của bạn',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.savings_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Consumer<SavingsService>(
      builder: (context, savingsService, child) {
        final stats = savingsService.stats;

        if (stats == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.headerGradientStart,
                context.headerGradientEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.headerGradientStart.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng đã tiết kiệm',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.formatVND(stats.totalSaved),
                        style: AppTypography.h2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${stats.overallProgress.toStringAsFixed(1)}%',
                      style: AppTypography.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Đang hoạt động',
                      stats.active.toString(),
                      Icons.play_circle_outline,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Hoàn thành',
                      stats.completed.toString(),
                      Icons.check_circle_outline,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Tổng cộng',
                      stats.total.toString(),
                      Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterButton('Tất cả', 'all'),
          const SizedBox(width: 8),
          _buildFilterButton('Đang hoạt động', 'active'),
          const SizedBox(width: 8),
          _buildFilterButton('Hoàn thành', 'completed'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? context.headerGradientStart
                : context.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? context.headerGradientStart
                  : context.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isSelected ? Colors.white : context.settingsItemTitleColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsGoalsList() {
    return Consumer<SavingsService>(
      builder: (context, savingsService, child) {
        if (savingsService.isLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (savingsService.error != null) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: context.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Có lỗi xảy ra',
                    style: AppTypography.h3.copyWith(
                      color: context.settingsItemTitleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    savingsService.error!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.settingsItemSubtitleColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadSavingsGoals,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        var goals = savingsService.savingsGoals;

        // Apply filter
        if (selectedFilter == 'active') {
          goals = goals
              .where((goal) => goal.status == SavingsStatus.active)
              .toList();
        } else if (selectedFilter == 'completed') {
          goals = goals
              .where((goal) => goal.status == SavingsStatus.completed)
              .toList();
        }

        if (goals.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.savings_outlined,
                    size: 80,
                    color: context.settingsItemSubtitleColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có mục tiêu tiết kiệm',
                    style: AppTypography.h3.copyWith(
                      color: context.settingsItemTitleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tạo mục tiêu đầu tiên của bạn',
                    style: AppTypography.bodySmall.copyWith(
                      color: context.settingsItemSubtitleColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/savings/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm mục tiêu'),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final goal = goals[index];
              return _buildSavingsGoalCard(goal);
            }, childCount: goals.length),
          ),
        );
      },
    );
  }

  Widget _buildSavingsGoalCard(SavingsGoal goal) {
    final progress = goal.progress;
    final isCompleted = goal.isCompleted;

    return GestureDetector(
      onTap: () => context.push('/savings/${goal.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
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
                    color: goal.colorValue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    goal.category.icon,
                    color: goal.colorValue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: AppTypography.h4.copyWith(
                          color: context.settingsItemTitleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.category.displayName,
                        style: AppTypography.caption.copyWith(
                          color: context.settingsItemSubtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.headerGradientStart.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: context.headerGradientStart,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Hoàn thành',
                          style: AppTypography.caption.copyWith(
                            color: context.headerGradientStart,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.formatVND(goal.currentAmount),
                  style: AppTypography.h3.copyWith(
                    color: context.settingsItemTitleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Mục tiêu: ${CurrencyFormatter.formatVND(goal.targetAmount)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.settingsItemSubtitleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.settingsItemSubtitleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          goal.colorValue,
                          goal.colorValue.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.toStringAsFixed(1)}% hoàn thành',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.settingsItemSubtitleColor,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: context.settingsItemSubtitleColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${goal.remainingDaysLocal} ngày',
                      style: AppTypography.bodySmall.copyWith(
                        color: context.settingsItemSubtitleColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
