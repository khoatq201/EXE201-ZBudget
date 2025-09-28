import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../models/settings/notification_settings.dart';
import '../../../services/notification_service.dart';

class NotificationTypeSettingsDialog extends StatefulWidget {
  final NotificationType notificationType;
  final NotificationSetting? initialSetting;
  final NotificationService notificationService;

  const NotificationTypeSettingsDialog({
    super.key,
    required this.notificationType,
    required this.initialSetting,
    required this.notificationService,
  });

  @override
  State<NotificationTypeSettingsDialog> createState() =>
      _NotificationTypeSettingsDialogState();
}

class _NotificationTypeSettingsDialogState
    extends State<NotificationTypeSettingsDialog> {
  late bool _isEnabled;
  late NotificationFrequency _frequency;
  TimeOfDay? _scheduledTime;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.initialSetting?.isEnabled ?? true;
    _frequency =
        widget.initialSetting?.frequency ?? NotificationFrequency.immediately;
    _scheduledTime = widget.initialSetting?.scheduledTime;
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.notificationType.icon,
              color: AppColors.primary500,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.notificationType.displayName,
              style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Text(
              _getNotificationTypeDescription(widget.notificationType),
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Enable/Disable Toggle
            SwitchListTile(
              title: Text(
                'Bật thông báo',
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _isEnabled
                    ? 'Nhận thông báo cho loại này'
                    : 'Không nhận thông báo',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              value: _isEnabled,
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary500;
                }
                return null;
              }),
              onChanged: (value) {
                setState(() {
                  _isEnabled = value;
                });
                _markAsChanged();
              },
            ),

            if (_isEnabled) ...[
              const Divider(height: 32),

              // Frequency Settings
              Text(
                'Tần suất thông báo',
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              ...NotificationFrequency.values.map((frequency) {
                return RadioListTile<NotificationFrequency>(
                  title: Text(frequency.displayName, style: AppTypography.body),
                  subtitle: Text(
                    _getFrequencyDescription(frequency),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: frequency,
                  groupValue: _frequency,
                  activeColor: AppColors.primary500,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _frequency = value;
                        // Reset scheduled time if frequency changes
                        if (value != NotificationFrequency.daily &&
                            value != NotificationFrequency.weekly) {
                          _scheduledTime = null;
                        }
                      });
                      _markAsChanged();
                    }
                  },
                );
              }),

              // Scheduled Time (for daily/weekly frequencies)
              if (_frequency == NotificationFrequency.daily ||
                  _frequency == NotificationFrequency.weekly) ...[
                const Divider(height: 32),

                ListTile(
                  leading: Icon(Icons.schedule, color: AppColors.primary500),
                  title: Text(
                    'Thời gian nhắc nhở',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _scheduledTime != null
                        ? widget.notificationService.formatTime(_scheduledTime!)
                        : 'Chưa đặt thời gian',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () => _showTimePicker(),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Hủy',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _hasChanges
                ? AppColors.primary500
                : AppColors.textSecondary,
          ),
          onPressed: _hasChanges ? _saveSettings : null,
          child: Text(
            'Lưu',
            style: AppTypography.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getNotificationTypeDescription(NotificationType type) {
    switch (type) {
      case NotificationType.budget:
        return 'Thông báo về tình trạng ngân sách, vượt hạn mức chi tiêu';
      case NotificationType.expense:
        return 'Thông báo khi có khoản chi tiêu mới được ghi nhận';
      case NotificationType.income:
        return 'Thông báo khi có thu nhập mới được ghi nhận';
      case NotificationType.challenge:
        return 'Thông báo về thử thách tiết kiệm và tiến độ hoàn thành';
      case NotificationType.reminder:
        return 'Nhắc nhở thanh toán hóa đơn, cập nhật chi tiêu';
      case NotificationType.achievement:
        return 'Thông báo khi đạt được thành tựu hoặc mục tiêu';
      case NotificationType.security:
        return 'Cảnh báo bảo mật, đăng nhập từ thiết bị mới';
      case NotificationType.system:
        return 'Thông báo hệ thống, cập nhật ứng dụng';
      case NotificationType.marketing:
        return 'Tin tức, khuyến mãi và tính năng mới';
    }
  }

  String _getFrequencyDescription(NotificationFrequency frequency) {
    switch (frequency) {
      case NotificationFrequency.immediately:
        return 'Thông báo ngay lập tức khi có sự kiện';
      case NotificationFrequency.daily:
        return 'Tổng hợp thông báo một lần mỗi ngày';
      case NotificationFrequency.weekly:
        return 'Tổng hợp thông báo một lần mỗi tuần';
      case NotificationFrequency.monthly:
        return 'Tổng hợp thông báo một lần mỗi tháng';
      case NotificationFrequency.never:
        return 'Không bao giờ thông báo';
    }
  }

  Future<void> _showTimePicker() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary500),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _scheduledTime = time;
      });
      _markAsChanged();
    }
  }

  Future<void> _saveSettings() async {
    final setting = NotificationSetting(
      type: widget.notificationType,
      isEnabled: _isEnabled,
      frequency: _frequency,
      scheduledTime: _scheduledTime,
    );

    await widget.notificationService.updateNotificationSetting(
      widget.notificationType,
      setting,
    );

    if (mounted) {
      Navigator.pop(
        context,
        true,
      ); // Return true to indicate changes were saved
    }
  }
}

class QuietHoursDialog extends StatefulWidget {
  final QuietHours initialQuietHours;
  final NotificationService notificationService;

  const QuietHoursDialog({
    super.key,
    required this.initialQuietHours,
    required this.notificationService,
  });

  @override
  State<QuietHoursDialog> createState() => _QuietHoursDialogState();
}

class _QuietHoursDialogState extends State<QuietHoursDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Set<int> _selectedDays;
  bool _hasChanges = false;

  final List<String> _dayNames = [
    'Chủ nhật',
    'Thứ hai',
    'Thứ ba',
    'Thứ tư',
    'Thứ năm',
    'Thứ sáu',
    'Thứ bảy',
  ];

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialQuietHours.startTime;
    _endTime = widget.initialQuietHours.endTime;
    _selectedDays = Set.from(widget.initialQuietHours.selectedDays);
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.bedtime, color: AppColors.primary500, size: 24),
          const SizedBox(width: 12),
          const Text('Cài đặt giờ im lặng'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Text(
              'Trong khoảng thời gian này, bạn sẽ không nhận được thông báo từ ứng dụng.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Time Range
            Text(
              'Khoảng thời gian',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildTimeSelector(
                    label: 'Bắt đầu',
                    time: _startTime,
                    onTap: () => _showTimePicker(isStartTime: true),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.arrow_forward, color: AppColors.textSecondary),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeSelector(
                    label: 'Kết thúc',
                    time: _endTime,
                    onTap: () => _showTimePicker(isStartTime: false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Days Selection
            Text(
              'Ngày trong tuần',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final isSelected = _selectedDays.contains(index);
                return FilterChip(
                  label: Text(
                    _dayNames[index],
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(index);
                      } else {
                        _selectedDays.remove(index);
                      }
                    });
                    _markAsChanged();
                  },
                  selectedColor: AppColors.primary500,
                  checkmarkColor: Colors.white,
                );
              }),
            ),

            const SizedBox(height: 16),

            // Quick selection buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDays = {1, 2, 3, 4, 5}; // Weekdays
                    });
                    _markAsChanged();
                  },
                  child: Text(
                    'Ngày làm việc',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDays = {0, 6}; // Weekend
                    });
                    _markAsChanged();
                  },
                  child: Text(
                    'Cuối tuần',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDays = {0, 1, 2, 3, 4, 5, 6}; // All days
                    });
                    _markAsChanged();
                  },
                  child: Text(
                    'Mọi ngày',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Hủy',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _hasChanges
                ? AppColors.primary500
                : AppColors.textSecondary,
          ),
          onPressed: _hasChanges ? _saveSettings : null,
          child: Text(
            'Lưu',
            style: AppTypography.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.notificationService.formatTime(time),
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker({required bool isStartTime}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary500),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        if (isStartTime) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
      _markAsChanged();
    }
  }

  Future<void> _saveSettings() async {
    final quietHours = QuietHours(
      isEnabled: true,
      startTime: _startTime,
      endTime: _endTime,
      selectedDays: _selectedDays.toList(),
    );

    await widget.notificationService.updateQuietHours(quietHours);

    if (mounted) {
      Navigator.pop(
        context,
        true,
      ); // Return true to indicate changes were saved
    }
  }
}

class MaxNotificationsDialog extends StatefulWidget {
  final int initialValue;
  final NotificationService notificationService;

  const MaxNotificationsDialog({
    super.key,
    required this.initialValue,
    required this.notificationService,
  });

  @override
  State<MaxNotificationsDialog> createState() => _MaxNotificationsDialogState();
}

class _MaxNotificationsDialogState extends State<MaxNotificationsDialog> {
  late int _maxNotifications;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _maxNotifications = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Số thông báo tối đa mỗi ngày'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giới hạn số lượng thông báo nhận được trong một ngày để tránh làm phiền.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Slider
          Text(
            'Tối đa: $_maxNotifications thông báo/ngày',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          Slider(
            value: _maxNotifications.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: AppColors.primary500,
            label: _maxNotifications.toString(),
            onChanged: (value) {
              setState(() {
                _maxNotifications = value.round();
                _hasChanges = true;
              });
            },
          ),

          const SizedBox(height: 16),

          // Preset buttons
          Wrap(
            spacing: 8,
            children: [5, 10, 20, 30].map((preset) {
              return FilterChip(
                label: Text(preset.toString()),
                selected: _maxNotifications == preset,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _maxNotifications = preset;
                      _hasChanges = true;
                    });
                  }
                },
                selectedColor: AppColors.primary500,
                checkmarkColor: Colors.white,
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Hủy',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _hasChanges
                ? AppColors.primary500
                : AppColors.textSecondary,
          ),
          onPressed: _hasChanges ? _saveSettings : null,
          child: Text(
            'Lưu',
            style: AppTypography.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    await widget.notificationService.updateMaxNotificationsPerDay(
      _maxNotifications,
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}
