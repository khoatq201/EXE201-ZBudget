import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../services/theme_service.dart';
import '../../../models/settings/theme_settings.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen>
    with TickerProviderStateMixin {
  final ThemeService _themeService = ThemeService();
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeService();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    await _themeService.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: _themeService.getPrimaryColor(),
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Giao diện',
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
                      _themeService.getPrimaryColor(),
                      _themeService.getPrimaryColor().withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Icon(
                        Icons.palette,
                        size: 150,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Theme Mode Section
                        _buildSectionHeader('Chế độ hiển thị'),
                        const SizedBox(height: 16),
                        _buildThemeModeSection(),
                        const SizedBox(height: 24),

                        // Color Scheme Section
                        _buildSectionHeader('Bảng màu'),
                        const SizedBox(height: 16),
                        _buildColorSchemeSection(),
                        const SizedBox(height: 24),

                        // Typography Section
                        _buildSectionHeader('Chữ viết'),
                        const SizedBox(height: 16),
                        _buildTypographySection(),
                        const SizedBox(height: 24),

                        // Layout Section
                        _buildSectionHeader('Bố cục'),
                        const SizedBox(height: 16),
                        _buildLayoutSection(),
                        const SizedBox(height: 24),

                        // Interaction Section
                        _buildSectionHeader('Tương tác'),
                        const SizedBox(height: 16),
                        _buildInteractionSection(),
                        const SizedBox(height: 24),

                        // Preview Section
                        _buildSectionHeader('Xem trước'),
                        const SizedBox(height: 16),
                        _buildPreviewSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                );
              },
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
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildThemeModeSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: AppThemeMode.values.asMap().entries.map((entry) {
          final index = entry.key;
          final mode = entry.value;
          final isSelected = _themeService.themeSettings.themeMode == mode;
          final isLast = index == AppThemeMode.values.length - 1;

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
                    color: isSelected
                        ? _themeService.getPrimaryColor().withOpacity(0.1)
                        : AppColors.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    mode.icon,
                    color: isSelected
                        ? _themeService.getPrimaryColor()
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                title: Text(
                  mode.displayName,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _getThemeModeDescription(mode),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Radio<AppThemeMode>(
                  value: mode,
                  groupValue: _themeService.themeSettings.themeMode,
                  activeColor: _themeService.getPrimaryColor(),
                  onChanged: (value) {
                    if (value != null) {
                      _themeService.updateThemeMode(value);
                      setState(() {});
                    }
                  },
                ),
                onTap: () {
                  _themeService.updateThemeMode(mode);
                  setState(() {});
                },
              ),
              if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorSchemeSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn màu chủ đạo cho ứng dụng',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppColorScheme.values.map((scheme) {
                final isSelected =
                    _themeService.themeSettings.colorScheme == scheme;

                return GestureDetector(
                  onTap: () {
                    _themeService.updateColorScheme(scheme);
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? scheme.color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: scheme.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: scheme.color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          scheme.displayName,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypographySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Font Size
          _buildSettingTile(
            icon: Icons.format_size,
            title: 'Kích thước chữ',
            subtitle: _themeService.getFontSizeDisplayName(),
            onTap: () => _showFontSizeDialog(),
            showDivider: true,
          ),

          // System Font
          _buildSettingTile(
            icon: Icons.font_download,
            title: 'Sử dụng font hệ thống',
            subtitle: _themeService.themeSettings.useSystemFont
                ? 'Sử dụng font của thiết bị'
                : 'Sử dụng font ứng dụng',
            trailing: Switch(
              value: _themeService.themeSettings.useSystemFont,
              activeColor: _themeService.getPrimaryColor(),
              onChanged: (value) {
                _themeService.toggleSystemFont(value);
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Border Radius
          _buildSettingTile(
            icon: Icons.border_style,
            title: 'Độ bo góc',
            subtitle: '${_themeService.themeSettings.borderRadius.toInt()}px',
            onTap: () => _showBorderRadiusDialog(),
            showDivider: true,
          ),

          // Compact Mode
          _buildSettingTile(
            icon: Icons.compress,
            title: 'Chế độ nhỏ gọn',
            subtitle: _themeService.themeSettings.compactMode
                ? 'Gián tiếp khoảng cách để tiết kiệm không gian'
                : 'Sử dụng khoảng cách bình thường',
            trailing: Switch(
              value: _themeService.themeSettings.compactMode,
              activeColor: _themeService.getPrimaryColor(),
              onChanged: (value) {
                _themeService.toggleCompactMode(value);
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Animations
          _buildSettingTile(
            icon: Icons.animation,
            title: 'Hiệu ứng chuyển động',
            subtitle: _themeService.themeSettings.enableAnimations
                ? 'Bật hiệu ứng chuyển trang và animation'
                : 'Tắt tất cả hiệu ứng để tăng hiệu suất',
            trailing: Switch(
              value: _themeService.themeSettings.enableAnimations,
              activeColor: _themeService.getPrimaryColor(),
              onChanged: (value) {
                _themeService.toggleAnimations(value);
                setState(() {});
              },
            ),
            showDivider: true,
          ),

          // Haptic Feedback
          _buildSettingTile(
            icon: Icons.vibration,
            title: 'Rung phản hồi',
            subtitle: _themeService.themeSettings.enableHapticFeedback
                ? 'Rung nhẹ khi tương tác với giao diện'
                : 'Tắt rung phản hồi',
            trailing: Switch(
              value: _themeService.themeSettings.enableHapticFeedback,
              activeColor: _themeService.getPrimaryColor(),
              onChanged: (value) {
                _themeService.toggleHapticFeedback(value);
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xem trước giao diện',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Preview card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _themeService.getPrimaryColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  _themeService.themeSettings.borderRadius,
                ),
                border: Border.all(
                  color: _themeService.getPrimaryColor().withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _themeService.getPrimaryColor(),
                          borderRadius: BorderRadius.circular(
                            _themeService.themeSettings.borderRadius / 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ZBudget App',
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize:
                                    AppTypography.body.fontSize! *
                                    _themeService.themeSettings.fontSize.scale,
                              ),
                            ),
                            Text(
                              'Quản lý tài chính cá nhân',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize:
                                    AppTypography.bodySmall.fontSize! *
                                    _themeService.themeSettings.fontSize.scale,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Sample button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _themeService.getPrimaryColor(),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            _themeService.themeSettings.borderRadius,
                          ),
                        ),
                      ),
                      onPressed: () {},
                      child: Text(
                        'Nút mẫu',
                        style: TextStyle(
                          fontSize:
                              14 * _themeService.themeSettings.fontSize.scale,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Reset button
            Center(
              child: TextButton.icon(
                onPressed: () => _showResetDialog(),
                icon: const Icon(Icons.restore),
                label: const Text('Đặt lại về mặc định'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
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
              color: _themeService.getPrimaryColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _themeService.getPrimaryColor(), size: 20),
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
          trailing:
              trailing ??
              (onTap != null
                  ? Icon(Icons.chevron_right, color: AppColors.textSecondary)
                  : null),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  String _getThemeModeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'Tự động thay đổi theo cài đặt thiết bị';
      case AppThemeMode.light:
        return 'Luôn sử dụng giao diện sáng';
      case AppThemeMode.dark:
        return 'Luôn sử dụng giao diện tối';
    }
  }

  // Dialog methods
  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kích thước chữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: FontSize.values.map((size) {
            return RadioListTile<FontSize>(
              title: Text(
                size.displayName,
                style: TextStyle(fontSize: 16 * size.scale),
              ),
              subtitle: Text('Mẫu: ${(16 * size.scale).toInt()}px'),
              value: size,
              groupValue: _themeService.themeSettings.fontSize,
              activeColor: _themeService.getPrimaryColor(),
              onChanged: (value) {
                if (value != null) {
                  _themeService.updateFontSize(value);
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

  void _showBorderRadiusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Độ bo góc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hiện tại: ${_themeService.themeSettings.borderRadius.toInt()}px',
            ),
            const SizedBox(height: 16),
            Slider(
              value: _themeService.themeSettings.borderRadius,
              min: 0,
              max: 24,
              divisions: 24,
              activeColor: _themeService.getPrimaryColor(),
              label: '${_themeService.themeSettings.borderRadius.toInt()}px',
              onChanged: (value) {
                _themeService.updateBorderRadius(value);
                setState(() {});
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt lại giao diện'),
        content: const Text(
          'Bạn có chắc chắn muốn đặt lại tất cả cài đặt giao diện về mặc định?',
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
              _themeService.resetToDefaults();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã đặt lại giao diện về mặc định'),
                ),
              );
            },
            child: const Text('Đặt lại'),
          ),
        ],
      ),
    );
  }
}
