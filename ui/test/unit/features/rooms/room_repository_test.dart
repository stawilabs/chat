import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/db/database.dart' hide RoomEvent, Room;
import 'package:stawi/features/messages/data/message_repository.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/rooms/data/room_repository.dart';
import 'package:stawi/features/rooms/domain/room.dart';

import '../../../test_helpers/test_database.dart';

void main() {
  late AppDatabase testDb;
  late RoomRepository repository;
  late MessageRepository messageRepository;

  setUp(() async {
    testDb = createTestDatabase();
    repository = RoomRepository(testDb);
    messageRepository = MessageRepository(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  group('RoomRepository', () {
    group('insertRoom', () {
      test('inserts a room successfully', () async {
        const room = Room(id: 'room-1', name: 'Test Room', type: 'group');

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result, isNotNull);
        expect(result!.id, equals('room-1'));
        expect(result.name, equals('Test Room'));
        expect(result.type, equals('group'));
      });

      test('inserts direct message room', () async {
        const room = Room(id: 'dm-1', name: '', type: 'direct');

        await repository.insertRoom(room);

        final result = await repository.getRoomById('dm-1');
        expect(result, isNotNull);
        expect(result!.type, equals('direct'));
      });

      test('inserts room with metadata', () async {
        const room = Room(
          id: 'room-1',
          name: 'Team Room',
          type: 'group',
          metadata: {
            'description': 'A team collaboration room',
            'avatarUrl': 'https://example.com/avatar.png',
            'isPublic': false,
          },
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result!.metadata, isNotNull);
        expect(
          result.metadata!['description'],
          equals('A team collaboration room'),
        );
        expect(
          result.metadata!['avatarUrl'],
          equals('https://example.com/avatar.png'),
        );
        expect(result.metadata!['isPublic'], equals(false));
      });

      test('updates existing room on conflict', () async {
        const room1 = Room(id: 'room-1', name: 'Original Name', type: 'group');

        const room2 = Room(
          id: 'room-1',
          name: 'Updated Name',
          type: 'group',
          unreadCount: 5,
        );

        await repository.insertRoom(room1);
        await repository.insertRoom(room2);

        final result = await repository.getRoomById('room-1');
        expect(result!.name, equals('Updated Name'));
        expect(result.unreadCount, equals(5));
      });

      test('inserts room with last event tracking', () async {
        const room = Room(
          id: 'room-1',
          name: 'Test Room',
          type: 'group',
          lastEventId: 'event-123',
          lastEventIndex: 42,
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result!.lastEventId, equals('event-123'));
        expect(result.lastEventIndex, equals(42));
      });
    });

    group('getAllRooms', () {
      test('returns empty list when no rooms', () async {
        final rooms = await repository.getAllRooms();
        expect(rooms, isEmpty);
      });

      test('returns all rooms', () async {
        await repository.insertRoom(
          const Room(id: 'room-1', name: 'Room 1', type: 'group'),
        );
        await repository.insertRoom(
          const Room(id: 'room-2', name: 'Room 2', type: 'group'),
        );
        await repository.insertRoom(
          const Room(id: 'room-3', name: 'Room 3', type: 'direct'),
        );

        final rooms = await repository.getAllRooms();

        expect(rooms.length, equals(3));
        expect(rooms.any((r) => r.id == 'room-1'), isTrue);
        expect(rooms.any((r) => r.id == 'room-2'), isTrue);
        expect(rooms.any((r) => r.id == 'room-3'), isTrue);
      });

      test('returns rooms ordered by lastEventIndex descending', () async {
        await repository.insertRoom(
          const Room(
            id: 'room-1',
            name: 'Room 1',
            type: 'group',
            lastEventIndex: 10,
          ),
        );
        await repository.insertRoom(
          const Room(
            id: 'room-2',
            name: 'Room 2',
            type: 'group',
            lastEventIndex: 30,
          ),
        );
        await repository.insertRoom(
          const Room(
            id: 'room-3',
            name: 'Room 3',
            type: 'group',
            lastEventIndex: 20,
          ),
        );

        final rooms = await repository.getAllRooms();

        expect(rooms[0].id, equals('room-2')); // lastEventIndex: 30
        expect(rooms[1].id, equals('room-3')); // lastEventIndex: 20
        expect(rooms[2].id, equals('room-1')); // lastEventIndex: 10
      });
    });

    group('getRoomById', () {
      test('returns null for non-existent room', () async {
        final result = await repository.getRoomById('non-existent');
        expect(result, isNull);
      });

      test('returns room with all fields', () async {
        const room = Room(
          id: 'room-1',
          name: 'Complete Room',
          type: 'group',
          lastEventId: 'event-999',
          lastEventIndex: 100,
          unreadCount: 15,
          metadata: {'key': 'value'},
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result, isNotNull);
        expect(result!.id, equals('room-1'));
        expect(result.name, equals('Complete Room'));
        expect(result.type, equals('group'));
        expect(result.lastEventId, equals('event-999'));
        expect(result.lastEventIndex, equals(100));
        expect(result.unreadCount, equals(15));
        expect(result.metadata!['key'], equals('value'));
      });
    });

    group('updateUnreadCount', () {
      test('updates unread count for existing room', () async {
        await repository.insertRoom(
          const Room(id: 'room-1', name: 'Test Room', type: 'group'),
        );

        await repository.updateUnreadCount('room-1', 10);

        final result = await repository.getRoomById('room-1');
        expect(result!.unreadCount, equals(10));
      });

      test('can set unread count to zero', () async {
        await repository.insertRoom(
          const Room(
            id: 'room-1',
            name: 'Test Room',
            type: 'group',
            unreadCount: 50,
          ),
        );

        await repository.updateUnreadCount('room-1', 0);

        final result = await repository.getRoomById('room-1');
        expect(result!.unreadCount, equals(0));
      });

      test('increments unread count correctly', () async {
        await repository.insertRoom(
          const Room(
            id: 'room-1',
            name: 'Test Room',
            type: 'group',
            unreadCount: 5,
          ),
        );

        await repository.updateUnreadCount('room-1', 6);

        final result = await repository.getRoomById('room-1');
        expect(result!.unreadCount, equals(6));
      });
    });

    group('getRoomsWithLastMessage', () {
      test('returns empty list when no rooms', () async {
        final rooms = await repository.getRoomsWithLastMessage();
        expect(rooms, isEmpty);
      });

      test('returns rooms without messages', () async {
        await repository.insertRoom(
          const Room(id: 'room-1', name: 'Empty Room', type: 'group'),
        );

        final rooms = await repository.getRoomsWithLastMessage();

        expect(rooms.length, equals(1));
        expect(rooms[0].id, equals('room-1'));
        expect(rooms[0].lastMessageText, isNull);
        expect(rooms[0].lastMessageTimestamp, isNull);
      });

      test('returns rooms with last message info', () async {
        final now = DateTime.now().millisecondsSinceEpoch;

        // Create room and set last event ID
        await repository.insertRoom(
          const Room(
            id: 'room-1',
            name: 'Chat Room',
            type: 'group',
            lastEventId: 'event-1',
          ),
        );

        // Create message
        await messageRepository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Hello, world!'},
            createdAt: now,
          ),
        );

        final rooms = await repository.getRoomsWithLastMessage();

        expect(rooms.length, equals(1));
        expect(rooms[0].lastMessageText, equals('Hello, world!'));
        expect(rooms[0].lastMessageTimestamp, equals(now));
        expect(rooms[0].lastMessageSenderId, equals('sender-1'));
      });

      test('returns rooms ordered by last message timestamp', () async {
        final now = DateTime.now().millisecondsSinceEpoch;

        // Room with older message
        await repository.insertRoom(
          const Room(
            id: 'room-1',
            name: 'Older Room',
            type: 'group',
            lastEventId: 'event-1',
          ),
        );
        await messageRepository.insertMessage(
          RoomEvent(
            id: 'event-1',
            roomId: 'room-1',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'Old message'},
            createdAt: now - 1000,
          ),
        );

        // Room with newer message
        await repository.insertRoom(
          const Room(
            id: 'room-2',
            name: 'Newer Room',
            type: 'group',
            lastEventId: 'event-2',
          ),
        );
        await messageRepository.insertMessage(
          RoomEvent(
            id: 'event-2',
            roomId: 'room-2',
            senderId: 'sender-1',
            type: RoomEventType.text,
            content: {'text': 'New message'},
            createdAt: now,
          ),
        );

        final rooms = await repository.getRoomsWithLastMessage();

        expect(rooms.length, equals(2));
        expect(rooms[0].id, equals('room-2')); // Newer first
        expect(rooms[1].id, equals('room-1')); // Older second
      });

      test('includes unread count', () async {
        await repository.insertRoom(
          const Room(
            id: 'room-1',
            name: 'Unread Room',
            type: 'group',
            unreadCount: 42,
          ),
        );

        final rooms = await repository.getRoomsWithLastMessage();

        expect(rooms[0].unreadCount, equals(42));
      });
    });

    group('edge cases', () {
      test('handles room with empty name', () async {
        const room = Room(id: 'room-1', name: '', type: 'direct');

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result!.name, equals(''));
      });

      test('handles room with special characters in name', () async {
        const room = Room(
          id: 'room-1',
          name: "Team's Chat 🎉 <script>alert('xss')</script>",
          type: 'group',
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(
          result!.name,
          equals("Team's Chat 🎉 <script>alert('xss')</script>"),
        );
      });

      test('handles complex metadata JSON', () async {
        const room = Room(
          id: 'room-1',
          name: 'Complex Room',
          type: 'group',
          metadata: {
            'nested': {
              'level1': {'level2': 'deep value'},
            },
            'array': [1, 2, 3, 'four'],
            'nullValue': null,
            'boolean': true,
          },
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        final nested = result!.metadata!['nested'] as Map<String, dynamic>;
        final level1 = nested['level1'] as Map<String, dynamic>;
        expect(level1['level2'], equals('deep value'));
        final array = result.metadata!['array'] as List<dynamic>;
        expect(array[3], equals('four'));
        expect(result.metadata!['boolean'], equals(true));
      });
    });
  });
}
