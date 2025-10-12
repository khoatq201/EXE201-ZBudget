import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/group_budget_service.dart';
import '../../constants/typography.dart';
import '../../constants/spacing.dart';
import '../../utils/theme_extensions.dart';

class AddGroupExpenseScreen extends StatefulWidget {
  final String budgetId;

  const AddGroupExpenseScreen({
    super.key,
    required this.budgetId,
  });

  @override
  State<AddGroupExpenseScreen> createState() => _AddGroupExpenseScreenState();
}

class _AddGroupExpenseScreenState extends State<AddGroupExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _splitType = 'auto';
  String _category = 'other';
  bool _isLoading = false;

  final List<Map<String, String>> _categories = [
    {'value': 'food', 'label': 'Ăn uống', 'icon': '🍽️'},
    {'value': 'transport', 'label': 'Di chuyển', 'icon': '🚗'},
    {'value': 'shopping', 'label': 'Mua sắm', 'icon': '🛍️'},
    {'value': 'entertainment', 'label': 'Giải trí', 'icon': '🎬'},
    {'value': 'utilities', 'label': 'Tiện ích', 'icon': '💡'},
    {'value': 'healthcare', 'label': 'Y tế', 'icon': '🏥'},
    {'value': 'education', 'label': 'Giáo dục', 'icon': '📚'},
    {'value': 'other', 'label': 'Khác', 'icon': '📝'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = Provider.of<GroupBudgetService>(context, listen: false);
      final result = await service.addExpense(
        budgetId: widget.budgetId,
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.replaceAll(',', '')),
        category: _category,
        splitType: _splitType,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm chi tiêu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm chi tiêu'),
        backgroundColor: context.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _buildBasicInfo(),
            const SizedBox(height: AppSpacing.lg),
            _buildCategorySelection(),
            const SizedBox(height: AppSpacing.lg),
            _buildSplitType(),
            const SizedBox(height: AppSpacing.xl2),
            _buildAddButton(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin chi tiêu',
              style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả *',
                hintText: 'VD: Tiền khách sạn',
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập mô tả';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Số tiền *',
                hintText: '100,000',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'VND',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số tiền';
                }
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'Số tiền không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                hintText: 'Thêm ghi chú...',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danh mục',
              style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _category == cat['value'];
                return ChoiceChip(
                  label: Text('${cat['icon']} ${cat['label']}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _category = cat['value']!);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitType() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cách chia',
              style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            RadioListTile<String>(
              title: const Text('Tự động (theo tỉ lệ đóng góp)'),
              subtitle: const Text('Chia theo % đóng góp của mỗi thành viên'),
              value: 'auto',
              groupValue: _splitType,
              onChanged: (value) => setState(() => _splitType = value!),
            ),
            RadioListTile<String>(
              title: const Text('Chia đều'),
              subtitle: const Text('Chia đều cho tất cả thành viên'),
              value: 'equal',
              groupValue: _splitType,
              onChanged: (value) => setState(() => _splitType = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _addExpense,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: context.colorScheme.primary,
        foregroundColor: Colors.white,
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
          : const Text(
              'Thêm chi tiêu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }
}
