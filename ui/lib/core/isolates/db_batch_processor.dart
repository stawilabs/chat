import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import 'isolate_manager.dart';

/// Task types for database batch processor isolate
class DbBatchTasks {
  static const String prepareInsertBatch = 'prepareInsertBatch';
  static const String prepareUpdateBatch = 'prepareUpdateBatch';
  static const String serializeForDb = 'serializeForDb';
  static const String deserializeFromDb = 'deserializeFromDb';
  static const String buildSearchIndex = 'buildSearchIndex';
  static const String filterAndSort = 'filterAndSort';
}

/// Input for batch insert preparation
class InsertBatchInput {
  InsertBatchInput({
    required this.tableName,
    required this.rows,
    this.conflictStrategy = 'replace',
  });

  factory InsertBatchInput.fromJson(Map<String, dynamic> json) =>
      InsertBatchInput(
        tableName: json['tableName'] as String,
        rows: (json['rows'] as List<dynamic>).cast<Map<String, dynamic>>(),
        conflictStrategy: json['conflictStrategy'] as String? ?? 'replace',
      );
  final String tableName;
  final List<Map<String, dynamic>> rows;
  final String conflictStrategy;

  Map<String, dynamic> toJson() => {
    'tableName': tableName,
    'rows': rows,
    'conflictStrategy': conflictStrategy,
  };
}

/// Result from batch preparation
class BatchPrepareResult {
  BatchPrepareResult({
    required this.tableName,
    required this.preparedRows,
    required this.rowCount,
    required this.estimatedSize,
    this.errors,
  });

  factory BatchPrepareResult.fromJson(Map<String, dynamic> json) =>
      BatchPrepareResult(
        tableName: json['tableName'] as String,
        preparedRows: (json['preparedRows'] as List<dynamic>)
            .cast<Map<String, dynamic>>(),
        rowCount: json['rowCount'] as int,
        estimatedSize: json['estimatedSize'] as int,
        errors: json['errors'] != null
            ? (json['errors'] as List<dynamic>).cast<String>()
            : null,
      );
  final String tableName;
  final List<Map<String, dynamic>> preparedRows;
  final int rowCount;
  final int estimatedSize;
  final List<String>? errors;

  Map<String, dynamic> toJson() => {
    'tableName': tableName,
    'preparedRows': preparedRows,
    'rowCount': rowCount,
    'estimatedSize': estimatedSize,
    if (errors != null) 'errors': errors,
  };
}

/// Search index entry for full-text search
class SearchIndexEntry {
  SearchIndexEntry({
    required this.id,
    required this.roomId,
    required this.searchableText,
    required this.timestamp,
    this.metadata,
  });

  factory SearchIndexEntry.fromJson(Map<String, dynamic> json) =>
      SearchIndexEntry(
        id: json['id'] as String,
        roomId: json['roomId'] as String,
        searchableText: json['searchableText'] as String,
        timestamp: json['timestamp'] as int,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
  final String id;
  final String roomId;
  final String searchableText;
  final int timestamp;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'searchableText': searchableText,
    'timestamp': timestamp,
    if (metadata != null) 'metadata': metadata,
  };
}

/// Entry point for the database batch processor isolate
void dbBatchProcessorEntryPoint(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is! IsolateMessage) return;

    switch (message.type) {
      case IsolateMessageType.execute:
        _handleTask(message, mainSendPort);
        break;
      case IsolateMessageType.shutdown:
        receivePort.close();
        break;
      default:
        break;
    }
  });
}

/// Handle a task in the isolate
void _handleTask(IsolateMessage message, SendPort sendPort) {
  try {
    dynamic result;

    switch (message.taskType) {
      case DbBatchTasks.prepareInsertBatch:
        result = _prepareInsertBatch(message.payload as Map<String, dynamic>);
        break;
      case DbBatchTasks.prepareUpdateBatch:
        result = _prepareUpdateBatch(message.payload as Map<String, dynamic>);
        break;
      case DbBatchTasks.serializeForDb:
        result = _serializeForDb(message.payload as List<dynamic>);
        break;
      case DbBatchTasks.deserializeFromDb:
        result = _deserializeFromDb(message.payload as List<dynamic>);
        break;
      case DbBatchTasks.buildSearchIndex:
        result = _buildSearchIndex(message.payload as List<dynamic>);
        break;
      case DbBatchTasks.filterAndSort:
        result = _filterAndSort(message.payload as Map<String, dynamic>);
        break;
      default:
        throw ArgumentError('Unknown task type: ${message.taskType}');
    }

    sendPort.send(
      IsolateMessage(
        type: IsolateMessageType.response,
        taskId: message.taskId,
        result: result,
      ),
    );
  } catch (e, stackTrace) {
    sendPort.send(
      IsolateMessage(
        type: IsolateMessageType.error,
        taskId: message.taskId,
        error: e.toString(),
        stackTrace: stackTrace.toString(),
      ),
    );
  }
}

/// Prepare a batch of rows for insert
Map<String, dynamic> _prepareInsertBatch(Map<String, dynamic> input) {
  final batchInput = InsertBatchInput.fromJson(input);
  final preparedRows = <Map<String, dynamic>>[];
  final errors = <String>[];
  var estimatedSize = 0;

  for (var i = 0; i < batchInput.rows.length; i++) {
    try {
      final row = batchInput.rows[i];
      final prepared = _prepareRow(row, batchInput.tableName);
      preparedRows.add(prepared);
      estimatedSize += _estimateRowSize(prepared);
    } catch (e) {
      errors.add('Row $i: $e');
    }
  }

  return BatchPrepareResult(
    tableName: batchInput.tableName,
    preparedRows: preparedRows,
    rowCount: preparedRows.length,
    estimatedSize: estimatedSize,
    errors: errors.isNotEmpty ? errors : null,
  ).toJson();
}

/// Prepare a batch of rows for update
Map<String, dynamic> _prepareUpdateBatch(Map<String, dynamic> input) {
  final tableName = input['tableName'] as String;
  final rows = (input['rows'] as List<dynamic>).cast<Map<String, dynamic>>();
  final whereColumn = input['whereColumn'] as String? ?? 'id';

  final preparedRows = <Map<String, dynamic>>[];
  final errors = <String>[];
  var estimatedSize = 0;

  for (var i = 0; i < rows.length; i++) {
    try {
      final row = rows[i];
      if (!row.containsKey(whereColumn)) {
        throw ArgumentError('Row missing where column: $whereColumn');
      }

      final prepared = _prepareRow(row, tableName);
      prepared['_whereColumn'] = whereColumn;
      prepared['_whereValue'] = row[whereColumn];
      preparedRows.add(prepared);
      estimatedSize += _estimateRowSize(prepared);
    } catch (e) {
      errors.add('Row $i: $e');
    }
  }

  return BatchPrepareResult(
    tableName: tableName,
    preparedRows: preparedRows,
    rowCount: preparedRows.length,
    estimatedSize: estimatedSize,
    errors: errors.isNotEmpty ? errors : null,
  ).toJson();
}

/// Serialize rows for database storage
List<Map<String, dynamic>> _serializeForDb(List<dynamic> rows) {
  final results = <Map<String, dynamic>>[];

  for (final row in rows) {
    if (row is! Map<String, dynamic>) continue;

    final serialized = <String, dynamic>{};
    for (final entry in row.entries) {
      serialized[entry.key] = _serializeValue(entry.value);
    }
    results.add(serialized);
  }

  return results;
}

/// Deserialize rows from database
List<Map<String, dynamic>> _deserializeFromDb(List<dynamic> rows) {
  final results = <Map<String, dynamic>>[];

  for (final row in rows) {
    if (row is! Map<String, dynamic>) continue;

    final deserialized = <String, dynamic>{};
    for (final entry in row.entries) {
      deserialized[entry.key] = _deserializeValue(entry.value);
    }
    results.add(deserialized);
  }

  return results;
}

/// Build search index entries from messages
List<Map<String, dynamic>> _buildSearchIndex(List<dynamic> messages) {
  final entries = <Map<String, dynamic>>[];

  for (final message in messages) {
    if (message is! Map<String, dynamic>) continue;

    final id = message['id'] as String?;
    final roomId = message['roomId'] as String?;
    final content = message['content'];
    final createdAt = message['createdAt'] as int?;

    if (id == null || roomId == null) continue;

    // Extract searchable text from content
    final searchableText = _extractSearchableText(content);
    if (searchableText.isEmpty) continue;

    entries.add(
      SearchIndexEntry(
        id: id,
        roomId: roomId,
        searchableText: searchableText.toLowerCase(),
        timestamp: createdAt ?? DateTime.now().millisecondsSinceEpoch,
        metadata: {'type': message['type'], 'senderId': message['senderId']},
      ).toJson(),
    );
  }

  return entries;
}

/// Filter and sort rows
Map<String, dynamic> _filterAndSort(Map<String, dynamic> input) {
  var rows = (input['rows'] as List<dynamic>).cast<Map<String, dynamic>>();
  final filters = input['filters'] as Map<String, dynamic>?;
  final sortBy = input['sortBy'] as String?;
  final sortDescending = input['sortDescending'] as bool? ?? false;
  final limit = input['limit'] as int?;
  final offset = input['offset'] as int?;

  // Apply filters
  if (filters != null && filters.isNotEmpty) {
    rows = rows.where((row) {
      for (final filter in filters.entries) {
        final fieldValue = row[filter.key];
        final filterValue = filter.value;

        if (filterValue is Map) {
          // Complex filter
          final op = filterValue['op'] as String?;
          final value = filterValue['value'];

          switch (op) {
            case 'eq':
              if (fieldValue != value) return false;
              break;
            case 'neq':
              if (fieldValue == value) return false;
              break;
            case 'gt':
              if (fieldValue is! num || value is! num || fieldValue <= value) {
                return false;
              }
              break;
            case 'gte':
              if (fieldValue is! num || value is! num || fieldValue < value) {
                return false;
              }
              break;
            case 'lt':
              if (fieldValue is! num || value is! num || fieldValue >= value) {
                return false;
              }
              break;
            case 'lte':
              if (fieldValue is! num || value is! num || fieldValue > value) {
                return false;
              }
              break;
            case 'contains':
              if (fieldValue is! String ||
                  value is! String ||
                  !fieldValue.toLowerCase().contains(value.toLowerCase())) {
                return false;
              }
              break;
            case 'in':
              if (value is! List || !value.contains(fieldValue)) {
                return false;
              }
              break;
          }
        } else {
          // Simple equality filter
          if (fieldValue != filterValue) return false;
        }
      }
      return true;
    }).toList();
  }

  // Apply sort
  if (sortBy != null) {
    rows.sort((a, b) {
      final aValue = a[sortBy];
      final bValue = b[sortBy];

      int comparison;
      if (aValue == null && bValue == null) {
        comparison = 0;
      } else if (aValue == null) {
        comparison = 1;
      } else if (bValue == null) {
        comparison = -1;
      } else if (aValue is Comparable) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = aValue.toString().compareTo(bValue.toString());
      }

      return sortDescending ? -comparison : comparison;
    });
  }

  // Apply pagination
  final totalCount = rows.length;
  if (offset != null && offset > 0) {
    rows = rows.skip(offset).toList();
  }
  if (limit != null && limit > 0) {
    rows = rows.take(limit).toList();
  }

  return {'rows': rows, 'totalCount': totalCount, 'returnedCount': rows.length};
}

/// Prepare a single row for database
Map<String, dynamic> _prepareRow(Map<String, dynamic> row, String tableName) {
  final prepared = <String, dynamic>{};

  for (final entry in row.entries) {
    final key = _toSnakeCase(entry.key);
    prepared[key] = _serializeValue(entry.value);
  }

  return prepared;
}

/// Serialize a value for database storage
Object? _serializeValue(Object? value) {
  if (value == null) return null;
  if (value is String || value is num || value is bool) return value;
  if (value is DateTime) return value.millisecondsSinceEpoch;
  if (value is List || value is Map) return jsonEncode(value);
  return value.toString();
}

/// Deserialize a value from database
Object? _deserializeValue(Object? value) {
  if (value == null) return null;
  if (value is String) {
    // Try to parse as JSON
    if (value.startsWith('{') || value.startsWith('[')) {
      try {
        return jsonDecode(value);
      } catch (_) {
        return value;
      }
    }
  }
  return value;
}

/// Extract searchable text from message content
String _extractSearchableText(Object? content) {
  if (content == null) return '';

  if (content is String) return content;

  if (content is Map<String, dynamic>) {
    final buffer = StringBuffer();

    // Extract text field
    if (content['text'] is String) {
      buffer.write(content['text']);
      buffer.write(' ');
    }

    // Extract filename for attachments
    if (content['fileName'] is String) {
      buffer.write(content['fileName']);
      buffer.write(' ');
    }

    // Extract body for other content types
    if (content['body'] is String) {
      buffer.write(content['body']);
      buffer.write(' ');
    }

    return buffer.toString().trim();
  }

  return '';
}

/// Estimate the size of a row in bytes
int _estimateRowSize(Map<String, dynamic> row) {
  var size = 0;
  for (final entry in row.entries) {
    size += entry.key.length * 2; // Key size
    size += _estimateValueSize(entry.value);
  }
  return size;
}

/// Estimate the size of a value in bytes
int _estimateValueSize(Object? value) {
  if (value == null) return 1;
  if (value is bool) return 1;
  if (value is int) return 8;
  if (value is double) return 8;
  if (value is String) return value.length * 2;
  if (value is List) {
    return value.fold<int>(4, (sum, item) => sum + _estimateValueSize(item));
  }
  if (value is Map) {
    return value.entries.fold<int>(4, (sum, entry) {
      return sum +
          _estimateValueSize(entry.key) +
          _estimateValueSize(entry.value);
    });
  }
  return 8;
}

/// Convert camelCase to snake_case
String _toSnakeCase(String input) {
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (char.toUpperCase() == char && char.toLowerCase() != char) {
      if (i > 0) buffer.write('_');
      buffer.write(char.toLowerCase());
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

/// Service for database batch processing in a background isolate
///
/// Offloads heavy data preparation and serialization to prevent UI jank.
///
/// Example:
/// ```dart
/// final processor = await ref.read(dbBatchProcessorServiceProvider.future);
///
/// final result = await processor.prepareInsertBatch(
///   'room_events',
///   messages,
/// );
/// ```
class DbBatchProcessorService {
  DbBatchProcessorService(this._isolateManager);

  static const String _isolateName = 'db_batch_processor';

  final IsolateManager _isolateManager;
  bool _initialized = false;

  /// Initialize the database batch processor isolate
  Future<void> initialize() async {
    if (_initialized) return;

    await _isolateManager.initialize();
    final success = await _isolateManager.spawnIsolate(
      _isolateName,
      dbBatchProcessorEntryPoint,
      debugName: 'DbBatchProcessor',
    );

    if (!success) {
      throw StateError('Failed to spawn db batch processor isolate');
    }

    _initialized = true;
    AppLogger.info('DbBatchProcessorService initialized');
  }

  /// Prepare a batch of rows for insert
  Future<BatchPrepareResult> prepareInsertBatch(
    String tableName,
    List<Map<String, dynamic>> rows, {
    String conflictStrategy = 'replace',
  }) async {
    await _ensureInitialized();

    final input = InsertBatchInput(
      tableName: tableName,
      rows: rows,
      conflictStrategy: conflictStrategy,
    );

    final result = await _isolateManager.execute<Map<String, dynamic>>(
      _isolateName,
      DbBatchTasks.prepareInsertBatch,
      input.toJson(),
    );

    return BatchPrepareResult.fromJson(result);
  }

  /// Prepare a batch of rows for update
  Future<BatchPrepareResult> prepareUpdateBatch(
    String tableName,
    List<Map<String, dynamic>> rows, {
    String whereColumn = 'id',
  }) async {
    await _ensureInitialized();

    final result = await _isolateManager.execute<Map<String, dynamic>>(
      _isolateName,
      DbBatchTasks.prepareUpdateBatch,
      {'tableName': tableName, 'rows': rows, 'whereColumn': whereColumn},
    );

    return BatchPrepareResult.fromJson(result);
  }

  /// Serialize rows for database storage
  Future<List<Map<String, dynamic>>> serializeForDb(
    List<Map<String, dynamic>> rows,
  ) async {
    await _ensureInitialized();

    return _isolateManager.execute<List<Map<String, dynamic>>>(
      _isolateName,
      DbBatchTasks.serializeForDb,
      rows,
    );
  }

  /// Deserialize rows from database
  Future<List<Map<String, dynamic>>> deserializeFromDb(
    List<Map<String, dynamic>> rows,
  ) async {
    await _ensureInitialized();

    return _isolateManager.execute<List<Map<String, dynamic>>>(
      _isolateName,
      DbBatchTasks.deserializeFromDb,
      rows,
    );
  }

  /// Build search index entries from messages
  Future<List<SearchIndexEntry>> buildSearchIndex(
    List<Map<String, dynamic>> messages,
  ) async {
    await _ensureInitialized();

    final result = await _isolateManager.execute<List<dynamic>>(
      _isolateName,
      DbBatchTasks.buildSearchIndex,
      messages,
    );

    return result
        .cast<Map<String, dynamic>>()
        .map(SearchIndexEntry.fromJson)
        .toList();
  }

  /// Filter and sort rows
  Future<Map<String, dynamic>> filterAndSort(
    List<Map<String, dynamic>> rows, {
    Map<String, dynamic>? filters,
    String? sortBy,
    bool sortDescending = false,
    int? limit,
    int? offset,
  }) async {
    await _ensureInitialized();

    return _isolateManager.execute<Map<String, dynamic>>(
      _isolateName,
      DbBatchTasks.filterAndSort,
      {
        'rows': rows,
        if (filters != null) 'filters': filters,
        if (sortBy != null) 'sortBy': sortBy,
        'sortDescending': sortDescending,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );
  }

  /// Shutdown the processor
  Future<void> shutdown() async {
    if (!_initialized) return;
    await _isolateManager.shutdownIsolate(_isolateName);
    _initialized = false;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
}

// Providers
final dbBatchProcessorServiceProvider = FutureProvider<DbBatchProcessorService>(
  (ref) async {
    final manager = ref.watch(isolateManagerProvider);
    final service = DbBatchProcessorService(manager);
    await service.initialize();

    ref.onDispose(() async {
      await service.shutdown();
    });

    return service;
  },
);
