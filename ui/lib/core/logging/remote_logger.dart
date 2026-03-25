import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'log_entry.dart';
import 'sensitive_data_filter.dart';

/// Configuration for remote logging
class RemoteLoggerConfig {
  const RemoteLoggerConfig({
    required this.endpoint,
    this.apiKey,
    this.batchSize = 10,
    this.flushInterval = const Duration(seconds: 30),
    this.maxQueueSize = 1000,
    this.timeout = const Duration(seconds: 10),
    this.enabled = true,
    this.minLevel = LogLevel.warning,
  });

  /// The endpoint URL to send logs to
  final String endpoint;

  /// Optional API key for authentication
  final String? apiKey;

  /// Number of logs to batch before sending
  final int batchSize;

  /// How often to flush logs to remote (even if batch not full)
  final Duration flushInterval;

  /// Maximum number of logs to queue before dropping old ones
  final int maxQueueSize;

  /// HTTP request timeout
  final Duration timeout;

  /// Whether remote logging is enabled
  final bool enabled;

  /// Minimum log level to send remotely
  final LogLevel minLevel;
}

/// Handles sending logs to a remote logging service
///
/// Features:
/// - Batches logs for efficient network usage
/// - Queues logs when offline and sends when back online
/// - Filters sensitive data before sending
/// - Automatic retry with exponential backoff
class RemoteLogger {
  RemoteLogger({required this.config, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final RemoteLoggerConfig config;
  final http.Client _httpClient;

  /// Queue of pending log entries
  final Queue<LogEntry> _queue = Queue<LogEntry>();

  /// Timer for periodic flushing
  Timer? _flushTimer;

  /// Whether the remote logger is initialized
  bool _initialized = false;

  /// Whether currently sending logs (to prevent concurrent sends)
  bool _sending = false;

  /// Consecutive failure count for backoff calculation
  int _consecutiveFailures = 0;

  /// Initialize the remote logger
  void initialize() {
    if (_initialized || !config.enabled) return;

    _flushTimer = Timer.periodic(config.flushInterval, (_) => flush());
    _initialized = true;
  }

  /// Add a log entry to the remote queue
  void log(LogEntry entry) {
    if (!_initialized || !config.enabled) return;

    // Only send logs at or above minimum level
    if (entry.level.index < config.minLevel.index) return;

    // Filter sensitive data before queuing
    final filteredEntry = _filterEntry(entry);

    // Add to queue, dropping old entries if full
    if (_queue.length >= config.maxQueueSize) {
      _queue.removeFirst();
    }
    _queue.add(filteredEntry);

    // Flush if batch size reached
    if (_queue.length >= config.batchSize) {
      flush();
    }
  }

  /// Filter sensitive data from a log entry
  LogEntry _filterEntry(LogEntry entry) {
    return entry.copyWith(
      message: SensitiveDataFilter.filterMessage(entry.message),
      error: entry.error != null
          ? SensitiveDataFilter.filterString(entry.error!)
          : null,
      stackTrace: entry.stackTrace != null
          ? SensitiveDataFilter.filterString(entry.stackTrace!)
          : null,
      data: entry.data != null
          ? SensitiveDataFilter.filterData(entry.data)
          : null,
    );
  }

  /// Flush queued logs to the remote server
  Future<void> flush() async {
    if (!_initialized || !config.enabled || _queue.isEmpty || _sending) return;

    _sending = true;

    try {
      // Take a batch of logs
      final batch = <LogEntry>[];
      while (batch.length < config.batchSize && _queue.isNotEmpty) {
        batch.add(_queue.removeFirst());
      }

      if (batch.isEmpty) return;

      final success = await _sendBatch(batch);

      if (success) {
        _consecutiveFailures = 0;
      } else {
        _consecutiveFailures++;
        // Re-queue failed batch at the front (they'll be retried)
        for (final entry in batch.reversed) {
          _queue.addFirst(entry);
        }
      }
    } finally {
      _sending = false;
    }
  }

  /// Send a batch of logs to the remote server
  Future<bool> _sendBatch(List<LogEntry> batch) async {
    // Calculate backoff delay
    if (_consecutiveFailures > 0) {
      final backoffMs = _calculateBackoff(_consecutiveFailures);
      await Future<void>.delayed(Duration(milliseconds: backoffMs));
    }

    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (config.apiKey != null) {
        headers['Authorization'] = 'Bearer ${config.apiKey}';
      }

      final body = jsonEncode({
        'logs': batch.map((e) => e.toJson()).toList(),
        'metadata': {
          'app': 'chat',
          'platform': defaultTargetPlatform.name,
          'sentAt': DateTime.now().toUtc().toIso8601String(),
        },
      });

      final response = await _httpClient
          .post(Uri.parse(config.endpoint), headers: headers, body: body)
          .timeout(config.timeout);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Failed to send logs to remote: $e');
      return false;
    }
  }

  /// Calculate exponential backoff delay
  int _calculateBackoff(int failures) {
    // Exponential backoff: 1s, 2s, 4s, 8s, max 60s
    const baseMs = 1000;
    const maxMs = 60000;
    final delay = baseMs * (1 << (failures - 1).clamp(0, 6));
    return delay.clamp(baseMs, maxMs);
  }

  /// Get the current queue size
  int get queueSize => _queue.length;

  /// Check if there are pending logs
  bool get hasPendingLogs => _queue.isNotEmpty;

  /// Close the remote logger and flush any remaining logs
  Future<void> close() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    // Try to flush remaining logs
    if (_queue.isNotEmpty) {
      await flush();
    }

    _initialized = false;
  }

  /// Clear all queued logs without sending
  void clearQueue() {
    _queue.clear();
  }
}
