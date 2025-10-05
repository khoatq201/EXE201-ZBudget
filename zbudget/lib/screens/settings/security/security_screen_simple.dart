import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/typography.dart';
import '../../../services/security_service.dart';
import '../../../models/settings/security_settings.dart';
import '../../../utils/theme_extensions.dart';

class SecurityScreenSimple extends StatefulWidget {
  const SecurityScreenSimple({super.key});

  @override
  State<SecurityScreenSimple> createState() => _SecurityScreenSimpleState();
}

class _SecurityScreenSimpleState extends State<SecurityScreenSimple> {
  @override
  void initState() {
    super.initState();
    // Initialize SecurityService when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final securityService = Provider.of<SecurityService>(
        context,
        listen: false,
      );
      securityService.initialize();
      // Refresh from server to get latest settings
      securityService.refreshFromServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityService>(
      builder: (context, securityService, child) {
        if (securityService.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: context.screenBackground,
          body: CustomScrollView(
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
                    'Bảo mật',
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
                            Icons.security,
                            size: 150,
                            color: context.colorScheme.onPrimary.withOpacity(0.1),
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
                      _buildSecurityLevelCard(
                        securityService.securitySettings,
                      ), // Use fresh data
                      const SizedBox(height: 24),

                      // Authentication Section
                      _buildSectionHeader('Xác thực'),
                      const SizedBox(height: 16),
                      Consumer<SecurityService>(
                        builder: (context, securityService, child) =>
                            _buildAuthenticationSection(
                              securityService
                                  .securitySettings, // Use fresh data
                              securityService,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Session Management Section
                      _buildSectionHeader('Quản lý phiên'),
                      const SizedBox(height: 16),
                      Consumer<SecurityService>(
                        builder: (context, securityService, child) =>
                            _buildSessionSection(
                              securityService.securitySettings,
                              securityService,
                            ), // Use fresh data
                      ),
                      const SizedBox(height: 24),

                      // Privacy & Protection Section
                      _buildSectionHeader('Quyền riêng tư & Bảo vệ'),
                      const SizedBox(height: 16),
                      Consumer<SecurityService>(
                        builder: (context, securityService, child) =>
                            _buildPrivacySection(
                              securityService.securitySettings,
                              securityService,
                            ), // Use fresh data
                      ),
                      const SizedBox(height: 24),

                      // Active Sessions
                      _buildSectionHeader('Thiết bị đang hoạt động'),
                      const SizedBox(height: 16),
                      Consumer<SecurityService>(
                        builder: (context, securityService, child) =>
                            _buildActiveSessionsSection(
                              securityService
                                  .securitySettings, // Use fresh data
                              securityService,
                            ),
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
              color: levelColor.withOpacity(0.1),
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
              color: levelColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '60%', // Demo: 6/10 features enabled
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
    SecuritySettings settings,
    SecurityService securityService,
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
            icon: Icons.fingerprint,
            title: 'Xác thực sinh trắc học',
            subtitle: securityService.isBiometricAvailable
                ? 'Sử dụng vân tay hoặc Face ID'
                : 'Thiết bị không hỗ trợ',
            value: settings.isBiometricEnabled,
            enabled: securityService.isBiometricAvailable,
            onChanged: (value) => _handleBiometricToggle(value),
            showDivider: true,
          ),

          // Two-Factor Authentication
          _buildSettingTile(
            icon: Icons.security,
            title: 'Xác thực 2 bước',
            subtitle: 'Thêm lớp bảo mật với mã OTP',
            value: settings.isTwoFactorEnabled,
            onChanged: (value) => _handleTwoFactorToggle(value),
            showDivider: true,
          ),

          // Change Password
          _buildActionTile(
            icon: Icons.lock_reset,
            title: 'Thay đổi mật khẩu',
            subtitle: settings.lastPasswordChange != null
                ? 'Đổi ${DateTime.now().difference(settings.lastPasswordChange!).inDays} ngày trước'
                : 'Chưa từng thay đổi',
            onTap: () => _showChangePasswordDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSection(
    SecuritySettings settings,
    SecurityService securityService,
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
            icon: Icons.lock_clock,
            title: 'Tự động khóa',
            subtitle: 'Khóa ứng dụng khi không sử dụng',
            value: settings.isAutoLockEnabled,
            onChanged: (value) => securityService.toggleAutoLock(value),
            showDivider: true,
          ),

          // Session Timeout
          _buildDropdownTile(
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
                securityService.updateSessionTimeout(value);
              }
            },
            showDivider: true,
          ),

          // Login Notifications
          _buildSettingTile(
            icon: Icons.notifications_active,
            title: 'Thông báo đăng nhập',
            subtitle: 'Nhận thông báo khi có đăng nhập mới',
            value: settings.isLoginNotificationEnabled,
            onChanged: (value) =>
                securityService.toggleLoginNotifications(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(
    SecuritySettings settings,
    SecurityService securityService,
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
            icon: Icons.enhanced_encryption,
            title: 'Mã hóa dữ liệu',
            subtitle: 'Bảo vệ dữ liệu cá nhân bằng mã hóa',
            value: settings.isDataEncryptionEnabled,
            onChanged: null, // Always enabled for security
            showDivider: true,
          ),

          // Screenshot Blocking
          _buildSettingTile(
            icon: Icons.screenshot_monitor,
            title: 'Chặn chụp màn hình',
            subtitle: 'Ngăn chặn chụp màn hình trong ứng dụng',
            value: settings.isScreenshotBlocked,
            onChanged: (value) =>
                securityService.toggleScreenshotBlocking(value),
            showDivider: true,
          ),

          // Failed Attempts
          _buildDropdownTile(
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
                securityService.updateMaxFailedAttempts(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionsSection(
    SecuritySettings settings,
    SecurityService securityService,
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
                  style: AppTypography.body.copyWith(
                    color: context.settingsItemSubtitleColor,
                  ),
                ),
                TextButton(
                  onPressed: () => _showTerminateAllSessionsDialog(),
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

            return _buildSessionTile(session: session, showDivider: !isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
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
              color: enabled ? context.settingsItemIconColor : context.settingsItemSubtitleColor,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: AppTypography.body.copyWith(
              color: enabled ? context.settingsItemTitleColor : context.settingsItemSubtitleColor,
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
            style: AppTypography.body.copyWith(
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
          trailing: Icon(Icons.chevron_right, color: context.settingsItemSubtitleColor),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildDropdownTile<T>({
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
            style: AppTypography.body.copyWith(
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
            style: AppTypography.body.copyWith(
              color: context.settingsItemTitleColor,
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildSessionTile({
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
              color: session.isCurrent ? Colors.green : context.settingsItemSubtitleColor,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  session.deviceName,
                  style: AppTypography.body.copyWith(
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
                    color: Colors.green.withOpacity(0.1),
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
                  onPressed: () => _showTerminateSessionDialog(session),
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

  // Handler methods
  Future<void> _handleBiometricToggle(bool value) async {
    final securityService = Provider.of<SecurityService>(
      context,
      listen: false,
    );
    if (value) {
      final success = await securityService.enableBiometric();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể bật sinh trắc học')),
        );
      }
    } else {
      await securityService.disableBiometric();
    }
    setState(() {});
  }

  void _handleTwoFactorToggle(bool value) {
    if (value) {
      _showTwoFactorSetupDialog();
    } else {
      _showTwoFactorDisableDialog();
    }
  }

  // Dialog methods
  void _showTwoFactorSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thiết lập xác thực 2 bước'),
        content: const Text(
          'Bạn có muốn thiết lập xác thực 2 bước để tăng cường bảo mật không?\n\nSau khi thiết lập, bạn sẽ nhận được mã QR để quét bằng ứng dụng Authenticator.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final securityService = Provider.of<SecurityService>(
                  context,
                  listen: false,
                );

                // Setup 2FA first
                final result = await securityService.setupTwoFactor();

                // Hide loading
                if (mounted) Navigator.pop(context);

                if (result != null && mounted) {
                  // Show QR code dialog
                  _showQRCodeDialog(result);
                }
              } catch (e) {
                // Hide loading
                if (mounted) Navigator.pop(context);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi thiết lập 2FA: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Thiết lập'),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog(Map<String, dynamic> setupData) {
    final TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quét mã QR'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quét mã QR này bằng ứng dụng Authenticator:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (setupData['qrCode'] != null)
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: setupData['qrCode'].toString().startsWith('data:')
                      ? Image.memory(
                          base64Decode(
                            setupData['qrCode'].toString().split(',')[1],
                          ),
                          fit: BoxFit.contain,
                        )
                      : const Icon(Icons.error, size: 50),
                ),
              const SizedBox(height: 16),
              if (setupData['secret'] != null) ...[
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
                    setupData['secret'].toString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: otpController,
                decoration: const InputDecoration(
                  labelText: 'Nhập mã xác thực 6 số',
                  hintText: '123456',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (otpController.text.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập mã xác thực 6 số'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final securityService = Provider.of<SecurityService>(
                  context,
                  listen: false,
                );
                final success = await securityService.enableTwoFactor(
                  otpController.text,
                );

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kích hoạt xác thực 2 bước thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {}); // Refresh UI
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mã xác thực không đúng'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorDisableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tắt xác thực 2 bước'),
        content: const Text(
          'Bạn có chắc chắn muốn tắt xác thực 2 bước? Điều này sẽ giảm mức độ bảo mật của tài khoản.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              final securityService = Provider.of<SecurityService>(
                context,
                listen: false,
              );
              securityService.disableTwoFactor('dummy_password');
              setState(() {});
            },
            child: const Text('Tắt'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thay đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentPassword = currentPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (currentPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập đầy đủ thông tin'),
                  ),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mật khẩu mới không khớp')),
                );
                return;
              }

              Navigator.pop(context);

              final securityService = Provider.of<SecurityService>(
                context,
                listen: false,
              );

              final success = await securityService.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đổi mật khẩu thành công')),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Không thể đổi mật khẩu. Vui lòng kiểm tra lại mật khẩu hiện tại',
                    ),
                  ),
                );
              }
            },
            child: const Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
  }

  void _showTerminateSessionDialog(LoginSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất thiết bị'),
        content: Text(
          'Bạn có muốn đăng xuất khỏi thiết bị "${session.deviceName}" không?',
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
              final securityService = Provider.of<SecurityService>(
                context,
                listen: false,
              );
              try {
                await securityService.terminateSession(session.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã đăng xuất thiết bị thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _showTerminateAllSessionsDialog() {
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
              final securityService = Provider.of<SecurityService>(
                context,
                listen: false,
              );
              final success = await securityService.terminateAllOtherSessions();
              if (success && mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã đăng xuất khỏi tất cả thiết bị khác'),
                  ),
                );
                setState(() {});
              }
            },
            child: const Text('Đăng xuất tất cả'),
          ),
        ],
      ),
    );
  }
}
