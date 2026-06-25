import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void log(String scope, String message, {Map<String, Object?>? data}) {
    debugPrint('[$scope] $message${data == null ? '' : ' | $data'}');
  }

  static void error(
    String scope,
    String message,
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?>? data,
  }) {
    debugPrint(
      '[$scope] ERROR: $message'
      '${data == null ? '' : ' | $data'}'
      '\nException: $error'
      '\nStack trace:\n$stackTrace',
    );
  }

  static Map<String, Object?> redactPassword(Map<String, Object?> data) {
    return data.map(
      (key, value) => MapEntry(
        key,
        key.toLowerCase().contains('password') ? '<redacted>' : value,
      ),
    );
  }
}
