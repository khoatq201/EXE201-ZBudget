import 'package:flutter/material.dart';
import '../../../models/settings/notification_settings.dart';
import '../../../utils/theme_extensions.dart';

class NotificationTypeSettingsDialog extends StatelessWidget {
  final NotificationSettings settings;
  final Function(NotificationSettings) onSave;

  const NotificationTypeSettingsDialog({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cài đặt loại thông báo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Thông báo toàn cục'),
            value: settings.isGlobalEnabled,
            onChanged: (value) {
              onSave(settings.copyWith(isGlobalEnabled: value));
            },
          ),
          SwitchListTile(
            title: const Text('Nhóm thông báo'),
            value: settings.groupNotifications,
            onChanged: (value) {
              onSave(settings.copyWith(groupNotifications: value));
            },
          ),
          SwitchListTile(
            title: const Text('Hiển thị preview'),
            value: settings.showPreviewInNotifications,
            onChanged: (value) {
              onSave(settings.copyWith(showPreviewInNotifications: value));
            },
          ),
          SwitchListTile(
            title: const Text('Thông báo thông minh'),
            value: settings.enableSmartNotifications,
            onChanged: (value) {
              onSave(settings.copyWith(enableSmartNotifications: value));
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class QuietHoursDialog extends StatelessWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Function(TimeOfDay, TimeOfDay) onSave;

  const QuietHoursDialog({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Giờ yên tĩnh'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Bắt đầu'),
            subtitle: Text(
              '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
            ),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: startTime,
              );
              if (time != null) {
                onSave(time, endTime);
              }
            },
          ),
          ListTile(
            title: const Text('Kết thúc'),
            subtitle: Text(
              '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
            ),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: endTime,
              );
              if (time != null) {
                onSave(startTime, time);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class MaxNotificationsDialog extends StatelessWidget {
  final int maxNotifications;
  final Function(int) onSave;

  const MaxNotificationsDialog({
    super.key,
    required this.maxNotifications,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Số thông báo tối đa'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: maxNotifications.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            label: maxNotifications.toString(),
            onChanged: (value) {
              onSave(value.round());
            },
          ),
          Text('Tối đa $maxNotifications thông báo mỗi ngày'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
