import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/group_budget_service.dart';
import '../../constants/typography.dart';
import '../../constants/spacing.dart';
import '../../utils/theme_extensions.dart';
import '../../utils/currency_input_formatter.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/receipt_scanner_widget.dart';
import '../../widgets/ocr_result_preview.dart';
import '../../services/receipt_parser_service.dart';

class AddGroupExpenseScreen extends StatefulWidget {
  final String budgetId;

  const AddGroupExpenseScreen({super.key, required this.budgetId});

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
        amount: CurrencyFormatter.parse(_amountController.text),
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
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle OCR receipt scanning
  void _scanReceipt() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReceiptScannerWidget(
          onReceiptScanned: _handleReceiptScanned,
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// Handle OCR result
  void _handleReceiptScanned(ReceiptData receiptData) {
    Navigator.of(context).pop(); // Close scanner

    // Show preview with ability to edit
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OCRResultPreview(
          receiptData: receiptData,
          onConfirm: _handleOCRConfirmed,
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// Handle confirmed OCR result
  void _handleOCRConfirmed(ReceiptData receiptData) {
    Navigator.of(context).pop(); // Close preview

    // Auto-fill form with OCR data
    setState(() {
      _descriptionController.text = receiptData.description;
      _amountController.text = CurrencyFormatter.format(receiptData.amount);
      _category = receiptData.category;

      if (receiptData.storeName.isNotEmpty) {
        _notesController.text = 'Cửa hàng: ${receiptData.storeName}';
      }
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã tự động điền thông tin từ hóa đơn'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Thông tin chi tiêu',
                    style: AppTypography.h6.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _scanReceipt,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Quét hóa đơn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
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
                hintText: '100.000',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'VND',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [VNDInputFormatter()],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số tiền';
                }
                final amount = CurrencyFormatter.parse(value);
                if (amount <= 0) {
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
