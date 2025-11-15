import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import '../../utils/theme_extensions.dart';
import '../../widgets/scan_receipt_modal.dart';
import '../../widgets/premium/usage_progress_widget.dart';
import '../../widgets/premium/upgrade_dialog.dart';
import '../../widgets/premium/premium_paywall.dart';
import '../../models/expense.dart';
import '../../models/budget.dart';
import '../../services/expense_service.dart';
import '../../services/budget_service.dart';
import '../../services/subscription_service.dart';
import '../../utils/formatters.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/ready_to_assign_dialog.dart';

class CategoryOption {
  final String id;
  final ExpenseCategory category;
  final String name;
  final String icon;
  final Color color;

  CategoryOption({
    required this.id,
    required this.category,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class PaymentMethodOption {
  final String id;
  final String name;
  final String icon;
  final Color color;

  PaymentMethodOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with TickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  ExpenseCategory? _selectedCategory;
  PaymentMethodOption? _selectedPaymentMethod;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Budget? _selectedBudget;
  List<Budget> _activeBudgets = [];
  bool _loadingBudgets = false;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<CategoryOption> categoryOptions = [
    CategoryOption(
      id: '1',
      category: ExpenseCategory.food,
      name: 'Ăn uống',
      icon: '🍜',
      color: AppColors.primary500,
    ),
    CategoryOption(
      id: '2',
      category: ExpenseCategory.transport,
      name: 'Di chuyển',
      icon: '🚗',
      color: AppColors.secondary500,
    ),
    CategoryOption(
      id: '3',
      category: ExpenseCategory.shopping,
      name: 'Mua sắm',
      icon: '🛍️',
      color: AppColors.accent500,
    ),
    CategoryOption(
      id: '4',
      category: ExpenseCategory.entertainment,
      name: 'Giải trí',
      icon: '🎬',
      color: AppColors.primary600,
    ),
    CategoryOption(
      id: '5',
      category: ExpenseCategory.healthcare,
      name: 'Y tế',
      icon: '🏥',
      color: AppColors.error,
    ),
    CategoryOption(
      id: '6',
      category: ExpenseCategory.education,
      name: 'Giáo dục',
      icon: '📚',
      color: AppColors.secondary600,
    ),
    CategoryOption(
      id: '7',
      category: ExpenseCategory.utilities,
      name: 'Tiện ích',
      icon: '💡',
      color: AppColors.warning,
    ),
    CategoryOption(
      id: '8',
      category: ExpenseCategory.other,
      name: 'Khác',
      icon: '💰',
      color: AppColors.dark500,
    ),
  ];

  final List<PaymentMethodOption> paymentMethods = [
    PaymentMethodOption(
      id: 'momo',
      name: 'MoMo',
      icon: '🎯',
      color: const Color(0xFFD82D8B),
    ),
    PaymentMethodOption(
      id: 'other', // zalopay -> other (not in API enum)
      name: 'ZaloPay',
      icon: '💙',
      color: const Color(0xFF0068FF),
    ),
    PaymentMethodOption(
      id: 'cash',
      name: 'Tiền mặt',
      icon: '💰',
      color: const Color(0xFF4CAF50),
    ),
    PaymentMethodOption(
      id: 'banking',
      name: 'Chuyển khoản',
      icon: '🏦',
      color: const Color(0xFFFF9800),
    ),
    PaymentMethodOption(
      id: 'card',
      name: 'Thẻ',
      icon: '💳',
      color: const Color(0xFF9C27B0),
    ),
    PaymentMethodOption(
      id: 'other', // viettelpay -> other (not in API enum)
      name: 'ViettelPay',
      icon: '📱',
      color: const Color(0xFFFF5722),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    // Load subscription usage stats for OCR progress display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionService>().getUsage();
    });

    _slideController.forward();
    _fadeController.forward();
    _loadActiveBudgets();
  }

  Future<void> _loadActiveBudgets() async {
    setState(() => _loadingBudgets = true);
    try {
      final budgetService = Provider.of<BudgetService>(context, listen: false);
      await budgetService.getBudgets(status: 'active');
      if (mounted) {
        setState(() {
          _activeBudgets = budgetService.budgets;
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

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildScanReceiptBanner(),
                        const SizedBox(height: 24),
                        _buildAmountInput(),
                        const SizedBox(height: 24),
                        _buildCategorySelection(),
                        const SizedBox(height: 24),
                        _buildPaymentMethodSelection(),
                        const SizedBox(height: 24),
                        _buildDateSelection(),
                        const SizedBox(height: 24),
                        _buildBudgetSelection(),
                        const SizedBox(height: 24),
                        _buildNoteInput(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Bottom Button
                _buildBottomButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.headerGradientStart, context.headerGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: context.headerGradientStart.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.headerTextColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back,
                color: context.headerTextColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thêm chi tiêu',
                  style: AppTypography.h2.copyWith(
                    color: context.headerTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Ghi lại khoản chi tiêu của bạn',
                  style: AppTypography.body.copyWith(
                    color: context.headerSubtitleColor,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showScanReceiptModal,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.headerTextColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.headerTextColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: context.headerTextColor,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quét HĐ',
                    style: AppTypography.caption.copyWith(
                      color: context.headerTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanReceiptBanner() {
    return Consumer<SubscriptionService>(
      builder: (context, subscriptionService, child) {
        final usageStats = subscriptionService.usageStats;
        final isPremium = subscriptionService.isPremium;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary500.withValues(alpha: 0.1),
                    AppColors.accent500.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary500.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quét hóa đơn thông minh',
                          style: AppTypography.body.copyWith(
                            color: context.primaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (usageStats == null)
                          Text(
                            'Đang tải...',
                            style: AppTypography.caption.copyWith(
                              color: context.secondaryTextColor,
                            ),
                          )
                        else if (isPremium)
                          Text(
                            'Unlimited - Premium ⭐',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accent500,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Free: ${usageStats.ocr.count}/${usageStats.ocr.limit} lần/ngày',
                                style: AppTypography.caption.copyWith(
                                  color: context.secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              CompactUsageProgress(
                                current: usageStats.ocr.count,
                                limit: usageStats.ocr.limit,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showScanReceiptModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Quét ngay',
                        style: AppTypography.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Số tiền *',
          style: AppTypography.h4.copyWith(
            color: context.primaryTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CurrencyInputFormatter(),
            ],
            style: AppTypography.h3.copyWith(
              color: context.primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: AppTypography.h3.copyWith(
                color: context.tertiaryTextColor,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'VNĐ',
                  style: AppTypography.body.copyWith(
                    color: AppColors.primary500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh mục *',
          style: AppTypography.h4.copyWith(
            color: context.primaryTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: categoryOptions.length,
          itemBuilder: (context, index) {
            final category = categoryOptions[index];
            final isSelected = _selectedCategory == category.category;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category.category;
                });
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? category.color : context.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? category.color : context.cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: category.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(category.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      category.name,
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? Colors.white
                            : context.secondaryTextColor,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phương thức thanh toán *',
          style: AppTypography.h4.copyWith(
            color: context.primaryTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: paymentMethods.map((method) {
            final isSelected = _selectedPaymentMethod?.id == method.id;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = method;
                });
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? method.color : context.cardBackground,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? method.color : context.cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: method.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(method.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      method.name,
                      style: AppTypography.body.copyWith(
                        color: isSelected
                            ? Colors.white
                            : context.primaryTextColor,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ngày chi tiêu',
          style: AppTypography.h4.copyWith(
            color: context.primaryTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppColors.primary500,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null && picked != _selectedDate) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primary500,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: AppTypography.body.copyWith(
                    color: context.primaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: context.secondaryTextColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ngân sách',
              style: AppTypography.h4.copyWith(
                color: context.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tùy chọn',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _loadingBudgets
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : _activeBudgets.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: context.tertiaryTextColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chưa có ngân sách nào. Chi tiêu sẽ không được link với ngân sách.',
                          style: AppTypography.caption.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : DropdownButton<Budget>(
                  value: _selectedBudget,
                  isExpanded: true,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Text(
                      'Chọn ngân sách (không bắt buộc)',
                      style: AppTypography.body.copyWith(
                        color: context.tertiaryTextColor,
                      ),
                    ),
                  ),
                  underline: const SizedBox(),
                  items: _activeBudgets.map((budget) {
                    return DropdownMenuItem<Budget>(
                      value: budget,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.name,
                              style: AppTypography.body.copyWith(
                                color: context.primaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_selectedCategory != null) ...[
                              const SizedBox(height: 4),
                              _buildCategoryAvailableInfo(budget),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (Budget? budget) {
                    setState(() {
                      _selectedBudget = budget;
                    });
                  },
                ),
        ),
        if (_selectedBudget != null && _selectedCategory != null) ...[
          const SizedBox(height: 12),
          _buildSelectedBudgetInfo(),
        ],
      ],
    );
  }

  Widget _buildCategoryAvailableInfo(Budget budget) {
    final categoryStr = _selectedCategory.toString().split('.').last;
    final allocation = budget.categoryAllocations.firstWhere(
      (a) => a.category.value == categoryStr,
      orElse: () => budget.categoryAllocations.first,
    );

    return Text(
      'Có sẵn: ${CurrencyFormatter.formatVND(allocation.available)}',
      style: AppTypography.caption.copyWith(
        color: allocation.available > 0 ? AppColors.success : AppColors.error,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSelectedBudgetInfo() {
    final categoryStr = _selectedCategory.toString().split('.').last;
    final allocation = _selectedBudget!.categoryAllocations.firstWhere(
      (a) => a.category.value == categoryStr,
      orElse: () => _selectedBudget!.categoryAllocations.first,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary500, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chi tiêu sẽ trừ từ "${_selectedBudget!.name}". Có sẵn: ${CurrencyFormatter.formatVND(allocation.available)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ghi chú',
          style: AppTypography.h4.copyWith(
            color: context.primaryTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 3,
            style: AppTypography.body.copyWith(color: context.primaryTextColor),
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú cho khoản chi tiêu này...',
              hintStyle: AppTypography.body.copyWith(
                color: context.tertiaryTextColor,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final isValid =
        _amountController.text.isNotEmpty &&
        _selectedCategory != null &&
        _selectedPaymentMethod != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isValid && !_isLoading ? _handleSaveExpense : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              disabledBackgroundColor: AppColors.dark200,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Lưu chi tiêu',
                    style: AppTypography.h4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _showScanReceiptModal() async {
    // Check subscription service for OCR quota
    final subscriptionService = context.read<SubscriptionService>();

    // Refresh usage stats to get latest data
    await subscriptionService.getUsage();

    final canUseOCR = await subscriptionService.canUseOCR();
    final usageStats = subscriptionService.usageStats;
    final isPremium = subscriptionService.isPremium;

    if (!canUseOCR && !isPremium) {
      // Show quota exceeded dialog
      if (!mounted) return;

      final ocrUsage = usageStats?.ocr;
      showUpgradeDialog(
        context,
        feature: 'Quét hóa đơn',
        reason: ocrUsage != null
            ? 'Bạn đã sử dụng ${ocrUsage.count}/${ocrUsage.limit} lần quét hôm nay. Nâng cấp Premium để quét không giới hạn!'
            : 'Bạn đã hết quota quét hóa đơn hôm nay. Nâng cấp Premium để tiếp tục!',
        onUpgrade: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PremiumPaywallScreen(
                feature: 'Quét hóa đơn không giới hạn',
                reason: 'Nâng cấp để sử dụng tính năng OCR không giới hạn',
              ),
            ),
          );
        },
      );
      return;
    }

    // Show scan modal
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ScanReceiptModal(
        onReceiptScanned: (receiptData) {
          // Close dialog first using dialog context
          Navigator.of(dialogContext).pop();
          // Then fill form
          _handleReceiptScanned(receiptData);
        },
        onClose: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  void _handleReceiptScanned(Map<String, dynamic> receiptData) {
    debugPrint('📸 [ADD EXPENSE] Receipt scanned callback received!');
    debugPrint('📸 [ADD EXPENSE] Receipt data: $receiptData');

    // Refresh usage stats to show updated count
    context.read<SubscriptionService>().getUsage();

    // Auto-fill form with scanned data
    setState(() {
      debugPrint('📸 [ADD EXPENSE] Starting setState to fill form...');

      // Format amount with currency formatter
      _amountController.text = CurrencyFormatter.formatVND(
        receiptData['amount'],
      );
      debugPrint('📸 [ADD EXPENSE] Amount filled: ${_amountController.text}');

      // Map category from receipt to our enum
      switch (receiptData['category']) {
        case 'food':
          _selectedCategory = ExpenseCategory.food;
          break;
        case 'transport':
          _selectedCategory = ExpenseCategory.transport;
          break;
        case 'healthcare':
          _selectedCategory = ExpenseCategory.healthcare;
          break;
        case 'shopping':
          _selectedCategory = ExpenseCategory.shopping;
          break;
        case 'entertainment':
          _selectedCategory = ExpenseCategory.entertainment;
          break;
        case 'utilities':
          _selectedCategory = ExpenseCategory.utilities;
          break;
        case 'education':
          _selectedCategory = ExpenseCategory.education;
          break;
        default:
          _selectedCategory = ExpenseCategory.other;
      }

      // Auto-fill note with merchant and description (clean Vietnamese characters)
      String noteText = '';
      if (receiptData['merchant'] != null &&
          receiptData['merchant'].toString().isNotEmpty) {
        noteText += 'Store: ${receiptData['merchant']}';
      }
      if (receiptData['description'] != null &&
          receiptData['description'].toString().isNotEmpty) {
        if (noteText.isNotEmpty) noteText += '\n';
        noteText += 'Description: ${receiptData['description']}';
      }
      if (receiptData['items'] != null &&
          (receiptData['items'] as List).isNotEmpty) {
        if (noteText.isNotEmpty) noteText += '\n';
        noteText += 'Items: ${(receiptData['items'] as List).join(', ')}';
      }
      _noteController.text = noteText;
      debugPrint('📸 [ADD EXPENSE] Note filled: $noteText');

      // Set default payment method to cash for scanned receipts
      _selectedPaymentMethod = paymentMethods.firstWhere(
        (method) => method.id == 'cash',
        orElse: () => paymentMethods.first,
      );
      debugPrint('📸 [ADD EXPENSE] Payment method set to cash');
    });
    debugPrint('📸 [ADD EXPENSE] setState completed, form filled successfully');

    // Show success message after form is filled (dialog already closed by caller)
    debugPrint('📸 [ADD EXPENSE] Showing success SnackBar...');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Đã quét hóa đơn! (${receiptData['confidence']}% chính xác)\nVui lòng kiểm tra và xác nhận thông tin.',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    // NOTE: Removed auto-submit - let user review and manually submit
    // Users can now check the OCR results before saving
  }

  Future<void> _handleSaveExpense() async {
    if (!mounted) return;

    debugPrint('🚀 [ADD_EXPENSE] Starting save expense...');

    setState(() {
      _isLoading = true;
    });

    try {
      final expenseService = Provider.of<ExpenseService>(
        context,
        listen: false,
      );

      // Get category name for title
      final categoryName = categoryOptions
          .firstWhere((opt) => opt.category == _selectedCategory)
          .name;

      // Convert amount to double (parse formatted currency string)
      final amount = CurrencyFormatter.parse(_amountController.text);

      // Convert category enum to string (lowercase)
      final categoryStr = _selectedCategory.toString().split('.').last;

      // Get payment method id (already mapped to valid API values)
      final paymentMethodStr = _selectedPaymentMethod!.id;

      debugPrint('📝 [ADD_EXPENSE] Preparing data:');
      debugPrint('   - Title: $categoryName');
      debugPrint('   - Amount: $amount');
      debugPrint('   - Category: $categoryStr');
      debugPrint('   - Payment: $paymentMethodStr');
      debugPrint('   - Date: $_selectedDate');
      debugPrint('   - Budget: ${_selectedBudget?.name ?? "None"}');

      // Create expense via API
      debugPrint('🌐 [ADD_EXPENSE] Calling API...');
      await expenseService.createExpense(
        title: categoryName,
        description: _noteController.text.isNotEmpty
            ? _noteController.text
            : null,
        amount: amount,
        category: categoryStr,
        paymentMethod: paymentMethodStr,
        date: _selectedDate,
        budgetId: _selectedBudget?.id,
      );

      debugPrint('✅ [ADD_EXPENSE] API call successful!');

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Chi tiêu đã được lưu thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Navigate back
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e, stackTrace) {
      debugPrint('❌ [ADD_EXPENSE] Error occurred: $e');
      debugPrint('📍 [ADD_EXPENSE] Stack trace: $stackTrace');

      if (!mounted) return;

      // Extract error message
      String errorMessage = 'Đã có lỗi xảy ra';
      if (e.toString().contains('Exception:')) {
        errorMessage = e.toString().replaceFirst('Exception:', '').trim();
      } else if (e.toString().contains('No access token')) {
        errorMessage = 'Vui lòng đăng nhập lại';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Kết nối quá chậm, vui lòng thử lại';
      }

      debugPrint('💬 [ADD_EXPENSE] Showing error to user: $errorMessage');

      // ✅ NEW: Check if error is about insufficient Ready to Assign
      if (errorMessage.contains('Ready to Assign')) {
        ReadyToAssignDialog.showErrorIfInsufficientFunds(
          context,
          errorMessage,
          'chi tiêu',
        );
      } else {
        // Show generic error as SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      debugPrint('🏁 [ADD_EXPENSE] Finished (loading = false)');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
