import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../constants/typography.dart';
import '../../../services/security_service.dart';
import '../../../models/settings/security_settings.dart';
import '../../../utils/theme_extensions.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityService>(
      builder: (context, securityService, child) {
        if (securityService.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final settings = securityService.securitySettings;

        return Scaffold(
          backgroundColor: context.screenBackground,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: context.headerGradientStart,
                foregroundColor: context.headerTextColor,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('Bảo mật'),
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
                            Icons.security,
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
                      // Security Level Card
                      _buildSecurityLevelCard(settings),
                      const SizedBox(height: 24),

                      // Authentication Section
                      _buildSectionHeader('Xác thực'),
                      const SizedBox(height: 16),
                      _buildAuthenticationSection(
                        context,
                        securityService,
                        settings,
                      ),
                      const SizedBox(height: 24),

                      // Session Management Section
                      _buildSectionHeader('Quản lý phiên'),
                      const SizedBox(height: 16),
                      _buildSessionSection(context, securityService, settings),
                      const SizedBox(height: 24),

                      // Privacy & Protection Section
                      _buildSectionHeader('Quyền riêng tư & Bảo vệ'),
                      const SizedBox(height: 16),
                      _buildPrivacySection(context, securityService, settings),
                      const SizedBox(height: 24),

                      // Active Sessions
                      _buildSectionHeader('Thiết bị đang hoạt động'),
                      const SizedBox(height: 16),
                      _buildActiveSessionsSection(
                        context,
                        securityService,
                        settings,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecurityLevelCard(SecuritySettings settings) {
    final level = settings.securityLevel;
    final levelText = level == 'high'
        ? 'Cao'
        : level == 'medium'
        ? 'Trung bình'
        : 'Thấp';
    final levelColor = level == 'high'
        ? Colors.green
        : level == 'medium'
        ? Colors.orange
        : Colors.red;

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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shield, color: levelColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mức độ bảo mật',
                  style: AppTypography.body.copyWith(
                    color: context.settingsCardSubtitle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  levelText.toUpperCase(),
                  style: AppTypography.h4.copyWith(
                    color: levelColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${((6 / 10) * 100).round()}%', // Demo: 6/10 features enabled
              style: AppTypography.bodySmall.copyWith(
                color: levelColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildAuthenticationSection(
    BuildContext context,
    SecurityService service,
    SecuritySettings settings,
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
          // Biometric Authentication
          _buildSettingTile(
            context: context,
            icon: Icons.fingerprint,
            title: 'Xác thực sinh trắc học',
            subtitle: service.isBiometricAvailable
                ? 'Sử dụng vân tay hoặc Face ID'
                : 'Thiết bị không hỗ trợ',
            value: settings.isBiometricEnabled,
            enabled: service.isBiometricAvailable,
            onChanged: (value) async {
              if (value) {
                final success = await service.enableBiometric();
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể bật sinh trắc học'),
                    ),
                  );
                }
              } else {
                await service.disableBiometric();
              }
            },
            showDivider: true,
          ),

          // Two-Factor Authentication
          _buildSettingTile(
            context: context,
            icon: Icons.security,
            title: 'Xác thực 2 bước',
            subtitle: 'Thêm lớp bảo mật với mã OTP',
            value: settings.isTwoFactorEnabled,
            onChanged: (value) {
              if (value) {
                _showTwoFactorSetupDialog(context, service);
              } else {
                _showTwoFactorDisableDialog(context, service);
              }
            },
            showDivider: true,
          ),

          // Change Password
          _buildActionTile(
            context: context,
            icon: Icons.lock_reset,
            title: 'Thay đổi mật khẩu',
            subtitle: settings.lastPasswordChange != null
                ? 'Đổi ${DateTime.now().difference(settings.lastPasswordChange!).inDays} ngày trước'
                : 'Chưa từng thay đổi',
            onTap: () => _showChangePasswordDialog(context, service),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSection(
    BuildContext context,
    SecurityService service,
    SecuritySettings settings,
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
          // Auto Lock
          _buildSettingTile(
            context: context,
            icon: Icons.lock_clock,
            title: 'Tự động khóa',
            subtitle: 'Khóa ứng dụng khi không sử dụng',
            value: settings.isAutoLockEnabled,
            onChanged: (value) => service.toggleAutoLock(value),
            showDivider: true,
          ),

          // Session Timeout
          _buildDropdownTile(
            context: context,
            icon: Icons.timer,
            title: 'Thời gian hết hạn phiên',
            subtitle: _getSessionTimeoutText(settings.sessionTimeout),
            items: SessionTimeout.values
                .map(
                  (timeout) => DropdownMenuItem(
                    value: timeout,
                    child: Text(_getSessionTimeoutText(timeout)),
                  ),
                )
                .toList(),
            value: settings.sessionTimeout,
            onChanged: (value) {
              if (value != null) {
                service.updateSessionTimeout(value);
              }
            },
            showDivider: true,
          ),

          // Login Notifications
          _buildSettingTile(
            context: context,
            icon: Icons.notifications_active,
            title: 'Thông báo đăng nhập',
            subtitle: 'Nhận thông báo khi có đăng nhập mới',
            value: settings.isLoginNotificationEnabled,
            onChanged: (value) => service.toggleLoginNotifications(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(
    BuildContext context,
    SecurityService service,
    SecuritySettings settings,
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
          // Data Encryption
          _buildSettingTile(
            context: context,
            icon: Icons.enhanced_encryption,
            title: 'Mã hóa dữ liệu',
            subtitle: 'Bảo vệ dữ liệu cá nhân bằng mã hóa',
            value: settings.isDataEncryptionEnabled,
            onChanged: null, // Always enabled for security
            showDivider: true,
          ),

          // Screenshot Blocking
          _buildSettingTile(
            context: context,
            icon: Icons.screenshot_monitor,
            title: 'Chặn chụp màn hình',
            subtitle: 'Ngăn chặn chụp màn hình trong ứng dụng',
            value: settings.isScreenshotBlocked,
            onChanged: (value) => service.toggleScreenshotBlocking(value),
            showDivider: true,
          ),

          // Failed Attempts
          _buildDropdownTile(
            context: context,
            icon: Icons.security,
            title: 'Số lần thử tối đa',
            subtitle: '${settings.maxFailedAttempts} lần thử không thành công',
            items: [3, 5, 10]
                .map(
                  (attempts) => DropdownMenuItem(
                    value: attempts,
                    child: Text('$attempts lần'),
                  ),
                )
                .toList(),
            value: settings.maxFailedAttempts,
            onChanged: (value) {
              if (value != null) {
                service.updateMaxFailedAttempts(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionsSection(
    BuildContext context,
    SecurityService service,
    SecuritySettings settings,
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
          // Header with terminate all option
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${settings.activeSessions.length} thiết bị',
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.settingsItemSubtitleColor,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _showTerminateAllSessionsDialog(context, service),
                  child: Text(
                    'Đăng xuất tất cả',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Sessions list
          ...settings.activeSessions.asMap().entries.map((entry) {
            final index = entry.key;
            final session = entry.value;
            final isLast = index == settings.activeSessions.length - 1;

            return _buildSessionTile(
              context: context,
              service: service,
              session: session,
              showDivider: !isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool enabled = true,
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
              color: context.settingsItemIconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: enabled
                  ? context.settingsItemIconColor
                  : context.settingsItemSubtitleColor,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: AppTypography.bodyLarge.copyWith(
              color: enabled
                  ? context.settingsItemTitleColor
                  : context.settingsItemSubtitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: context.settingsItemSubtitleColor,
            ),
          ),
          trailing: Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: context.colorScheme.primary,
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
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
              color: context.settingsItemIconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: context.settingsItemIconColor, size: 20),
          ),
          title: Text(
            title,
            style: AppTypography.bodyLarge.copyWith(
              color: context.settingsItemTitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: context.settingsItemSubtitleColor,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: context.settingsItemSubtitleColor,
          ),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildDropdownTile<T>({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<DropdownMenuItem<T>> items,
    required T value,
    required ValueChanged<T?> onChanged,
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
              color: context.settingsItemIconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: context.settingsItemIconColor, size: 20),
          ),
          title: Text(
            title,
            style: AppTypography.bodyLarge.copyWith(
              color: context.settingsItemTitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: context.settingsItemSubtitleColor,
            ),
          ),
          trailing: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            underline: const SizedBox(),
            style: AppTypography.bodyMedium.copyWith(
              color: context.settingsItemTitleColor,
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildSessionTile({
    required BuildContext context,
    required SecurityService service,
    required LoginSession session,
    bool showDivider = false,
  }) {
    final deviceIcon = _getDeviceIcon(session.deviceType);
    final timeDiff = DateTime.now().difference(session.lastActiveTime);
    final timeText = _formatTimeDifference(timeDiff);

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
              color: session.isCurrent
                  ? Colors.green.withOpacity(0.1)
                  : context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              deviceIcon,
              color: session.isCurrent
                  ? Colors.green
                  : context.settingsItemSubtitleColor,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  session.deviceName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (session.isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Hiện tại',
                    style: AppTypography.caption.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${session.location} • $timeText',
                style: AppTypography.bodySmall.copyWith(
                  color: context.settingsItemSubtitleColor,
                ),
              ),
              Text(
                session.ipAddress,
                style: AppTypography.caption.copyWith(
                  color: context.settingsItemSubtitleColor,
                ),
              ),
            ],
          ),
          trailing: !session.isCurrent
              ? IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed: () =>
                      _showTerminateSessionDialog(context, service, session),
                )
              : null,
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
        return Icons.phone_android;
      case 'desktop':
        return Icons.computer;
      case 'web':
        return Icons.web;
      default:
        return Icons.devices;
    }
  }

  String _formatTimeDifference(Duration difference) {
    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${difference.inDays} ngày trước';
    }
  }

  String _getSessionTimeoutText(SessionTimeout timeout) {
    switch (timeout) {
      case SessionTimeout.minutes5:
        return '5 phút';
      case SessionTimeout.minutes15:
        return '15 phút';
      case SessionTimeout.minutes30:
        return '30 phút';
      case SessionTimeout.hour1:
        return '1 giờ';
      case SessionTimeout.hour4:
        return '4 giờ';
      case SessionTimeout.never:
        return 'Không bao giờ';
    }
  }

  // Dialog methods
  void _showTwoFactorSetupDialog(
    BuildContext context,
    SecurityService service,
  ) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;
          String? qrCode;
          String? secret;
          final TextEditingController tokenController = TextEditingController();

          return AlertDialog(
            title: const Text('Thiết lập xác thực 2 bước'),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (qrCode == null && !isLoading) ...[
                    const Text(
                      'Bạn có muốn thiết lập xác thực 2 bước để tăng cường bảo mật không?',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLoading) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Đang tạo mã QR...'),
                  ],
                  if (qrCode != null) ...[
                    const Text(
                      'Quét mã QR này bằng ứng dụng Authenticator (Google Authenticator, Authy, v.v.):',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.memory(
                        base64Decode(qrCode!.split(',')[1]),
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (secret != null) ...[
                      const Text(
                        'Hoặc nhập thủ công mã này:',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          secret!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: tokenController,
                      decoration: const InputDecoration(
                        labelText: 'Nhập mã xác thực 6 số',
                        hintText: '123456',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              if (qrCode == null && !isLoading)
                ElevatedButton(
                  onPressed: () async {
                    setState(() => isLoading = true);
                    try {
                      final result = await service.setupTwoFactor();
                      if (result != null) {
                        setState(() {
                          qrCode = result['qrCode'];
                          secret = result['secret'];
                          isLoading = false;
                        });
                      }
                    } catch (e) {
                      setState(() => isLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Thiết lập'),
                ),
              if (qrCode != null)
                ElevatedButton(
                  onPressed: () async {
                    if (tokenController.text.length != 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập mã xác thực 6 số'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() => isLoading = true);
                    try {
                      final success = await service.enableTwoFactor(
                        tokenController.text,
                      );
                      if (success && context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Kích hoạt xác thực 2 bước thành công',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mã xác thực không đúng'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      setState(() => isLoading = false);
                    }
                  },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Xác nhận'),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showTwoFactorDisableDialog(
    BuildContext context,
    SecurityService service,
  ) {
    final TextEditingController passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;

          return AlertDialog(
            title: const Text('Tắt xác thực 2 bước'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bạn có chắc chắn muốn tắt xác thực 2 bước? Điều này sẽ giảm mức độ bảo mật của tài khoản.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Nhập mật khẩu để xác nhận',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setState(() => isLoading = true);

                          try {
                            final success = await service.disableTwoFactor(
                              passwordController.text,
                            );
                            if (success && context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Tắt xác thực 2 bước thành công',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Mật khẩu không đúng hoặc có lỗi xảy ra',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => isLoading = false);
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tắt'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    SecurityService service,
  ) {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thay đổi mật khẩu'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu hiện tại';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu mới',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu mới';
                    }
                    if (value.length < 8) {
                      return 'Mật khẩu phải có ít nhất 8 ký tự';
                    }
                    if (!RegExp(
                      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]',
                    ).hasMatch(value)) {
                      return 'Mật khẩu phải chứa chữ hoa, chữ thường, số và ký tự đặc biệt';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu mới';
                    }
                    if (value != newPasswordController.text) {
                      return 'Mật khẩu xác nhận không khớp';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);

                        try {
                          final success = await service.changePassword(
                            currentPassword: currentPasswordController.text,
                            newPassword: newPasswordController.text,
                          );

                          if (success) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Thay đổi mật khẩu thành công'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Thay đổi mật khẩu thất bại'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTerminateSessionDialog(
    BuildContext context,
    SecurityService service,
    LoginSession session,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất thiết bị'),
        content: Text('Bạn có muốn đăng xuất khỏi ${session.deviceName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success = await service.terminateSession(session.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã đăng xuất khỏi thiết bị')),
                );
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _showTerminateAllSessionsDialog(
    BuildContext context,
    SecurityService service,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất tất cả thiết bị'),
        content: const Text(
          'Bạn có muốn đăng xuất khỏi tất cả thiết bị khác không? Hành động này không thể hoàn tác.',
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
              final success = await service.terminateAllOtherSessions();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã đăng xuất khỏi tất cả thiết bị khác'),
                  ),
                );
              }
            },
            child: const Text('Đăng xuất tất cả'),
          ),
        ],
      ),
    );
  }
}
