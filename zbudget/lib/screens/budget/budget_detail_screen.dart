import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/budget.dart';
import '../../services/budget_service.dart';
import '../../constants/typography.dart';
import '../../utils/theme_extensions.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/currency_input_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/common_header.dart';

class BudgetDetailScreen extends StatefulWidget {
  final String budgetId;

  const BudgetDetailScreen({super.key, required this.budgetId});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  Budget? _budget;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    setState(() => _isLoading = true);
    final budgetService = Provider.of<BudgetService>(context, listen: false);
    final budget = await budgetService.getBudgetById(widget.budgetId);
    setState(() {
      _budget = budget;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _budget == null
              ? Column(
                  children: [
                    CommonHeaderPresets.detail(
                      context: context,
                      title: 'Chi tiết ngân sách',
                      subtitle: 'Không tìm thấy',
                    ),
                    Expanded(child: _buildErrorState()),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _loadBudget,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeader(),
                        _buildFundingStatusCard(),
                        _buildSpendingStatusCard(),
                        _buildCategoriesCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final budget = _budget!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.headerGradientStart,
            context.headerGradientEnd,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            budget.name,
            style: AppTypography.h2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '${DateFormatter.toDisplayFormat(budget.period.startDate)} - ${DateFormatter.toDisplayFormat(budget.period.endDate)}',
            style: AppTypography.bodySmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tổng ngân sách', style: AppTypography.caption.copyWith(color: Colors.white70)),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: CurrencyFormatter.format(budget.totalAmount).replaceAll(' ₫', ''),
                          style: AppTypography.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ' ₫',
                          style: AppTypography.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${budget.period.daysRemaining} ngày',
                      style: AppTypography.bodySmall.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFundingStatusCard() {
    final budget = _budget!;
    final fundingStatus = budget.fundingStatus;
    final isFullyFunded = budget.isFullyFunded;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trạng thái funding (YNAB)', style: AppTypography.h4),
              Icon(
                isFullyFunded ? Icons.check_circle : Icons.warning_amber,
                color: isFullyFunded ? Colors.green : context.warningColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Phân bổ', CurrencyFormatter.formatVND(budget.totalAllocated)),
          const SizedBox(height: 8),
          _buildStatRow('Đã fund', CurrencyFormatter.formatVND(budget.totalFunded)),
          const SizedBox(height: 8),
          _buildStatRow(
            'Cần fund thêm',
            CurrencyFormatter.formatVND(budget.needsMoreFunding),
            valueColor: budget.needsMoreFunding > 0 ? context.warningColor : Colors.green,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: fundingStatus.fundingPercentage / 100,
            backgroundColor: Colors.grey.shade200,
            color: isFullyFunded ? Colors.green : context.warningColor,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Text(
            '${fundingStatus.fundingPercentage.toStringAsFixed(1)}% funded',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingStatusCard() {
    final budget = _budget!;
    final status = budget.status;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
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
          Text('Tình hình chi tiêu', style: AppTypography.h4),
          const SizedBox(height: 16),
          _buildStatRow('Đã chi', CurrencyFormatter.formatVND(status.totalSpent)),
          const SizedBox(height: 8),
          _buildStatRow('Còn lại', CurrencyFormatter.formatVND(status.totalRemaining)),
          const SizedBox(height: 8),
          _buildStatRow('Chi trung bình/ngày', CurrencyFormatter.formatVND(status.dailyAverageSpent)),
          const SizedBox(height: 8),
          _buildStatRow('Dự kiến tổng', CurrencyFormatter.formatVND(status.projectedTotal)),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (status.spentPercentage / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            color: status.isOverBudget ? context.errorColor : context.colorScheme.primary,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Text(
            '${status.spentPercentage.toStringAsFixed(1)}% spent',
            style: AppTypography.caption.copyWith(
              color: status.isOverBudget ? context.errorColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesCard() {
    final budget = _budget!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Phân bổ theo danh mục', style: AppTypography.h4),
              Text(
                '${budget.categoryAllocations.length} danh mục',
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...budget.categoryAllocations.map((cat) => _buildCategoryItem(cat)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(CategoryAllocation cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(cat.category.icon, size: 24, color: context.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.category.displayName, style: AppTypography.h5),
                    Text('${cat.percentage.toStringAsFixed(0)}% phân bổ', style: AppTypography.caption),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _showFundDialog(cat),
                tooltip: 'Fund danh mục này',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatRow('Phân bổ', CurrencyFormatter.formatVND(cat.allocated)),
          const SizedBox(height: 4),
          _buildStatRow('Đã fund', CurrencyFormatter.formatVND(cat.funded)),
          const SizedBox(height: 4),
          _buildStatRow('Đã chi', CurrencyFormatter.formatVND(cat.spent)),
          const SizedBox(height: 4),
          _buildStatRow(
            'Có sẵn',
            CurrencyFormatter.formatVND(cat.available),
            valueColor: cat.available >= 0 ? Colors.green : context.errorColor,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: cat.fundingPercentage / 100,
            backgroundColor: Colors.grey.shade200,
            color: cat.isFullyFunded ? Colors.green : context.warningColor,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 4),
          Text(
            cat.isFullyFunded ? 'Fully Funded' : 'Cần fund thêm ${CurrencyFormatter.formatVND(cat.needsMoreFunding)}',
            style: AppTypography.caption.copyWith(
              color: cat.isFullyFunded ? Colors.green : context.warningColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: Colors.grey.shade600)),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Future<void> _showFundDialog(CategoryAllocation cat) async {
    final amountController = TextEditingController();
    final budgetService = Provider.of<BudgetService>(context, listen: false);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fund ${cat.category.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ready to Assign: ${CurrencyFormatter.formatVND(budgetService.readyToAssign)}'),
            const SizedBox(height: 8),
            Text('Cần fund: ${CurrencyFormatter.formatVND(cat.needsMoreFunding)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Số tiền',
                border: OutlineInputBorder(),
                suffixText: '₫',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = CurrencyFormatter.parse(amountController.text);
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Số tiền phải lớn hơn 0')),
                );
                return;
              }

              Navigator.pop(context);

              final result = await budgetService.fundBudgetCategory(
                budgetId: widget.budgetId,
                category: cat.category.value,
                amount: amount,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Thành công'),
                    backgroundColor: result['success'] ? Colors.green : context.errorColor,
                  ),
                );

                if (result['success']) {
                  _loadBudget();
                }
              }
            },
            child: const Text('Fund'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: context.errorColor),
          const SizedBox(height: 16),
          Text('Không tìm thấy ngân sách', style: AppTypography.h4),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }
}
