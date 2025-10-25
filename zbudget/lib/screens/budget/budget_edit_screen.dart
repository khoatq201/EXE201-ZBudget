import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import '../../models/budget_models.dart';
import '../../models/expense.dart';
import '../../utils/currency_input_formatter.dart';
import '../../utils/currency_formatter.dart';

class BudgetEditScreen extends StatefulWidget {
  final BudgetData budget;

  const BudgetEditScreen({super.key, required this.budget});

  @override
  State<BudgetEditScreen> createState() => _BudgetEditScreenState();
}

class _BudgetEditScreenState extends State<BudgetEditScreen>
    with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _totalAmountController;
  late List<BudgetCategoryData> _categories;
  late BudgetPeriod _selectedPeriod;
  bool _isEditing = false;

  late AnimationController _editModeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.budget.name);
    _totalAmountController = TextEditingController(
      text: widget.budget.totalAmount.toString(),
    );
    _categories = List.from(widget.budget.categories);
    _selectedPeriod = widget.budget.period;

    _editModeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalAmountController.dispose();
    _editModeController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
    if (_isEditing) {
      _editModeController.forward();
    } else {
      _editModeController.reverse();
      _saveChanges();
    }
  }

  void _saveChanges() {
    // Implement save logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu thay đổi thành công!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _updateCategoryAmount(int index, double percentage) {
    final totalAmount = int.tryParse(_totalAmountController.text) ?? 0;
    final newAmount = (totalAmount * percentage / 100).round();

    setState(() {
      _categories[index] = BudgetCategoryData(
        category: _categories[index].category,
        allocatedAmount: newAmount,
        spentAmount: _categories[index].spentAmount,
        color: _categories[index].color,
      );
      _rebalanceCategories(index, percentage);
    });
  }

  void _rebalanceCategories(int changedIndex, double newPercentage) {
    final totalAmount = int.tryParse(_totalAmountController.text) ?? 0;
    if (totalAmount == 0) return;

    // Calculate remaining percentage for other categories
    double remainingPercentage = 100 - newPercentage;
    double currentOthersTotal = 0;

    // Calculate current total of other categories
    for (int i = 0; i < _categories.length; i++) {
      if (i != changedIndex) {
        currentOthersTotal +=
            (_categories[i].allocatedAmount / totalAmount) * 100;
      }
    }

    if (currentOthersTotal == 0) return;

    // Redistribute remaining percentage proportionally
    for (int i = 0; i < _categories.length; i++) {
      if (i != changedIndex) {
        final currentPercentage =
            (_categories[i].allocatedAmount / totalAmount) * 100;
        final newCategoryPercentage =
            (currentPercentage / currentOthersTotal) * remainingPercentage;
        final newAmount = (totalAmount * newCategoryPercentage / 100).round();

        _categories[i] = BudgetCategoryData(
          category: _categories[i].category,
          allocatedAmount: newAmount,
          spentAmount: _categories[i].spentAmount,
          color: _categories[i].color,
        );
      }
    }
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder: (context) => _AddCategoryDialog(
        onAdd: (category, amount, color) {
          setState(() {
            _categories.add(
              BudgetCategoryData(
                category: category,
                allocatedAmount: amount,
                spentAmount: 0,
                color: color,
              ),
            );
          });
        },
      ),
    );
  }

  void _removeCategory(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa danh mục'),
        content: Text(
          'Bạn có chắc muốn xóa danh mục "${_getCategoryName(_categories[index].category)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _categories.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _editCategoryAmount(int index) {
    final controller = TextEditingController(
      text: _categories[index].allocatedAmount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Chỉnh sửa ${_getCategoryName(_categories[index].category)}',
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          decoration: const InputDecoration(
            labelText: 'Số tiền (VND)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final amount = CurrencyFormatter.parse(controller.text).round();
              setState(() {
                _categories[index] = BudgetCategoryData(
                  category: _categories[index].category,
                  allocatedAmount: amount,
                  spentAmount: _categories[index].spentAmount,
                  color: _categories[index].color,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
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

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.healthcare:
        return Icons.local_hospital;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.utilities:
        return Icons.receipt;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VND';
  }

  String _getPeriodText(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return 'Ngày';
      case BudgetPeriod.weekly:
        return 'Tuần';
      case BudgetPeriod.monthly:
        return 'Tháng';
      case BudgetPeriod.yearly:
        return 'Năm';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = int.tryParse(_totalAmountController.text) ?? 0;
    final totalSpent = _categories.fold<int>(
      0,
      (sum, category) => sum + category.spentAmount,
    );
    final totalAllocated = _categories.fold<int>(
      0,
      (sum, category) => sum + category.allocatedAmount,
    );

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chi tiết ngân sách',
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isEditing ? Icons.save : Icons.edit,
                key: ValueKey(_isEditing),
                color: AppColors.primary500,
              ),
            ),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Budget Name
                    _isEditing
                        ? TextField(
                            controller: _nameController,
                            style: AppTypography.h3,
                            decoration: const InputDecoration(
                              labelText: 'Tên ngân sách',
                              border: OutlineInputBorder(),
                            ),
                          )
                        : Text(_nameController.text, style: AppTypography.h3),
                    const SizedBox(height: 16),

                    // Period Selector
                    if (_isEditing) ...[
                      Text(
                        'Chu kỳ',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: BudgetPeriod.values.map((period) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: ChoiceChip(
                                label: Text(
                                  _getPeriodText(period),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _selectedPeriod == period
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                selected: _selectedPeriod == period,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedPeriod = period;
                                    });
                                  }
                                },
                                selectedColor: AppColors.primary500,
                                backgroundColor: AppColors.backgroundSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Total Amount
                    Row(
                      children: [
                        Text(
                          'Tổng ngân sách: ',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (_isEditing)
                          Expanded(
                            child: TextField(
                              controller: _totalAmountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [VNDInputFormatter()],
                              style: AppTypography.h4.copyWith(
                                color: AppColors.primary500,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                suffixText: 'VND',
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          )
                        else
                          Text(
                            _formatCurrency(totalAmount),
                            style: AppTypography.h4.copyWith(
                              color: AppColors.primary500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Progress Overview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đã chi',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              _formatCurrency(totalSpent),
                              style: AppTypography.body.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Còn lại',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              _formatCurrency(totalAmount - totalSpent),
                              style: AppTypography.body.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress Bar
                    LinearProgressIndicator(
                      value: totalAmount > 0 ? totalSpent / totalAmount : 0,
                      backgroundColor: AppColors.backgroundSecondary,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        totalSpent > totalAmount
                            ? Colors.red
                            : AppColors.primary500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Categories Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Danh mục chi tiêu', style: AppTypography.h4),
                if (_isEditing)
                  IconButton(
                    icon: Icon(Icons.add, color: AppColors.primary500),
                    onPressed: _addCategory,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Categories List
            ...List.generate(_categories.length, (index) {
              final category = _categories[index];
              final percentage = totalAmount > 0
                  ? (category.allocatedAmount / totalAmount) * 100
                  : 0.0;
              final spentPercentage = category.allocatedAmount > 0
                  ? (category.spentAmount / category.allocatedAmount) * 100
                  : 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Category Header
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: category.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getCategoryIcon(category.category),
                              color: category.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getCategoryName(category.category),
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}% ngân sách',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isEditing) ...[
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _editCategoryAmount(index),
                              color: AppColors.textSecondary,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => _removeCategory(index),
                              color: Colors.red,
                            ),
                          ],
                          Text(
                            _formatCurrency(category.allocatedAmount),
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Allocation Slider (only in edit mode)
                      if (_isEditing) ...[
                        Text(
                          'Tỷ lệ phân bổ: ${percentage.toStringAsFixed(1)}%',
                          style: AppTypography.caption,
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: category.color,
                            thumbColor: category.color,
                            overlayColor: category.color.withValues(alpha: 0.2),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: percentage.clamp(0.0, 100.0),
                            min: 0,
                            max: 100,
                            divisions: 100,
                            onChanged: (value) {
                              HapticFeedback.lightImpact();
                              _updateCategoryAmount(index, value);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Spending Progress
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đã chi: ${_formatCurrency(category.spentAmount)}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Còn lại: ${_formatCurrency(category.allocatedAmount - category.spentAmount)}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: spentPercentage / 100,
                        backgroundColor: category.color.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          spentPercentage > 100 ? Colors.red : category.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Summary Card
            if (totalAllocated != totalAmount)
              Card(
                color: Colors.orange.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chưa phân bổ đủ ngân sách',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              'Còn thiếu: ${_formatCurrency(totalAmount - totalAllocated)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  final Function(ExpenseCategory, int, Color) onAdd;

  const _AddCategoryDialog({required this.onAdd});

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  ExpenseCategory? _selectedCategory;
  final _amountController = TextEditingController();
  Color _selectedColor = const Color(0xFFFF6B6B);

  final List<Color> _colors = [
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFF45B7D1),
    const Color(0xFF96CEB4),
    const Color(0xFFFFD700),
    const Color(0xFFFF8C42),
    const Color(0xFF6C5CE7),
    const Color(0xFFE17055),
  ];

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
    return AlertDialog(
      title: const Text('Thêm danh mục mới'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category Selection
          DropdownButtonFormField<ExpenseCategory>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Chọn danh mục',
              border: OutlineInputBorder(),
            ),
            items: ExpenseCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(_getCategoryName(category)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Amount Input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [VNDInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Số tiền (VND)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // Color Selection
          const Text('Chọn màu:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _colors.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: _selectedColor == color
                        ? Border.all(color: Colors.black, width: 2)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () {
            if (_selectedCategory != null &&
                _amountController.text.isNotEmpty) {
              final amount = int.tryParse(_amountController.text) ?? 0;
              widget.onAdd(_selectedCategory!, amount, _selectedColor);
              Navigator.pop(context);
            }
          },
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}
