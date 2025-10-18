import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_sync_service.dart';

/// Notification Badge Widget - Hiển thị số thông báo chưa đọc
class NotificationBadge extends StatefulWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;
  final EdgeInsets? badgePadding;

  const NotificationBadge({
    super.key,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
    this.badgePadding,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final service = context.read<NotificationSyncService>();
    final count = await service.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationSyncService>(
      builder: (context, service, child) {
        // Update count when notifications change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (service.notifications.isNotEmpty) {
            final unreadCount = service.unreadNotifications.length;
            if (unreadCount != _unreadCount) {
              setState(() {
                _unreadCount = unreadCount;
              });
            }
          }
        });

        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (_unreadCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding:
                      widget.badgePadding ??
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.badgeColor ?? Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    minWidth: widget.badgeSize ?? 16,
                    minHeight: widget.badgeSize ?? 16,
                  ),
                  child: Text(
                    _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                    style: TextStyle(
                      color: widget.textColor ?? Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Simple Notification Badge - Chỉ hiển thị dot
class NotificationDot extends StatefulWidget {
  final Widget child;
  final Color? dotColor;
  final double? dotSize;

  const NotificationDot({
    super.key,
    required this.child,
    this.dotColor,
    this.dotSize,
  });

  @override
  State<NotificationDot> createState() => _NotificationDotState();
}

class _NotificationDotState extends State<NotificationDot> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final service = context.read<NotificationSyncService>();
    final count = await service.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationSyncService>(
      builder: (context, service, child) {
        // Update count when notifications change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (service.notifications.isNotEmpty) {
            final unreadCount = service.unreadNotifications.length;
            if (unreadCount != _unreadCount) {
              setState(() {
                _unreadCount = unreadCount;
              });
            }
          }
        });

        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (_unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: widget.dotSize ?? 8,
                  height: widget.dotSize ?? 8,
                  decoration: BoxDecoration(
                    color: widget.dotColor ?? Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Notification Badge with Animation
class AnimatedNotificationBadge extends StatefulWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;
  final EdgeInsets? badgePadding;
  final Duration animationDuration;

  const AnimatedNotificationBadge({
    super.key,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
    this.badgePadding,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedNotificationBadge> createState() =>
      _AnimatedNotificationBadgeState();
}

class _AnimatedNotificationBadgeState extends State<AnimatedNotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _unreadCount = 0;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final service = context.read<NotificationSyncService>();
    final count = await service.getUnreadCount();
    if (mounted) {
      setState(() {
        _previousCount = _unreadCount;
        _unreadCount = count;
      });

      // Animate if count increased
      if (_unreadCount > _previousCount && _unreadCount > 0) {
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationSyncService>(
      builder: (context, service, child) {
        // Update count when notifications change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (service.notifications.isNotEmpty) {
            final unreadCount = service.unreadNotifications.length;
            if (unreadCount != _unreadCount) {
              setState(() {
                _previousCount = _unreadCount;
                _unreadCount = unreadCount;
              });

              // Animate if count increased
              if (_unreadCount > _previousCount && _unreadCount > 0) {
                _animationController.forward().then((_) {
                  _animationController.reverse();
                });
              }
            }
          }
        });

        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (_unreadCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        padding:
                            widget.badgePadding ??
                            const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                        decoration: BoxDecoration(
                          color: widget.badgeColor ?? Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(
                          minWidth: widget.badgeSize ?? 16,
                          minHeight: widget.badgeSize ?? 16,
                        ),
                        child: Text(
                          _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                          style: TextStyle(
                            color: widget.textColor ?? Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
