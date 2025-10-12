import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/group_budget_service.dart';
import '../../models/group_budget.dart';
import '../../constants/typography.dart';
import '../../constants/spacing.dart';
import '../../utils/theme_extensions.dart';
import '../../utils/currency_formatter.dart';

class SettlementScreen extends StatefulWidget {
  final String budgetId;

  const SettlementScreen({
    super.key,
    required this.budgetId,
  });

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  List<Map<String, dynamic>>? _settlementPlan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettlementPlan();
  }

  Future<void> _loadSettlementPlan() async {
    setState(() => _isLoading = true);
    try {
      final service = Provider.of<GroupBudgetService>(context, listen: false);
      final plan = await service.getSettlementPlan(widget.budgetId);
      setState(() {
        _settlementPlan = plan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _recordPayment(String toUserId, double amount) async {
    try {
      final service = Provider.of<GroupBudgetService>(context, listen: false);
      final result = await service.recordPayment(
        budgetId: widget.budgetId,
        toUserId: toUserId,
        amount: amount,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ghi nhận thanh toán thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload settlement plan
        _loadSettlementPlan();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showPaymentDialog(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${payment['fromName']} trả ${payment['toName']}:'),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(payment['amount']),
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn có chắc chắn muốn ghi nhận khoản thanh toán này?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _recordPayment(
                payment['toUserId'],
                payment['amount'].toDouble(),
              );
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phương án thanh toán'),
        backgroundColor: context.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<GroupBudgetService>(
        builder: (context, service, child) {
          final budget = service.currentBudget;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (budget != null) _buildBalanceOverview(budget),
              const SizedBox(height: AppSpacing.xl),
              _buildSettlementPlan(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceOverview(GroupBudget budget) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng quan cân đối',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...budget.members.map((member) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(member.name),
                      Text(
                        member.balance >= 0
                            ? '+${CurrencyFormatter.format(member.balance)}'
                            : CurrencyFormatter.format(member.balance),
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
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementPlan() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_settlementPlan == null || _settlementPlan!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green.shade400,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Tất cả đã thanh toán!',
                style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Không có khoản nợ nào cần thanh toán',
                style: AppTypography.body.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phương án thanh toán tối ưu',
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Chỉ cần ${_settlementPlan!.length} giao dịch để thanh toán hết',
          style: AppTypography.bodySmall.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._settlementPlan!.map((payment) => _buildPaymentCard(payment)),
      ],
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _showPaymentDialog(payment),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    payment['fromName'][0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          payment['fromName'],
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          payment['toName'],
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(payment['amount']),
                      style: AppTypography.h6.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: context.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
