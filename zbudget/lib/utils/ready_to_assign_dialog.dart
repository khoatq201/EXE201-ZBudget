import 'package:flutter/material.dart';
import '../constants/typography.dart';
import 'formatters.dart';

/// Dialog to show when user doesn't have enough Ready to Assign funds
class ReadyToAssignDialog {
  static void showInsufficientFundsDialog(
    BuildContext context, {
    required double available,
    required double needed,
    required String action, // 'chi tiêu', 'tiết kiệm', etc.
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: const Text('Không đủ tiền Ready to Assign'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn không thể $action vì không có đủ tiền chưa phân bổ.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildAmountRow(
              context,
              'Có sẵn:',
              available,
              Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _buildAmountRow(
              context,
              'Cần:',
              needed,
              Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            _buildAmountRow(
              context,
              'Thiếu:',
              needed - available,
              Theme.of(context).colorScheme.error,
              bold: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Giải pháp:',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Thêm thu nhập mới\n'
                    '• Gắn $action vào budget đã có\n'
                    '• Phân bổ từ thu nhập có sẵn',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to add income screen
              // context.push('/income/add');
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm thu nhập'),
          ),
        ],
      ),
    );
  }

  static Widget _buildAmountRow(
    BuildContext context,
    String label,
    double amount,
    Color color, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          amount.toVND(),
          style: AppTypography.bodyMedium.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Parse error message from backend and show appropriate dialog
  static void showErrorIfInsufficientFunds(
    BuildContext context,
    String errorMessage,
    String action,
  ) {
    // Parse error message format:
    // "Không đủ tiền Ready to Assign. Có sẵn: 500,000 đ, cần: 1,000,000 đ. ..."
    if (errorMessage.contains('Ready to Assign')) {
      final regex = RegExp(r'Có sẵn: ([\d,]+).*cần: ([\d,]+)');
      final match = regex.firstMatch(errorMessage);

      if (match != null) {
        final availableStr = match.group(1)?.replaceAll(',', '') ?? '0';
        final neededStr = match.group(2)?.replaceAll(',', '') ?? '0';

        final available = double.tryParse(availableStr) ?? 0;
        final needed = double.tryParse(neededStr) ?? 0;

        showInsufficientFundsDialog(
          context,
          available: available,
          needed: needed,
          action: action,
        );
        return;
      }
    }

    // Fallback: show generic error
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: const Text('Lỗi'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
