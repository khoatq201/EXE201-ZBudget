import 'package:flutter/material.dart';

class DebugService extends ChangeNotifier {
  static final DebugService _instance = DebugService._internal();
  factory DebugService() => _instance;
  DebugService._internal();

  final List<String> _logs = [];

  List<String> get logs => List.unmodifiable(_logs);

  void log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _logs.add('[$timestamp] $message');

    // Keep only last 50 logs
    if (_logs.length > 50) {
      _logs.removeAt(0);
    }

    // Also print to console
    print(message);
    notifyListeners();
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }
}
