import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import 'correlation_id.dart';
import 'log_entry.dart';
import 'log_storage.dart';
import 'remote_logger.dart';
import 'sensitive_data_filter.dart';

/// Simple log printer - one line per message, easy to scan
class _SimpleLogPrinter extends LogPrinter {
  static const _levelPrefixes = {
    Level.trace: 'TRACE',
    Level.debug: 'DEBUG',
    Level.info: 'INFO',
    Level.warning: 'WARN',
    Level.error: 'ERROR',
    Level.fatal: 'FATAL',
  };

  @override
  List<String> log(LogEvent event) {
    final prefix = _levelPrefixes[event.level] ?? '?';
    final time = DateTime.now().toString().substring(11, 19); // HH:MM:SS
    final correlationId = CorrelationId.current;
    final correlationPart = correlationId != null ? ' [$correlationId]' : '';
    final lines = <String>['$time $prefix$correlationPart  ${event.message}'];

    if (event.error != null) {
      lines.add('         > ${event.error}');
    }
    if (event.stackTrace != null && event.level.index >= Level.error.index) {
      // Only show first 3 frames for errors
      final frames = event.stackTrace.toString().split('\n').take(3);
      for (final frame in frames) {
        if (frame.trim().isNotEmpty) {
          lines.add('            $frame');
        }
      }
    }
    return lines;
  }
}

/// Map from Logger package Level to our LogLevel
LogLevel _mapLevel(Level level) {
  switch (level) {
    case Level.trace:
    case Level.debug:
      return LogLevel.debug;
    case Level.info:
      return LogLevel.info;
    case Level.warning:
      return LogLevel.warning;
    case Level.error:
    case Level.fatal:
      return LogLevel.error;
    default:
      return LogLevel.info;
  }
}

/// Centralized application logger with enhanced features
///
/// Features:
/// - Log levels: debug, info, warning, error
/// - Remote logging for warnings and errors
/// - Local log storage with rotation (max 10MB)
/// - Log export for support
/// - Correlation IDs for request tracing
/// - Sensitive data filtering
class AppLogger {
  static final Logger _logger = Logger(
    printer: _SimpleLogPrinter(),
    level: kDebugMode ? Level.debug : Level.info,
  );

  static const _uuid = Uuid();

  /// Log storage for local persistence
  static LogStorage? _logStorage;

  /// Remote logger for sending logs to backend
  static RemoteLogger? _remoteLogger;

  /// Whether the logger has been initialized
  static bool _initialized = false;

  /// Initialize the logger with optional remote logging
  ///
  /// Call this early in app startup (e.g., in main.dart)
  static Future<void> initialize({
    RemoteLoggerConfig? remoteConfig,
    int maxLocalLogSize = 10 * 1024 * 1024, // 10MB default
    int maxLogFiles = 5,
  }) async {
    if (_initialized) return;

    // Initialize local log storage
    _logStorage = LogStorage(
      maxFileSize: maxLocalLogSize,
      maxFiles: maxLogFiles,
    );
    await _logStorage!.initialize();

    // Initialize remote logger if config provided
    if (remoteConfig != null && remoteConfig.enabled) {
      _remoteLogger = RemoteLogger(config: remoteConfig);
      _remoteLogger!.initialize();
    }

    _initialized = true;
    info(
      'AppLogger initialized',
      data: {
        'remoteLogging': remoteConfig?.enabled ?? false,
        'maxLocalLogSize': maxLocalLogSize,
        'maxLogFiles': maxLogFiles,
      },
    );
  }

  /// Generate a new correlation ID for tracing
  static String generateCorrelationId() {
    return _uuid.v4();
  }

  /// Set the current correlation ID
  static void setCorrelationId(String id) {
    CorrelationId.set(id);
  }

  /// Get the current correlation ID
  static String? getCorrelationId() {
    return CorrelationId.current;
  }

  /// Clear the current correlation ID
  static void clearCorrelationId() {
    CorrelationId.clear();
  }

  /// Execute a function with a new correlation ID
  static T withCorrelationId<T>(T Function(String correlationId) fn) {
    return CorrelationId.withNewCorrelationId(fn);
  }

  /// Execute an async function with a new correlation ID
  static Future<T> withCorrelationIdAsync<T>(
    Future<T> Function(String correlationId) fn,
  ) {
    return CorrelationId.withNewCorrelationIdAsync(fn);
  }

  /// Verbose logging - most detailed
  /// Use for very granular debugging information
  static void verbose(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? tag,
  }) {
    _log(
      Level.trace,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
      tag: tag,
    );
  }

  /// Debug logging - detailed information for debugging
  /// Use for debugging flow and state changes
  static void debug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? tag,
  }) {
    _log(
      Level.debug,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
      tag: tag,
    );
  }

  /// Info logging - general information
  /// Use for important events and state changes
  static void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? tag,
  }) {
    _log(
      Level.info,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
      tag: tag,
    );
  }

  /// Warning logging - potentially harmful situations
  /// Use for recoverable errors or unexpected situations
  static void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? tag,
  }) {
    _log(
      Level.warning,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
      tag: tag,
    );
  }

  /// Error logging - error events
  /// Use for errors that don't crash the app but need attention
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? tag,
  }) {
    _log(
      Level.error,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
      tag: tag,
    );

    // Hook for error reporting services (Sentry, Firebase Crashlytics, etc.)
    _reportError(message, error, stackTrace, data);
  }

  /// Fatal logging - very severe error events
  /// Use for critical errors that might lead to application crash
  static void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? tag,
  }) {
    _log(
      Level.fatal,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
      tag: tag,
    );

    // Always report fatal errors
    _reportError(message, error, stackTrace, data, isFatal: true);
  }

  /// Internal logging method that handles all log levels
  static void _log(
    Level level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? tag,
  }) {
    // Filter sensitive data
    final filteredMessage = SensitiveDataFilter.filterMessage(message);
    final filteredData = SensitiveDataFilter.filterData(data);
    final filteredError = SensitiveDataFilter.filterError(error);

    // Format message with data
    final formattedMessage = _formatMessage(filteredMessage, filteredData, tag);

    // Log to console
    _logger.log(
      level,
      formattedMessage,
      error: filteredError,
      stackTrace: stackTrace,
    );

    // Create log entry for storage/remote
    final entry = LogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now().toUtc(),
      level: _mapLevel(level),
      message: filteredMessage,
      correlationId: CorrelationId.current,
      error: filteredError,
      stackTrace: SensitiveDataFilter.filterStackTrace(stackTrace),
      data: filteredData.isNotEmpty ? filteredData : null,
      tag: tag,
    );

    // Store locally
    _logStorage?.write(entry);

    // Send to remote (for warnings and above)
    if (level.index >= Level.warning.index) {
      _remoteLogger?.log(entry);
    }
  }

  /// Format message with additional data
  static String _formatMessage(
    String message,
    Map<String, dynamic>? data,
    String? tag,
  ) {
    final parts = <String>[];

    if (tag != null) {
      parts.add('[$tag]');
    }

    parts.add(message);

    if (data != null && data.isNotEmpty) {
      final dataStr = data.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      parts.add('| Data: {$dataStr}');
    }

    return parts.join(' ');
  }

  /// Report error to external error reporting service
  /// This is a placeholder for integration with services like Sentry, Firebase Crashlytics, etc.
  static void _reportError(
    String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data, {
    bool isFatal = false,
  }) {
    // Only report errors in release mode to avoid noise during development
    if (!kReleaseMode) {
      return;
    }

    // Note: Error reporting service integration will be implemented when needed
    // Example for Sentry:
    // Sentry.captureException(
    //   error,
    //   stackTrace: stackTrace,
    //   hint: Hint.withMap({
    //     'message': message,
    //     'data': data,
    //     'isFatal': isFatal,
    //   }),
    // );

    // Example for Firebase Crashlytics:
    // FirebaseCrashlytics.instance.recordError(
    //   error,
    //   stackTrace,
    //   reason: message,
    //   fatal: isFatal,
    //   information: data?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
    // );
  }

  /// Export all logs as a string for support
  static Future<String> exportLogs() async {
    if (_logStorage == null) {
      return 'Log storage not initialized. Call AppLogger.initialize() first.';
    }
    return _logStorage!.exportLogs();
  }

  /// Export logs to a file and return the file path
  static Future<String?> exportLogsToFile() async {
    return _logStorage?.exportLogsToFile();
  }

  /// Get the total size of all log files in bytes
  static Future<int> getTotalLogSize() async {
    return await _logStorage?.getTotalLogSize() ?? 0;
  }

  /// Clear all stored logs
  static Future<void> clearLogs() async {
    await _logStorage?.clearLogs();
  }

  /// Get the log directory path
  static String? get logDirectoryPath => _logStorage?.logDirectoryPath;

  /// Flush pending logs to storage and remote
  static Future<void> flush() async {
    await _logStorage?.flush();
    await _remoteLogger?.flush();
  }

  /// Check if there are pending remote logs
  static bool get hasPendingRemoteLogs =>
      _remoteLogger?.hasPendingLogs ?? false;

  /// Get the number of pending remote logs
  static int get pendingRemoteLogCount => _remoteLogger?.queueSize ?? 0;

  /// Close the logger (cleanup)
  static Future<void> close() async {
    info('AppLogger closing');
    await flush();
    await _logStorage?.close();
    await _remoteLogger?.close();
    _logger.close();
    _initialized = false;
  }
}
