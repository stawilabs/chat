import 'package:freezed_annotation/freezed_annotation.dart';

part 'log_entry.freezed.dart';
part 'log_entry.g.dart';

/// Log severity levels
enum LogLevel { debug, info, warning, error }

/// Represents a single log entry with all metadata
@freezed
abstract class LogEntry with _$LogEntry {
  const factory LogEntry({
    required String id,
    required DateTime timestamp,
    required LogLevel level,
    required String message,
    String? correlationId,
    String? error,
    String? stackTrace,
    Map<String, dynamic>? data,
    String? tag,
  }) = _LogEntry;

  factory LogEntry.fromJson(Map<String, dynamic> json) =>
      _$LogEntryFromJson(json);
}
