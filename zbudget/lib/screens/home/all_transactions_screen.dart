import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import '../../utils/theme_extensions.dart';
import '../../models/dashboard.dart';
import '../../services/dashboard_service.dart';
import '../../utils/formatters.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

enum TransactionFilter { all, income, expense }

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  TransactionFilter _selectedFilter = TransactionFilter.all;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  List<Transaction> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    // Schedule the load after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final dashboardService = Provider.of<DashboardService>(context, listen: false);

      // Determine type filter for API
      String typeFilter = 'all';
      switch (_selectedFilter) {
        case TransactionFilter.income:
          typeFilter = 'income';
          break;
        case TransactionFilter.expense:
          typeFilter = 'expense';
          break;
        case TransactionFilter.all:
          typeFilter = 'all';
          break;
      }

      // Call new getAllTransactions API
      final result = await dashboardService.getAllTransactions(
        type: typeFilter,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _allTransactions = result['transactions'] as List<Transaction>;
      });

      debugPrint('✅ Loaded ${_allTransactions.length} transactions');
    } catch (e) {
      debugPrint('❌ Error loading transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải giao dịch: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Transaction> get _filteredTransactions {
    // All filtering is now done on backend
    return _allTransactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Toàn bộ giao dịch'),
        backgroundColor: context.headerGradientStart,
        foregroundColor: context.headerTextColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type filter
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  'Tất cả',
                  TransactionFilter.all,
                  Icons.list,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Thu nhập',
                  TransactionFilter.income,
                  Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Chi tiêu',
                  TransactionFilter.expense,
                  Icons.arrow_upward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date range filter
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: _startDate == null
                      ? 'Từ ngày'
                      : DateFormat('dd/MM/yyyy').format(_startDate!),
                  onTap: () => _selectStartDate(),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  label: _endDate == null
                      ? 'Đến ngày'
                      : DateFormat('dd/MM/yyyy').format(_endDate!),
                  onTap: () => _selectEndDate(),
                ),
              ),
            ],
          ),
          if (_startDate != null || _endDate != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                _loadTransactions(); // Reload without date filter
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Xóa bộ lọc ngày'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TransactionFilter filter, IconData icon) {
    final isSelected = _selectedFilter == filter;
    Color color;

    switch (filter) {
      case TransactionFilter.income:
        color = AppColors.success;
        break;
      case TransactionFilter.expense:
        color = AppColors.error;
        break;
      case TransactionFilter.all:
        color = AppColors.primary500;
        break;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        _loadTransactions(); // Reload with new filter
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : context.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : context.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : context.secondaryTextColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : context.secondaryTextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 16, color: AppColors.primary500),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: context.primaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary500),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
      // Reload if both dates are selected
      if (_endDate != null) {
        _loadTransactions();
      }
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary500),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      // Reload if both dates are selected
      if (_startDate != null) {
        _loadTransactions();
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có giao dịch nào',
            style: AppTypography.h3.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi bộ lọc của bạn',
            style: AppTypography.bodyMedium.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    // Group transactions by date
    final groupedTransactions = <String, List<Transaction>>{};

    for (var transaction in _filteredTransactions) {
      final dateKey = DateFormat('dd/MM/yyyy').format(transaction.date);
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    // Sort date keys in descending order (newest first)
    final sortedDateKeys = groupedTransactions.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('dd/MM/yyyy').parse(a);
        final dateB = DateFormat('dd/MM/yyyy').parse(b);
        return dateB.compareTo(dateA); // Descending order
      });

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDateKeys.length,
        itemBuilder: (context, index) {
          final dateKey = sortedDateKeys[index];
          final transactions = groupedTransactions[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  dateKey,
                  style: AppTypography.h4.copyWith(
                    color: context.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...transactions.map((txn) => _buildTransactionItem(txn)),
              const SizedBox(height: 8),
            ],
          );
        },
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: transaction.isIncome
                  ? AppColors.success.withAlpha(26)
                  : AppColors.error.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: transaction.isIncome ? AppColors.success : AppColors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getCategoryName(transaction.category),
                  style: AppTypography.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction.isIncome
              ? CurrencyFormatter.formatIncome(transaction.amount)
              : CurrencyFormatter.formatExpense(transaction.amount),
            style: AppTypography.h4.copyWith(
              color: transaction.isIncome ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String category) {
    const categoryNames = {
      'food': 'Ăn uống',
      'transport': 'Di chuyển',
      'shopping': 'Mua sắm',
      'entertainment': 'Giải trí',
      'healthcare': 'Y tế',
      'education': 'Giáo dục',
      'utilities': 'Sinh hoạt',
      'salary': 'Lương',
      'freelance': 'Freelance',
      'business': 'Kinh doanh',
      'investment': 'Đầu tư',
      'bonus': 'Thưởng',
      'gift': 'Quà tặng',
      'other': 'Khác',
    };
    return categoryNames[category] ?? category;
  }
}
