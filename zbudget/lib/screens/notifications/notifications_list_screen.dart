import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../services/notification_sync_service.dart';
import '../../widgets/notification_badge.dart';

/// Notifications List Screen - Hiển thị danh sách thông báo
class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() =>
      _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';
  bool _showUnreadOnly = false;

  final List<String> _categories = [
    'all',
    'budget',
    'expense',
    'challenge',
    'group',
    'social',
    'system',
    'insights',
    'savings',
    'reminder',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final service = context.read<NotificationSyncService>();
    await service.fetchNotifications();
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }

  List<NotificationModel> _getFilteredNotifications() {
    final service = context.watch<NotificationSyncService>();
    var notifications = service.notifications;

    // Filter by category
    if (_selectedCategory != 'all') {
      notifications = notifications
          .where((n) => n.category == _selectedCategory)
          .toList();
    }

    // Filter by read status
    if (_showUnreadOnly) {
      notifications = notifications.where((n) => !n.isRead).toList();
    }

    return notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Chưa đọc'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
            itemBuilder: (context) => _categories.map((category) {
              return PopupMenuItem<String>(
                value: category,
                child: Row(
                  children: [
                    Icon(_getCategoryIcon(category)),
                    const SizedBox(width: 8),
                    Text(_getCategoryName(category)),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshNotifications,
          ),
        ],
      ),
      body: Consumer<NotificationSyncService>(
        builder: (context, service, child) {
          if (service.isLoading && service.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (service.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi tải thông báo',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshNotifications,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final notifications = _getFilteredNotifications();

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có thông báo',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedCategory == 'all'
                        ? 'Bạn chưa có thông báo nào'
                        : 'Không có thông báo trong danh mục này',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationsList(notifications),
              _buildNotificationsList(
                notifications.where((n) => !n.isRead).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications) {
    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return NotificationCard(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onMarkAsRead: () => _markAsRead(notification),
            onDelete: () => _deleteNotification(notification),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read if not already read
    if (!notification.isRead) {
      _markAsRead(notification);
    }

    // Navigate based on notification data
    _navigateFromNotification(notification);
  }

  void _navigateFromNotification(NotificationModel notification) {
    // Navigate based on notification type or data
    switch (notification.type) {
      case 'budget_alert':
        if (notification.data?.budgetId != null) {
          Navigator.pushNamed(
            context,
            '/budget/${notification.data!.budgetId}',
          );
        } else {
          Navigator.pushNamed(context, '/budgets');
        }
        break;
      case 'large_expense_alert':
        if (notification.data?.expenseId != null) {
          Navigator.pushNamed(
            context,
            '/expense/${notification.data!.expenseId}',
          );
        } else {
          Navigator.pushNamed(context, '/expenses');
        }
        break;
      case 'daily_expense_reminder':
        Navigator.pushNamed(context, '/expenses/add');
        break;
      case 'weekly_report':
      case 'monthly_report':
        Navigator.pushNamed(context, '/reports');
        break;
      case 'savings_reminder':
        if (notification.data?.goalId != null) {
          Navigator.pushNamed(context, '/savings/${notification.data!.goalId}');
        } else {
          Navigator.pushNamed(context, '/savings');
        }
        break;
      default:
        // Default to dashboard
        Navigator.pushNamed(context, '/dashboard');
        break;
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    final service = context.read<NotificationSyncService>();
    final success = await service.markAsRead(notification.id);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã đánh dấu đã đọc')));
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final service = context.read<NotificationSyncService>();
    final success = await service.deleteNotification(notification.id);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa thông báo')));
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'budget':
        return Icons.account_balance_wallet;
      case 'expense':
        return Icons.shopping_cart;
      case 'challenge':
        return Icons.emoji_events;
      case 'group':
        return Icons.group;
      case 'social':
        return Icons.favorite;
      case 'system':
        return Icons.notifications;
      case 'insights':
        return Icons.analytics;
      case 'savings':
        return Icons.savings;
      case 'reminder':
        return Icons.schedule;
      default:
        return Icons.all_inclusive;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'all':
        return 'Tất cả';
      case 'budget':
        return 'Ngân sách';
      case 'expense':
        return 'Chi tiêu';
      case 'challenge':
        return 'Thử thách';
      case 'group':
        return 'Nhóm';
      case 'social':
        return 'Xã hội';
      case 'system':
        return 'Hệ thống';
      case 'insights':
        return 'Phân tích';
      case 'savings':
        return 'Tiết kiệm';
      case 'reminder':
        return 'Nhắc nhở';
      default:
        return category;
    }
  }
}

/// Notification Card Widget
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: notification.isRead ? 1 : 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notification.priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  notification.categoryIcon,
                  color: notification.priorityColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and unread indicator
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: notification.priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Message
                    Text(
                      notification.message,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Footer
                    Row(
                      children: [
                        // Time
                        Text(
                          _formatTime(notification.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                        const SizedBox(width: 8),

                        // Priority badge
                        if (notification.priority == 'urgent' ||
                            notification.priority == 'high')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: notification.priorityColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              notification.priority == 'urgent'
                                  ? 'Khẩn cấp'
                                  : 'Quan trọng',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        const Spacer(),

                        // Action buttons
                        if (!notification.isRead && onMarkAsRead != null)
                          IconButton(
                            icon: const Icon(Icons.mark_email_read, size: 20),
                            onPressed: onMarkAsRead,
                            tooltip: 'Đánh dấu đã đọc',
                          ),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: onDelete,
                            tooltip: 'Xóa',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
