import 'package:flutter/material.dart';
import '../utils/theme_extensions.dart';

/// Common header widget for consistent UI across screens
///
/// Supports 4 variants:
/// - gradient: Header with gradient background (default)
/// - solid: Header with solid color background
/// - transparent: Header with transparent background
/// - elevated: Header with elevation and shadow
///
/// Features:
/// - Automatic theme switching support (light/dark)
/// - Flexible height and padding
/// - Optional leading/trailing actions
/// - Optional subtitle
/// - Custom content support
class CommonHeader extends StatelessWidget {
  /// Title text displayed in header
  final String title;

  /// Optional subtitle text below title
  final String? subtitle;

  /// Header variant type
  final HeaderVariant variant;

  /// Custom height (default: automatic based on content)
  final double? height;

  /// Leading widget (usually back button or menu icon)
  final Widget? leading;

  /// Trailing widget (usually action buttons)
  final Widget? trailing;

  /// Custom content to display below title/subtitle
  final Widget? child;

  /// Additional padding (default: EdgeInsets.all(16))
  final EdgeInsetsGeometry? padding;

  /// Whether to show bottom border
  final bool showBorder;

  /// Custom background color (overrides variant color)
  final Color? backgroundColor;

  /// Custom gradient colors (overrides variant gradient)
  final List<Color>? gradientColors;

  /// Title text style (optional)
  final TextStyle? titleStyle;

  /// Subtitle text style (optional)
  final TextStyle? subtitleStyle;

  const CommonHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.variant = HeaderVariant.gradient,
    this.height,
    this.leading,
    this.trailing,
    this.child,
    this.padding,
    this.showBorder = false,
    this.backgroundColor,
    this.gradientColors,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate effective height
    final double effectiveHeight =
        height ??
        (child != null ? double.infinity : (subtitle != null ? 140.0 : 100.0));

    // Build header decoration based on variant
    final decoration = _buildDecoration(context);

    // Build header content
    final content = Container(
      width: double.infinity,
      constraints: effectiveHeight == double.infinity
          ? null
          : BoxConstraints(minHeight: effectiveHeight),
      decoration: decoration,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading, Title, Trailing row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading widget
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],

                  // Title and subtitle
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              titleStyle ??
                              Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(
                                color: _getTextColor(context),
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style:
                                subtitleStyle ??
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: _getTextColor(
                                    context,
                                  ).withValues(alpha: 0.85),
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Trailing widget
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),

              // Custom child content
              if (child != null) ...[const SizedBox(height: 16), child!],
            ],
          ),
        ),
      ),
    );

    // Wrap with Material for elevation variant
    if (variant == HeaderVariant.elevated) {
      return Material(elevation: 4, child: content);
    }

    return content;
  }

  /// Build decoration based on variant and theme
  BoxDecoration _buildDecoration(BuildContext context) {
    // Use custom background color if provided
    if (backgroundColor != null) {
      return BoxDecoration(
        color: backgroundColor,
        border: showBorder
            ? Border(bottom: BorderSide(color: context.cardBorder, width: 1))
            : null,
      );
    }

    // Build decoration based on variant
    switch (variant) {
      case HeaderVariant.gradient:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                gradientColors ??
                [context.headerGradientStart, context.headerGradientEnd],
          ),
          border: showBorder
              ? Border(
                  bottom: BorderSide(
                    color: context.cardBorder.withValues(alpha: 0.3),
                    width: 1,
                  ),
                )
              : null,
        );

      case HeaderVariant.solid:
        return BoxDecoration(
          color: context.appBarBackground,
          border: showBorder
              ? Border(bottom: BorderSide(color: context.cardBorder, width: 1))
              : null,
        );

      case HeaderVariant.transparent:
        return BoxDecoration(
          color: Colors.transparent,
          border: showBorder
              ? Border(bottom: BorderSide(color: context.cardBorder, width: 1))
              : null,
        );

      case HeaderVariant.elevated:
        return BoxDecoration(
          color: context.cardBackground,
          border: showBorder
              ? Border(bottom: BorderSide(color: context.cardBorder, width: 1))
              : null,
        );
    }
  }

  /// Get text color based on variant and theme
  Color _getTextColor(BuildContext context) {
    // Use white for gradient headers
    if (variant == HeaderVariant.gradient) {
      return context.headerTextColor;
    }

    // Use theme-aware text color for other variants
    return context.primaryTextColor;
  }
}

/// Header variant types
enum HeaderVariant {
  /// Gradient background (vibrant, eye-catching)
  gradient,

  /// Solid color background (clean, professional)
  solid,

  /// Transparent background (minimal, content-focused)
  transparent,

  /// Elevated with shadow (Material Design style)
  elevated,
}

/// Preset header configurations for common use cases
class CommonHeaderPresets {
  /// Dashboard header with gradient
  static CommonHeader dashboard({
    required String userName,
    String? subtitle,
    Widget? trailing,
  }) {
    return CommonHeader(
      title: 'Xin chào, $userName',
      subtitle: subtitle ?? 'Chào mừng trở lại',
      variant: HeaderVariant.gradient,
      trailing: trailing,
    );
  }

  /// Detail screen header with back button
  static CommonHeader detail({
    required BuildContext context,
    required String title,
    String? subtitle,
    List<Widget>? actions,
  }) {
    return CommonHeader(
      title: title,
      subtitle: subtitle,
      variant: HeaderVariant.solid,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      trailing: actions != null && actions.isNotEmpty
          ? Row(mainAxisSize: MainAxisSize.min, children: actions)
          : null,
      showBorder: true,
    );
  }

  /// List screen header with transparent background
  static CommonHeader list({
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return CommonHeader(
      title: title,
      subtitle: subtitle,
      variant: HeaderVariant.transparent,
      trailing: trailing,
    );
  }

  /// Settings header with solid background
  static CommonHeader settings({
    required BuildContext context,
    required String title,
    String? subtitle,
  }) {
    return CommonHeader(
      title: title,
      subtitle: subtitle,
      variant: HeaderVariant.solid,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      showBorder: true,
    );
  }

  /// Stats header with custom child content
  static CommonHeader stats({
    required String title,
    required Widget statsWidget,
  }) {
    return CommonHeader(
      title: title,
      variant: HeaderVariant.gradient,
      child: statsWidget,
    );
  }
}
