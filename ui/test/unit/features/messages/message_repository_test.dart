import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/db/database.dart' hide RoomEvent;
import 'package:stawi/features/messages/data/message_repository.dart';
import 'package:stawi/features/messages/domain/room_event.dart';

import '../../../test_helpers/test_database.dart';

void main() {
  late AppDatabase testDb;
  late MessageRepository repository;

  /// Helper to create a room in the database (required due to foreign key constraints)
  Future<void> createTestRoom(String roomId, {String? name}) async {
    await testDb
        .into(testDb.rooms)
        .insertOnConflictUpdate(
          RoomsCompanion.insert(
            id: roomId,
            name: Value(name ?? 'Test Room'),
            type: const Value('group'),
          ),
        );
  }

  setUp(() async {
    testDb = createTestDatabase();
    repository = MessageRepository(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  group('MessageRepository', () {
    group('insertMessage', () {
      test('inserts a text message successfully', () async {
        await createTestRoom('room-1');

        final event = RoomEvent(
          id: 'event-1',
          roomId: 'room-1',
          senderId: 'sender-1',
          type: RoomEventType.text,
          content: {'text': 'Hello, world!'},
          status: EventStatus.sent,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        await repository.insertMessage(event);

        final result = await repository.getEventById('event-1');
        expect(result, isNotNull);
        expect(result!.id, equals('event-1'));
        expect(result.roomId, equals('room-1'));
        expect(result.senderId, equals('sender-1'));
        expect(result.type, equals(RoomEventType.text));
        expect(result.content['text'], equals('Hello, world!'));
      });

      test('updates existing message on conflict', () async {
        await createTestRoom('room-1');

        final event1 = RoomEvent(
          id: 'event-1',
          roomId: 'room-1',
          senderId: 'sender-1',
          type: RoomEventType.text,
          content: {'text': 'Original'},
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        final event2 = RoomEvent(
          id: 'event-1',
          roomId: 'room-1',
          senderId: 'sender-1',
          type: RoomEventType.text,
          content: {'text': 'Updated'},
          status: EventStatus.sent,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        await repository.insertMessage(event1);
        await repository.insertMessage(event2);

        final result = await repository.getEventById('event-1');
        expect(result!.content['text'], equals('Updated'));
        expect(result.status, equals(EventStatus.sent));
      });

      test('inserts message with all event types', () async {
        await createTestRoom('room-1');

        for (final type in RoomEventType.values) {
          final event = RoomEvent(
            id: 'event-${type.name}',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: type,
            content: {'type': type.name},
            createdAt: DateTime.now().millisecondsSinceEpoch,
          );

          await repository.insertMessage(event);

          final result = await repository.getEventById('event-${type.name}');
          expect(result, isNotNull, reason: 'Failed for type: ${type.name}');
          expect(result!.type, equals(type));
        }
      });
    });

    group('getMessagesForRoom', () {
      test('returns empty list for room with no messages', () async {
        await createTestRoom('empty-room');

        final messages = await repository.getMessagesForRoom('empty-room');
        expect(messages, isEmpty);
      });

      test('returns messages for specific room', () async {
        await createTestRoom('room-1');
        await createTestRoom('room-2');

        for (var i = 1; i <= 5; i++) {
          await repository.insertMessage(
            RoomEvent(
              id: 'room1-event-$i',
              roomId: 'room-1',
              senderId: 'sender-1',
              type: RoomEventType.text,
              content: {'text': 'Message $i'},
              createdAt: DateTime.now().millisecondsSinceEpoch + i,
            ),
          );
        }

        for (var i = 1; i <= 3; i++) {
          await repository.insertMessage(
            RoomEvent(
              id: 'room2-event-$i',
              roomId: 'room-2',
              senderId: 'sender-1',
              type: RoomEventType.text,
              content: {'text': 'Message $i'},
              createdAt: DateTime.now().millisecondsSinceEpoch + i,
            ),
          );
        }

        final room1Messages = await repository.getMessagesForRoom('room-1');
        final room2Messages = await repository.getMessagesForRoom('room-2');

        expect(room1Messages.length, equals(5));
        expect(room2Messages.length, equals(3));
      });

      test('returns messages ordered by timestamp (oldest first)', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-3',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Third'},
            createdAt: now + 3000,
          ),
        );

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'First'},
            createdAt: now + 1000,
          ),
        );

        await repository.insertMessage(
          RoomEvent(
            id: 'event-2',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Second'},
            createdAt: now + 2000,
          ),
        );

        final messages = await repository.getMessagesForRoom('room-1');

        expect(messages[0].content['text'], equals('First'));
        expect(messages[1].content['text'], equals('Second'));
        expect(messages[2].content['text'], equals('Third'));
      });

      test('respects limit parameter', () async {
        await createTestRoom('room-1');

        for (var i = 1; i <= 100; i++) {
          await repository.insertMessage(
            RoomEvent(
              id: 'event-$i',
              roomId: 'room-1',
              senderId: 'sender-1',
              type: RoomEventType.text,
              content: {'text': 'Message $i'},
              createdAt: DateTime.now().millisecondsSinceEpoch + i,
            ),
          );
        }

        final limitedMessages = await repository.getMessagesForRoom(
          'room-1',
          limit: 20,
        );

        expect(limitedMessages.length, equals(20));
      });
    });

    group('getMessagesBeforeTimestamp', () {
      test('returns messages before given timestamp', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        for (var i = 1; i <= 10; i++) {
          await repository.insertMessage(
            RoomEvent(
              id: 'event-$i',
              roomId: 'room-1',
              senderId: 'sender-1',
              type: RoomEventType.text,
              content: {'text': 'Message $i'},
              createdAt: now + (i * 1000),
            ),
          );
        }

        final messages = await repository.getMessagesBeforeTimestamp(
          'room-1',
          beforeTimestamp: now + 5500,
        );

        expect(messages.length, equals(5));
        expect(messages.last.content['text'], equals('Message 5'));
      });
    });

    group('getOldestMessageTimestamp', () {
      test('returns null for room with no messages', () async {
        await createTestRoom('empty-room');

        final timestamp = await repository.getOldestMessageTimestamp(
          'empty-room',
        );
        expect(timestamp, isNull);
      });

      test('returns oldest timestamp for room with messages', () async {
        await createTestRoom('room-1');
        final oldest = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-2',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Newer'},
            createdAt: oldest + 1000,
          ),
        );

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Oldest'},
            createdAt: oldest,
          ),
        );

        final timestamp = await repository.getOldestMessageTimestamp('room-1');
        expect(timestamp, equals(oldest));
      });
    });

    group('getMessageCount', () {
      test('returns 0 for empty room', () async {
        await createTestRoom('empty-room');

        final count = await repository.getMessageCount('empty-room');
        expect(count, equals(0));
      });

      test('returns correct count for room with messages', () async {
        await createTestRoom('room-1');

        for (var i = 1; i <= 15; i++) {
          await repository.insertMessage(
            RoomEvent(
              id: 'event-$i',
              roomId: 'room-1',
              senderId: 'sender-1',
              type: RoomEventType.text,
              content: {'text': 'Message $i'},
              createdAt: DateTime.now().millisecondsSinceEpoch + i,
            ),
          );
        }

        final count = await repository.getMessageCount('room-1');
        expect(count, equals(15));
      });
    });

    group('updateMessageStatus', () {
      test('updates status of existing message', () async {
        await createTestRoom('room-1');

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Test'},
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );

        await repository.updateMessageStatus('event-1', EventStatus.sent);

        final result = await repository.getEventById('event-1');
        expect(result!.status, equals(EventStatus.sent));
      });

      test('updates through all status transitions', () async {
        await createTestRoom('room-1');

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Test'},
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );

        // Pending -> Sent
        await repository.updateMessageStatus('event-1', EventStatus.sent);
        var result = await repository.getEventById('event-1');
        expect(result!.status, equals(EventStatus.sent));

        // Sent -> Delivered
        await repository.updateMessageStatus('event-1', EventStatus.delivered);
        result = await repository.getEventById('event-1');
        expect(result!.status, equals(EventStatus.delivered));

        // Delivered -> Read
        await repository.updateMessageStatus('event-1', EventStatus.read);
        result = await repository.getEventById('event-1');
        expect(result!.status, equals(EventStatus.read));
      });
    });

    group('updateMessagesStatus', () {
      test('updates status of multiple messages', () async {
        await createTestRoom('room-1');

        for (var i = 1; i <= 5; i++) {
          await repository.insertMessage(
            RoomEvent(
              id: 'event-$i',
              roomId: 'room-1',
              senderId: 'sender-1',
              type: RoomEventType.text,
              content: {'text': 'Message $i'},
              createdAt: DateTime.now().millisecondsSinceEpoch + i,
            ),
          );
        }

        await repository.updateMessagesStatus([
          'event-1',
          'event-2',
          'event-3',
        ], EventStatus.sent);

        final event1 = await repository.getEventById('event-1');
        final event2 = await repository.getEventById('event-2');
        final event3 = await repository.getEventById('event-3');
        final event4 = await repository.getEventById('event-4');

        expect(event1!.status, equals(EventStatus.sent));
        expect(event2!.status, equals(EventStatus.sent));
        expect(event3!.status, equals(EventStatus.sent));
        expect(event4!.status, equals(EventStatus.pending));
      });

      test('handles empty list gracefully', () async {
        await repository.updateMessagesStatus([], EventStatus.sent);
      });
    });

    group('getEventById', () {
      test('returns null for non-existent event', () async {
        final result = await repository.getEventById('non-existent');
        expect(result, isNull);
      });

      test('returns event with all fields populated', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            senderContactId: 'contact-1',
            type: RoomEventType.image,
            content: {'url': 'https://example.com/image.jpg', 'size': 1024},
            parentId: 'parent-event',
            status: EventStatus.delivered,
            createdAt: now,
            serverTs: now + 100,
            localId: 'local-123',
          ),
        );

        final result = await repository.getEventById('event-1');
        expect(result, isNotNull);
        expect(result!.id, equals('event-1'));
        expect(result.roomId, equals('room-1'));
        expect(result.senderId, equals('sender-1'));
        expect(result.type, equals(RoomEventType.image));
        expect(result.content['url'], equals('https://example.com/image.jpg'));
        expect(result.parentId, equals('parent-event'));
        expect(result.status, equals(EventStatus.delivered));
        expect(result.createdAt, equals(now));
        expect(result.serverTs, equals(now + 100));
        expect(result.localId, equals('local-123'));
      });
    });

    group('getReactionsForEvent', () {
      test('returns empty list when no reactions', () async {
        await createTestRoom('room-1');

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Hello'},
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );

        final reactions = await repository.getReactionsForEvent('event-1');
        expect(reactions, isEmpty);
      });

      test('returns reactions for message', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        // Parent message
        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Hello'},
            createdAt: now,
          ),
        );

        // Reactions
        await repository.insertMessage(
          RoomEvent(
            id: 'reaction-1',
            roomId: 'room-1',
            senderId: 'sender-2',
            type: RoomEventType.reaction,
            content: {'emoji': '👍'},
            parentId: 'event-1',
            createdAt: now + 1,
          ),
        );

        await repository.insertMessage(
          RoomEvent(
            id: 'reaction-2',
            roomId: 'room-1',
            senderId: 'sender-3',
            type: RoomEventType.reaction,
            content: {'emoji': '❤️'},
            parentId: 'event-1',
            createdAt: now + 2,
          ),
        );

        // Non-reaction reply (should not be included)
        await repository.insertMessage(
          RoomEvent(
            id: 'reply-1',
            roomId: 'room-1',
            senderId: 'sender-2',
            type: RoomEventType.text,
            content: {'text': 'Nice message!'},
            parentId: 'event-1',
            createdAt: now + 3,
          ),
        );

        final reactions = await repository.getReactionsForEvent('event-1');

        expect(reactions.length, equals(2));
        expect(
          reactions.every((r) => r.type == RoomEventType.reaction),
          isTrue,
        );
        expect(reactions.any((r) => r.content['emoji'] == '👍'), isTrue);
        expect(reactions.any((r) => r.content['emoji'] == '❤️'), isTrue);
      });
    });

    group('watchMessagesForRoom', () {
      test('emits initial messages', () async {
        await createTestRoom('room-1');

        for (var i = 1; i <= 3; i++) {
          await repository.insertMessage(
            RoomEvent(
              id: 'event-$i',
              roomId: 'room-1',
              senderId: 'sender-1',
              type: RoomEventType.text,
              content: {'text': 'Message $i'},
              createdAt: DateTime.now().millisecondsSinceEpoch + i,
            ),
          );
        }

        final stream = repository.watchMessagesForRoom('room-1');
        final messages = await stream.first;

        expect(messages.length, equals(3));
      });

      test('emits updates when messages are inserted', () async {
        await createTestRoom('room-1');

        final stream = repository.watchMessagesForRoom('room-1');

        // Get initial empty state
        var messages = await stream.first;
        expect(messages, isEmpty);

        // Insert a message
        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'New message'},
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );

        // Wait for the stream to emit the update
        messages = await stream.first;
        expect(messages.length, equals(1));
        expect(messages[0].content['text'], equals('New message'));
      });
    });

    group('updateMessageContent', () {
      test('updates message content successfully', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Original message'},
            createdAt: now,
          ),
        );

        await repository.updateMessageContent('event-1', {
          'text': 'Edited message',
        });

        final updated = await repository.getEventById('event-1');
        expect(updated!.content['text'], equals('Edited message'));
        expect(updated.editedAt, isNotNull);
        expect(updated.isEdited, isTrue);
      });

      test('preserves original content on first edit', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Original message'},
            createdAt: now,
          ),
        );

        await repository.updateMessageContent('event-1', {
          'text': 'Edited message',
        }, originalContent: 'Original message');

        final updated = await repository.getEventById('event-1');
        expect(updated!.content['text'], equals('Edited message'));
        expect(updated.editedAt, isNotNull);
      });

      test('sets editedAt timestamp', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Original'},
            createdAt: now,
          ),
        );

        // Ensure editedAt is null before edit
        var event = await repository.getEventById('event-1');
        expect(event!.editedAt, isNull);
        expect(event.isEdited, isFalse);

        await repository.updateMessageContent('event-1', {'text': 'Edited'});

        event = await repository.getEventById('event-1');
        expect(event!.editedAt, isNotNull);
        expect(event.editedAt, greaterThanOrEqualTo(now));
        expect(event.isEdited, isTrue);
      });
    });

    group('canEditMessage', () {
      test('returns true for own recent text message', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'current-user',
            type: RoomEventType.text,
            content: {'text': 'My message'},
            status: EventStatus.sent,
            createdAt: now,
          ),
        );

        final canEdit = await repository.canEditMessage(
          'event-1',
          'current-user',
        );
        expect(canEdit, isTrue);
      });

      test('returns false for other user message', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'other-user',
            type: RoomEventType.text,
            content: {'text': 'Their message'},
            status: EventStatus.sent,
            createdAt: now,
          ),
        );

        final canEdit = await repository.canEditMessage(
          'event-1',
          'current-user',
        );
        expect(canEdit, isFalse);
      });

      test('returns false for non-text message', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'current-user',
            type: RoomEventType.image,
            content: {'url': 'https://example.com/image.jpg'},
            status: EventStatus.sent,
            createdAt: now,
          ),
        );

        final canEdit = await repository.canEditMessage(
          'event-1',
          'current-user',
        );
        expect(canEdit, isFalse);
      });

      test('returns false for message outside edit window', () async {
        await createTestRoom('room-1');
        // Message from 20 minutes ago
        final oldTimestamp =
            DateTime.now().millisecondsSinceEpoch - (20 * 60 * 1000);

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'current-user',
            type: RoomEventType.text,
            content: {'text': 'Old message'},
            status: EventStatus.sent,
            createdAt: oldTimestamp,
          ),
        );

        final canEdit = await repository.canEditMessage(
          'event-1',
          'current-user',
        );
        expect(canEdit, isFalse);
      });

      test('returns false for pending message', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'current-user',
            type: RoomEventType.text,
            content: {'text': 'Pending message'},
            createdAt: now,
          ),
        );

        final canEdit = await repository.canEditMessage(
          'event-1',
          'current-user',
        );
        expect(canEdit, isFalse);
      });

      test('returns false for failed message', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'current-user',
            type: RoomEventType.text,
            content: {'text': 'Failed message'},
            status: EventStatus.failed,
            createdAt: now,
          ),
        );

        final canEdit = await repository.canEditMessage(
          'event-1',
          'current-user',
        );
        expect(canEdit, isFalse);
      });

      test('returns false for non-existent message', () async {
        final canEdit = await repository.canEditMessage(
          'non-existent',
          'current-user',
        );
        expect(canEdit, isFalse);
      });

      test('respects custom edit window', () async {
        await createTestRoom('room-1');
        // Message from 2 minutes ago
        final recentTimestamp =
            DateTime.now().millisecondsSinceEpoch - (2 * 60 * 1000);

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'current-user',
            type: RoomEventType.text,
            content: {'text': 'Recent message'},
            status: EventStatus.sent,
            createdAt: recentTimestamp,
          ),
        );

        // With 1 minute window, should not be editable
        final canEditShortWindow = await repository.canEditMessage(
          'event-1',
          'current-user',
          editWindow: const Duration(minutes: 1),
        );
        expect(canEditShortWindow, isFalse);

        // With 5 minute window, should be editable
        final canEditLongWindow = await repository.canEditMessage(
          'event-1',
          'current-user',
          editWindow: const Duration(minutes: 5),
        );
        expect(canEditLongWindow, isTrue);
      });
    });

    group('message editing with isEdited flag', () {
      test('new messages have isEdited as false', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'New message'},
            createdAt: now,
          ),
        );

        final event = await repository.getEventById('event-1');
        expect(event!.isEdited, isFalse);
        expect(event.editedAt, isNull);
      });

      test('edited messages have isEdited as true', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Original'},
            createdAt: now,
          ),
        );

        await repository.updateMessageContent('event-1', {'text': 'Edited'});

        final event = await repository.getEventById('event-1');
        expect(event!.isEdited, isTrue);
        expect(event.editedAt, isNotNull);
      });

      test('can insert message with editedAt already set', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;
        final editedAt = now + 1000;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Already edited'},
            createdAt: now,
            editedAt: editedAt,
          ),
        );

        final event = await repository.getEventById('event-1');
        expect(event!.isEdited, isTrue);
        expect(event.editedAt, equals(editedAt));
      });
    });

    group('deleteMessage', () {
      test('marks message as redacted', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'To be deleted'},
            status: EventStatus.sent,
            createdAt: now,
          ),
        );

        await repository.deleteMessage('event-1');

        final event = await repository.getEventById('event-1');
        expect(event!.isDeleted, isTrue);
        expect(event.redacted, isTrue);
        expect(event.redactedAt, isNotNull);
      });

      test('sets deletedBy when provided', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'To be deleted'},
            status: EventStatus.sent,
            createdAt: now,
          ),
        );

        await repository.deleteMessage('event-1', deletedBy: 'admin-user');

        final event = await repository.getEventById('event-1');
        expect(event!.isDeleted, isTrue);
        expect(event.redactedBy, equals('admin-user'));
      });

      test('preserves original content after deletion', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Original content'},
            status: EventStatus.sent,
            createdAt: now,
          ),
        );

        await repository.deleteMessage('event-1');

        final event = await repository.getEventById('event-1');
        // Content is preserved but message is marked as deleted
        expect(event!.isDeleted, isTrue);
        expect(event.content['text'], equals('Original content'));
      });
    });

    group('deleteMessageForMe', () {
      test('removes message from local database', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'To be deleted locally'},
            status: EventStatus.sent,
            createdAt: now,
          ),
        );

        // Verify message exists
        var event = await repository.getEventById('event-1');
        expect(event, isNotNull);

        await repository.deleteMessageForMe('event-1');

        // Verify message is removed
        event = await repository.getEventById('event-1');
        expect(event, isNull);
      });

      test('only removes specified message', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Message 1'},
            status: EventStatus.sent,
            createdAt: now,
          ),
        );

        await repository.insertMessage(
          RoomEvent(
            id: 'event-2',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Message 2'},
            status: EventStatus.sent,
            createdAt: now + 1000,
          ),
        );

        await repository.deleteMessageForMe('event-1');

        // First message should be gone
        final event1 = await repository.getEventById('event-1');
        expect(event1, isNull);

        // Second message should remain
        final event2 = await repository.getEventById('event-2');
        expect(event2, isNotNull);
        expect(event2!.content['text'], equals('Message 2'));
      });
    });

    group('canDeleteMessage', () {
      test('returns true for own recent message', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'current-user',
            type: RoomEventType.text,
            content: {'text': 'My message'},
            status: EventStatus.sent,
            createdAt: now,
          ),
        );

        final canDelete = await repository.canDeleteMessage(
          'event-1',
          'current-user',
        );
        expect(canDelete, isTrue);
      });

      test('returns false for other user message', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'other-user',
            type: RoomEventType.text,
            content: {'text': 'Their message'},
            status: EventStatus.sent,
            createdAt: now,
          ),
        );

        final canDelete = await repository.canDeleteMessage(
          'event-1',
          'current-user',
        );
        expect(canDelete, isFalse);
      });

      test('returns true for admin regardless of owner', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'other-user',
            type: RoomEventType.text,
            content: {'text': 'Their message'},
            status: EventStatus.sent,
            createdAt: now,
          ),
        );

        final canDelete = await repository.canDeleteMessage(
          'event-1',
          'admin-user',
          isAdmin: true,
        );
        expect(canDelete, isTrue);
      });

      test('returns false for already deleted message', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'current-user',
            type: RoomEventType.text,
            content: {'text': 'My message'},
            status: EventStatus.sent,
            createdAt: now,
            redacted: true,
            redactedAt: now + 1000,
          ),
        );

        final canDelete = await repository.canDeleteMessage(
          'event-1',
          'current-user',
        );
        expect(canDelete, isFalse);
      });

      test('returns false for message outside delete window', () async {
        await createTestRoom('room-1');
        // Message from 25 hours ago (default window is 24 hours)
        final oldTimestamp =
            DateTime.now().millisecondsSinceEpoch - (25 * 60 * 60 * 1000);

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'current-user',
            type: RoomEventType.text,
            content: {'text': 'Old message'},
            status: EventStatus.sent,
            createdAt: oldTimestamp,
          ),
        );

        final canDelete = await repository.canDeleteMessage(
          'event-1',
          'current-user',
        );
        expect(canDelete, isFalse);
      });

      test('returns false for pending message', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'current-user',
            type: RoomEventType.text,
            content: {'text': 'Pending message'},
            createdAt: now,
          ),
        );

        final canDelete = await repository.canDeleteMessage(
          'event-1',
          'current-user',
        );
        expect(canDelete, isFalse);
      });

      test('returns false for failed message', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'current-user',
            type: RoomEventType.text,
            content: {'text': 'Failed message'},
            status: EventStatus.failed,
            createdAt: now,
          ),
        );

        final canDelete = await repository.canDeleteMessage(
          'event-1',
          'current-user',
        );
        expect(canDelete, isFalse);
      });

      test('returns false for non-existent message', () async {
        final canDelete = await repository.canDeleteMessage(
          'non-existent',
          'current-user',
        );
        expect(canDelete, isFalse);
      });

      test('respects custom delete window', () async {
        await createTestRoom('room-1');
        // Message from 2 hours ago
        final recentTimestamp =
            DateTime.now().millisecondsSinceEpoch - (2 * 60 * 60 * 1000);

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'current-user',
            type: RoomEventType.text,
            content: {'text': 'Recent message'},
            status: EventStatus.sent,
            createdAt: recentTimestamp,
          ),
        );

        // With 1 hour window, should not be deletable
        final canDeleteShortWindow = await repository.canDeleteMessage(
          'event-1',
          'current-user',
          deleteWindow: const Duration(hours: 1),
        );
        expect(canDeleteShortWindow, isFalse);

        // With 3 hour window, should be deletable
        final canDeleteLongWindow = await repository.canDeleteMessage(
          'event-1',
          'current-user',
          deleteWindow: const Duration(hours: 3),
        );
        expect(canDeleteLongWindow, isTrue);
      });

      test('allows admin to delete old messages', () async {
        await createTestRoom('room-1');
        // Message from 25 hours ago
        final oldTimestamp =
            DateTime.now().millisecondsSinceEpoch - (25 * 60 * 60 * 1000);

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'other-user',
            type: RoomEventType.text,
            content: {'text': 'Old message'},
            status: EventStatus.sent,
            createdAt: oldTimestamp,
          ),
        );

        // Admin can delete even old messages
        final canDelete = await repository.canDeleteMessage(
          'event-1',
          'admin-user',
          isAdmin: true,
        );
        expect(canDelete, isTrue);
      });
    });

    group('expired messages (disappearing messages)', () {
      test('getExpiredMessages returns messages past expiry time', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;
        final pastExpiry = now - 1000; // 1 second ago
        final futureExpiry = now + 60000; // 1 minute in future

        // Expired message
        await repository.insertMessage(
          RoomEvent(
            id: 'event-expired',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Expired message'},
            createdAt: now - 10000,
            expiresAt: pastExpiry,
          ),
        );

        // Not expired message
        await repository.insertMessage(
          RoomEvent(
            id: 'event-not-expired',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Not expired message'},
            createdAt: now - 5000,
            expiresAt: futureExpiry,
          ),
        );

        // No expiry (permanent) message
        await repository.insertMessage(
          RoomEvent(
            id: 'event-permanent',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Permanent message'},
            createdAt: now,
          ),
        );

        final expiredMessages = await repository.getExpiredMessages();

        expect(expiredMessages.length, equals(1));
        expect(expiredMessages[0].id, equals('event-expired'));
      });

      test(
        'getExpiredMessages returns empty list when no expired messages',
        () async {
          await createTestRoom('room-1');
          final now = DateTime.now().millisecondsSinceEpoch;
          final futureExpiry = now + 60000;

          await repository.insertMessage(
            RoomEvent(
              id: 'event-1',
              roomId: 'room-1',
              senderId: 'sender-1',
              type: RoomEventType.text,
              content: {'text': 'Not expired'},
              createdAt: now,
              expiresAt: futureExpiry,
            ),
          );

          final expiredMessages = await repository.getExpiredMessages();
          expect(expiredMessages, isEmpty);
        },
      );

      test('deleteExpiredMessages removes expired messages', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;
        final pastExpiry = now - 1000;
        final futureExpiry = now + 60000;

        // Expired messages
        await repository.insertMessage(
          RoomEvent(
            id: 'event-expired-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Expired 1'},
            createdAt: now - 10000,
            expiresAt: pastExpiry,
          ),
        );

        await repository.insertMessage(
          RoomEvent(
            id: 'event-expired-2',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Expired 2'},
            createdAt: now - 9000,
            expiresAt: pastExpiry - 500,
          ),
        );

        // Not expired message
        await repository.insertMessage(
          RoomEvent(
            id: 'event-not-expired',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Not expired'},
            createdAt: now,
            expiresAt: futureExpiry,
          ),
        );

        // Permanent message
        await repository.insertMessage(
          RoomEvent(
            id: 'event-permanent',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Permanent'},
            createdAt: now,
          ),
        );

        final deletedCount = await repository.deleteExpiredMessages();

        expect(deletedCount, equals(2));

        // Verify expired messages are gone
        expect(await repository.getEventById('event-expired-1'), isNull);
        expect(await repository.getEventById('event-expired-2'), isNull);

        // Verify non-expired and permanent messages remain
        expect(await repository.getEventById('event-not-expired'), isNotNull);
        expect(await repository.getEventById('event-permanent'), isNotNull);
      });

      test(
        'deleteExpiredMessages returns 0 when no expired messages',
        () async {
          await createTestRoom('room-1');
          final now = DateTime.now().millisecondsSinceEpoch;

          await repository.insertMessage(
            RoomEvent(
              id: 'event-1',
              roomId: 'room-1',
              senderId: 'sender-1',
              type: RoomEventType.text,
              content: {'text': 'Permanent'},
              createdAt: now,
            ),
          );

          final deletedCount = await repository.deleteExpiredMessages();
          expect(deletedCount, equals(0));
        },
      );

      test('setMessageExpiry sets expiration time for message', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;
        final expiresAt = now + 60000;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Message'},
            createdAt: now,
          ),
        );

        // Initially no expiry
        var event = await repository.getEventById('event-1');
        expect(event!.expiresAt, isNull);
        expect(event.isDisappearing, isFalse);

        // Set expiry
        await repository.setMessageExpiry('event-1', expiresAt);

        event = await repository.getEventById('event-1');
        expect(event!.expiresAt, equals(expiresAt));
        expect(event.isDisappearing, isTrue);
      });

      test('message isExpired returns correct value', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        // Create message with past expiry
        await repository.insertMessage(
          RoomEvent(
            id: 'event-expired',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Expired'},
            createdAt: now - 10000,
            expiresAt: now - 1000,
          ),
        );

        // Create message with future expiry
        await repository.insertMessage(
          RoomEvent(
            id: 'event-not-expired',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Not expired'},
            createdAt: now,
            expiresAt: now + 60000,
          ),
        );

        final expiredEvent = await repository.getEventById('event-expired');
        final notExpiredEvent = await repository.getEventById(
          'event-not-expired',
        );

        expect(expiredEvent!.hasExpired, isTrue);
        expect(notExpiredEvent!.hasExpired, isFalse);
      });
    });

    group('message deletion with isDeleted flag', () {
      test('new messages have isDeleted as false', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'New message'},
            createdAt: now,
          ),
        );

        final event = await repository.getEventById('event-1');
        expect(event!.isDeleted, isFalse);
        expect(event.redacted, isFalse);
        expect(event.redactedAt, isNull);
        expect(event.redactedBy, isNull);
      });

      test('deleted messages have isDeleted as true', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Original'},
            status: EventStatus.sent,
            createdAt: now,
          ),
        );

        await repository.deleteMessage('event-1', deletedBy: 'sender-1');

        final event = await repository.getEventById('event-1');
        expect(event!.isDeleted, isTrue);
        expect(event.redacted, isTrue);
        expect(event.redactedAt, isNotNull);
        expect(event.redactedBy, equals('sender-1'));
      });

      test('can insert message with redacted already set', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;
        final redactedAt = now + 1000;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Already deleted'},
            createdAt: now,
            redacted: true,
            redactedAt: redactedAt,
            redactedBy: 'admin-user',
          ),
        );

        final event = await repository.getEventById('event-1');
        expect(event!.isDeleted, isTrue);
        expect(event.redacted, isTrue);
        expect(event.redactedAt, equals(redactedAt));
        expect(event.redactedBy, equals('admin-user'));
      });
    });

    group('starred messages', () {
      test('new messages are not starred by default', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Message'},
            createdAt: now,
          ),
        );

        final event = await repository.getEventById('event-1');
        expect(event!.starred, isFalse);
        expect(event.starredAt, isNull);
        expect(event.isStarred, isFalse);
      });

      test('starMessage stars a message', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Message'},
            createdAt: now,
          ),
        );

        final result = await repository.starMessage('event-1');
        expect(result, isTrue);

        final event = await repository.getEventById('event-1');
        expect(event!.starred, isTrue);
        expect(event.starredAt, isNotNull);
        expect(event.isStarred, isTrue);
      });

      test('starMessage returns false if already starred', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Message'},
            createdAt: now,
          ),
        );

        await repository.starMessage('event-1');
        final secondResult = await repository.starMessage('event-1');
        expect(secondResult, isFalse);
      });

      test('unstarMessage unstars a message', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Message'},
            createdAt: now,
          ),
        );

        await repository.starMessage('event-1');
        final result = await repository.unstarMessage('event-1');
        expect(result, isTrue);

        final event = await repository.getEventById('event-1');
        expect(event!.starred, isFalse);
        expect(event.starredAt, isNull);
      });

      test('unstarMessage returns false if not starred', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Message'},
            createdAt: now,
          ),
        );

        final result = await repository.unstarMessage('event-1');
        expect(result, isFalse);
      });

      test('toggleStar toggles starred state', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Message'},
            createdAt: now,
          ),
        );

        // Toggle on
        var result = await repository.toggleStar('event-1');
        expect(result, isTrue);
        var event = await repository.getEventById('event-1');
        expect(event!.isStarred, isTrue);

        // Toggle off
        result = await repository.toggleStar('event-1');
        expect(result, isFalse);
        event = await repository.getEventById('event-1');
        expect(event!.isStarred, isFalse);
      });

      test('getStarredMessages returns only starred messages', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        // Create multiple messages
        for (var i = 1; i <= 5; i++) {
          await repository.insertMessage(
            RoomEvent(
              id: 'event-$i',
              roomId: 'room-1',
              senderId: 'sender-1',
              type: RoomEventType.text,
              content: {'text': 'Message $i'},
              createdAt: now + i,
            ),
          );
        }

        // Star some messages
        await repository.starMessage('event-2');
        await repository.starMessage('event-4');

        final starred = await repository.getStarredMessages();
        expect(starred.length, equals(2));
        expect(starred.any((e) => e.id == 'event-2'), isTrue);
        expect(starred.any((e) => e.id == 'event-4'), isTrue);
      });

      test(
        'getStarredMessages returns messages ordered by starredAt desc',
        () async {
          await createTestRoom('room-1');
          final now = DateTime.now().millisecondsSinceEpoch;

          for (var i = 1; i <= 3; i++) {
            await repository.insertMessage(
              RoomEvent(
                id: 'event-$i',
                roomId: 'room-1',
                senderId: 'sender-1',
                type: RoomEventType.text,
                content: {'text': 'Message $i'},
                createdAt: now + i,
              ),
            );
          }

          // Star in specific order
          await repository.starMessage('event-1');
          await Future.delayed(const Duration(milliseconds: 10));
          await repository.starMessage('event-3');
          await Future.delayed(const Duration(milliseconds: 10));
          await repository.starMessage('event-2');

          final starred = await repository.getStarredMessages();
          expect(starred.length, equals(3));
          // Most recently starred first
          expect(starred[0].id, equals('event-2'));
          expect(starred[1].id, equals('event-3'));
          expect(starred[2].id, equals('event-1'));
        },
      );

      test(
        'getStarredMessagesForRoom returns only starred messages from room',
        () async {
          await createTestRoom('room-1');
          await createTestRoom('room-2');
          final now = DateTime.now().millisecondsSinceEpoch;

          await repository.insertMessage(
            RoomEvent(
              id: 'event-1',
              roomId: 'room-1',
              senderId: 'sender-1',
              type: RoomEventType.text,
              content: {'text': 'Message 1'},
              createdAt: now,
            ),
          );

          await repository.insertMessage(
            RoomEvent(
              id: 'event-2',
              roomId: 'room-2',
              senderId: 'sender-1',
              type: RoomEventType.text,
              content: {'text': 'Message 2'},
              createdAt: now + 1,
            ),
          );

          await repository.starMessage('event-1');
          await repository.starMessage('event-2');

          final room1Starred = await repository.getStarredMessagesForRoom(
            'room-1',
          );
          expect(room1Starred.length, equals(1));
          expect(room1Starred[0].id, equals('event-1'));

          final room2Starred = await repository.getStarredMessagesForRoom(
            'room-2',
          );
          expect(room2Starred.length, equals(1));
          expect(room2Starred[0].id, equals('event-2'));
        },
      );

      test('getStarredMessagesCount returns correct count', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        for (var i = 1; i <= 5; i++) {
          await repository.insertMessage(
            RoomEvent(
              id: 'event-$i',
              roomId: 'room-1',
              senderId: 'sender-1',
              type: RoomEventType.text,
              content: {'text': 'Message $i'},
              createdAt: now + i,
            ),
          );
        }

        expect(await repository.getStarredMessagesCount(), equals(0));

        await repository.starMessage('event-1');
        await repository.starMessage('event-3');
        expect(await repository.getStarredMessagesCount(), equals(2));

        await repository.unstarMessage('event-1');
        expect(await repository.getStarredMessagesCount(), equals(1));
      });

      test('clearAllStarredMessages removes all stars', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        for (var i = 1; i <= 3; i++) {
          await repository.insertMessage(
            RoomEvent(
              id: 'event-$i',
              roomId: 'room-1',
              senderId: 'sender-1',
              type: RoomEventType.text,
              content: {'text': 'Message $i'},
              createdAt: now + i,
            ),
          );
          await repository.starMessage('event-$i');
        }

        expect(await repository.getStarredMessagesCount(), equals(3));

        final cleared = await repository.clearAllStarredMessages();
        expect(cleared, equals(3));
        expect(await repository.getStarredMessagesCount(), equals(0));

        // Messages still exist, just not starred
        for (var i = 1; i <= 3; i++) {
          final event = await repository.getEventById('event-$i');
          expect(event, isNotNull);
          expect(event!.starred, isFalse);
        }
      });

      test('canBeStarred returns false for deleted messages', () async {
        await createTestRoom('room-1');
        final now = DateTime.now().millisecondsSinceEpoch;

        await repository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Message'},
            status: EventStatus.sent,
            createdAt: now,
          ),
        );

        var event = await repository.getEventById('event-1');
        expect(event!.canBeStarred, isTrue);

        await repository.deleteMessage('event-1');

        event = await repository.getEventById('event-1');
        expect(event!.canBeStarred, isFalse);
      });
    });
  });
}
