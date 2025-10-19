import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/typography.dart';
import '../../../services/notification_service.dart';
import '../../../utils/theme_extensions.dart';

class NotificationSettingsSimple extends StatelessWidget {
  const NotificationSettingsSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
        backgroundColor: context.headerGradientStart,
        foregroundColor: context.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          if (notificationService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final isGlobalEnabled =
              notificationService.notificationSettings.isGlobalEnabled;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: SwitchListTile(
                  title: Text(
                    'Nhận tất cả thông báo',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.settingsItemTitleColor,
                    ),
                  ),
                  subtitle: Text(
                    isGlobalEnabled
                        ? 'Bạn sẽ nhận được tất cả thông báo từ ứng dụng.'
                        : 'Bạn sẽ không nhận được bất kỳ thông báo nào từ ứng dụng.',
                    style: AppTypography.bodySmall.copyWith(
                      color: context.settingsItemSubtitleColor,
                    ),
                  ),
                  value: isGlobalEnabled,
                  onChanged: (value) {
                    notificationService.toggleGlobalNotifications(value);
                  },
                  activeColor: context.colorScheme.primary,
                ),
              ),
              // Optional: Add a small informational text if notifications are off
              if (!isGlobalEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Bạn có thể bật lại thông báo bất cứ lúc nào để không bỏ lỡ các cập nhật quan trọng.',
                    style: AppTypography.bodySmall.copyWith(
                      color: context.settingsItemSubtitleColor,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}




