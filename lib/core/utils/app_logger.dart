import 'package:flutter/foundation.dart';

/// Debug-only logger. Never logs in release builds.
class AppLogger {
  AppLogger._();

  static void d(String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[BKReader] $message');
      if (error != null) debugPrint('  error: $error');
      if (stack != null) debugPrint('  stack: $stack');
    }
  }

  static void e(String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[BKReader][ERROR] $message');
      if (error != null) debugPrint('  error: $error');
      if (stack != null) debugPrint('  stack: $stack');
    }
  }
}
