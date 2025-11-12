import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/spacing.dart';
import '../../../utils/theme_extensions.dart';
import '../../../services/feedback_service.dart';
import '../../../models/feedback.dart' as feedback_model;

class AllFeedbacksScreen extends StatefulWidget {
  const AllFeedbacksScreen({super.key});

  @override
  State<AllFeedbacksScreen> createState() => _AllFeedbacksScreenState();
}

class _AllFeedbacksScreenState extends State<AllFeedbacksScreen> {
  bool _isLoading = true;
  List<feedback_model.Feedback> _feedbacks = [];
  String? _errorMessage;
  String? _selectedType;
  String? _selectedStatus;

  final List<Map<String, dynamic>> _filterTypes = [
    {'value': null, 'label': 'Tất cả loại'},
    {'value': 'suggestion', 'label': 'Đề xuất'},
    {'value': 'bug', 'label': 'Báo lỗi'},
    {'value': 'compliment', 'label': 'Khen ngợi'},
    {'value': 'complaint', 'label': 'Phàn nàn'},
  ];

  final List<Map<String, dynamic>> _filterStatuses = [
    {'value': null, 'label': 'Tất cả trạng thái'},
    {'value': 'pending', 'label': 'Đang chờ'},
    {'value': 'reviewed', 'label': 'Đã xem'},
    {'value': 'resolved', 'label': 'Đã giải quyết'},
    {'value': 'archived', 'label': 'Lưu trữ'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAllFeedbacks();
  }

  Future<void> _loadAllFeedbacks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FeedbackService.getAllFeedbacks(
        type: _selectedType,
        status: _selectedStatus,
        limit: 100, // Load many for public view
      );

      if (mounted) {
        if (result['success'] == true) {
          final List<dynamic> rawData = result['data'] ?? [];
          setState(() {
            _feedbacks = rawData
                .map((json) => feedback_model.Feedback.fromJson(json as Map<String, dynamic>))
                .toList();
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
        title: const Text('Tất cả phản hồi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
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
              onPressed: _loadAllFeedbacks,
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
              _selectedType != null || _selectedStatus != null
                  ? 'Không có phản hồi phù hợp với bộ lọc'
                  : 'Chưa có phản hồi nào được gửi',
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
    return Column(
      children: [
        // Filter chips
        if (_selectedType != null || _selectedStatus != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.sm,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                if (_selectedType != null)
                  Chip(
                    label: Text(
                      _filterTypes
                          .firstWhere((e) => e['value'] == _selectedType)['label'],
                    ),
                    onDeleted: () {
                      setState(() => _selectedType = null);
                      _loadAllFeedbacks();
                    },
                  ),
                if (_selectedStatus != null)
                  Chip(
                    label: Text(
                      _filterStatuses
                          .firstWhere((e) => e['value'] == _selectedStatus)['label'],
                    ),
                    onDeleted: () {
                      setState(() => _selectedStatus = null);
                      _loadAllFeedbacks();
                    },
                  ),
              ],
            ),
          ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAllFeedbacks,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              itemCount: _feedbacks.length,
              itemBuilder: (context, index) {
                final feedback = _feedbacks[index];
                return _buildFeedbackCard(feedback);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackCard(feedback_model.Feedback feedback) {
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
                        color: _getTypeColor(feedback.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getTypeColor(feedback.type).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTypeIcon(feedback.type),
                            size: 16,
                            color: _getTypeColor(feedback.type),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            feedback.getTypeLabel(),
                            style: AppTypography.caption.copyWith(
                              color: _getTypeColor(feedback.type),
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
                        color: _getStatusColor(feedback.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        feedback.getStatusLabel(),
                        style: AppTypography.caption.copyWith(
                          color: _getStatusColor(feedback.status),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // User info
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: context.settingsItemSubtitleColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      feedback.name,
                      style: AppTypography.caption.copyWith(
                        color: context.settingsItemSubtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Rating stars
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < feedback.rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: index < feedback.rating
                          ? context.colorScheme.secondary
                          : context.settingsItemSubtitleColor,
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Content preview
                Text(
                  feedback.content,
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
                      DateFormat('dd/MM/yyyy HH:mm').format(feedback.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: context.settingsItemSubtitleColor,
                      ),
                    ),
                    if (feedback.adminResponse != null) ...[
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

  void _showFeedbackDetail(feedback_model.Feedback feedback) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FeedbackDetailSheet(feedback: feedback),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bộ lọc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Loại phản hồi'),
            DropdownButton<String?>(
              value: _selectedType,
              isExpanded: true,
              items: _filterTypes.map((filter) {
                return DropdownMenuItem<String?>(
                  value: filter['value'],
                  child: Text(filter['label']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Trạng thái'),
            DropdownButton<String?>(
              value: _selectedStatus,
              isExpanded: true,
              items: _filterStatuses.map((filter) {
                return DropdownMenuItem<String?>(
                  value: filter['value'],
                  child: Text(filter['label']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedStatus = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedStatus = null;
              });
              Navigator.pop(context);
              _loadAllFeedbacks();
            },
            child: const Text('Xóa bộ lọc'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadAllFeedbacks();
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }
}

class _FeedbackDetailSheet extends StatelessWidget {
  final feedback_model.Feedback feedback;

  const _FeedbackDetailSheet({required this.feedback});

  @override
  Widget build(BuildContext context) {
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
                        feedback.getTypeLabel(),
                        style: AppTypography.h5.copyWith(
                          color: context.settingsItemTitleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // User info
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 20,
                            color: context.settingsItemSubtitleColor,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                feedback.name,
                                style: AppTypography.body.copyWith(
                                  color: context.settingsItemTitleColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                feedback.email,
                                style: AppTypography.caption.copyWith(
                                  color: context.settingsItemSubtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Rating
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < feedback.rating ? Icons.star : Icons.star_border,
                            size: 24,
                            color: index < feedback.rating
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
                            DateFormat('dd/MM/yyyy HH:mm').format(feedback.createdAt),
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
                          feedback.content,
                          style: AppTypography.body.copyWith(
                            color: context.settingsItemTitleColor,
                          ),
                        ),
                      ),

                      // Device info
                      if (feedback.deviceInfo != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Thông tin thiết bị',
                          style: AppTypography.h6.copyWith(
                            color: context.settingsItemTitleColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${feedback.deviceInfo!.platform} - ${feedback.deviceInfo!.osVersion}',
                          style: AppTypography.caption.copyWith(
                            color: context.settingsItemSubtitleColor,
                          ),
                        ),
                      ],

                      // Admin response
                      if (feedback.adminResponse != null) ...[
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
                              color: context.colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            feedback.adminResponse!.message,
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
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
