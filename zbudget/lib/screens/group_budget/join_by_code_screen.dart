import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/group_budget_service.dart';
import '../../constants/typography.dart';
import '../../constants/spacing.dart';
import '../../utils/theme_extensions.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/currency_input_formatter.dart';

class JoinByCodeScreen extends StatefulWidget {
  const JoinByCodeScreen({super.key});

  @override
  State<JoinByCodeScreen> createState() => _JoinByCodeScreenState();
}

class _JoinByCodeScreenState extends State<JoinByCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _percentageController = TextEditingController();
  bool _isLoading = false;
  bool _showPercentage = true;

  @override
  void dispose() {
    _codeController.dispose();
    _percentageController.dispose();
    super.dispose();
  }

  Future<void> _joinBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = Provider.of<GroupBudgetService>(context, listen: false);
      final result = await service.joinByCode(
        _codeController.text.trim(),
        contributionPercentage: _showPercentage
            ? double.tryParse(_percentageController.text.trim())
            : null,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final budget = result['budget'];
        SnackBarUtils.showSuccess(
          context,
          'Đã tham gia "${budget?.name ?? 'ngân sách'}" thành công!',
        );
        context.go('/group-budgets');
      } else {
        SnackBarUtils.showError(
          context,
          result['message'] ?? 'Có lỗi xảy ra',
        );
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Lỗi: $e');
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
        title: const Text('Tham gia ngân sách'),
        backgroundColor: context.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // Illustration
            Icon(
              Icons.group_add,
              size: 120,
              color: context.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              'Nhập mã mời',
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Nhập mã 6 ký tự để tham gia ngân sách nhóm',
              style: AppTypography.body.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl2),

            // Invite Code Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Mã mời *',
                        hintText: 'Nhập 6 ký tự (VD: ABCD12)',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 8,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập mã mời';
                        }
                        if (value.trim().length < 6) {
                          return 'Mã mời phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SwitchListTile(
                      title: const Text('Nhập tỉ lệ đóng góp'),
                      subtitle: const Text('Bỏ qua nếu chưa biết tỉ lệ'),
                      value: _showPercentage,
                      onChanged: (value) {
                        setState(() => _showPercentage = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_showPercentage) ...[
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _percentageController,
                        decoration: const InputDecoration(
                          labelText: 'Tỉ lệ đóng góp (%)',
                          hintText: 'VD: 30',
                          prefixIcon: Icon(Icons.percent),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [PercentageInputFormatter()],
                        validator: (value) {
                          if (_showPercentage) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tỉ lệ đóng góp';
                            }
                            final percentage = double.tryParse(value);
                            if (percentage == null || percentage < 0 || percentage > 100) {
                              return 'Tỉ lệ phải từ 0-100%';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),

            // Join Button
            ElevatedButton(
              onPressed: _isLoading ? null : _joinBudget,
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
                      'Tham gia',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Info box
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Mã mời được cung cấp bởi người tạo ngân sách. Bạn có thể tìm thấy mã trên màn hình chi tiết ngân sách.',
                      style: AppTypography.bodySmall.copyWith(
                        color: context.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
