import 'package:flutter/material.dart';

/// Premium Badge Widget - Hiển thị badge Premium cho user
class PremiumBadge extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;

  const PremiumBadge({
    super.key,
    this.size = 24,
    this.showText = true,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showText ? 12 : 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: backgroundColor != null
              ? [backgroundColor!, backgroundColor!]
              : [
                  const Color(0xFFFFD700), // Gold
                  const Color(0xFFFFA500), // Orange
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? const Color(0xFFFFD700)).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: size,
            color: iconColor ?? Colors.white,
          ),
          if (showText) ...[
            const SizedBox(width: 4),
            Text(
              'Premium',
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: size * 0.6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Premium Icon Badge - Chỉ hiển thị icon
class PremiumIconBadge extends StatelessWidget {
  final double size;
  final Color? color;

  const PremiumIconBadge({
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: color != null
              ? [color!, color!]
              : [
                  const Color(0xFFFFD700),
                  const Color(0xFFFFA500),
                ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (color ?? const Color(0xFFFFD700)).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        Icons.star,
        size: size,
        color: Colors.white,
      ),
    );
  }
}

/// Animated Premium Badge - Badge với animation
class AnimatedPremiumBadge extends StatefulWidget {
  final double size;
  final bool showText;
  final Duration animationDuration;

  const AnimatedPremiumBadge({
    super.key,
    this.size = 24,
    this.showText = true,
    this.animationDuration = const Duration(seconds: 2),
  });

  @override
  State<AnimatedPremiumBadge> createState() => _AnimatedPremiumBadgeState();
}

class _AnimatedPremiumBadgeState extends State<AnimatedPremiumBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: PremiumBadge(
              size: widget.size,
              showText: widget.showText,
            ),
          ),
        );
      },
    );
  }
}
