// ignore_for_file: avoid_slow_async_io

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'log_entry.dart';

/// Manages local log file storage with rotation support
///
/// Features:
/// - Writes logs to local files
/// - Rotates logs when size limit is reached (default 10MB)
/// - Maintains a configurable number of old log files
/// - Provides export functionality for support
class LogStorage {
  LogStorage({
    this.maxFileSize = 10 * 1024 * 1024, // 10MB default
    this.maxFiles = 5,
    this.logFileName = 'app.log',
  });

  /// Maximum size of a single log file in bytes
  final int maxFileSize;

  /// Maximum number of log files to keep (including current)
  final int maxFiles;

  /// Base name for log files
  final String logFileName;

  Directory? _logDirectory;
  File? _currentLogFile;
  IOSink? _sink;
  int _currentFileSize = 0;
  bool _initialized = false;

  /// Initialize the log storage
  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _logDirectory = Directory('${appDir.path}/logs');

      if (!await _logDirectory!.exists()) {
        await _logDirectory!.create(recursive: true);
      }

      await _openCurrentLogFile();
      _initialized = true;
    } catch (e) {
      // Silently fail - logging should not crash the app
      debugPrint('Failed to initialize log storage: $e');
    }
  }

  /// Open or create the current log file
  Future<void> _openCurrentLogFile() async {
    if (_logDirectory == null) return;

    _currentLogFile = File('${_logDirectory!.path}/$logFileName');

    if (await _currentLogFile!.exists()) {
      _currentFileSize = await _currentLogFile!.length();
    } else {
      _currentFileSize = 0;
    }

    _sink = _currentLogFile!.openWrite(mode: FileMode.append);
  }

  /// Write a log entry to storage
  Future<void> write(LogEntry entry) async {
    if (!_initialized || _sink == null || kIsWeb) return;

    try {
      final jsonLine = '${jsonEncode(entry.toJson())}\n';
      final bytes = utf8.encode(jsonLine);

      // Check if we need to rotate
      if (_currentFileSize + bytes.length > maxFileSize) {
        await _rotate();
      }

      _sink!.write(jsonLine);
      _currentFileSize += bytes.length;

      // Flush periodically to ensure logs are written
      // (sink.flush() is relatively expensive, so we don't call it on every write)
    } catch (e) {
      debugPrint('Failed to write log entry: $e');
    }
  }

  /// Rotate log files
  Future<void> _rotate() async {
    if (_logDirectory == null || _currentLogFile == null) return;

    // Close current sink
    await _sink?.flush();
    await _sink?.close();
    _sink = null;

    // Rename current file with timestamp
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final rotatedName = '${logFileName.replaceAll('.log', '')}_$timestamp.log';
    final rotatedFile = File('${_logDirectory!.path}/$rotatedName');

    try {
      await _currentLogFile!.rename(rotatedFile.path);
    } catch (e) {
      debugPrint('Failed to rotate log file: $e');
    }

    // Clean up old files
    await _cleanupOldFiles();

    // Open new log file
    _currentFileSize = 0;
    await _openCurrentLogFile();
  }

  /// Remove old log files exceeding the max count
  Future<void> _cleanupOldFiles() async {
    if (_logDirectory == null) return;

    try {
      final files = await _logDirectory!
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      // Sort by modification time, newest first
      files.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      // Delete files exceeding the limit (keep maxFiles - 1 for rotated + 1 current)
      if (files.length >= maxFiles) {
        for (var i = maxFiles - 1; i < files.length; i++) {
          try {
            await files[i].delete();
          } catch (e) {
            debugPrint('Failed to delete old log file: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to cleanup old log files: $e');
    }
  }

  /// Flush pending writes to disk
  Future<void> flush() async {
    try {
      await _sink?.flush();
    } catch (e) {
      debugPrint('Failed to flush log sink: $e');
    }
  }

  /// Export all logs as a single string for support
  Future<String> exportLogs() async {
    if (_logDirectory == null || kIsWeb) {
      return 'Log export not available on this platform';
    }

    await flush();

    final buffer = StringBuffer();
    buffer.writeln('=== Chat App Log Export ===');
    buffer.writeln('Exported at: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    try {
      final files = await _logDirectory!
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      // Sort by modification time, oldest first
      files.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return aStat.modified.compareTo(bStat.modified);
      });

      for (final file in files) {
        buffer.writeln('--- ${file.path.split('/').last} ---');
        try {
          final content = await file.readAsString();
          buffer.writeln(content);
        } catch (e) {
          buffer.writeln('Error reading file: $e');
        }
        buffer.writeln();
      }
    } catch (e) {
      buffer.writeln('Error exporting logs: $e');
    }

    return buffer.toString();
  }

  /// Export logs to a file and return the file path
  Future<String?> exportLogsToFile() async {
    if (_logDirectory == null || kIsWeb) return null;

    await flush();

    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final exportFile = File('${_logDirectory!.path}/export_$timestamp.txt');

      final content = await exportLogs();
      await exportFile.writeAsString(content);

      return exportFile.path;
    } catch (e) {
      debugPrint('Failed to export logs to file: $e');
      return null;
    }
  }

  /// Get the total size of all log files
  Future<int> getTotalLogSize() async {
    if (_logDirectory == null || kIsWeb) return 0;

    try {
      final files = await _logDirectory!
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      var totalSize = 0;
      for (final file in files) {
        totalSize += await file.length();
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all log files
  Future<void> clearLogs() async {
    if (_logDirectory == null || kIsWeb) return;

    await _sink?.flush();
    await _sink?.close();
    _sink = null;

    try {
      final files = await _logDirectory!
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      for (final file in files) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('Failed to delete log file: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to clear logs: $e');
    }

    // Reopen the current log file
    _currentFileSize = 0;
    await _openCurrentLogFile();
  }

  /// Get the log directory path
  String? get logDirectoryPath => _logDirectory?.path;

  /// Close the log storage (call on app shutdown)
  Future<void> close() async {
    try {
      await _sink?.flush();
      await _sink?.close();
      _sink = null;
      _initialized = false;
    } catch (e) {
      debugPrint('Failed to close log storage: $e');
    }
  }
}
