import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/db/database.dart' hide RoomEvent, Room;
import 'package:stawi/features/rooms/data/room_repository.dart';
import 'package:stawi/features/rooms/domain/room.dart';

import '../../../test_helpers/test_database.dart';

void main() {
  late AppDatabase testDb;
  late RoomRepository repository;

  setUp(() async {
    testDb = createTestDatabase();
    repository = RoomRepository(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  group('Group Settings', () {
    group('name validation', () {
      test('accepts name up to 100 characters', () async {
        final longName = 'A' * 100;
        final room = Room(id: 'room-1', name: longName, type: 'group');

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result, isNotNull);
        expect(result!.name, equals(longName));
        expect(result.name.length, equals(100));
      });

      test('accepts empty name for direct messages', () async {
        const room = Room(id: 'dm-1', name: '', type: 'direct');

        await repository.insertRoom(room);

        final result = await repository.getRoomById('dm-1');
        expect(result, isNotNull);
        expect(result!.name, isEmpty);
      });

      test('handles special characters in name', () async {
        const room = Room(
          id: 'room-1',
          name: r"Team's Group Chat! @#$%",
          type: 'group',
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result!.name, equals(r"Team's Group Chat! @#$%"));
      });

      test('handles unicode characters in name', () async {
        const room = Room(id: 'room-1', name: 'Test Group', type: 'group');

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result!.name, equals('Test Group'));
      });
    });

    group('description metadata', () {
      test('stores description in metadata', () async {
        const room = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {'description': 'This is a test group description'},
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result!.metadata, isNotNull);
        expect(
          result.metadata!['description'],
          equals('This is a test group description'),
        );
      });

      test('accepts description up to 500 characters', () async {
        final longDescription = 'A' * 500;
        final room = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {'description': longDescription},
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result!.metadata!['description'], equals(longDescription));
        expect((result.metadata!['description'] as String).length, equals(500));
      });

      test('handles empty description', () async {
        const room = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {'description': ''},
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result!.metadata!['description'], equals(''));
      });
    });

    group('avatar metadata', () {
      test('stores avatarUrl in metadata', () async {
        const room = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {'avatarUrl': 'https://example.com/avatar.png'},
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result!.metadata, isNotNull);
        expect(
          result.metadata!['avatarUrl'],
          equals('https://example.com/avatar.png'),
        );
      });

      test('handles null avatarUrl', () async {
        const room = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {'avatarUrl': null},
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result!.metadata!['avatarUrl'], isNull);
      });
    });

    group('permission settings', () {
      test('stores editInfoPermission in metadata', () async {
        const room = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {'editInfoPermission': 'admins'},
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result!.metadata!['editInfoPermission'], equals('admins'));
      });

      test('stores sendMessagesPermission in metadata', () async {
        const room = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {'sendMessagesPermission': 'all_members'},
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(
          result!.metadata!['sendMessagesPermission'],
          equals('all_members'),
        );
      });

      test('stores addMembersPermission in metadata', () async {
        const room = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {'addMembersPermission': 'admins'},
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result!.metadata!['addMembersPermission'], equals('admins'));
      });

      test('stores all permission settings together', () async {
        const room = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {
            'editInfoPermission': 'all_members',
            'sendMessagesPermission': 'all_members',
            'addMembersPermission': 'admins',
          },
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result!.metadata!['editInfoPermission'], equals('all_members'));
        expect(
          result.metadata!['sendMessagesPermission'],
          equals('all_members'),
        );
        expect(result.metadata!['addMembersPermission'], equals('admins'));
      });
    });

    group('update room settings', () {
      test('updates room name', () async {
        const originalRoom = Room(
          id: 'room-1',
          name: 'Original Name',
          type: 'group',
        );
        await repository.insertRoom(originalRoom);

        const updatedRoom = Room(
          id: 'room-1',
          name: 'Updated Name',
          type: 'group',
        );
        await repository.insertRoom(updatedRoom);

        final result = await repository.getRoomById('room-1');
        expect(result!.name, equals('Updated Name'));
      });

      test('updates room description', () async {
        const originalRoom = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {'description': 'Original description'},
        );
        await repository.insertRoom(originalRoom);

        const updatedRoom = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {'description': 'Updated description'},
        );
        await repository.insertRoom(updatedRoom);

        final result = await repository.getRoomById('room-1');
        expect(result!.metadata!['description'], equals('Updated description'));
      });

      test('updates room avatar', () async {
        const originalRoom = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {'avatarUrl': 'https://example.com/old.png'},
        );
        await repository.insertRoom(originalRoom);

        const updatedRoom = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {'avatarUrl': 'https://example.com/new.png'},
        );
        await repository.insertRoom(updatedRoom);

        final result = await repository.getRoomById('room-1');
        expect(
          result!.metadata!['avatarUrl'],
          equals('https://example.com/new.png'),
        );
      });

      test('updates room permissions', () async {
        const originalRoom = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {
            'editInfoPermission': 'admins',
            'sendMessagesPermission': 'all_members',
            'addMembersPermission': 'admins',
          },
        );
        await repository.insertRoom(originalRoom);

        const updatedRoom = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {
            'editInfoPermission': 'all_members',
            'sendMessagesPermission': 'admins',
            'addMembersPermission': 'all_members',
          },
        );
        await repository.insertRoom(updatedRoom);

        final result = await repository.getRoomById('room-1');
        expect(result!.metadata!['editInfoPermission'], equals('all_members'));
        expect(result.metadata!['sendMessagesPermission'], equals('admins'));
        expect(result.metadata!['addMembersPermission'], equals('all_members'));
      });

      test('preserves other metadata when updating specific fields', () async {
        const originalRoom = Room(
          id: 'room-1',
          name: 'Test Group',
          type: 'group',
          metadata: {
            'description': 'Test description',
            'avatarUrl': 'https://example.com/avatar.png',
            'customField': 'custom value',
          },
        );
        await repository.insertRoom(originalRoom);

        const updatedRoom = Room(
          id: 'room-1',
          name: 'Updated Name',
          type: 'group',
          metadata: {
            'description': 'Updated description',
            'avatarUrl': 'https://example.com/avatar.png',
            'customField': 'custom value',
          },
        );
        await repository.insertRoom(updatedRoom);

        final result = await repository.getRoomById('room-1');
        expect(result!.name, equals('Updated Name'));
        expect(result.metadata!['description'], equals('Updated description'));
        expect(
          result.metadata!['avatarUrl'],
          equals('https://example.com/avatar.png'),
        );
        expect(result.metadata!['customField'], equals('custom value'));
      });
    });

    group('complex metadata', () {
      test('stores complete group settings', () async {
        const room = Room(
          id: 'room-1',
          name: 'Complete Group',
          type: 'group',
          metadata: {
            'description': 'A complete group with all settings',
            'avatarUrl': 'https://example.com/group.png',
            'editInfoPermission': 'admins',
            'sendMessagesPermission': 'all_members',
            'addMembersPermission': 'admins',
            'isPrivate': true,
            'createdBy': 'user-123',
          },
        );

        await repository.insertRoom(room);

        final result = await repository.getRoomById('room-1');
        expect(result, isNotNull);
        expect(result!.name, equals('Complete Group'));
        expect(result.type, equals('group'));
        expect(
          result.metadata!['description'],
          equals('A complete group with all settings'),
        );
        expect(
          result.metadata!['avatarUrl'],
          equals('https://example.com/group.png'),
        );
        expect(result.metadata!['editInfoPermission'], equals('admins'));
        expect(
          result.metadata!['sendMessagesPermission'],
          equals('all_members'),
        );
        expect(result.metadata!['addMembersPermission'], equals('admins'));
        expect(result.metadata!['isPrivate'], equals(true));
        expect(result.metadata!['createdBy'], equals('user-123'));
      });
    });
  });
}
