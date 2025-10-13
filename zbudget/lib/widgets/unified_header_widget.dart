import 'package:flutter/material.dart';
import '../utils/theme_extensions.dart';
import '../constants/typography.dart';

class UnifiedHeaderWidget extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const UnifiedHeaderWidget({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AppTypography.h6.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colorScheme.onSurface,
        ),
      ),
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: context.colorScheme.onSurface,
              ),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : leading,
      actions: actions,
      backgroundColor: context.colorScheme.surface,
      elevation: 0,
      centerTitle: true,
    );
  }
}

class HeaderConfigs {
  static Widget getHeader(String type) {
    switch (type) {
      case 'settings':
        return const UnifiedHeaderWidget(
          title: 'Cài đặt',
          showBackButton: false,
        );
      case 'profile':
        return const UnifiedHeaderWidget(title: 'Hồ sơ');
      case 'security':
        return const UnifiedHeaderWidget(title: 'Bảo mật');
      case 'theme':
        return const UnifiedHeaderWidget(title: 'Giao diện');
      case 'language':
        return const UnifiedHeaderWidget(title: 'Ngôn ngữ');
      case 'notifications':
        return const UnifiedHeaderWidget(title: 'Thông báo');
      default:
        return const UnifiedHeaderWidget(title: 'Cài đặt');
    }
  }
}
