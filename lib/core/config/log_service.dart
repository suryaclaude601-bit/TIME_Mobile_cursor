import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class LogService {
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(message, name: tag ?? 'App');
    }
  }

  static void info(String message, {String? tag}) {
    developer.log(message, name: tag ?? 'App', level: 800);
  }

  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    developer.log(
      message,
      name: tag ?? 'App',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
