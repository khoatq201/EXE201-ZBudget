import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/backend_ocr_service.dart';
import '../constants/typography.dart';
import '../constants/spacing.dart';
import '../constants/colors.dart';
import '../utils/theme_extensions.dart';
import '../utils/currency_formatter.dart';

/// Widget for previewing and editing OCR results
class OCRResultPreview extends StatefulWidget {
  final ReceiptData receiptData;
  final Function(ReceiptData) onConfirm;
  final VoidCallback onCancel;

  const OCRResultPreview({
    super.key,
    required this.receiptData,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<OCRResultPreview> createState() => _OCRResultPreviewState();
}

class _OCRResultPreviewState extends State<OCRResultPreview> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;

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
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.receiptData.amount > 0
          ? CurrencyFormatter.format(widget.receiptData.amount)
          : '',
    );
    _descriptionController = TextEditingController(
      text: widget.receiptData.description,
    );
    _selectedCategory = widget.receiptData.category;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem trước kết quả'),
        actions: [
          TextButton(onPressed: _confirmResult, child: const Text('Xác nhận')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfidenceIndicator(),
            const SizedBox(height: AppSpacing.lg),
            _buildAmountSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildDescriptionSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildCategorySection(),
            const SizedBox(height: AppSpacing.lg),
            _buildStoreInfoSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildItemsSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    final confidence = widget.receiptData.confidence;
    Color confidenceColor;
    String confidenceText;

    if (confidence >= 0.8) {
      confidenceColor = Colors.green;
      confidenceText = 'Độ tin cậy cao';
    } else if (confidence >= 0.6) {
      confidenceColor = Colors.orange;
      confidenceText = 'Độ tin cậy trung bình';
    } else {
      confidenceColor = Colors.red;
      confidenceText = 'Độ tin cậy thấp';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: confidenceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: confidenceColor),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: confidenceColor),
          const SizedBox(width: 8),
          Text(
            confidenceText,
            style: TextStyle(
              color: confidenceColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${(confidence * 100).toInt()}%',
            style: TextStyle(
              color: confidenceColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Số tiền',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Nhập số tiền',
            suffixText: 'VND',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.attach_money),
          ),
          onChanged: (value) {
            // Validate amount
            final amount = CurrencyFormatter.parse(value);
            if (amount <= 0) {
              setState(() {});
            }
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mô tả',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Nhập mô tả chi tiêu',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.description),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh mục',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category['value'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['value']!;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colorScheme.primary
                      : context.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? context.colorScheme.primary
                        : context.colorScheme.outline,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category['icon']!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      category['label']!,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : context.colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.bold
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

  Widget _buildStoreInfoSection() {
    if (!widget.receiptData.hasStoreName) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin cửa hàng',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.colorScheme.outline),
          ),
          child: Row(
            children: [
              const Icon(Icons.store, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.receiptData.storeName,
                  style: AppTypography.body,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    if (!widget.receiptData.hasItems) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Các món đã mua',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.receiptData.items
            .map(
              (item) => Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: context.colorScheme.outline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: AppTypography.bodySmall)),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hủy'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _confirmResult,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Xác nhận'),
          ),
        ),
      ],
    );
  }

  void _confirmResult() {
    final amount = CurrencyFormatter.parse(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedReceiptData = ReceiptData(
      amount: amount,
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      date: widget.receiptData.date,
      storeName: widget.receiptData.storeName,
      items: widget.receiptData.items,
      rawText: widget.receiptData.rawText,
      confidence: widget.receiptData.confidence,
    );

    widget.onConfirm(updatedReceiptData);
  }
}
