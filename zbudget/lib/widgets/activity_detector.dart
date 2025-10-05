import 'package:flutter/material.dart';
import '../services/session_manager.dart';

/// Widget wrapper để detect user activity và update session
class ActivityDetector extends StatelessWidget {
  final Widget child;

  const ActivityDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => SessionManager.instance.updateActivity(),
      onPointerMove: (_) => SessionManager.instance.updateActivity(),
      onPointerUp: (_) => SessionManager.instance.updateActivity(),
      child: child,
    );
  }
}
