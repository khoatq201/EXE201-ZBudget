import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';

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
  final TextEditingController _monthlyIncomeController = TextEditingController();

  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  String? _selectedTemplateId;
  bool _autoSaving = true;
  bool _emergencyFund = true;
  bool _smartAlerts = true;
  bool _weeklyReview = false;
  bool _isLoading = false;

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

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
    final totalBudget = int.tryParse(_totalBudgetController.text) ?? 0;
    if (totalBudget > 0) {
      setState(() {
        for (var category in _categories.where((c) => c.isSelected)) {
          category.allocatedAmount = (totalBudget * category.percentage / 100).round();
        }
      });
    }
  }

  Future<void> _saveBudget() async {
    if (_budgetNameController.text.isEmpty || _totalBudgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo ngân sách thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
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
          colors: [AppColors.primary500, AppColors.primary400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tạo ngân sách mới',
                  style: AppTypography.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Lập kế hoạch chi tiêu thông minh',
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
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

  Widget _buildBasicInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Budget Name
          Text(
            'Tên ngân sách',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
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
                borderSide: BorderSide(color: AppColors.dark300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary500),
              ),
              filled: true,
              fillColor: AppColors.backgroundSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Total Budget
          Text(
            'Tổng ngân sách',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _totalBudgetController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => _updateCategoryAmounts(),
            decoration: InputDecoration(
              hintText: 'VD: 3000000',
              suffixText: 'VND',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.dark300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary500),
              ),
              filled: true,
              fillColor: AppColors.backgroundSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Budget Period
          Text(
            'Chu kỳ ngân sách',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
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
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary500 : AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.primary500 : AppColors.dark300,
                      ),
                    ),
                    child: Text(
                      getPeriodText(period),
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildBudgetTemplates() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
              Icon(Icons.description_outlined, color: AppColors.primary500),
              const SizedBox(width: 8),
              Text(
                'Mẫu ngân sách Việt Nam',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn mẫu phù hợp với hoàn cảnh của bạn',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
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
                      color: isSelected ? AppColors.primary500.withValues(alpha: 0.1) : AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary500 : AppColors.dark300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary500 : AppColors.dark300,
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
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                template.description,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatCurrency(template.totalAmount),
                                style: AppTypography.body.copyWith(
                                  color: AppColors.primary500,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primary500,
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
        color: Colors.white,
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
              Icon(Icons.category_outlined, color: AppColors.primary500),
              const SizedBox(width: 8),
              Text(
                'Danh mục chi tiêu',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn và phân bổ ngân sách cho từng danh mục',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
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
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: category.isSelected ? category.color : AppColors.dark300,
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
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (category.isSelected && category.allocatedAmount > 0) ...[
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
        color: Colors.white,
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
              Icon(Icons.settings_outlined, color: AppColors.primary500),
              const SizedBox(width: 8),
              Text(
                'Cài đặt nâng cao',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
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

  Widget _buildSwitchOption(String title, String subtitle, bool value, Function(bool) onChanged) {
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
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary500,
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
          backgroundColor: AppColors.primary500,
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
}
