import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';

enum SavingsCategory {
  emergency,
  purchase,
  travel,
  education,
  investment,
  home,
  vehicle,
  health,
  wedding,
  other,
}

enum SavingsPriority { low, medium, high, urgent }

class SavingsCategoryOption {
  final SavingsCategory category;
  final String name;
  final String icon;
  final Color color;
  final String description;

  SavingsCategoryOption({
    required this.category,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class CreateSavingsGoalScreen extends StatefulWidget {
  const CreateSavingsGoalScreen({super.key});

  @override
  State<CreateSavingsGoalScreen> createState() =>
      _CreateSavingsGoalScreenState();
}

class _CreateSavingsGoalScreenState extends State<CreateSavingsGoalScreen>
    with TickerProviderStateMixin {
  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _monthlyContributionController =
      TextEditingController();

  SavingsCategory? _selectedCategory;
  SavingsPriority _selectedPriority = SavingsPriority.medium;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));
  bool _autoSaveEnabled = true;
  bool _reminderEnabled = true;
  String _reminderFrequency = 'weekly';
  bool _isLoading = false;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<SavingsCategoryOption> _goalCategories = [
    SavingsCategoryOption(
      category: SavingsCategory.emergency,
      name: 'Quỹ khẩn cấp',
      icon: '🚨',
      color: const Color(0xFFFF6B6B),
      description: 'Dự phòng tài chính an toàn',
    ),
    SavingsCategoryOption(
      category: SavingsCategory.purchase,
      name: 'Mua sắm lớn',
      icon: '🛍️',
      color: const Color(0xFF4ECDC4),
      description: 'Điện thoại, laptop, đồ gia dụng',
    ),
    SavingsCategoryOption(
      category: SavingsCategory.travel,
      name: 'Du lịch & nghỉ dưỡng',
      icon: '✈️',
      color: const Color(0xFF45B7D1),
      description: 'Chuyến đi và trải nghiệm',
    ),
    SavingsCategoryOption(
      category: SavingsCategory.education,
      name: 'Giáo dục',
      icon: '🎓',
      color: const Color(0xFF96CEB4),
      description: 'Khóa học và phát triển bản thân',
    ),
    SavingsCategoryOption(
      category: SavingsCategory.investment,
      name: 'Đầu tư',
      icon: '📈',
      color: const Color(0xFFFFEAA7),
      description: 'Cổ phiếu, crypto, vàng',
    ),
    SavingsCategoryOption(
      category: SavingsCategory.home,
      name: 'Nhà ở & bất động sản',
      icon: '🏠',
      color: const Color(0xFFDDA0DD),
      description: 'Mua nhà, đặt cọc',
    ),
    SavingsCategoryOption(
      category: SavingsCategory.vehicle,
      name: 'Phương tiện',
      icon: '🚗',
      color: const Color(0xFFFFB6C1),
      description: 'Xe máy, ô tô',
    ),
    SavingsCategoryOption(
      category: SavingsCategory.health,
      name: 'Sức khỏe & y tế',
      icon: '🏥',
      color: const Color(0xFF87CEEB),
      description: 'Chi phí y tế, chăm sóc sức khỏe',
    ),
    SavingsCategoryOption(
      category: SavingsCategory.wedding,
      name: 'Đám cưới',
      icon: '💒',
      color: const Color(0xFFFFC0CB),
      description: 'Chi phí tổ chức đám cưới',
    ),
    SavingsCategoryOption(
      category: SavingsCategory.other,
      name: 'Khác',
      icon: '📝',
      color: const Color(0xFFD3D3D3),
      description: 'Mục tiêu khác',
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
    _goalNameController.dispose();
    _targetAmountController.dispose();
    _descriptionController.dispose();
    _monthlyContributionController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ';
  }

  String getPriorityText(SavingsPriority priority) {
    switch (priority) {
      case SavingsPriority.low:
        return 'Thấp';
      case SavingsPriority.medium:
        return 'Trung bình';
      case SavingsPriority.high:
        return 'Cao';
      case SavingsPriority.urgent:
        return 'Khẩn cấp';
    }
  }

  Color getPriorityColor(SavingsPriority priority) {
    switch (priority) {
      case SavingsPriority.low:
        return Colors.green;
      case SavingsPriority.medium:
        return Colors.orange;
      case SavingsPriority.high:
        return Colors.red;
      case SavingsPriority.urgent:
        return Colors.purple;
    }
  }

  int _calculateMonthsToTarget() {
    final targetAmount = int.tryParse(_targetAmountController.text) ?? 0;
    final monthlyContribution =
        int.tryParse(_monthlyContributionController.text) ?? 0;

    if (targetAmount > 0 && monthlyContribution > 0) {
      return (targetAmount / monthlyContribution).ceil();
    }
    return 0;
  }

  Future<void> _selectTargetDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary500,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  Future<void> _saveSavingsGoal() async {
    if (_goalNameController.text.isEmpty ||
        _targetAmountController.text.isEmpty ||
        _selectedCategory == null) {
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
          content: Text('Tạo mục tiêu tiết kiệm thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $error')));
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
                        _buildCategorySelection(),
                        const SizedBox(height: 24),
                        _buildTargetAndContribution(),
                        const SizedBox(height: 24),
                        _buildAdvancedSettings(),
                        const SizedBox(height: 24),
                        _buildProgressPreview(),
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
          colors: [AppColors.success, const Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
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
                  'Tạo mục tiêu tiết kiệm',
                  style: AppTypography.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Xây dựng tương lai tài chính',
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
            child: const Icon(Icons.savings, color: Colors.white, size: 28),
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

          // Goal Name
          Text(
            'Tên mục tiêu',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _goalNameController,
            decoration: InputDecoration(
              hintText: 'VD: Mua laptop mới cho học tập',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.dark300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.success),
              ),
              filled: true,
              fillColor: AppColors.backgroundSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'Mô tả (tùy chọn)',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Mô tả chi tiết về mục tiêu của bạn...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.dark300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.success),
              ),
              filled: true,
              fillColor: AppColors.backgroundSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Priority
          Text(
            'Mức độ ưu tiên',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: SavingsPriority.values.map((priority) {
              final isSelected = _selectedPriority == priority;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPriority = priority;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? getPriorityColor(priority)
                          : AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? getPriorityColor(priority)
                            : AppColors.dark300,
                      ),
                    ),
                    child: Text(
                      getPriorityText(priority),
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
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
              Icon(Icons.category_outlined, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'Danh mục mục tiêu',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn loại mục tiêu tiết kiệm của bạn',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _goalCategories.length,
            itemBuilder: (context, index) {
              final category = _goalCategories[index];
              final isSelected = _selectedCategory == category.category;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category.category;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? category.color.withValues(alpha: 0.1)
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? category.color : AppColors.dark300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            category.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: category.color,
                              size: 20,
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
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildTargetAndContribution() {
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
              Icon(Icons.track_changes, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'Mục tiêu & Kế hoạch',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Target Amount
          Text(
            'Số tiền mục tiêu',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _targetAmountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'VD: 15000000',
              suffixText: 'VND',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.dark300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.success),
              ),
              filled: true,
              fillColor: AppColors.backgroundSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Target Date
          Text(
            'Ngày hoàn thành mục tiêu',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectTargetDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.dark300),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(
                    '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Monthly Contribution
          Text(
            'Số tiền tiết kiệm hàng tháng',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _monthlyContributionController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'VD: 500000',
              suffixText: 'VND/tháng',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.dark300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.success),
              ),
              filled: true,
              fillColor: AppColors.backgroundSecondary,
            ),
          ),

          // Progress Calculation
          if (_targetAmountController.text.isNotEmpty &&
              _monthlyContributionController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn sẽ đạt mục tiêu trong ${_calculateMonthsToTarget()} tháng',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              Icon(Icons.settings_outlined, color: AppColors.success),
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
            'Tự động chuyển tiền vào mục tiêu hàng tháng',
            _autoSaveEnabled,
            (value) => setState(() => _autoSaveEnabled = value),
          ),

          _buildSwitchOption(
            'Thông báo nhắc nhở',
            'Nhận thông báo về tiến độ tiết kiệm',
            _reminderEnabled,
            (value) => setState(() => _reminderEnabled = value),
          ),

          if (_reminderEnabled) ...[
            const SizedBox(height: 16),
            Text(
              'Tần suất nhắc nhở',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['daily', 'weekly', 'monthly'].map((frequency) {
                final isSelected = _reminderFrequency == frequency;
                final frequencyText = frequency == 'daily'
                    ? 'Hàng ngày'
                    : frequency == 'weekly'
                    ? 'Hàng tuần'
                    : 'Hàng tháng';

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _reminderFrequency = frequency;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.success
                            : AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.success
                              : AppColors.dark300,
                        ),
                      ),
                      child: Text(
                        frequencyText,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
            activeThumbColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPreview() {
    final targetAmount = int.tryParse(_targetAmountController.text) ?? 0;
    final monthlyContribution =
        int.tryParse(_monthlyContributionController.text) ?? 0;

    if (targetAmount == 0 || monthlyContribution == 0) {
      return const SizedBox.shrink();
    }

    final monthsToTarget = _calculateMonthsToTarget();
    final progressPercentage = monthsToTarget > 0
        ? (1.0 / monthsToTarget) * 100
        : 0.0;

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
              Icon(Icons.preview, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'Xem trước kế hoạch',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mục tiêu',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    formatCurrency(targetAmount),
                    style: AppTypography.h5.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Hàng tháng',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    formatCurrency(monthlyContribution),
                    style: AppTypography.h5.copyWith(
                      color: AppColors.primary500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Tiến độ dự kiến (tháng đầu)',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.dark200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (progressPercentage / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${progressPercentage.toStringAsFixed(1)}% sau tháng đầu tiên',
            style: AppTypography.caption.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveSavingsGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
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
                'Tạo mục tiêu tiết kiệm',
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
