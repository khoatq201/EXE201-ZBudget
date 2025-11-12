import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/spacing.dart';
import '../../../utils/theme_extensions.dart';
import '../../../services/feedback_service.dart';

class MyFeedbacksScreen extends StatefulWidget {
  const MyFeedbacksScreen({super.key});

  @override
  State<MyFeedbacksScreen> createState() => _MyFeedbacksScreenState();
}

class _MyFeedbacksScreenState extends State<MyFeedbacksScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _feedbacks = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyFeedbacks();
  }

  Future<void> _loadMyFeedbacks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FeedbackService.getMyFeedbacks();

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _feedbacks = List<Map<String, dynamic>>.from(result['data'] ?? []);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Không thể tải phản hồi';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Có lỗi xảy ra: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  String _getTypeLabel(String type) {
    const labels = {
      'suggestion': 'Đề xuất',
      'bug': 'Báo lỗi',
      'compliment': 'Khen ngợi',
      'complaint': 'Phàn nàn',
    };
    return labels[type] ?? type;
  }

  Color _getTypeColor(String type) {
    const colors = {
      'suggestion': AppColors.primary500,
      'bug': AppColors.error,
      'compliment': AppColors.success,
      'complaint': AppColors.warning,
    };
    return colors[type] ?? AppColors.dark400;
  }

  IconData _getTypeIcon(String type) {
    const icons = {
      'suggestion': Icons.lightbulb_outline,
      'bug': Icons.bug_report,
      'compliment': Icons.favorite,
      'complaint': Icons.sentiment_dissatisfied,
    };
    return icons[type] ?? Icons.feedback;
  }

  String _getStatusLabel(String status) {
    const labels = {
      'pending': 'Đang chờ',
      'reviewed': 'Đã xem',
      'resolved': 'Đã giải quyết',
      'archived': 'Lưu trữ',
    };
    return labels[status] ?? status;
  }

  Color _getStatusColor(String status) {
    final colors = {
      'pending': AppColors.warning,
      'reviewed': AppColors.info,
      'resolved': AppColors.success,
      'archived': AppColors.dark400,
    };
    return colors[status] ?? AppColors.dark400;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.background,
      appBar: AppBar(
        backgroundColor: context.headerGradientStart,
        foregroundColor: context.headerTextColor,
        elevation: 0,
        title: const Text('Phản hồi của tôi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _feedbacks.isEmpty
                  ? _buildEmptyView()
                  : _buildFeedbackList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _errorMessage!,
              style: AppTypography.body.copyWith(
                color: context.settingsItemTitleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _loadMyFeedbacks,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feedback_outlined,
              size: 64,
              color: context.settingsItemSubtitleColor,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Chưa có phản hồi nào',
              style: AppTypography.h6.copyWith(
                color: context.settingsItemTitleColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Hãy gửi phản hồi đầu tiên của bạn',
              style: AppTypography.body.copyWith(
                color: context.settingsItemSubtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackList() {
    return RefreshIndicator(
      onRefresh: _loadMyFeedbacks,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        itemCount: _feedbacks.length,
        itemBuilder: (context, index) {
          final feedback = _feedbacks[index];
          return _buildFeedbackCard(feedback);
        },
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    final type = feedback['type'] as String? ?? '';
    final status = feedback['status'] as String? ?? 'pending';
    final rating = feedback['rating'] as int? ?? 0;
    final content = feedback['content'] as String? ?? '';
    final createdAt = feedback['createdAt'] as String?;
    final adminResponse = feedback['adminResponse'] as Map<String, dynamic>?;

    DateTime? date;
    if (createdAt != null) {
      try {
        date = DateTime.parse(createdAt);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showFeedbackDetail(feedback),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Type badge and status
                Row(
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getTypeColor(type).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTypeIcon(type),
                            size: 16,
                            color: _getTypeColor(type),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getTypeLabel(type),
                            style: AppTypography.caption.copyWith(
                              color: _getTypeColor(type),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusLabel(status),
                        style: AppTypography.caption.copyWith(
                          color: _getStatusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Rating stars
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: index < rating
                          ? context.colorScheme.secondary
                          : context.settingsItemSubtitleColor,
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Content preview
                Text(
                  content,
                  style: AppTypography.body.copyWith(
                    color: context.settingsItemTitleColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Footer: Date and admin response indicator
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: context.settingsItemSubtitleColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(date)
                          : 'N/A',
                      style: AppTypography.caption.copyWith(
                        color: context.settingsItemSubtitleColor,
                      ),
                    ),
                    if (adminResponse != null &&
                        adminResponse['message'] != null) ...[
                      const Spacer(),
                      Icon(
                        Icons.reply,
                        size: 14,
                        color: context.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Đã phản hồi',
                        style: AppTypography.caption.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFeedbackDetail(Map<String, dynamic> feedback) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FeedbackDetailSheet(feedback: feedback),
    );
  }
}

class _FeedbackDetailSheet extends StatelessWidget {
  final Map<String, dynamic> feedback;

  const _FeedbackDetailSheet({required this.feedback});

  String _getTypeLabel(String type) {
    const labels = {
      'suggestion': 'Đề xuất tính năng',
      'bug': 'Báo lỗi',
      'compliment': 'Khen ngợi',
      'complaint': 'Phàn nàn',
    };
    return labels[type] ?? type;
  }

  @override
  Widget build(BuildContext context) {
    final type = feedback['type'] as String? ?? '';
    final rating = feedback['rating'] as int? ?? 0;
    final content = feedback['content'] as String? ?? '';
    final createdAt = feedback['createdAt'] as String?;
    final adminResponse = feedback['adminResponse'] as Map<String, dynamic>?;

    DateTime? date;
    if (createdAt != null) {
      try {
        date = DateTime.parse(createdAt);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.settingsItemSubtitleColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type
                      Text(
                        _getTypeLabel(type),
                        style: AppTypography.h5.copyWith(
                          color: context.settingsItemTitleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Rating
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            size: 24,
                            color: index < rating
                                ? context.colorScheme.secondary
                                : context.settingsItemSubtitleColor,
                          );
                        }),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Date
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: context.settingsItemSubtitleColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            date != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(date)
                                : 'N/A',
                            style: AppTypography.body.copyWith(
                              color: context.settingsItemSubtitleColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Content
                      Text(
                        'Nội dung',
                        style: AppTypography.h6.copyWith(
                          color: context.settingsItemTitleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.cardBorder),
                        ),
                        child: Text(
                          content,
                          style: AppTypography.body.copyWith(
                            color: context.settingsItemTitleColor,
                          ),
                        ),
                      ),

                      // Admin response
                      if (adminResponse != null &&
                          adminResponse['message'] != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Phản hồi từ Admin',
                          style: AppTypography.h6.copyWith(
                            color: context.settingsItemTitleColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: context.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  context.colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            adminResponse['message'] as String,
                            style: AppTypography.body.copyWith(
                              color: context.settingsItemTitleColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Close button
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.primary,
                      foregroundColor: context.headerTextColor,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
