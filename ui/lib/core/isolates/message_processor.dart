import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import 'isolate_manager.dart';

/// Task types for message processor isolate
class MessageProcessorTasks {
  static const String processMessageBatch = 'processMessageBatch';
  static const String validateMessages = 'validateMessages';
  static const String deduplicateMessages = 'deduplicateMessages';
  static const String parseJsonBatch = 'parseJsonBatch';
  static const String serializeMessages = 'serializeMessages';
}

/// Input for processing a batch of messages
class MessageBatchInput {
  MessageBatchInput({required this.messages, this.roomId, this.existingIds});

  factory MessageBatchInput.fromJson(Map<String, dynamic> json) =>
      MessageBatchInput(
        messages: (json['messages'] as List<dynamic>)
            .cast<Map<String, dynamic>>(),
        roomId: json['roomId'] as String?,
        existingIds: json['existingIds'] != null
            ? Set<String>.from(json['existingIds'] as List)
            : null,
      );
  final List<Map<String, dynamic>> messages;
  final String? roomId;
  final Set<String>? existingIds;

  Map<String, dynamic> toJson() => {
    'messages': messages,
    if (roomId != null) 'roomId': roomId,
    if (existingIds != null) 'existingIds': existingIds!.toList(),
  };
}

/// Result from processing a batch of messages
class MessageBatchResult {
  MessageBatchResult({
    required this.processedMessages,
    required this.newMessageCount,
    required this.duplicateCount,
    required this.invalidCount,
    this.errors,
  });

  factory MessageBatchResult.fromJson(Map<String, dynamic> json) =>
      MessageBatchResult(
        processedMessages: (json['processedMessages'] as List<dynamic>)
            .cast<Map<String, dynamic>>(),
        newMessageCount: json['newMessageCount'] as int,
        duplicateCount: json['duplicateCount'] as int,
        invalidCount: json['invalidCount'] as int,
        errors: json['errors'] != null
            ? (json['errors'] as List<dynamic>).cast<String>()
            : null,
      );
  final List<Map<String, dynamic>> processedMessages;
  final int newMessageCount;
  final int duplicateCount;
  final int invalidCount;
  final List<String>? errors;

  Map<String, dynamic> toJson() => {
    'processedMessages': processedMessages,
    'newMessageCount': newMessageCount,
    'duplicateCount': duplicateCount,
    'invalidCount': invalidCount,
    if (errors != null) 'errors': errors,
  };
}

/// Entry point for the message processor isolate
void messageProcessorEntryPoint(SendPort mainSendPort) {
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
      case MessageProcessorTasks.processMessageBatch:
        result = _processMessageBatch(message.payload as Map<String, dynamic>);
        break;
      case MessageProcessorTasks.validateMessages:
        result = _validateMessages(message.payload as List<dynamic>);
        break;
      case MessageProcessorTasks.deduplicateMessages:
        result = _deduplicateMessages(message.payload as Map<String, dynamic>);
        break;
      case MessageProcessorTasks.parseJsonBatch:
        result = _parseJsonBatch(message.payload as List<dynamic>);
        break;
      case MessageProcessorTasks.serializeMessages:
        result = _serializeMessages(message.payload as List<dynamic>);
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

/// Process a batch of incoming messages
Map<String, dynamic> _processMessageBatch(Map<String, dynamic> input) {
  final batchInput = MessageBatchInput.fromJson(input);
  final messages = batchInput.messages;
  final existingIds = batchInput.existingIds ?? <String>{};

  final processedMessages = <Map<String, dynamic>>[];
  final errors = <String>[];
  var duplicateCount = 0;
  var invalidCount = 0;

  for (final message in messages) {
    try {
      // Validate required fields
      if (!_isValidMessage(message)) {
        invalidCount++;
        continue;
      }

      final id = message['id'] as String;

      // Check for duplicates
      if (existingIds.contains(id)) {
        duplicateCount++;
        continue;
      }

      // Process and normalize the message
      final processed = _normalizeMessage(message);
      processedMessages.add(processed);
    } catch (e) {
      invalidCount++;
      errors.add('Error processing message: $e');
    }
  }

  return MessageBatchResult(
    processedMessages: processedMessages,
    newMessageCount: processedMessages.length,
    duplicateCount: duplicateCount,
    invalidCount: invalidCount,
    errors: errors.isNotEmpty ? errors : null,
  ).toJson();
}

/// Validate a list of messages
List<Map<String, dynamic>> _validateMessages(List<dynamic> messages) {
  final results = <Map<String, dynamic>>[];

  for (final message in messages) {
    if (message is! Map<String, dynamic>) {
      results.add({'valid': false, 'error': 'Message is not a Map'});
      continue;
    }

    final errors = <String>[];

    // Check required fields
    if (!message.containsKey('id') || message['id'] == null) {
      errors.add('Missing required field: id');
    }
    if (!message.containsKey('roomId') || message['roomId'] == null) {
      errors.add('Missing required field: roomId');
    }
    if (!message.containsKey('senderId') || message['senderId'] == null) {
      errors.add('Missing required field: senderId');
    }
    if (!message.containsKey('type') || message['type'] == null) {
      errors.add('Missing required field: type');
    }
    if (!message.containsKey('content') || message['content'] == null) {
      errors.add('Missing required field: content');
    }
    if (!message.containsKey('createdAt') || message['createdAt'] == null) {
      errors.add('Missing required field: createdAt');
    }

    // Validate field types
    if (message['id'] is! String) {
      errors.add('Field id must be a String');
    }
    if (message['roomId'] is! String) {
      errors.add('Field roomId must be a String');
    }
    if (message['createdAt'] is! int) {
      errors.add('Field createdAt must be an int');
    }

    results.add({
      'valid': errors.isEmpty,
      'errors': errors,
      'id': message['id'],
    });
  }

  return results;
}

/// Deduplicate messages based on ID
Map<String, dynamic> _deduplicateMessages(Map<String, dynamic> input) {
  final messages = (input['messages'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final existingIds = input['existingIds'] != null
      ? Set<String>.from(input['existingIds'] as List)
      : <String>{};

  final seen = <String>{};
  final unique = <Map<String, dynamic>>[];
  var duplicateCount = 0;

  for (final message in messages) {
    final id = message['id'] as String?;
    if (id == null) continue;

    if (existingIds.contains(id) || seen.contains(id)) {
      duplicateCount++;
      continue;
    }

    seen.add(id);
    unique.add(message);
  }

  return {
    'messages': unique,
    'duplicateCount': duplicateCount,
    'uniqueCount': unique.length,
  };
}

/// Parse a batch of JSON strings into maps
List<Map<String, dynamic>> _parseJsonBatch(List<dynamic> jsonStrings) {
  final results = <Map<String, dynamic>>[];

  for (final jsonStr in jsonStrings) {
    if (jsonStr is! String) continue;

    try {
      final parsed = jsonDecode(jsonStr);
      if (parsed is Map<String, dynamic>) {
        results.add(parsed);
      }
    } catch (e) {
      // Skip invalid JSON
    }
  }

  return results;
}

/// Serialize messages to JSON strings
List<String> _serializeMessages(List<dynamic> messages) {
  final results = <String>[];

  for (final message in messages) {
    if (message is! Map<String, dynamic>) continue;

    try {
      results.add(jsonEncode(message));
    } catch (e) {
      // Skip messages that can't be serialized
    }
  }

  return results;
}

/// Check if a message has all required fields
bool _isValidMessage(Map<String, dynamic> message) =>
    message.containsKey('id') &&
    message['id'] is String &&
    (message['id'] as String).isNotEmpty &&
    message.containsKey('roomId') &&
    message['roomId'] is String &&
    message.containsKey('type');

/// Normalize a message to ensure consistent structure
Map<String, dynamic> _normalizeMessage(Map<String, dynamic> message) {
  final normalized = Map<String, dynamic>.from(message);

  // Ensure required fields have defaults
  normalized['status'] ??= 1; // EventStatus.sent
  normalized['createdAt'] ??= DateTime.now().millisecondsSinceEpoch;
  normalized['content'] ??= <String, dynamic>{};

  // Trim string fields
  if (normalized['id'] is String) {
    normalized['id'] = (normalized['id'] as String).trim();
  }
  if (normalized['roomId'] is String) {
    normalized['roomId'] = (normalized['roomId'] as String).trim();
  }
  if (normalized['senderId'] is String) {
    normalized['senderId'] = (normalized['senderId'] as String).trim();
  }

  return normalized;
}

/// Service for processing messages in a background isolate
///
/// Offloads heavy message processing operations to prevent UI jank.
///
/// Example:
/// ```dart
/// final processor = await ref.read(messageProcessorServiceProvider.future);
///
/// final result = await processor.processBatch(messages);
/// print('Processed ${result.newMessageCount} new messages');
/// ```
class MessageProcessorService {
  MessageProcessorService(this._isolateManager);

  static const String _isolateName = 'message_processor';

  final IsolateManager _isolateManager;
  bool _initialized = false;

  /// Initialize the message processor isolate
  Future<void> initialize() async {
    if (_initialized) return;

    await _isolateManager.initialize();
    final success = await _isolateManager.spawnIsolate(
      _isolateName,
      messageProcessorEntryPoint,
      debugName: 'MessageProcessor',
    );

    if (!success) {
      throw StateError('Failed to spawn message processor isolate');
    }

    _initialized = true;
    AppLogger.info('MessageProcessorService initialized');
  }

  /// Process a batch of messages
  Future<MessageBatchResult> processBatch(
    List<Map<String, dynamic>> messages, {
    String? roomId,
    Set<String>? existingIds,
  }) async {
    await _ensureInitialized();

    final input = MessageBatchInput(
      messages: messages,
      roomId: roomId,
      existingIds: existingIds,
    );

    final result = await _isolateManager.execute<Map<String, dynamic>>(
      _isolateName,
      MessageProcessorTasks.processMessageBatch,
      input.toJson(),
    );

    return MessageBatchResult.fromJson(result);
  }

  /// Validate a list of messages
  Future<List<Map<String, dynamic>>> validateMessages(
    List<Map<String, dynamic>> messages,
  ) async {
    await _ensureInitialized();

    return _isolateManager.execute<List<Map<String, dynamic>>>(
      _isolateName,
      MessageProcessorTasks.validateMessages,
      messages,
    );
  }

  /// Deduplicate messages
  Future<Map<String, dynamic>> deduplicateMessages(
    List<Map<String, dynamic>> messages, {
    Set<String>? existingIds,
  }) async {
    await _ensureInitialized();

    return _isolateManager.execute<Map<String, dynamic>>(
      _isolateName,
      MessageProcessorTasks.deduplicateMessages,
      {
        'messages': messages,
        if (existingIds != null) 'existingIds': existingIds.toList(),
      },
    );
  }

  /// Parse a batch of JSON strings
  Future<List<Map<String, dynamic>>> parseJsonBatch(
    List<String> jsonStrings,
  ) async {
    await _ensureInitialized();

    return _isolateManager.execute<List<Map<String, dynamic>>>(
      _isolateName,
      MessageProcessorTasks.parseJsonBatch,
      jsonStrings,
    );
  }

  /// Serialize messages to JSON
  Future<List<String>> serializeMessages(
    List<Map<String, dynamic>> messages,
  ) async {
    await _ensureInitialized();

    return _isolateManager.execute<List<String>>(
      _isolateName,
      MessageProcessorTasks.serializeMessages,
      messages,
    );
  }

  /// Shutdown the message processor
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
final messageProcessorServiceProvider = FutureProvider<MessageProcessorService>(
  (ref) async {
    final manager = ref.watch(isolateManagerProvider);
    final service = MessageProcessorService(manager);
    await service.initialize();

    ref.onDispose(() async {
      await service.shutdown();
    });

    return service;
  },
);
