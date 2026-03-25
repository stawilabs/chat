import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:sentry_flutter/sentry_flutter.dart';

/// Service for error tracking and crash reporting using Sentry
class ErrorTrackingService {
  static bool _initialized = false;

  /// Initialize Sentry for error tracking
  /// Call this before runApp in main.dart
  static Future<void> initialize({
    required String dsn,
    required FutureOr<void> Function() appRunner,
    String? environment,
    double tracesSampleRate = 0.2,
  }) async {
    if (_initialized) {
      await appRunner();
      return;
    }

    await SentryFlutter.init((options) {
      options.dsn = dsn;
      options.tracesSampleRate = tracesSampleRate;
      options.environment =
          environment ??
          (kReleaseMode
              ? 'production'
              : kDebugMode
              ? 'development'
              : 'staging');

      // Enable automatic breadcrumb tracking
      options.enableAutoNativeBreadcrumbs = true;
      options.enableAutoPerformanceTracing = true;

      // Capture unhandled errors
      options.attachStacktrace = true;

      // Release version is auto-detected from pubspec.yaml by sentry_flutter

      // Only send errors in release mode by default
      options.beforeSend = (event, hint) {
        // In debug mode, only send if explicitly enabled
        if (kDebugMode && !_debugSendEnabled) {
          return null;
        }
        return event;
      };
    }, appRunner: appRunner);

    _initialized = true;
  }

  static bool _debugSendEnabled = false;

  /// Enable sending errors in debug mode (for testing)
  static void enableDebugSend() {
    _debugSendEnabled = true;
  }

  /// Set user context for error reports
  static Future<void> setUser({
    required String id,
    String? email,
    String? username,
    Map<String, String>? extra,
  }) async {
    await Sentry.configureScope((scope) {
      scope.setUser(
        SentryUser(id: id, email: email, username: username, data: extra),
      );
    });
  }

  /// Clear user context (on logout)
  static Future<void> clearUser() async {
    await Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// Add a breadcrumb for debugging context
  static Future<void> addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) async {
    await Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data,
        level: level,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  /// Capture an exception with optional stack trace
  static Future<void> captureException(
    Object exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
    SentryLevel level = SentryLevel.error,
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: _scopeWithExtras(extra, level: level),
    );
  }

  /// Capture a message for logging
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
  }) async {
    await Sentry.captureMessage(
      message,
      level: level,
      withScope: _scopeWithExtras(extra),
    );
  }

  /// Start a performance transaction
  static ISentrySpan startTransaction({
    required String name,
    required String operation,
    String? description,
  }) => Sentry.startTransaction(
    name,
    operation,
    description: description,
    bindToScope: true,
  );

  /// Set a tag for filtering in Sentry
  static Future<void> setTag(String key, String value) async {
    await Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  /// Set extra context data
  static Future<void> setExtra(String key, Object value) async {
    await Sentry.configureScope((scope) {
      scope.setContexts(key, value);
    });
  }

  /// Check if Sentry is initialized
  static bool get isInitialized => _initialized;

  /// Helper to create a scope callback with extra data and optional level
  static ScopeCallback? _scopeWithExtras(
    Map<String, dynamic>? extra, {
    SentryLevel? level,
  }) {
    if (extra == null && level == null) return null;
    return (scope) {
      if (extra != null) {
        scope.setContexts('extra', extra);
      }
      if (level != null) {
        scope.level = level;
      }
    };
  }
}
