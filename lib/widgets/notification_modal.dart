import 'package:flutter/material.dart';
import 'dart:ui';
import '../constants/colors.dart';
import '../constants/typography.dart';

class NotificationData {
  final String id;
  final String type;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final String icon;
  final String priority;

  NotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.icon,
    required this.priority,
  });
}

class NotificationModal extends StatefulWidget {
  final bool visible;
  final VoidCallback onClose;
  final Function(NotificationData)? onNotificationPress;

  const NotificationModal({
    super.key,
    required this.visible,
    required this.onClose,
    this.onNotificationPress,
  });

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<NotificationData> notifications = [
    NotificationData(
      id: '1',
      type: 'debt',
      title: 'Nhắc nhở đòi nợ',
      message:
          'Minh Tú nợ bạn 150,000đ từ bữa ăn hôm qua. Hãy nhắc nhở bạn ấy!',
      time: '2 phút trước',
      isRead: false,
      icon: '💰',
      priority: 'high',
    ),
    NotificationData(
      id: '2',
      type: 'group_fund',
      title: 'Biến động quỹ nhóm',
      message: 'Nhóm "Du lịch Đà Lạt" đã có thêm 500,000đ từ Hoàng Nam',
      time: '1 giờ trước',
      isRead: false,
      icon: '👥',
      priority: 'medium',
    ),
    NotificationData(
      id: '3',
      type: 'feature',
      title: 'Tính năng mới',
      message: 'Tính năng quét hóa đơn bằng AI đã được cập nhật. Hãy thử ngay!',
      time: '3 giờ trước',
      isRead: true,
      icon: '🆕',
      priority: 'low',
    ),
    NotificationData(
      id: '4',
      type: 'budget',
      title: 'Vượt ngân sách',
      message: 'Bạn đã chi tiêu 85% ngân sách tháng này. Hãy cẩn thận!',
      time: '1 ngày trước',
      isRead: false,
      icon: '⚠️',
      priority: 'high',
    ),
    NotificationData(
      id: '5',
      type: 'reminder',
      title: 'Nhắc nhở tiết kiệm',
      message: 'Đừng quên mục tiêu tiết kiệm 2M đ trong tháng này!',
      time: '2 ngày trước',
      isRead: true,
      icon: '🎯',
      priority: 'medium',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    if (widget.visible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(NotificationModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _animationController.forward();
    } else if (!widget.visible && oldWidget.visible) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color getNotificationColor(String type) {
    switch (type) {
      case 'debt':
        return const Color(0xFFFF6B6B);
      case 'group_fund':
        return const Color(0xFF4ECDC4);
      case 'feature':
        return const Color(0xFF45B7D1);
      case 'budget':
        return const Color(0xFFFFA726);
      case 'reminder':
        return AppColors.primary500;
      default:
        return AppColors.primary500;
    }
  }

  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFFF6B6B);
      case 'medium':
        return const Color(0xFFFFA726);
      case 'low':
        return const Color(0xFF66BB6A);
      default:
        return const Color(0xFF66BB6A);
    }
  }

  String getTypeText(String type) {
    switch (type) {
      case 'debt':
        return 'Đòi nợ';
      case 'group_fund':
        return 'Quỹ nhóm';
      case 'feature':
        return 'Tính năng';
      case 'budget':
        return 'Ngân sách';
      case 'reminder':
        return 'Nhắc nhở';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.dark200, width: 1),
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thông báo',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notification List - Scrollable
                  Flexible(
                    child: notifications.isEmpty
                        ? _buildEmptyState()
                        : Container(
                            constraints: const BoxConstraints(
                              maxHeight: 350, // Max height for scroll area
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                return _buildNotificationItem(
                                  notifications[index],
                                );
                              },
                            ),
                          ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.dark200, width: 1),
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        // Mark all as read logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Đã đánh dấu tất cả đã đọc'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.done_all,
                            size: 16,
                            color: AppColors.primary500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Đánh dấu tất cả đã đọc',
                            style: AppTypography.body.copyWith(
                              color: AppColors.primary500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(NotificationData notification) {
    return GestureDetector(
      onTap: () => widget.onNotificationPress?.call(notification),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: !notification.isRead
              ? AppColors.primary500.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.dark200.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with priority dot
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: getNotificationColor(
                        notification.type,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        notification.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: getPriorityColor(notification.priority),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        notification.time,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Message
                  Text(
                    notification.message,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: getNotificationColor(notification.type),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          getTypeText(notification.type),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary500,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔔', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Không có thông báo',
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn sẽ nhận được thông báo về các hoạt động quan trọng tại đây',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
