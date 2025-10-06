import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/spacing.dart';
import '../../../utils/theme_extensions.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _feedbackController = TextEditingController();

  String _selectedType = 'suggestion';
  int _rating = 0;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _feedbackTypes = [
    {
      'value': 'suggestion',
      'label': 'Đề xuất tính năng',
      'icon': Icons.lightbulb_outline,
      'color': AppColors.primary500,
    },
    {
      'value': 'bug',
      'label': 'Báo lỗi',
      'icon': Icons.bug_report,
      'color': AppColors.error,
    },
    {
      'value': 'compliment',
      'label': 'Khen ngợi',
      'icon': Icons.favorite,
      'color': AppColors.success,
    },
    {
      'value': 'complaint',
      'label': 'Phàn nàn',
      'icon': Icons.sentiment_dissatisfied,
      'color': AppColors.warning,
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.background,
      appBar: AppBar(
        backgroundColor: context.headerGradientStart,
        foregroundColor: context.colorScheme.onPrimary,
        elevation: 0,
        title: const Text('Gửi phản hồi'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            // Header Message
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.only(bottom: AppSpacing.sectionSpacing),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.feedback,
                    size: 48,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Ý kiến của bạn rất quan trọng!',
                    style: AppTypography.h6.copyWith(
                      color: context.settingsItemTitleColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Hãy chia sẻ trải nghiệm của bạn để chúng tôi cải thiện ứng dụng tốt hơn.',
                    style: AppTypography.bodySmall.copyWith(
                      color: context.settingsItemSubtitleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Feedback Type Selection
            _buildFeedbackTypeSection(),

            const SizedBox(height: AppSpacing.sectionSpacing),

            // Rating Section
            _buildRatingSection(),

            const SizedBox(height: AppSpacing.sectionSpacing),

            // Personal Information
            _buildPersonalInfoSection(),

            const SizedBox(height: AppSpacing.sectionSpacing),

            // Feedback Content
            _buildFeedbackContentSection(),

            const SizedBox(height: AppSpacing.xl),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: AppColors.textInverse,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textInverse,
                          ),
                        ),
                      )
                    : const Text(
                        'Gửi phản hồi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loại phản hồi',
          style: AppTypography.h6.copyWith(
            color: context.settingsItemTitleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _feedbackTypes.length,
          itemBuilder: (context, index) {
            final type = _feedbackTypes[index];
            final isSelected = _selectedType == type['value'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = type['value'];
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (type['color'] as Color).withOpacity(0.1)
                      : context.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (type['color'] as Color)
                        : context.cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type['icon'],
                      color: isSelected
                          ? (type['color'] as Color)
                          : context.settingsItemSubtitleColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        type['label'],
                        style: AppTypography.bodySmall.copyWith(
                          color: isSelected
                              ? (type['color'] as Color)
                              : context.settingsItemSubtitleColor,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đánh giá trải nghiệm',
          style: AppTypography.h6.copyWith(
            color: context.settingsItemTitleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Bạn cảm thấy thế nào về ứng dụng?',
                style: AppTypography.body.copyWith(
                  color: context.settingsItemTitleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = starIndex;
                      });
                    },
                    child: Icon(
                      starIndex <= _rating ? Icons.star : Icons.star_border,
                      color: starIndex <= _rating
                          ? context.colorScheme.secondary
                          : context.settingsItemSubtitleColor,
                      size: 36,
                    ),
                  );
                }),
              ),
              if (_rating > 0) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _getRatingText(_rating),
                  style: AppTypography.bodySmall.copyWith(
                    color: context.settingsItemSubtitleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin liên hệ',
          style: AppTypography.h6.copyWith(
            color: context.settingsItemTitleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Họ và tên',
            hintText: 'Nhập họ và tên của bạn',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: context.inputFieldBackground,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập họ và tên';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Nhập địa chỉ email của bạn',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: context.inputFieldBackground,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Email không hợp lệ';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFeedbackContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nội dung phản hồi',
          style: AppTypography.h6.copyWith(
            color: context.settingsItemTitleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _feedbackController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Chia sẻ chi tiết về trải nghiệm của bạn...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: context.inputFieldBackground,
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập nội dung phản hồi';
            }
            if (value.length < 10) {
              return 'Nội dung phản hồi quá ngắn (tối thiểu 10 ký tự)';
            }
            return null;
          },
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Rất không hài lòng 😞';
      case 2:
        return 'Không hài lòng 😐';
      case 3:
        return 'Bình thường 🙂';
      case 4:
        return 'Hài lòng 😊';
      case 5:
        return 'Rất hài lòng 🤩';
      default:
        return '';
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng đánh giá trải nghiệm của bạn'),
          backgroundColor: context.colorScheme.secondary,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: context.colorScheme.secondary,
                  size: 64,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Cảm ơn bạn!',
                  style: AppTypography.h6.copyWith(
                    color: context.settingsItemTitleColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Phản hồi của bạn đã được gửi thành công. Chúng tôi sẽ xem xét và phản hồi sớm nhất có thể.',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.settingsItemSubtitleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to settings
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.secondary,
                    foregroundColor: context.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra. Vui lòng thử lại!'),
            backgroundColor: AppColors.error,
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
}
