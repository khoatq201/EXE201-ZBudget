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

class GroupBudgetListScreen extends StatefulWidget {
  const GroupBudgetListScreen({super.key});

  @override
  State<GroupBudgetListScreen> createState() => _GroupBudgetListScreenState();
}

class _GroupBudgetListScreenState extends State<GroupBudgetListScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  String selectedFilter = 'all';
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    );
    _fabController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupBudgets();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupBudgets() async {
    final service = Provider.of<GroupBudgetService>(context, listen: false);
    await service.getGroupBudgets();
  }

  Future<void> _refreshBudgets() async {
    return _loadGroupBudgets();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _refreshBudgets,
        color: context.colorScheme.primary,
        child: CustomScrollView(
          slivers: [
            _buildModernAppBar(),
            SliverToBoxAdapter(child: const SizedBox(height: 8)),
            SliverToBoxAdapter(child: _buildFilterChips()),
            SliverToBoxAdapter(child: const SizedBox(height: 8)),
            _buildBudgetList(),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _showCreateOptions(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tạo mới', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: context.colorScheme.primary,
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colorScheme.primary,
                context.colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -50,
                bottom: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
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
                            Icons.groups_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ngân sách nhóm',
                              style: AppTypography.h3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Quản lý chi tiêu chung',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _buildFilterChip('all', 'Tất cả', Icons.grid_view_rounded),
          const SizedBox(width: 8),
          _buildFilterChip('active', 'Hoạt động', Icons.play_circle_outline_rounded),
          const SizedBox(width: 8),
          _buildFilterChip('settled', 'Đã thanh toán', Icons.check_circle_outline_rounded),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, IconData icon) {
    final isSelected = selectedFilter == filter;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() => selectedFilter = filter);
          }
        },
        backgroundColor: context.colorScheme.surface,
        selectedColor: context.colorScheme.primaryContainer,
        checkmarkColor: context.colorScheme.primary,
        side: BorderSide(
          color: isSelected
              ? context.colorScheme.primary
              : context.colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildBudgetList() {
    return Consumer<GroupBudgetService>(
      builder: (context, service, child) {
        if (service.isLoading && service.budgets.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (service.error != null) {
          return SliverFillRemaining(
            child: _buildErrorState(service.error!),
          );
        }

        List<GroupBudget> filteredBudgets;
        switch (selectedFilter) {
          case 'active':
            filteredBudgets = service.activeBudgets;
            break;
          case 'settled':
            filteredBudgets = service.settledBudgets;
            break;
          default:
            filteredBudgets = service.budgets;
        }

        if (filteredBudgets.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState());
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 8, AppSpacing.lg, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildModernBudgetCard(filteredBudgets[index], index);
              },
              childCount: filteredBudgets.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernBudgetCard(GroupBudget budget, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              budget.isOverBudget
                  ? Colors.red.shade50
                  : context.colorScheme.primaryContainer.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/group-budgets/${budget.id}'),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.name,
                              style: AppTypography.h5.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                            if (budget.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                budget.description!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      _buildStatusBadge(budget),
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
                          Text(
                            'Đã chi',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(budget.totalSpent),
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: budget.isOverBudget
                                  ? Colors.red.shade700
                                  : context.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 8,
                          child: LinearProgressIndicator(
                            value: (budget.spentPercentage / 100).clamp(0.0, 1.0),
                            backgroundColor: context.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              budget.isOverBudget
                                  ? Colors.red.shade400
                                  : context.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tổng: ${CurrencyFormatter.format(budget.totalBudget)} • ${budget.spentPercentage.toStringAsFixed(1)}%',
                        style: AppTypography.caption.copyWith(
                          color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Footer
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.people_rounded,
                        '${budget.memberCount}',
                        context.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.receipt_long_rounded,
                        '${budget.expenseCount}',
                        Colors.orange,
                      ),
                      const Spacer(),
                      _buildInviteCodeChip(budget.inviteCode),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(GroupBudget budget) {
    Color color;
    IconData icon;

    if (budget.isSettled) {
      color = Colors.green;
      icon = Icons.check_circle_rounded;
    } else if (!budget.isActive) {
      color = Colors.grey;
      icon = Icons.pause_circle_rounded;
    } else if (budget.isOverBudget) {
      color = Colors.red;
      icon = Icons.warning_rounded;
    } else {
      color = context.colorScheme.primary;
      icon = Icons.trending_up_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            budget.statusDisplay,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCodeChip(String code) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Đã sao chép mã: $code'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.colorScheme.primary.withValues(alpha: 0.2),
              context.colorScheme.primary.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_2_rounded,
              size: 14,
              color: context.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              code,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: context.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_rounded,
              size: 64,
              color: context.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có ngân sách nhóm',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo ngân sách mới hoặc tham gia\nbằng mã mời để bắt đầu',
            style: AppTypography.body.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.push('/group-budgets/create'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tạo mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/group-budgets/join'),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Tham gia'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTypography.body.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadGroupBudgets,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  color: context.colorScheme.primary,
                ),
              ),
              title: const Text(
                'Tạo ngân sách mới',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Tạo ngân sách nhóm và mời thành viên'),
              onTap: () {
                Navigator.pop(context);
                context.push('/group-budgets/create');
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.green.shade700,
                ),
              ),
              title: const Text(
                'Tham gia bằng mã',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Nhập mã mời để tham gia ngân sách'),
              onTap: () {
                Navigator.pop(context);
                context.push('/group-budgets/join');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
