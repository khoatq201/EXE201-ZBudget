import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/typography.dart';
import '../../../services/notification_service.dart';
import '../../../models/settings/notification_settings.dart';
import '../../../utils/theme_extensions.dart';
import 'notification_dialogs.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          if (notificationService.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final settings = notificationService.notificationSettings;
          final stats = notificationService.getNotificationStatistics();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: context.headerGradientStart,
                foregroundColor: context.colorScheme.onPrimary,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Thông báo',
                    style: AppTypography.h3.copyWith(
                      color: context.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          context.headerGradientStart,
                          context.headerGradientEnd,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Icon(
                            Icons.notifications,
                            size: 150,
                            color: context.colorScheme.onPrimary.withOpacity(
                              0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notification Overview Card
                      _buildNotificationOverviewCard(settings, stats),
                      const SizedBox(height: 24),

                      // Global Settings Section
                      _buildSectionHeader('Cài đặt chung'),
                      const SizedBox(height: 16),
                      _buildGlobalSettingsSection(
                        settings,
                        notificationService,
                      ),
                      const SizedBox(height: 24),

                      // Notification Types Section
                      _buildSectionHeader('Loại thông báo'),
                      const SizedBox(height: 16),
                      _buildNotificationTypesSection(
                        settings,
                        notificationService,
                      ),
                      const SizedBox(height: 24),

                      // Quiet Hours Section
                      _buildSectionHeader('Giờ im lặng'),
                      const SizedBox(height: 16),
                      _buildQuietHoursSection(settings, notificationService),
                      const SizedBox(height: 24),

                      // Advanced Settings Section
                      _buildSectionHeader('Cài đặt nâng cao'),
                      const SizedBox(height: 16),
                      _buildAdvancedSettingsSection(
                        settings,
                        notificationService,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationOverviewCard(
    NotificationSettings settings,
    Map<String, dynamic> stats,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: settings.isGlobalEnabled
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  settings.isGlobalEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: settings.isGlobalEnabled
                      ? Colors.green
                      : Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trạng thái thông báo',
                      style: AppTypography.body.copyWith(
                        color: context.notificationCardSubtext,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settings.isGlobalEnabled ? 'Đang bật' : 'Đang tắt',
                      style: AppTypography.h4.copyWith(
                        color: settings.isGlobalEnabled
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${stats['enabledNotifications']}/${stats['totalNotifications']}',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Đã bật',
                '${stats['enabledNotifications']}',
                Colors.green,
              ),
              _buildStatItem(
                'Đã tắt',
                '${stats['disabledNotifications']}',
                Colors.red,
              ),
              _buildStatItem(
                'Im lặng',
                settings.quietHours.isEnabled ? 'Bật' : 'Tắt',
                settings.quietHours.isEnabled ? Colors.blue : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.h4.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: context.notificationCardSubtext,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.h4.copyWith(
        fontWeight: FontWeight.bold,
        color: context.settingsSectionTitle,
      ),
    );
  }

  Widget _buildGlobalSettingsSection(
    NotificationSettings settings,
    NotificationService notificationService,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Global Notifications Toggle
          _buildSettingTile(
            icon: Icons.notifications,
            title: 'Tất cả thông báo',
            subtitle: settings.isGlobalEnabled
                ? 'Đang nhận thông báo'
                : 'Đã tắt thông báo',
            value: settings.isGlobalEnabled,
            onChanged: (value) =>
                notificationService.toggleGlobalNotifications(value),
            showDivider: true,
          ),

          // Group Notifications
          _buildSettingTile(
            icon: Icons.group_work,
            title: 'Nhóm thông báo',
            subtitle: 'Gộp thông báo cùng loại lại với nhau',
            value: settings.groupNotifications,
            onChanged: (value) =>
                notificationService.toggleGroupNotifications(value),
            showDivider: true,
          ),

          // Show Preview
          _buildSettingTile(
            icon: Icons.preview,
            title: 'Hiển thị nội dung',
            subtitle: 'Xem trước nội dung trong thông báo',
            value: settings.showPreviewInNotifications,
            onChanged: (value) =>
                notificationService.toggleShowPreviewInNotifications(value),
            showDivider: true,
          ),

          // Smart Notifications
          _buildSettingTile(
            icon: Icons.psychology,
            title: 'Thông báo thông minh',
            subtitle: 'Tự động điều chỉnh thông báo theo thói quen',
            value: settings.enableSmartNotifications,
            onChanged: (value) =>
                notificationService.toggleSmartNotifications(value),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypesSection(
    NotificationSettings settings,
    NotificationService notificationService,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with bulk actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tùy chỉnh từng loại',
                  style: AppTypography.body.copyWith(
                    color: context.notificationCardSubtext,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          _enableAllNotifications(notificationService),
                      child: Text(
                        'Bật tất cả',
                        style: AppTypography.bodySmall.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () =>
                          _disableAllNotifications(notificationService),
                      child: Text(
                        'Tắt tất cả',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notification type list
          ...NotificationType.values.asMap().entries.map((entry) {
            final index = entry.key;
            final type = entry.value;
            final setting = settings.getSettingForType(type);
            final isLast = index == NotificationType.values.length - 1;

            return _buildNotificationTypeTile(
              type: type,
              setting: setting,
              notificationService: notificationService,
              showDivider: !isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNotificationTypeTile({
    required NotificationType type,
    NotificationSetting? setting,
    required NotificationService notificationService,
    bool showDivider = false,
  }) {
    final isEnabled = setting?.isEnabled ?? false;
    final subtitle = _getNotificationTypeSubtitle(
      type,
      setting,
      notificationService,
    );

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled
                  ? context.notificationIconBackground
                  : context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              type.icon,
              color: isEnabled
                  ? context.notificationIconColor
                  : context.notificationCardSubtext,
              size: 20,
            ),
          ),
          title: Text(
            type.displayName,
            style: AppTypography.body.copyWith(
              color: context.notificationCardText,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: context.notificationCardSubtext,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: isEnabled,
                onChanged: (value) =>
                    _toggleNotificationType(type, value, notificationService),
                activeColor: context.colorScheme.primary,
              ),
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: context.notificationCardSubtext,
                  size: 20,
                ),
                onPressed: () => _showNotificationTypeSettings(
                  type,
                  setting,
                  notificationService,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  String _getNotificationTypeSubtitle(
    NotificationType type,
    NotificationSetting? setting,
    NotificationService notificationService,
  ) {
    if (setting == null || !setting.isEnabled) {
      return 'Đã tắt';
    }

    final frequency = setting.frequency.displayName;
    if (setting.scheduledTime != null) {
      final time = notificationService.formatTime(setting.scheduledTime!);
      return '$frequency • $time';
    }

    return frequency;
  }

  Widget _buildQuietHoursSection(
    NotificationSettings settings,
    NotificationService notificationService,
  ) {
    final quietHours = settings.quietHours;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Quiet Hours Toggle
          _buildSettingTile(
            icon: Icons.bedtime,
            title: 'Bật giờ im lặng',
            subtitle: quietHours.isEnabled
                ? '${quietHours.timeRangeText} • ${quietHours.daysText}'
                : 'Nhận thông báo mọi lúc',
            value: quietHours.isEnabled,
            onChanged: (value) => notificationService.toggleQuietHours(value),
            showDivider: quietHours.isEnabled,
          ),

          // Quiet Hours Settings (only show if enabled)
          if (quietHours.isEnabled) ...[
            _buildActionTile(
              icon: Icons.schedule,
              title: 'Thời gian im lặng',
              subtitle: quietHours.timeRangeText,
              onTap: () => _showQuietHoursTimeDialog(notificationService),
              showDivider: true,
            ),
            _buildActionTile(
              icon: Icons.calendar_today,
              title: 'Ngày trong tuần',
              subtitle: quietHours.daysText,
              onTap: () => _showQuietHoursDaysDialog(notificationService),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsSection(
    NotificationSettings settings,
    NotificationService notificationService,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Notification Sound
          _buildActionTile(
            icon: Icons.volume_up,
            title: 'Âm thanh thông báo',
            subtitle: notificationService.getNotificationSoundDisplayName(
              settings.notificationSound,
            ),
            onTap: () => _showNotificationSoundDialog(notificationService),
            showDivider: true,
          ),

          // Max Notifications Per Day
          _buildActionTile(
            icon: Icons.numbers,
            title: 'Tối đa mỗi ngày',
            subtitle: '${settings.maxNotificationsPerDay} thông báo',
            onTap: () => _showMaxNotificationsDialog(notificationService),
            showDivider: true,
          ),

          // Reset Settings
          _buildActionTile(
            icon: Icons.restore,
            title: 'Đặt lại cài đặt',
            subtitle: 'Khôi phục về mặc định',
            onTap: () => _showResetSettingsDialog(notificationService),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.notificationIconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: context.notificationIconColor, size: 20),
          ),
          title: Text(
            title,
            style: AppTypography.body.copyWith(
              color: context.notificationCardText,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: context.notificationCardSubtext,
            ),
          ),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: context.colorScheme.primary,
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.notificationIconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: context.notificationIconColor, size: 20),
          ),
          title: Text(
            title,
            style: AppTypography.body.copyWith(
              color: context.notificationCardText,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: context.notificationCardSubtext,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: context.notificationCardSubtext,
          ),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  // Handler methods
  Future<void> _toggleNotificationType(
    NotificationType type,
    bool enabled,
    NotificationService notificationService,
  ) async {
    await notificationService.toggleNotificationType(type, enabled);
  }

  Future<void> _enableAllNotifications(
    NotificationService notificationService,
  ) async {
    await notificationService.enableAllNotifications();
  }

  Future<void> _disableAllNotifications(
    NotificationService notificationService,
  ) async {
    await notificationService.disableAllNotifications();
  }

  // Dialog methods
  void _showNotificationTypeSettings(
    NotificationType type,
    NotificationSetting? setting,
    NotificationService notificationService,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => NotificationTypeSettingsDialog(
        settings: notificationService.notificationSettings,
        onSave: (newSettings) {
          // Handle save logic here
        },
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  void _showQuietHoursTimeDialog(
    NotificationService notificationService,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => QuietHoursDialog(
        startTime:
            notificationService.notificationSettings.quietHours.startTime,
        endTime: notificationService.notificationSettings.quietHours.endTime,
        onSave: (start, end) {
          // Handle save logic here
        },
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  void _showQuietHoursDaysDialog(
    NotificationService notificationService,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => QuietHoursDialog(
        startTime:
            notificationService.notificationSettings.quietHours.startTime,
        endTime: notificationService.notificationSettings.quietHours.endTime,
        onSave: (start, end) {
          // Handle save logic here
        },
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  void _showNotificationSoundDialog(NotificationService notificationService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Âm thanh thông báo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: notificationService.availableNotificationSounds.map((
            sound,
          ) {
            return RadioListTile<String>(
              title: Text(
                notificationService.getNotificationSoundDisplayName(sound),
              ),
              value: sound,
              groupValue:
                  notificationService.notificationSettings.notificationSound,
              onChanged: (value) {
                if (value != null) {
                  notificationService.updateNotificationSound(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _showMaxNotificationsDialog(
    NotificationService notificationService,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MaxNotificationsDialog(
        maxNotifications:
            notificationService.notificationSettings.maxNotificationsPerDay,
        onSave: (value) {
          // Handle save logic here
        },
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  void _showResetSettingsDialog(NotificationService notificationService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt lại cài đặt'),
        content: const Text(
          'Bạn có chắc chắn muốn đặt lại tất cả cài đặt thông báo về mặc định? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await notificationService.resetToDefaults();
            },
            child: const Text('Đặt lại'),
          ),
        ],
      ),
    );
  }
}
