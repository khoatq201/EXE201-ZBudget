import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/savings_service.dart';
import '../../models/savings_models.dart';
import '../../constants/typography.dart';
import '../../utils/theme_extensions.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/currency_input_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../utils/ready_to_assign_dialog.dart';
import '../../widgets/common_header.dart';

class SavingsDetailScreen extends StatefulWidget {
  final String goalId;

  const SavingsDetailScreen({super.key, required this.goalId});

  @override
  State<SavingsDetailScreen> createState() => _SavingsDetailScreenState();
}

class _SavingsDetailScreenState extends State<SavingsDetailScreen> {
  SavingsGoal? _goal;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoalDetails();
  }

  Future<void> _loadGoalDetails() async {
    setState(() {
      _isLoading = true;
    });

    final savingsService = Provider.of<SavingsService>(context, listen: false);
    final goal = await savingsService.getSavingsGoalById(widget.goalId);

    if (mounted) {
      setState(() {
        _goal = goal;
        _isLoading = false;
      });
    }
  }

  Future<void> _showContributeDialog() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đóng góp tiết kiệm'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Số tiền',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: '₫',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = CurrencyFormatter.parse(amountController.text);
              if (amount > 0) {
                Navigator.pop(context);
                await _addContribution(amount, noteController.text);
              }
            },
            child: const Text('Đóng góp'),
          ),
        ],
      ),
    );
  }

  Future<void> _addContribution(double amount, String? note) async {
    final savingsService = Provider.of<SavingsService>(context, listen: false);

    final result = await savingsService.addContribution(
      goalId: widget.goalId,
      amount: amount,
      note: note?.isEmpty == true ? null : note,
    );

    if (!mounted) return;

    // ✅ NEW: Check if error is about insufficient Ready to Assign
    if (result['success'] == false) {
      final errorMessage = result['message'] ?? 'Đã có lỗi xảy ra';

      if (errorMessage.contains('Ready to Assign')) {
        ReadyToAssignDialog.showErrorIfInsufficientFunds(
          context,
          errorMessage,
          'tiết kiệm',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: context.colorScheme.error,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Đã đóng góp thành công'),
          backgroundColor: context.colorScheme.primary,
        ),
      );
      _loadGoalDetails();
    }
  }

  Future<void> _showWithdrawDialog() async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rút tiền tiết kiệm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Số dư hiện tại: ${CurrencyFormatter.formatVND(_goal!.currentAmount)}',
              style: AppTypography.bodySmall.copyWith(
                color: context.settingsItemSubtitleColor,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Số tiền rút',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: '₫',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Lý do (tùy chọn)',
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
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
              if (amount > 0 && amount <= _goal!.currentAmount) {
                Navigator.pop(context);
                await _withdrawFromSavings(amount, reasonController.text);
              } else if (amount > _goal!.currentAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Số tiền rút vượt quá số dư'),
                    backgroundColor: context.colorScheme.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
            ),
            child: const Text('Rút tiền'),
          ),
        ],
      ),
    );
  }

  Future<void> _withdrawFromSavings(double amount, String? reason) async {
    final savingsService = Provider.of<SavingsService>(context, listen: false);

    final result = await savingsService.withdrawFromSavings(
      goalId: widget.goalId,
      amount: amount,
      reason: reason?.isEmpty == true ? null : reason,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Đã rút tiền thành công'),
        backgroundColor: result['success'] == true
            ? context.colorScheme.primary
            : context.colorScheme.error,
      ),
    );

    if (result['success'] == true) {
      _loadGoalDetails();
    }
  }

  Future<void> _deleteGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa mục tiêu'),
        content: const Text('Bạn có chắc chắn muốn xóa mục tiêu này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final savingsService = Provider.of<SavingsService>(
        context,
        listen: false,
      );
      final result = await savingsService.deleteSavingsGoal(widget.goalId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Đã xóa mục tiêu'),
          backgroundColor: result['success'] == true
              ? context.colorScheme.primary
              : context.colorScheme.error,
        ),
      );

      if (result['success'] == true) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Column(
          children: [
            CommonHeaderPresets.detail(
              context: context,
              title: 'Chi tiết mục tiêu',
              subtitle: 'Đang tải...',
            ),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    if (_goal == null) {
      return Scaffold(
        body: Column(
          children: [
            CommonHeaderPresets.detail(
              context: context,
              title: 'Chi tiết mục tiêu',
              subtitle: 'Không tìm thấy',
            ),
            Expanded(
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
                    const Text('Không tìm thấy mục tiêu'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final goal = _goal!;
    final targetDate = DateFormatter.toDisplayFormat(goal.targetDate);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadGoalDetails,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            CommonHeaderPresets.detail(
              context: context,
              title: goal.name,
              subtitle: 'Mục tiêu: $targetDate',
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      context.push('/savings/edit/${widget.goalId}'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteGoal,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProgressCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                  const SizedBox(height: 16),
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  _buildContributionsCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _goal!.progress;
    final isCompleted = _goal!.isCompleted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_goal!.colorValue, _goal!.colorValue.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _goal!.category.icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _goal!.name,
                      style: AppTypography.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _goal!.category.displayName,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Đã tiết kiệm',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatVND(_goal!.currentAmount),
            style: AppTypography.h1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mục tiêu: ${CurrencyFormatter.formatVND(_goal!.targetAmount)}',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress / 100,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
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
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Còn ${CurrencyFormatter.formatVND(_goal!.remaining)}',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showContributeDialog,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Đóng góp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showWithdrawDialog,
            icon: const Icon(Icons.remove_circle_outline),
            label: const Text('Rút tiền'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin',
            style: AppTypography.h4.copyWith(
              color: context.settingsItemTitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            'Ngày mục tiêu',
            DateFormatter.toDisplayFormat(_goal!.targetDate),
            Icons.calendar_today,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'Thời gian còn lại',
            '${_goal!.remainingDaysLocal} ngày',
            Icons.access_time,
          ),
          const Divider(height: 24),
          _buildStatRow('Độ ưu tiên', _goal!.priority.displayName, Icons.flag),
          if (_goal!.description != null) ...[
            const Divider(height: 24),
            _buildStatRow('Mô tả', _goal!.description!, Icons.description),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.settingsItemSubtitleColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: context.settingsItemSubtitleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTypography.bodySmall.copyWith(
                  color: context.settingsItemTitleColor,
                  fontWeight: FontWeight.w500,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContributionsCard() {
    final contributions = _goal!.contributions;
    final withdrawals = _goal!.withdrawals;
    final allTransactions = <dynamic>[...contributions, ...withdrawals]
      ..sort((a, b) => b.date.compareTo(a.date));

    if (allTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: context.settingsItemSubtitleColor.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có giao dịch',
                style: AppTypography.bodySmall.copyWith(
                  color: context.settingsItemSubtitleColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lịch sử giao dịch',
            style: AppTypography.h4.copyWith(
              color: context.settingsItemTitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...allTransactions.map((transaction) {
            if (transaction is Contribution) {
              return _buildTransactionItem(
                icon: Icons.add_circle,
                iconColor: context.colorScheme.primary,
                title: transaction.note ?? 'Đóng góp',
                amount: '+${CurrencyFormatter.formatVND(transaction.amount)}',
                amountColor: context.colorScheme.primary,
                date: DateFormatter.toDisplayFormat(transaction.date),
              );
            } else if (transaction is Withdrawal) {
              return _buildTransactionItem(
                icon: Icons.remove_circle,
                iconColor: context.colorScheme.error,
                title: transaction.reason ?? 'Rút tiền',
                amount: '-${CurrencyFormatter.formatVND(transaction.amount)}',
                amountColor: context.colorScheme.error,
                date: DateFormatter.toDisplayFormat(transaction.date),
              );
            }
            return const SizedBox.shrink();
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    required Color amountColor,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.screenBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.settingsItemTitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: AppTypography.caption.copyWith(
                    color: context.settingsItemSubtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTypography.bodySmall.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
