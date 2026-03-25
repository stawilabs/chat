import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/db/database.dart';

void main() {
  group('Message Search (FTS5)', () {
    late AppDatabase db;

    setUp(() async {
      // Create an in-memory database for testing
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    /// Helper to insert a room
    Future<void> insertRoom(String roomId, {String? name}) async {
      await db
          .into(db.rooms)
          .insert(RoomsCompanion.insert(id: roomId, name: Value(name)));
    }

    /// Helper to insert a text message
    Future<void> insertTextMessage({
      required String id,
      required String roomId,
      required String text,
      String senderId = 'sender1',
    }) async {
      await db
          .into(db.roomEvents)
          .insert(
            RoomEventsCompanion.insert(
              id: id,
              roomId: roomId,
              senderId: senderId,
              type: 0, // text message type
              content: Value(jsonEncode({'text': text})),
              status: const Value(1),
            ),
          );
    }

    group('searchMessages', () {
      test('returns empty list for empty query', () async {
        final results = await db.searchMessages('');

        expect(results, isEmpty);
      });

      test('returns empty list for whitespace-only query', () async {
        final results = await db.searchMessages('   ');

        expect(results, isEmpty);
      });

      test('finds message by single word', () async {
        await insertRoom('room1');
        await insertTextMessage(
          id: 'msg1',
          roomId: 'room1',
          text: 'Hello world',
        );

        final results = await db.searchMessages('hello');

        expect(results, hasLength(1));
        expect(results.first.id, equals('msg1'));
      });

      test('finds message by multiple words', () async {
        await insertRoom('room1');
        await insertTextMessage(
          id: 'msg1',
          roomId: 'room1',
          text: 'The quick brown fox jumps over the lazy dog',
        );

        final results = await db.searchMessages('quick fox');

        expect(results, hasLength(1));
        expect(results.first.id, equals('msg1'));
      });

      test('finds messages across multiple rooms', () async {
        await insertRoom('room1');
        await insertRoom('room2');
        await insertTextMessage(
          id: 'msg1',
          roomId: 'room1',
          text: 'Meeting at noon',
        );
        await insertTextMessage(
          id: 'msg2',
          roomId: 'room2',
          text: 'Meeting reminder',
        );

        final results = await db.searchMessages('meeting');

        expect(results, hasLength(2));
      });

      test('respects limit parameter', () async {
        await insertRoom('room1');
        for (var i = 0; i < 10; i++) {
          await insertTextMessage(
            id: 'msg$i',
            roomId: 'room1',
            text: 'Test message $i',
          );
        }

        final results = await db.searchMessages('test', limit: 5);

        expect(results, hasLength(5));
      });

      test('returns empty list when no matches', () async {
        await insertRoom('room1');
        await insertTextMessage(
          id: 'msg1',
          roomId: 'room1',
          text: 'Hello world',
        );

        final results = await db.searchMessages('nonexistent');

        expect(results, isEmpty);
      });
    });

    group('searchMessagesInRoom', () {
      test('returns empty list for empty query', () async {
        final results = await db.searchMessagesInRoom('room1', '');

        expect(results, isEmpty);
      });

      test('returns empty list for whitespace-only query', () async {
        final results = await db.searchMessagesInRoom('room1', '   ');

        expect(results, isEmpty);
      });

      test('finds message only in specified room', () async {
        await insertRoom('room1');
        await insertRoom('room2');
        await insertTextMessage(
          id: 'msg1',
          roomId: 'room1',
          text: 'Hello from room1',
        );
        await insertTextMessage(
          id: 'msg2',
          roomId: 'room2',
          text: 'Hello from room2',
        );

        final results = await db.searchMessagesInRoom('room1', 'hello');

        expect(results, hasLength(1));
        expect(results.first.id, equals('msg1'));
        expect(results.first.roomId, equals('room1'));
      });

      test('does not return messages from other rooms', () async {
        await insertRoom('room1');
        await insertRoom('room2');
        await insertTextMessage(
          id: 'msg1',
          roomId: 'room1',
          text: 'Hello world',
        );
        await insertTextMessage(
          id: 'msg2',
          roomId: 'room2',
          text: 'Hello universe',
        );

        final results = await db.searchMessagesInRoom('room1', 'universe');

        expect(results, isEmpty);
      });
    });

    group('FTS5 triggers', () {
      test('INSERT trigger adds message to FTS index', () async {
        await insertRoom('room1');
        await insertTextMessage(
          id: 'msg1',
          roomId: 'room1',
          text: 'Unique searchable content',
        );

        final results = await db.searchMessages('searchable');

        expect(results, hasLength(1));
      });

      test('UPDATE trigger updates FTS index', () async {
        await insertRoom('room1');
        await insertTextMessage(
          id: 'msg1',
          roomId: 'room1',
          text: 'Original content',
        );

        // Update the message
        await (db.update(
          db.roomEvents,
        )..where((e) => e.id.equals('msg1'))).write(
          RoomEventsCompanion(
            content: Value(jsonEncode({'text': 'Updated content'})),
          ),
        );

        // Old content should not be found
        final oldResults = await db.searchMessages('original');
        expect(oldResults, isEmpty);

        // New content should be found
        final newResults = await db.searchMessages('updated');
        expect(newResults, hasLength(1));
      });

      test('DELETE trigger removes message from FTS index', () async {
        await insertRoom('room1');
        await insertTextMessage(
          id: 'msg1',
          roomId: 'room1',
          text: 'Content to delete',
        );

        // Verify it's searchable
        var results = await db.searchMessages('delete');
        expect(results, hasLength(1));

        // Delete the message
        await (db.delete(
          db.roomEvents,
        )..where((e) => e.id.equals('msg1'))).go();

        // Should no longer be found
        results = await db.searchMessages('delete');
        expect(results, isEmpty);
      });
    });

    group('FTS5 table creation', () {
      test('database creates successfully with FTS5 support', () async {
        // If database creation succeeds, FTS5 is supported
        expect(db, isNotNull);
      });

      test('schema version is 18', () {
        // Version 18: renamed room_members → room_subscriptions, subscription_id → id
        expect(db.schemaVersion, equals(18));
      });
    });

    group('rebuildFtsIndex', () {
      test('completes without error', () async {
        await expectLater(db.rebuildFtsIndex(), completes);
      });

      test('rebuilds index correctly', () async {
        await insertRoom('room1');
        await insertTextMessage(
          id: 'msg1',
          roomId: 'room1',
          text: 'Rebuild test message',
        );

        // Rebuild should preserve searchability
        await db.rebuildFtsIndex();

        final results = await db.searchMessages('rebuild');
        expect(results, hasLength(1));
      });
    });

    group('edge cases', () {
      test('handles null content gracefully', () async {
        await insertRoom('room1');
        // Insert message with null content
        await db
            .into(db.roomEvents)
            .insert(
              RoomEventsCompanion.insert(
                id: 'msg1',
                roomId: 'room1',
                senderId: 'sender1',
                type: 0,
                status: const Value(1),
              ),
            );

        // Should not crash
        final results = await db.searchMessages('anything');
        expect(results, isEmpty);
      });

      test('handles non-text message types', () async {
        await insertRoom('room1');
        // Insert an image message (type = 1)
        await db
            .into(db.roomEvents)
            .insert(
              RoomEventsCompanion.insert(
                id: 'img1',
                roomId: 'room1',
                senderId: 'sender1',
                type: 1, // image type
                content: Value(
                  jsonEncode({'url': 'image.jpg', 'text': 'photo'}),
                ),
                status: const Value(1),
              ),
            );

        // Non-text messages should not be in FTS index
        final results = await db.searchMessages('photo');
        expect(results, isEmpty);
      });
    });
  });
}
