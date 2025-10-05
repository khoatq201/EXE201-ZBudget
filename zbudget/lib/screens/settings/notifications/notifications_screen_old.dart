import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../services/notification_service.dart';
import '../../../models/settings/notification_settings.dart';
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
      backgroundColor: AppColors.backgroundPrimary,
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
            backgroundColor: AppColors.primary500,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Thông báo',
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary500,
                      AppColors.primary500.withValues(alpha: 0.8),
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
                        color: Colors.white.withValues(alpha: 0.1),
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
                  _buildGlobalSettingsSection(settings),
                  const SizedBox(height: 24),

                  // Notification Types Section
                  _buildSectionHeader('Loại thông báo'),
                  const SizedBox(height: 16),
                  _buildNotificationTypesSection(settings),
                  const SizedBox(height: 24),

                  // Quiet Hours Section
                  _buildSectionHeader('Giờ im lặng'),
                  const SizedBox(height: 16),
                  _buildQuietHoursSection(settings),
                  const SizedBox(height: 24),

                  // Advanced Settings Section
                  _buildSectionHeader('Cài đặt nâng cao'),
                  const SizedBox(height: 16),
                  _buildAdvancedSettingsSection(settings),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
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
                        color: AppColors.textSecondary,
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
                  color: AppColors.primary500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${stats['enabledNotifications']}/${stats['totalNotifications']}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary500,
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
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.h4.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildGlobalSettingsSection(NotificationSettings settings) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                _notificationService.toggleGlobalNotifications(value),
            showDivider: true,
          ),

          // Group Notifications
          _buildSettingTile(
            icon: Icons.group_work,
            title: 'Nhóm thông báo',
            subtitle: 'Gộp thông báo cùng loại lại với nhau',
            value: settings.groupNotifications,
            onChanged: (value) =>
                _notificationService.toggleGroupNotifications(value),
            showDivider: true,
          ),

          // Show Preview
          _buildSettingTile(
            icon: Icons.preview,
            title: 'Hiển thị nội dung',
            subtitle: 'Xem trước nội dung trong thông báo',
            value: settings.showPreviewInNotifications,
            onChanged: (value) =>
                _notificationService.toggleShowPreviewInNotifications(value),
            showDivider: true,
          ),

          // Smart Notifications
          _buildSettingTile(
            icon: Icons.psychology,
            title: 'Thông báo thông minh',
            subtitle: 'Tự động điều chỉnh thông báo theo thói quen',
            value: settings.enableSmartNotifications,
            onChanged: (value) =>
                _notificationService.toggleSmartNotifications(value),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypesSection(NotificationSettings settings) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _enableAllNotifications(),
                      child: Text(
                        'Bật tất cả',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _disableAllNotifications(),
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
    bool showDivider = false,
  }) {
    final isEnabled = setting?.isEnabled ?? false;
    final subtitle = _getNotificationTypeSubtitle(type, setting);

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
                  ? AppColors.primary500.withValues(alpha: 0.1)
                  : AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              type.icon,
              color: isEnabled ? AppColors.primary500 : AppColors.textSecondary,
              size: 20,
            ),
          ),
          title: Text(
            type.displayName,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: isEnabled,
                onChanged: (value) => _toggleNotificationType(type, value),
                activeThumbColor: AppColors.primary500,
              ),
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => _showNotificationTypeSettings(type, setting),
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
  ) {
    if (setting == null || !setting.isEnabled) {
      return 'Đã tắt';
    }

    final frequency = setting.frequency.displayName;
    if (setting.scheduledTime != null) {
      final time = _notificationService.formatTime(setting.scheduledTime!);
      return '$frequency • $time';
    }

    return frequency;
  }

  Widget _buildQuietHoursSection(NotificationSettings settings) {
    final quietHours = settings.quietHours;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            onChanged: (value) => _notificationService.toggleQuietHours(value),
            showDivider: quietHours.isEnabled,
          ),

          // Quiet Hours Settings (only show if enabled)
          if (quietHours.isEnabled) ...[
            _buildActionTile(
              icon: Icons.schedule,
              title: 'Thời gian im lặng',
              subtitle: quietHours.timeRangeText,
              onTap: () => _showQuietHoursTimeDialog(),
              showDivider: true,
            ),
            _buildActionTile(
              icon: Icons.calendar_today,
              title: 'Ngày trong tuần',
              subtitle: quietHours.daysText,
              onTap: () => _showQuietHoursDaysDialog(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsSection(NotificationSettings settings) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            subtitle: _notificationService.getNotificationSoundDisplayName(
              settings.notificationSound,
            ),
            onTap: () => _showNotificationSoundDialog(),
            showDivider: true,
          ),

          // Max Notifications Per Day
          _buildActionTile(
            icon: Icons.numbers,
            title: 'Tối đa mỗi ngày',
            subtitle: '${settings.maxNotificationsPerDay} thông báo',
            onTap: () => _showMaxNotificationsDialog(),
            showDivider: true,
          ),

          // Reset Settings
          _buildActionTile(
            icon: Icons.restore,
            title: 'Đặt lại cài đặt',
            subtitle: 'Khôi phục về mặc định',
            onTap: () => _showResetSettingsDialog(),
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
              color: AppColors.primary500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary500, size: 20),
          ),
          title: Text(
            title,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary500,
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
              color: AppColors.primary500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary500, size: 20),
          ),
          title: Text(
            title,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
  ) async {
    await _notificationService.toggleNotificationType(type, enabled);
    setState(() {});
  }

  Future<void> _enableAllNotifications() async {
    await _notificationService.enableAllNotifications();
    setState(() {});
  }

  Future<void> _disableAllNotifications() async {
    await _notificationService.disableAllNotifications();
    setState(() {});
  }

  // Dialog methods
  void _showNotificationTypeSettings(
    NotificationType type,
    NotificationSetting? setting,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => NotificationTypeSettingsDialog(
        notificationType: type,
        initialSetting: setting,
        notificationService: _notificationService,
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  void _showQuietHoursTimeDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => QuietHoursDialog(
        initialQuietHours: _notificationService.notificationSettings.quietHours,
        notificationService: _notificationService,
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  void _showQuietHoursDaysDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => QuietHoursDialog(
        initialQuietHours: _notificationService.notificationSettings.quietHours,
        notificationService: _notificationService,
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  void _showNotificationSoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Âm thanh thông báo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _notificationService.availableNotificationSounds.map((
            sound,
          ) {
            return RadioListTile<String>(
              title: Text(
                _notificationService.getNotificationSoundDisplayName(sound),
              ),
              value: sound,
              groupValue:
                  _notificationService.notificationSettings.notificationSound,
              onChanged: (value) {
                if (value != null) {
                  _notificationService.updateNotificationSound(value);
                  Navigator.pop(context);
                  setState(() {});
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

  void _showMaxNotificationsDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MaxNotificationsDialog(
        initialValue:
            _notificationService.notificationSettings.maxNotificationsPerDay,
        notificationService: _notificationService,
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  void _showResetSettingsDialog() {
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
              await _notificationService.resetToDefaults();
              setState(() {});
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã đặt lại cài đặt thông báo')),
                );
              }
            },
            child: const Text('Đặt lại'),
          ),
        ],
      ),
    );
  }
}
