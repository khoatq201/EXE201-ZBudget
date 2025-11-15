import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/typography.dart';
import '../../services/budget_service.dart';
import '../../services/subscription_service.dart';
import '../../models/budget.dart' as budget_model;
import '../../utils/currency_input_formatter.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/theme_extensions.dart';
import '../settings/subscription_settings_screen.dart';

enum BudgetPeriod { daily, weekly, monthly, yearly }

enum ExpenseCategory {
  food,
  transport,
  utilities,
  shopping,
  entertainment,
  healthcare,
  education,
  other,
}

class CategoryBudget {
  final ExpenseCategory category;
  final String name;
  final String icon;
  final Color color;
  int allocatedAmount;
  double percentage;
  bool isSelected;
  final String priority;
  TextEditingController? _percentageController;

  CategoryBudget({
    required this.category,
    required this.name,
    required this.icon,
    required this.color,
    required this.allocatedAmount,
    required this.percentage,
    required this.isSelected,
    required this.priority,
  });

  TextEditingController get percentageController {
    _percentageController ??= TextEditingController(
      text: percentage.toStringAsFixed(0),
    );
    return _percentageController!;
  }

  void dispose() {
    _percentageController?.dispose();
  }
}

class BudgetTemplate {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int totalAmount;
  final BudgetPeriod period;
  final List<CategoryBudget> categories;

  BudgetTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.totalAmount,
    required this.period,
    required this.categories,
  });
}

class CreateBudgetScreen extends StatefulWidget {
  const CreateBudgetScreen({super.key});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen>
    with TickerProviderStateMixin {
  final TextEditingController _budgetNameController = TextEditingController();
  final TextEditingController _totalBudgetController = TextEditingController();
  final TextEditingController _monthlyIncomeController =
      TextEditingController();

  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  String? _selectedTemplateId;
  bool _autoSaving = true;
  bool _emergencyFund = true;
  bool _smartAlerts = true;
  bool _weeklyReview = false;
  bool _isLoading = false;

  // Custom date selection
  bool _useCustomDates = false;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Year selection for yearly budget
  int _selectedYear = DateTime.now().year;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  List<CategoryBudget> _categories = [
    CategoryBudget(
      category: ExpenseCategory.food,
      name: 'Ăn uống',
      icon: '🍽️',
      color: const Color(0xFFFF6B6B),
      allocatedAmount: 0,
      percentage: 30,
      isSelected: true,
      priority: 'high',
    ),
    CategoryBudget(
      category: ExpenseCategory.transport,
      name: 'Di chuyển',
      icon: '🚗',
      color: const Color(0xFF4ECDC4),
      allocatedAmount: 0,
      percentage: 15,
      isSelected: true,
      priority: 'high',
    ),
    CategoryBudget(
      category: ExpenseCategory.utilities,
      name: 'Tiện ích',
      icon: '💡',
      color: const Color(0xFFFFD93D),
      allocatedAmount: 0,
      percentage: 10,
      isSelected: true,
      priority: 'high',
    ),
    CategoryBudget(
      category: ExpenseCategory.shopping,
      name: 'Mua sắm',
      icon: '🛍️',
      color: const Color(0xFF45B7D1),
      allocatedAmount: 0,
      percentage: 15,
      isSelected: false,
      priority: 'medium',
    ),
    CategoryBudget(
      category: ExpenseCategory.entertainment,
      name: 'Giải trí',
      icon: '🎮',
      color: const Color(0xFF96CEB4),
      allocatedAmount: 0,
      percentage: 10,
      isSelected: false,
      priority: 'medium',
    ),
    CategoryBudget(
      category: ExpenseCategory.healthcare,
      name: 'Y tế',
      icon: '🏥',
      color: const Color(0xFFDDA0DD),
      allocatedAmount: 0,
      percentage: 5,
      isSelected: false,
      priority: 'medium',
    ),
    CategoryBudget(
      category: ExpenseCategory.education,
      name: 'Giáo dục',
      icon: '📚',
      color: const Color(0xFF87CEEB),
      allocatedAmount: 0,
      percentage: 10,
      isSelected: false,
      priority: 'low',
    ),
    CategoryBudget(
      category: ExpenseCategory.other,
      name: 'Khác',
      icon: '📝',
      color: const Color(0xFFD3D3D3),
      allocatedAmount: 0,
      percentage: 5,
      isSelected: false,
      priority: 'low',
    ),
  ];

  final List<BudgetTemplate> _vietnameseBudgetTemplates = [
    BudgetTemplate(
      id: 'student',
      name: 'Sinh viên Việt Nam',
      description: 'Ngân sách phù hợp cho sinh viên với tiền trợ cấp',
      icon: '🎓',
      totalAmount: 3000000,
      period: BudgetPeriod.monthly,
      categories: [
        CategoryBudget(
          category: ExpenseCategory.food,
          name: 'Ăn uống',
          icon: '🍽️',
          color: const Color(0xFFFF6B6B),
          allocatedAmount: 1200000,
          percentage: 40,
          isSelected: true,
          priority: 'high',
        ),
        CategoryBudget(
          category: ExpenseCategory.transport,
          name: 'Di chuyển',
          icon: '🚗',
          color: const Color(0xFF4ECDC4),
          allocatedAmount: 450000,
          percentage: 15,
          isSelected: true,
          priority: 'high',
        ),
        CategoryBudget(
          category: ExpenseCategory.education,
          name: 'Học tập',
          icon: '📚',
          color: const Color(0xFF87CEEB),
          allocatedAmount: 600000,
          percentage: 20,
          isSelected: true,
          priority: 'high',
        ),
        CategoryBudget(
          category: ExpenseCategory.entertainment,
          name: 'Giải trí',
          icon: '🎮',
          color: const Color(0xFF96CEB4),
          allocatedAmount: 450000,
          percentage: 15,
          isSelected: true,
          priority: 'medium',
        ),
        CategoryBudget(
          category: ExpenseCategory.other,
          name: 'Khác',
          icon: '📝',
          color: const Color(0xFFD3D3D3),
          allocatedAmount: 300000,
          percentage: 10,
          isSelected: true,
          priority: 'low',
        ),
      ],
    ),
    BudgetTemplate(
      id: 'office_worker',
      name: 'Nhân viên văn phòng',
      description: 'Dành cho người lao động có thu nhập ổn định',
      icon: '💼',
      totalAmount: 8000000,
      period: BudgetPeriod.monthly,
      categories: [
        CategoryBudget(
          category: ExpenseCategory.food,
          name: 'Ăn uống',
          icon: '🍽️',
          color: const Color(0xFFFF6B6B),
          allocatedAmount: 2400000,
          percentage: 30,
          isSelected: true,
          priority: 'high',
        ),
        CategoryBudget(
          category: ExpenseCategory.transport,
          name: 'Di chuyển',
          icon: '🚗',
          color: const Color(0xFF4ECDC4),
          allocatedAmount: 1200000,
          percentage: 15,
          isSelected: true,
          priority: 'high',
        ),
        CategoryBudget(
          category: ExpenseCategory.utilities,
          name: 'Tiện ích',
          icon: '💡',
          color: const Color(0xFFFFD93D),
          allocatedAmount: 800000,
          percentage: 10,
          isSelected: true,
          priority: 'high',
        ),
        CategoryBudget(
          category: ExpenseCategory.shopping,
          name: 'Mua sắm',
          icon: '🛍️',
          color: const Color(0xFF45B7D1),
          allocatedAmount: 1200000,
          percentage: 15,
          isSelected: true,
          priority: 'medium',
        ),
        CategoryBudget(
          category: ExpenseCategory.entertainment,
          name: 'Giải trí',
          icon: '🎮',
          color: const Color(0xFF96CEB4),
          allocatedAmount: 800000,
          percentage: 10,
          isSelected: true,
          priority: 'medium',
        ),
        CategoryBudget(
          category: ExpenseCategory.healthcare,
          name: 'Y tế',
          icon: '🏥',
          color: const Color(0xFFDDA0DD),
          allocatedAmount: 800000,
          percentage: 10,
          isSelected: true,
          priority: 'medium',
        ),
        CategoryBudget(
          category: ExpenseCategory.other,
          name: 'Khác',
          icon: '📝',
          color: const Color(0xFFD3D3D3),
          allocatedAmount: 800000,
          percentage: 10,
          isSelected: true,
          priority: 'low',
        ),
      ],
    ),
    BudgetTemplate(
      id: 'family',
      name: 'Gia đình 4 người',
      description: 'Ngân sách cho gia đình Việt Nam hiện đại',
      icon: '👨‍👩‍👧‍👦',
      totalAmount: 15000000,
      period: BudgetPeriod.monthly,
      categories: [
        CategoryBudget(
          category: ExpenseCategory.food,
          name: 'Ăn uống',
          icon: '🍽️',
          color: const Color(0xFFFF6B6B),
          allocatedAmount: 4500000,
          percentage: 30,
          isSelected: true,
          priority: 'high',
        ),
        CategoryBudget(
          category: ExpenseCategory.education,
          name: 'Giáo dục con em',
          icon: '📚',
          color: const Color(0xFF87CEEB),
          allocatedAmount: 3000000,
          percentage: 20,
          isSelected: true,
          priority: 'high',
        ),
        CategoryBudget(
          category: ExpenseCategory.utilities,
          name: 'Tiện ích',
          icon: '💡',
          color: const Color(0xFFFFD93D),
          allocatedAmount: 1500000,
          percentage: 10,
          isSelected: true,
          priority: 'high',
        ),
        CategoryBudget(
          category: ExpenseCategory.transport,
          name: 'Di chuyển',
          icon: '🚗',
          color: const Color(0xFF4ECDC4),
          allocatedAmount: 2250000,
          percentage: 15,
          isSelected: true,
          priority: 'high',
        ),
        CategoryBudget(
          category: ExpenseCategory.healthcare,
          name: 'Y tế',
          icon: '🏥',
          color: const Color(0xFFDDA0DD),
          allocatedAmount: 1500000,
          percentage: 10,
          isSelected: true,
          priority: 'medium',
        ),
        CategoryBudget(
          category: ExpenseCategory.entertainment,
          name: 'Giải trí',
          icon: '🎮',
          color: const Color(0xFF96CEB4),
          allocatedAmount: 1125000,
          percentage: 7.5,
          isSelected: true,
          priority: 'medium',
        ),
        CategoryBudget(
          category: ExpenseCategory.other,
          name: 'Khác',
          icon: '📝',
          color: const Color(0xFFD3D3D3),
          allocatedAmount: 1125000,
          percentage: 7.5,
          isSelected: true,
          priority: 'low',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _budgetNameController.dispose();
    _totalBudgetController.dispose();
    _monthlyIncomeController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    for (var category in _categories) {
      category.dispose();
    }
    super.dispose();
  }

  String formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ';
  }

  String getPeriodText(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return 'Hàng ngày';
      case BudgetPeriod.weekly:
        return 'Hàng tuần';
      case BudgetPeriod.monthly:
        return 'Hàng tháng';
      case BudgetPeriod.yearly:
        return 'Hàng năm';
    }
  }

  void _applyTemplate(BudgetTemplate template) {
    setState(() {
      _selectedTemplateId = template.id;
      _budgetNameController.text = template.name;
      _totalBudgetController.text = template.totalAmount.toString();
      _selectedPeriod = template.period;
      _categories = List.from(template.categories);
    });
  }

  void _updateCategoryAmounts() {
    final totalBudget = CurrencyFormatter.parse(
      _totalBudgetController.text,
    ).round();
    if (totalBudget > 0) {
      for (var category in _categories.where((c) => c.isSelected)) {
        category.allocatedAmount = (totalBudget * category.percentage / 100)
            .round();
        // Update controller text without triggering onChanged
        final newText = category.percentage.toStringAsFixed(0);
        if (category.percentageController.text != newText) {
          category.percentageController.text = newText;
        }
      }
    }
  }

  Future<void> _saveBudget() async {
    if (_budgetNameController.text.isEmpty ||
        _totalBudgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    // Validate selected categories
    final selectedCategories = _categories.where((c) => c.isSelected).toList();
    if (selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một danh mục')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final budgetService = Provider.of<BudgetService>(context, listen: false);

      // Parse total budget amount
      final totalAmount = CurrencyFormatter.parse(_totalBudgetController.text);

      if (totalAmount <= 0) {
        throw Exception('Số tiền ngân sách phải lớn hơn 0');
      }

      // Validate custom dates if selected
      if (_useCustomDates) {
        if (_customStartDate == null || _customEndDate == null) {
          throw Exception('Vui lòng chọn đầy đủ ngày bắt đầu và ngày kết thúc');
        }
        if (_customStartDate!.isAfter(_customEndDate!)) {
          throw Exception('Ngày bắt đầu phải trước ngày kết thúc');
        }
        if (_customStartDate!.isBefore(
          DateTime.now().subtract(const Duration(days: 1)),
        )) {
          throw Exception('Ngày bắt đầu không được là ngày trong quá khứ');
        }
      }

      // Calculate period dates
      DateTime startDate, endDate;

      if (_useCustomDates &&
          _customStartDate != null &&
          _customEndDate != null) {
        // Use custom dates
        startDate = _customStartDate!;
        endDate = _customEndDate!.add(
          const Duration(hours: 23, minutes: 59, seconds: 59),
        );
      } else {
        // Use predefined periods
        final now = DateTime.now();
        switch (_selectedPeriod) {
          case BudgetPeriod.daily:
            startDate = DateTime(now.year, now.month, now.day);
            endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
            break;
          case BudgetPeriod.weekly:
            startDate = now.subtract(Duration(days: now.weekday - 1));
            endDate = startDate.add(
              const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
            );
            break;
          case BudgetPeriod.monthly:
            startDate = DateTime(now.year, now.month, 1);
            endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
            break;
          case BudgetPeriod.yearly:
            startDate = DateTime(_selectedYear, 1, 1);
            endDate = DateTime(_selectedYear, 12, 31, 23, 59, 59);
            break;
        }
      }

      // Create category allocations from selected categories
      final categoryAllocations = selectedCategories.map((cat) {
        return budget_model.CategoryAllocation(
          category: _mapExpenseCategoryToBudgetCategory(cat.category),
          allocated: cat.allocatedAmount.toDouble(),
          percentage: cat.percentage.toDouble(),
          remaining: cat.allocatedAmount.toDouble(),
          lastUpdated: DateTime.now(),
        );
      }).toList();

      // Create budget period
      final period = budget_model.BudgetPeriod(
        startDate: startDate,
        endDate: endDate,
        type: _useCustomDates
            ? budget_model.BudgetPeriodType.custom
            : _mapBudgetPeriodToBudgetPeriodType(_selectedPeriod),
      );

      // Call API to create budget
      final result = await budgetService.createBudget(
        name: _budgetNameController.text,
        totalAmount: totalAmount,
        period: period,
        categoryAllocations: categoryAllocations,
      );

      if (!mounted) return;

      if (result['success']) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tạo ngân sách thành công!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        // Check if it's a limit exceeded error (403)
        if (result['limitExceeded'] == true ||
            result['upgradeRequired'] == true) {
          if (!mounted) return;
          // Clear error before showing dialog to prevent error state persisting
          final budgetService = Provider.of<BudgetService>(
            context,
            listen: false,
          );
          budgetService.clearError();
          _showUpgradeDialog(result['message'] ?? 'Đã đạt giới hạn ngân sách');
          return;
        }
        throw Exception(result['message'] ?? 'Lỗi khi tạo ngân sách');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show upgrade dialog when limit is reached
  void _showUpgradeDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Nâng cấp Premium', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Với Premium bạn có thể:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _buildBenefit('Tạo tối đa 20 ngân sách'),
                  _buildBenefit('Tạo tối đa 10 mục tiêu tiết kiệm'),
                  _buildBenefit('Quét OCR không giới hạn'),
                  _buildBenefit('Phân tích AI chi tiết'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionSettingsScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.white,
            ),
            child: const Text('Nâng cấp ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFFFFA500), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  // Helper methods to map enums
  budget_model.BudgetCategory _mapExpenseCategoryToBudgetCategory(
    ExpenseCategory cat,
  ) {
    switch (cat) {
      case ExpenseCategory.food:
        return budget_model.BudgetCategory.food;
      case ExpenseCategory.transport:
        return budget_model.BudgetCategory.transport;
      case ExpenseCategory.shopping:
        return budget_model.BudgetCategory.shopping;
      case ExpenseCategory.entertainment:
        return budget_model.BudgetCategory.entertainment;
      case ExpenseCategory.healthcare:
        return budget_model.BudgetCategory.healthcare;
      case ExpenseCategory.education:
        return budget_model.BudgetCategory.education;
      case ExpenseCategory.utilities:
        return budget_model.BudgetCategory.utilities;
      case ExpenseCategory.other:
        return budget_model.BudgetCategory.other;
    }
  }

  budget_model.BudgetPeriodType _mapBudgetPeriodToBudgetPeriodType(
    BudgetPeriod period,
  ) {
    switch (period) {
      case BudgetPeriod.daily:
        return budget_model.BudgetPeriodType.daily;
      case BudgetPeriod.weekly:
        return budget_model.BudgetPeriodType.weekly;
      case BudgetPeriod.monthly:
        return budget_model.BudgetPeriodType.monthly;
      case BudgetPeriod.yearly:
        return budget_model.BudgetPeriodType.yearly;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLimitInfoBanner(),
                        const SizedBox(height: 4),
                        _buildBasicInfo(),
                        const SizedBox(height: 24),
                        _buildBudgetTemplates(),
                        const SizedBox(height: 24),
                        _buildCategorySelection(),
                        const SizedBox(height: 24),
                        _buildAdvancedSettings(),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: context.headerTextColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tạo ngân sách mới',
                  style: AppTypography.h2.copyWith(
                    color: context.headerTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Lập kế hoạch chi tiêu thông minh',
                  style: AppTypography.body.copyWith(
                    color: context.headerSubtitleColor,
                  ),
                ),
              ],
            ),
          ),
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
        ],
      ),
    );
  }

  Widget _buildLimitInfoBanner() {
    return Consumer2<SubscriptionService, BudgetService>(
      builder: (context, subscriptionService, budgetService, child) {
        final subscription = subscriptionService.subscription;
        final isPremium = subscription?.isPremium ?? false;
        final limit = subscription?.features.maxBudgets ?? 2;

        // Count active budgets
        final budgets = budgetService.budgets;
        final activeBudgets = budgets.where((b) => b.isActive).length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPremium
                  ? [
                      const Color(0xFFFFD700).withValues(alpha: 0.1),
                      const Color(0xFFFFA500).withValues(alpha: 0.1),
                    ]
                  : [
                      Colors.blue.withValues(alpha: 0.1),
                      Colors.blue.withValues(alpha: 0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPremium
                  ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                  : Colors.blue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isPremium
                      ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                      : Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isPremium ? Icons.workspace_premium : Icons.info_outline,
                  color: isPremium ? const Color(0xFFFFA500) : Colors.blue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isPremium ? 'Gói Premium' : 'Gói Free',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ngân sách: $activeBudgets/$limit đang hoạt động',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (!isPremium) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Premium: 20',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBasicInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin cơ bản',
            style: AppTypography.h4.copyWith(
              color: context.primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Budget Name
          Text(
            'Tên ngân sách',
            style: AppTypography.body.copyWith(
              color: context.secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _budgetNameController,
            decoration: InputDecoration(
              hintText: 'VD: Ngân sách tháng 12',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colorScheme.primary),
              ),
              filled: true,
              fillColor: context.scaffoldBackground,
            ),
          ),
          const SizedBox(height: 16),

          // Total Budget
          Text(
            'Tổng ngân sách',
            style: AppTypography.body.copyWith(
              color: context.secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _totalBudgetController,
            keyboardType: TextInputType.number,
            inputFormatters: [VNDInputFormatter()],
            onChanged: (value) => _updateCategoryAmounts(),
            decoration: InputDecoration(
              hintText: '3.000.000',
              suffixText: 'VND',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colorScheme.primary),
              ),
              filled: true,
              fillColor: context.scaffoldBackground,
            ),
          ),
          const SizedBox(height: 16),

          // Budget Period
          Text(
            'Chu kỳ ngân sách',
            style: AppTypography.body.copyWith(
              color: context.secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: BudgetPeriod.values.map((period) {
              final isSelected = _selectedPeriod == period;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = period;
                      _useCustomDates = false;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colorScheme.primary
                          : context.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? context.colorScheme.primary
                            : context.cardBorder,
                      ),
                    ),
                    child: Text(
                      getPeriodText(period),
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? Colors.white
                            : context.secondaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Year Selection for Yearly Budget
          if (_selectedPeriod == BudgetPeriod.yearly) ...[
            Text(
              'Chọn năm',
              style: AppTypography.body.copyWith(
                color: context.secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final year = await showDialog<int>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Chọn năm'),
                    content: SizedBox(
                      width: 200,
                      height: 300,
                      child: YearPicker(
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 5),
                        selectedDate: DateTime(_selectedYear),
                        onChanged: (date) {
                          Navigator.pop(context, date.year);
                        },
                      ),
                    ),
                  ),
                );
                if (year != null) {
                  setState(() {
                    _selectedYear = year;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: context.secondaryTextColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Năm $_selectedYear',
                      style: AppTypography.body.copyWith(
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_drop_down,
                      color: context.secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Custom Date Selection
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _useCustomDates = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _useCustomDates
                          ? context.colorScheme.primary
                          : context.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _useCustomDates
                            ? context.colorScheme.primary
                            : context.cardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: _useCustomDates
                              ? Colors.white
                              : context.secondaryTextColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tùy chỉnh',
                          style: AppTypography.caption.copyWith(
                            color: _useCustomDates
                                ? Colors.white
                                : context.secondaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Custom Date Pickers
          if (_useCustomDates) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngày bắt đầu',
                        style: AppTypography.caption.copyWith(
                          color: context.secondaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _customStartDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              _customStartDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: context.cardBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: context.secondaryTextColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _customStartDate != null
                                      ? _formatDate(_customStartDate!)
                                      : 'Chọn ngày bắt đầu',
                                  style: AppTypography.body.copyWith(
                                    color: _customStartDate != null
                                        ? context.primaryTextColor
                                        : context.secondaryTextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngày kết thúc',
                        style: AppTypography.caption.copyWith(
                          color: context.secondaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                _customEndDate ??
                                (_customStartDate ?? DateTime.now()).add(
                                  const Duration(days: 30),
                                ),
                            firstDate: _customStartDate ?? DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              _customEndDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: context.cardBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: context.secondaryTextColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _customEndDate != null
                                      ? _formatDate(_customEndDate!)
                                      : 'Chọn ngày kết thúc',
                                  style: AppTypography.body.copyWith(
                                    color: _customEndDate != null
                                        ? context.primaryTextColor
                                        : context.secondaryTextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetTemplates() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: context.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Mẫu ngân sách Việt Nam',
                style: AppTypography.h4.copyWith(
                  color: context.primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn mẫu phù hợp với hoàn cảnh của bạn',
            style: AppTypography.body.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: _vietnameseBudgetTemplates.map((template) {
              final isSelected = _selectedTemplateId == template.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _applyTemplate(template),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colorScheme.primary.withValues(alpha: 0.1)
                          : context.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? context.colorScheme.primary
                            : context.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.colorScheme.primary
                                : context.cardBorder,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            template.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.name,
                                style: AppTypography.h5.copyWith(
                                  color: context.primaryTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                template.description,
                                style: AppTypography.caption.copyWith(
                                  color: context.secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatCurrency(template.totalAmount),
                                style: AppTypography.body.copyWith(
                                  color: context.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: context.colorScheme.primary,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category_outlined, color: context.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Danh mục chi tiêu',
                style: AppTypography.h4.copyWith(
                  color: context.primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn và phân bổ ngân sách cho từng danh mục',
            style: AppTypography.body.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          // Total percentage display
          Builder(
            builder: (context) {
              final totalPercentage = _categories
                  .where((c) => c.isSelected)
                  .fold<double>(0, (sum, cat) => sum + cat.percentage);
              final isValid = totalPercentage <= 100;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isValid
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isValid ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isValid ? Icons.check_circle : Icons.warning,
                      size: 16,
                      color: isValid ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tổng: ${totalPercentage.toStringAsFixed(0)}%',
                      style: AppTypography.caption.copyWith(
                        color: isValid
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isValid) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(Vượt quá 100%)',
                        style: AppTypography.caption.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio:
                  0.75, // Giảm từ 1.1 xuống 0.75 để card cao hơn, tránh overflow
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    category.isSelected = !category.isSelected;
                  });
                  _updateCategoryAmounts();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: category.isSelected
                        ? category.color.withValues(alpha: 0.1)
                        : context.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: category.isSelected
                          ? category.color
                          : context.cardBorder,
                      width: category.isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            category.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const Spacer(),
                          if (category.isSelected)
                            Icon(
                              Icons.check_circle,
                              color: category.color,
                              size: 16,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        style: AppTypography.caption.copyWith(
                          color: context.primaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category.isSelected) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            inputFormatters: [PercentageInputFormatter()],
                            decoration: InputDecoration(
                              labelText: '%',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            controller: category.percentageController,
                            onChanged: (value) {
                              final newPercentage = double.tryParse(value) ?? 0;
                              setState(() {
                                category.percentage = newPercentage;
                                _updateCategoryAmounts();
                              });
                            },
                          ),
                        ),
                        if (category.allocatedAmount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            formatCurrency(category.allocatedAmount),
                            style: AppTypography.caption.copyWith(
                              color: category.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_outlined, color: context.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Cài đặt nâng cao',
                style: AppTypography.h4.copyWith(
                  color: context.primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSwitchOption(
            'Tự động tiết kiệm',
            'Tự động chuyển tiền dư vào tiết kiệm',
            _autoSaving,
            (value) => setState(() => _autoSaving = value),
          ),

          _buildSwitchOption(
            'Quỹ khẩn cấp',
            'Dành riêng 10% cho tình huống khẩn cấp',
            _emergencyFund,
            (value) => setState(() => _emergencyFund = value),
          ),

          _buildSwitchOption(
            'Thông báo thông minh',
            'Nhận cảnh báo khi chi tiêu vượt mức',
            _smartAlerts,
            (value) => setState(() => _smartAlerts = value),
          ),

          _buildSwitchOption(
            'Báo cáo hàng tuần',
            'Nhận báo cáo chi tiêu mỗi tuần',
            _weeklyReview,
            (value) => setState(() => _weeklyReview = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchOption(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: context.primaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: context.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveBudget,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Tạo ngân sách',
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
