/// Seed data factories for E2E tests.
///
/// Provides factory methods for generating test data such as messages,
/// rooms, and batch data for throughput tests.
library;

import 'dart:math';

import 'package:uuid/uuid.dart';

/// Factory class for generating test messages.
class TestMessageFactory {
  /// Private constructor.
  TestMessageFactory._();

  static const _uuid = Uuid();
  static final _random = Random();

  /// Generates a test text message with optional parameters.
  ///
  /// [text] - The message text. If not provided, a random message is generated.
  /// [roomId] - The room ID. Defaults to a random ID.
  /// [senderId] - The sender profile ID. Defaults to a random ID.
  static TestMessage generateTestMessage({
    String? text,
    String? roomId,
    String? senderId,
  }) {
    return TestMessage(
      id: _uuid.v4(),
      roomId: roomId ?? _uuid.v4(),
      senderId: senderId ?? _uuid.v4(),
      text: text ?? _generateRandomText(),
      createdAt: DateTime.now(),
    );
  }

  /// Generates a unique message text with timestamp for verification.
  ///
  /// The generated text includes a UUID and timestamp to ensure uniqueness,
  /// making it easy to verify message delivery in tests.
  static String generateUniqueMessageText([String? prefix]) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = _uuid.v4().substring(0, 8);
    final effectivePrefix = prefix ?? 'E2E Test';
    return '$effectivePrefix [$uuid] - $timestamp';
  }

  /// Generates a random text message for testing.
  static String _generateRandomText() {
    final messages = [
      'Hello from E2E test!',
      'This is a test message.',
      'Testing message delivery.',
      'Automated E2E test message.',
      'Message verification test.',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Generates a batch of test messages for throughput testing.
  ///
  /// [count] - Number of messages to generate.
  /// [roomId] - The room ID for all messages.
  /// [senderId] - The sender ID for all messages.
  /// [delayBetweenMs] - Optional delay between message timestamps.
  static List<TestMessage> generateMessageBatch({
    required int count,
    String? roomId,
    String? senderId,
    int delayBetweenMs = 100,
  }) {
    final effectiveRoomId = roomId ?? _uuid.v4();
    final effectiveSenderId = senderId ?? _uuid.v4();
    final baseTime = DateTime.now();

    return List.generate(count, (index) {
      return TestMessage(
        id: _uuid.v4(),
        roomId: effectiveRoomId,
        senderId: effectiveSenderId,
        text:
            'Batch message ${index + 1} of $count [${_uuid.v4().substring(0, 8)}]',
        createdAt: baseTime.add(Duration(milliseconds: index * delayBetweenMs)),
      );
    });
  }
}

/// Factory class for generating test rooms.
class TestRoomFactory {
  /// Private constructor.
  TestRoomFactory._();

  static const _uuid = Uuid();
  static final _random = Random();

  /// Generates a test room with optional parameters.
  ///
  /// [name] - The room name. If not provided, a random name is generated.
  /// [type] - The room type (direct, group). Defaults to group.
  /// [memberIds] - List of member profile IDs.
  static TestRoom generateTestRoom({
    String? name,
    RoomType type = RoomType.group,
    List<String>? memberIds,
  }) {
    return TestRoom(
      id: _uuid.v4(),
      name: name ?? _generateRandomRoomName(),
      type: type,
      memberIds: memberIds ?? [],
      createdAt: DateTime.now(),
    );
  }

  /// Generates a unique room name with timestamp.
  static String generateUniqueRoomName([String? prefix]) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = _uuid.v4().substring(0, 6);
    final effectivePrefix = prefix ?? 'E2E Room';
    return '$effectivePrefix $uuid-$timestamp';
  }

  /// Generates a random room name for testing.
  static String _generateRandomRoomName() {
    final names = [
      'Test Chat Room',
      'E2E Test Group',
      'Automated Test Room',
      'Test Discussion',
      'Quality Assurance Room',
    ];
    return '${names[_random.nextInt(names.length)]} ${_uuid.v4().substring(0, 4)}';
  }
}

/// Represents a test message for E2E tests.
class TestMessage {
  /// Creates a test message.
  const TestMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.replyToId,
    this.attachmentUrl,
    this.attachmentType,
  });

  /// Unique message ID.
  final String id;

  /// Room ID the message belongs to.
  final String roomId;

  /// Sender profile ID.
  final String senderId;

  /// Message text content.
  final String text;

  /// Message creation timestamp.
  final DateTime createdAt;

  /// Optional ID of message being replied to.
  final String? replyToId;

  /// Optional attachment URL.
  final String? attachmentUrl;

  /// Optional attachment type (image, video, file).
  final String? attachmentType;

  @override
  String toString() => 'TestMessage(id: $id, text: $text, roomId: $roomId)';
}

/// Represents a test room for E2E tests.
class TestRoom {
  /// Creates a test room.
  const TestRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.memberIds,
    required this.createdAt,
    this.description,
  });

  /// Unique room ID.
  final String id;

  /// Room display name.
  final String name;

  /// Room type (direct or group).
  final RoomType type;

  /// List of member profile IDs.
  final List<String> memberIds;

  /// Room creation timestamp.
  final DateTime createdAt;

  /// Optional room description.
  final String? description;

  @override
  String toString() =>
      'TestRoom(id: $id, name: $name, type: $type, members: ${memberIds.length})';
}

/// Room type enumeration.
enum RoomType {
  /// Direct message room (1-on-1).
  direct,

  /// Group chat room (multiple members).
  group,

  /// Channel (broadcast-style room).
  channel,
}

/// Batch configuration for throughput tests.
class MessageBatchConfig {
  /// Creates a batch configuration.
  const MessageBatchConfig({
    required this.totalMessages,
    required this.batchSize,
    required this.delayBetweenBatchesMs,
  });

  /// Small batch for quick tests.
  static const small = MessageBatchConfig(
    totalMessages: 10,
    batchSize: 5,
    delayBetweenBatchesMs: 100,
  );

  /// Medium batch for standard tests.
  static const medium = MessageBatchConfig(
    totalMessages: 50,
    batchSize: 10,
    delayBetweenBatchesMs: 50,
  );

  /// Large batch for stress tests.
  static const large = MessageBatchConfig(
    totalMessages: 100,
    batchSize: 20,
    delayBetweenBatchesMs: 25,
  );

  /// Total number of messages to send.
  final int totalMessages;

  /// Number of messages per batch.
  final int batchSize;

  /// Delay between batches in milliseconds.
  final int delayBetweenBatchesMs;

  /// Number of batches required.
  int get batchCount => (totalMessages / batchSize).ceil();
}

/// Test data cleanup helper.
///
/// Tracks resources created during E2E tests for cleanup after test completion.
/// Register a cleanup callback using `registerCleanupCallbacks` to handle actual
/// deletion of test data via API calls or database operations.
class TestDataCleanup {
  /// Private constructor.
  TestDataCleanup._();

  /// List of room IDs created during tests that need cleanup.
  static final List<String> _createdRoomIds = [];

  /// List of message IDs created during tests.
  static final List<String> _createdMessageIds = [];

  /// Callback function to delete a room by ID.
  /// Set this via `registerCleanupCallbacks` before running cleanup.
  static Future<void> Function(String roomId)? _deleteRoomCallback;

  /// Callback function to delete a message by ID.
  static Future<void> Function(String messageId)? _deleteMessageCallback;

  /// Records a room ID for later cleanup.
  static void recordRoom(String roomId) {
    _createdRoomIds.add(roomId);
  }

  /// Records a message ID for later cleanup.
  static void recordMessage(String messageId) {
    _createdMessageIds.add(messageId);
  }

  /// Gets all recorded room IDs.
  static List<String> get roomIds => List.unmodifiable(_createdRoomIds);

  /// Gets all recorded message IDs.
  static List<String> get messageIds => List.unmodifiable(_createdMessageIds);

  /// Registers callbacks for cleanup operations.
  ///
  /// These callbacks should perform the actual deletion via API calls.
  ///
  /// Example:
  /// ```dart
  /// TestDataCleanup.registerCleanupCallbacks(
  ///   deleteRoom: (roomId) => apiClient.deleteRoom(roomId),
  ///   deleteMessage: (msgId) => apiClient.deleteMessage(msgId),
  /// );
  /// ```
  static void registerCleanupCallbacks({
    Future<void> Function(String roomId)? deleteRoom,
    Future<void> Function(String messageId)? deleteMessage,
  }) {
    _deleteRoomCallback = deleteRoom;
    _deleteMessageCallback = deleteMessage;
  }

  /// Cleans up all recorded test data.
  ///
  /// Calls the registered cleanup callbacks for each recorded room and message.
  /// Continues cleanup even if individual deletions fail, collecting all errors.
  ///
  /// Returns a list of errors encountered during cleanup (empty if all succeeded).
  static Future<List<String>> cleanupAll() async {
    final errors = <String>[];

    // Clean up messages first (they may be in rooms we're about to delete)
    if (_deleteMessageCallback != null) {
      for (final messageId in _createdMessageIds) {
        try {
          await _deleteMessageCallback!(messageId);
        } catch (e) {
          errors.add('Failed to delete message $messageId: $e');
        }
      }
    }

    // Clean up rooms
    if (_deleteRoomCallback != null) {
      for (final roomId in _createdRoomIds) {
        try {
          await _deleteRoomCallback!(roomId);
        } catch (e) {
          errors.add('Failed to delete room $roomId: $e');
        }
      }
    }

    // Clear records after cleanup attempt
    clearRecords();

    return errors;
  }

  /// Clears all recorded IDs without performing cleanup.
  ///
  /// Use this when test data doesn't need to be cleaned up (e.g., test failed
  /// before data was created, or cleanup is handled elsewhere).
  static void clearRecords() {
    _createdRoomIds.clear();
    _createdMessageIds.clear();
  }

  /// Resets cleanup callbacks.
  ///
  /// Call this in test teardown to prevent stale callbacks.
  static void resetCallbacks() {
    _deleteRoomCallback = null;
    _deleteMessageCallback = null;
  }
}
