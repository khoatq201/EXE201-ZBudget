import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/savings_service.dart';
import '../../services/subscription_service.dart';
import '../../models/savings_models.dart';
import '../../constants/typography.dart';
import '../../utils/theme_extensions.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/currency_input_formatter.dart';
import '../../utils/date_formatter.dart';
import '../settings/subscription_settings_screen.dart';

class CreateSavingsScreen extends StatefulWidget {
  final String? goalId; // For edit mode

  const CreateSavingsScreen({super.key, this.goalId});

  @override
  State<CreateSavingsScreen> createState() => _CreateSavingsScreenState();
}

class _CreateSavingsScreenState extends State<CreateSavingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));
  SavingsCategory _selectedCategory = SavingsCategory.other;
  SavingsPriority _selectedPriority = SavingsPriority.medium;
  String _selectedColor = '#4CAF50';
  bool _isLoading = false;
  bool _isEditMode = false;
  SavingsGoal? _existingGoal;

  final List<String> _colorOptions = [
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#FF9800', // Orange
    '#F44336', // Red
    '#9C27B0', // Purple
    '#00BCD4', // Cyan
    '#FF5722', // Deep Orange
    '#795548', // Brown
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.goalId != null;
    if (_isEditMode) {
      _loadExistingGoal();
    }
  }

  Future<void> _loadExistingGoal() async {
    final savingsService = Provider.of<SavingsService>(context, listen: false);
    final goal = await savingsService.getSavingsGoalById(widget.goalId!);

    if (goal != null && mounted) {
      setState(() {
        _existingGoal = goal;
        _nameController.text = goal.name;
        _descriptionController.text = goal.description ?? '';
        _targetAmountController.text = goal.targetAmount.toStringAsFixed(0);
        _targetDate = goal.targetDate;
        _selectedCategory = goal.category;
        _selectedPriority = goal.priority;
        _selectedColor = goal.color;
        _notesController.text = goal.notes ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.colorScheme.primary,
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final savingsService = Provider.of<SavingsService>(context, listen: false);

    final targetAmount = CurrencyFormatter.parse(_targetAmountController.text);

    Map<String, dynamic> result;

    if (_isEditMode && _existingGoal != null) {
      result = await savingsService.updateSavingsGoal(
        id: widget.goalId!,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        targetAmount: targetAmount,
        targetDate: _targetDate,
        category: _selectedCategory,
        priority: _selectedPriority,
        color: _selectedColor,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    } else {
      result = await savingsService.createSavingsGoal(
        name: _nameController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        targetAmount: targetAmount,
        targetDate: _targetDate,
        category: _selectedCategory,
        priority: _selectedPriority,
        color: _selectedColor,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Đã lưu mục tiêu tiết kiệm'),
          backgroundColor: context.colorScheme.primary,
        ),
      );
      context.pop();
    } else {
      // Check if it's a limit exceeded error (403)
      if (result['limitExceeded'] == true || result['upgradeRequired'] == true) {
        // Clear error before showing dialog to prevent error state persisting
        final savingsService = Provider.of<SavingsService>(context, listen: false);
        savingsService.clearError();
        _showUpgradeDialog(result['message'] ?? 'Đã đạt giới hạn mục tiêu tiết kiệm');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Có lỗi xảy ra'),
          backgroundColor: context.colorScheme.error,
        ),
      );
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
              child: const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
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
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Chỉnh sửa mục tiêu' : 'Thêm mục tiêu tiết kiệm',
        ),
        backgroundColor: context.headerGradientStart,
        foregroundColor: context.headerTextColor,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Limit Info Banner
            if (!_isEditMode) _buildLimitInfoBanner(),
            if (!_isEditMode) const SizedBox(height: 4),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên mục tiêu *',
                hintText: 'Ví dụ: Quỹ khẩn cấp',
                prefixIcon: const Icon(Icons.label_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên mục tiêu';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            _buildCategorySelector(),
            const SizedBox(height: 16),

            // Target Amount
            TextFormField(
              controller: _targetAmountController,
              decoration: InputDecoration(
                labelText: 'Số tiền mục tiêu *',
                hintText: '0',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: '₫',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số tiền mục tiêu';
                }
                final amount = CurrencyFormatter.parse(value);
                if (amount <= 0) {
                  return 'Số tiền phải lớn hơn 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Target Date
            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Ngày mục tiêu *',
                    hintText: 'Chọn ngày',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  controller: TextEditingController(
                    text: DateFormatter.toDisplayFormat(_targetDate),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Priority
            _buildPrioritySelector(),
            const SizedBox(height: 16),

            // Color Picker
            _buildColorPicker(),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Thêm mô tả chi tiết...',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Thêm ghi chú...',
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveSavingsGoal,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                      _isEditMode ? 'Cập nhật' : 'Tạo mục tiêu',
                      style: AppTypography.button.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh mục *',
          style: AppTypography.bodySmall.copyWith(
            color: context.settingsItemTitleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: SavingsCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colorScheme.primary
                      : context.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? context.colorScheme.primary
                        : context.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.icon,
                      size: 20,
                      color: isSelected
                          ? Colors.white
                          : context.settingsItemTitleColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.displayName,
                      style: AppTypography.bodySmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : context.settingsItemTitleColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Độ ưu tiên',
          style: AppTypography.bodySmall.copyWith(
            color: context.settingsItemTitleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
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
                        ? context.colorScheme.primary
                        : context.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? context.colorScheme.primary
                          : context.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    priority.displayName,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : context.settingsItemTitleColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Màu sắc',
          style: AppTypography.bodySmall.copyWith(
            color: context.settingsItemTitleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colorOptions.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? context.colorScheme.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLimitInfoBanner() {
    return Consumer2<SubscriptionService, SavingsService>(
      builder: (context, subscriptionService, savingsService, child) {
        final subscription = subscriptionService.subscription;
        final isPremium = subscription?.isPremium ?? false;
        final limit = subscription?.features.maxSavingsGoals ?? 2;

        // Count active savings goals
        final goals = savingsService.savingsGoals;
        final activeGoals = goals.where((g) => g.status == SavingsStatus.active).length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPremium
                  ? [const Color(0xFFFFD700).withValues(alpha: 0.1), const Color(0xFFFFA500).withValues(alpha: 0.1)]
                  : [Colors.green.withValues(alpha: 0.1), Colors.green.withValues(alpha: 0.05)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPremium ? const Color(0xFFFFD700).withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isPremium ? const Color(0xFFFFD700).withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isPremium ? Icons.workspace_premium : Icons.savings_outlined,
                  color: isPremium ? const Color(0xFFFFA500) : Colors.green,
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
                      'Mục tiêu: $activeGoals/$limit đang hoạt động',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPremium) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Premium: 10',
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
}
