import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import '../../models/budget_models.dart';
import '../../services/expense_service.dart';

class AddExpenseFromBudgetScreen extends StatefulWidget {
  final String budgetId;
  final ExpenseCategory? preselectedCategory;

  const AddExpenseFromBudgetScreen({
    super.key,
    required this.budgetId,
    this.preselectedCategory,
  });

  @override
  State<AddExpenseFromBudgetScreen> createState() =>
      _AddExpenseFromBudgetScreenState();
}

class _AddExpenseFromBudgetScreenState extends State<AddExpenseFromBudgetScreen>
    with TickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  ExpenseCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.preselectedCategory;

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _slideController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _slideController.dispose();
    super.dispose();
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
        return Icons.shopping_cart;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.healthcare:
        return Icons.medical_services;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.utilities:
        return Icons.receipt;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }

  String formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VND';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary500,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
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
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn danh mục chi tiêu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = int.parse(_amountController.text.replaceAll(',', ''));
      final expenseService = context.read<ExpenseService>();

      await expenseService.addExpense(
        category: _selectedCategory!,
        amount: amount,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        budgetId: widget.budgetId,
      );

      if (mounted) {
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm chi tiêu ${formatCurrency(amount)}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Quay lại màn hình trước
        Navigator.pop(context, true); // true để báo hiệu đã thêm thành công
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm chi tiêu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseService = context.watch<ExpenseService>();
    final budget = expenseService.getBudgetById(widget.budgetId);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thêm chi tiêu',
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (budget != null) _buildBudgetInfo(budget),
                const SizedBox(height: 24),
                _buildAmountInput(),
                const SizedBox(height: 24),
                _buildCategorySelection(budget),
                const SizedBox(height: 24),
                _buildDateSelection(),
                const SizedBox(height: 24),
                _buildDescriptionInput(),
                const SizedBox(height: 40),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetInfo(BudgetData budget) {
    final remainingAmount = budget.totalAmount - budget.spentAmount;
    final progressPercentage = (budget.spentAmount / budget.totalAmount) * 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary500, AppColors.primary400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            budget.name,
            style: AppTypography.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatCurrency(budget.spentAmount),
                    style: AppTypography.h5.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Đã chi',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(remainingAmount),
                    style: AppTypography.h5.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Còn lại',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (budget.spentAmount / budget.totalAmount).clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              progressPercentage > 90 ? Colors.red : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${progressPercentage.toInt()}% / ${formatCurrency(budget.totalAmount)}',
            style: AppTypography.caption.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Số tiền',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            // Định dạng số với dấu phẩy
            TextInputFormatter.withFunction((oldValue, newValue) {
              final text = newValue.text.replaceAll(',', '');
              if (text.isEmpty) return newValue;

              final number = int.tryParse(text);
              if (number == null) return oldValue;

              final formatted = number.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},',
              );

              return TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }),
          ],
          decoration: InputDecoration(
            hintText: '0',
            suffixText: 'VND',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary500, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: AppTypography.h4.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập số tiền';
            }
            final amount = int.tryParse(value.replaceAll(',', ''));
            if (amount == null || amount <= 0) {
              return 'Số tiền không hợp lệ';
            }
            if (amount > 100000000) {
              // 100 triệu VND
              return 'Số tiền quá lớn';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySelection(BudgetData? budget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh mục',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (budget != null)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: budget.categories.map((category) {
              final isSelected = _selectedCategory == category.category;
              final remainingAmount =
                  category.allocatedAmount - category.spentAmount;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category.category;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? category.color.withOpacity(0.2)
                        : Colors.white,
                    border: Border.all(
                      color: isSelected ? category.color : AppColors.primary200,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: category.color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getCategoryIcon(category.category),
                        color: category.color,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getCategoryName(category.category),
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency(remainingAmount),
                        style: AppTypography.caption.copyWith(
                          color: remainingAmount > 0
                              ? AppColors.success
                              : Colors.red,
                          fontSize: 10,
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
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.primary200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primary500),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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
      ],
    );
  }

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mô tả (tùy chọn)',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Nhập mô tả chi tiêu...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary500, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          foregroundColor: Colors.white,
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
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Lưu chi tiêu',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
