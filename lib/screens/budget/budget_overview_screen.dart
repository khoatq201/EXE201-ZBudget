import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import '../../models/budget_models.dart';
import '../../services/expense_service.dart';
import 'budget_edit_screen.dart';
import 'add_expense_from_budget_screen.dart';

class BudgetOverviewScreen extends StatefulWidget {
  const BudgetOverviewScreen({super.key});

  @override
  State<BudgetOverviewScreen> createState() => _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends State<BudgetOverviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  BudgetPeriod selectedPeriod = BudgetPeriod.monthly;
  bool showSmartInsights = true;

  // Sẽ được cập nhật từ ExpenseService
  BudgetData? currentBudget;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _progressController.forward();

    // Khởi tạo ExpenseService và dữ liệu mẫu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expenseService = context.read<ExpenseService>();
      expenseService.initializeSampleBudget();

      setState(() {
        currentBudget = expenseService.getBudgetById('1');
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VND';
  }

  String _getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Ăn uống';
      case ExpenseCategory.transport:
        return 'Di chuyển';
      case ExpenseCategory.shopping:
        return 'Mua sắm';
      case ExpenseCategory.entertainment:
        return 'Giải trí';
      case ExpenseCategory.healthcare:
        return 'Sức khỏe';
      case ExpenseCategory.education:
        return 'Giáo dục';
      case ExpenseCategory.utilities:
        return 'Hóa đơn';
      case ExpenseCategory.other:
        return 'Khác';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi từ ExpenseService
    final expenseService = context.watch<ExpenseService>();
    currentBudget = expenseService.getBudgetById('1');

    if (currentBudget == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final progressPercentage =
        (currentBudget!.spentAmount / currentBudget!.totalAmount) * 100;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                _buildBudgetOverview(progressPercentage),
                _buildCategoryBreakdown(),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary500, AppColors.primary400],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ngân sách của bạn',
                  style: AppTypography.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quản lý tài chính thông minh',
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOverview(double progressPercentage) {
    return GestureDetector(
      onTap: () {
        if (currentBudget != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BudgetEditScreen(budget: currentBudget!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                Text(
                  currentBudget!.name,
                  style: AppTypography.h4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Đang hoạt động',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        (progressPercentage / 100) * _progressAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: progressPercentage > 80
                              ? [
                                  const Color(0xFFFF6B6B),
                                  const Color(0xFFFF8E8E),
                                ]
                              : [AppColors.primary500, AppColors.primary400],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatCurrency(currentBudget!.spentAmount),
                      style: AppTypography.h4.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Đã chi',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(
                        currentBudget!.totalAmount - currentBudget!.spentAmount,
                      ),
                      style: AppTypography.h4.copyWith(
                        color: AppColors.primary500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Còn lại',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${progressPercentage.toInt()}% / ${formatCurrency(currentBudget!.totalAmount)}',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân bổ theo danh mục',
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...currentBudget!.categories.map((category) {
            final progress = category.spentAmount / category.allocatedAmount;
            return _buildCategoryItem(category, progress);
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BudgetCategoryData category, double progress) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getCategoryName(category.category),
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(category.spentAmount),
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '/ ${formatCurrency(category.allocatedAmount)}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: category.color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 1.0 ? Colors.red : category.color,
            ),
          ),
          if (progress > 1.0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Vượt ngân sách ${((progress - 1) * 100).toInt()}%',
                style: AppTypography.caption.copyWith(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (currentBudget != null) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddExpenseFromBudgetScreen(
                            budgetId: currentBudget!.id,
                          ),
                        ),
                      );

                      // Refresh dữ liệu nếu có thay đổi
                      if (result == true && mounted) {
                        setState(() {
                          // Widget sẽ rebuild và lấy dữ liệu mới từ ExpenseService
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add),
                      const SizedBox(width: 8),
                      Text(
                        'Thêm chi tiêu',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Xem báo cáo chi tiết')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary500,
                    side: BorderSide(color: AppColors.primary500),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.analytics),
                      const SizedBox(width: 8),
                      Text(
                        'Báo cáo',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
