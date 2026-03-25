import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart' hide isNull, isNotNull;
import 'package:stawi/core/db/database.dart';
import 'package:stawi/features/notifications/mute_service.dart';
import 'package:stawi/features/rooms/data/room_repository.dart';
import 'package:stawi/features/rooms/domain/room.dart' as domain;

void main() {
  late AppDatabase database;
  late RoomRepository roomRepository;
  late MuteService muteService;

  setUp(() async {
    // Create an in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
    roomRepository = RoomRepository(database);
    muteService = MuteService(roomRepository);

    // Insert a test room
    await database
        .into(database.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'test-room-1',
            name: const Value('Test Room'),
            type: const Value('group'),
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('MuteService', () {
    group('muteRoom', () {
      test('should mute room for 8 hours', () async {
        final beforeMute = DateTime.now().millisecondsSinceEpoch;

        await muteService.muteRoom(
          'test-room-1',
          domain.MuteDuration.eightHours,
        );

        final mutedUntil = await muteService.getMutedUntil('test-room-1');
        final afterMute = DateTime.now().millisecondsSinceEpoch;

        expect(mutedUntil, isNot(equals(null)));
        // Should be approximately 8 hours from now
        final expectedMin = beforeMute + (8 * 60 * 60 * 1000);
        final expectedMax = afterMute + (8 * 60 * 60 * 1000);
        expect(mutedUntil, greaterThanOrEqualTo(expectedMin));
        expect(mutedUntil, lessThanOrEqualTo(expectedMax));
      });

      test('should mute room for 1 week', () async {
        final beforeMute = DateTime.now().millisecondsSinceEpoch;

        await muteService.muteRoom('test-room-1', domain.MuteDuration.oneWeek);

        final mutedUntil = await muteService.getMutedUntil('test-room-1');
        final afterMute = DateTime.now().millisecondsSinceEpoch;

        expect(mutedUntil, isNot(equals(null)));
        // Should be approximately 7 days from now
        final expectedMin = beforeMute + (7 * 24 * 60 * 60 * 1000);
        final expectedMax = afterMute + (7 * 24 * 60 * 60 * 1000);
        expect(mutedUntil, greaterThanOrEqualTo(expectedMin));
        expect(mutedUntil, lessThanOrEqualTo(expectedMax));
      });

      test('should mute room forever with value 0', () async {
        await muteService.muteRoom('test-room-1', domain.MuteDuration.forever);

        final mutedUntil = await muteService.getMutedUntil('test-room-1');

        expect(mutedUntil, equals(0));
      });
    });

    group('unmuteRoom', () {
      test('should unmute a muted room', () async {
        // First mute the room
        await muteService.muteRoom('test-room-1', domain.MuteDuration.forever);
        expect(await muteService.isRoomMuted('test-room-1'), isTrue);

        // Then unmute
        await muteService.unmuteRoom('test-room-1');

        final mutedUntil = await muteService.getMutedUntil('test-room-1');
        expect(mutedUntil, equals(null));
        expect(await muteService.isRoomMuted('test-room-1'), isFalse);
      });

      test('should handle unmuting an already unmuted room', () async {
        // Room is not muted initially
        expect(await muteService.isRoomMuted('test-room-1'), isFalse);

        // Unmuting should not throw
        await muteService.unmuteRoom('test-room-1');

        expect(await muteService.isRoomMuted('test-room-1'), isFalse);
      });
    });

    group('isRoomMuted', () {
      test('should return false for unmuted room', () async {
        final isMuted = await muteService.isRoomMuted('test-room-1');

        expect(isMuted, isFalse);
      });

      test('should return true for room muted forever', () async {
        await muteService.muteRoom('test-room-1', domain.MuteDuration.forever);

        final isMuted = await muteService.isRoomMuted('test-room-1');

        expect(isMuted, isTrue);
      });

      test('should return true for room muted with future timestamp', () async {
        await muteService.muteRoom(
          'test-room-1',
          domain.MuteDuration.eightHours,
        );

        final isMuted = await muteService.isRoomMuted('test-room-1');

        expect(isMuted, isTrue);
      });

      test('should return false for expired mute', () async {
        // Manually set an expired mute timestamp
        await roomRepository.updateMutedUntil(
          'test-room-1',
          DateTime.now().millisecondsSinceEpoch - 1000, // 1 second ago
        );

        final isMuted = await muteService.isRoomMuted('test-room-1');

        expect(isMuted, isFalse);
      });

      test('should return false for non-existent room', () async {
        final isMuted = await muteService.isRoomMuted('non-existent-room');

        expect(isMuted, isFalse);
      });
    });

    group('getMuteTimeRemaining', () {
      test('should return null for unmuted room', () async {
        final remaining = await muteService.getMuteTimeRemaining('test-room-1');

        expect(remaining, equals(null));
      });

      test('should return "Forever" for room muted forever', () async {
        await muteService.muteRoom('test-room-1', domain.MuteDuration.forever);

        final remaining = await muteService.getMuteTimeRemaining('test-room-1');

        expect(remaining, equals('Forever'));
      });

      test('should return time remaining string for timed mute', () async {
        await muteService.muteRoom(
          'test-room-1',
          domain.MuteDuration.eightHours,
        );

        final remaining = await muteService.getMuteTimeRemaining('test-room-1');

        expect(remaining, isNot(equals(null)));
        // Should contain 'h' for hours
        expect(remaining!.contains('h'), isTrue);
      });

      test('should return null for expired mute', () async {
        // Manually set an expired mute timestamp
        await roomRepository.updateMutedUntil(
          'test-room-1',
          DateTime.now().millisecondsSinceEpoch - 1000, // 1 second ago
        );

        final remaining = await muteService.getMuteTimeRemaining('test-room-1');

        expect(remaining, equals(null));
      });
    });
  });

  group('domain.MuteDuration', () {
    test('eightHours should have correct duration in milliseconds', () {
      expect(
        domain.MuteDuration.eightHours.durationMs,
        equals(8 * 60 * 60 * 1000),
      );
    });

    test('oneWeek should have correct duration in milliseconds', () {
      expect(
        domain.MuteDuration.oneWeek.durationMs,
        equals(7 * 24 * 60 * 60 * 1000),
      );
    });

    test('forever should have duration 0', () {
      expect(domain.MuteDuration.forever.durationMs, equals(0));
    });

    test('getMutedUntilTimestamp should return 0 for forever', () {
      expect(domain.MuteDuration.forever.getMutedUntilTimestamp(), equals(0));
    });

    test(
      'getMutedUntilTimestamp should return future timestamp for timed durations',
      () {
        final now = DateTime.now().millisecondsSinceEpoch;
        final timestamp = domain.MuteDuration.eightHours
            .getMutedUntilTimestamp();

        expect(timestamp, greaterThan(now));
        expect(
          timestamp,
          lessThanOrEqualTo(
            now + domain.MuteDuration.eightHours.durationMs + 1000,
          ),
        );
      },
    );

    test('labels should be human-readable', () {
      expect(domain.MuteDuration.eightHours.label, equals('8 hours'));
      expect(domain.MuteDuration.oneWeek.label, equals('1 week'));
      expect(domain.MuteDuration.forever.label, equals('Forever'));
    });
  });

  group('Room.isMuted getter', () {
    test('should return false when mutedUntil is null', () {
      const room = domain.Room(id: 'room-1', name: 'Test', type: 'group');

      expect(room.isMuted, isFalse);
    });

    test('should return true when mutedUntil is 0 (forever)', () {
      const room = domain.Room(
        id: 'room-1',
        name: 'Test',
        type: 'group',
        mutedUntil: 0,
      );

      expect(room.isMuted, isTrue);
    });

    test('should return true when mutedUntil is in the future', () {
      final futureTimestamp =
          DateTime.now().millisecondsSinceEpoch +
          (60 * 60 * 1000); // 1 hour from now
      final room = domain.Room(
        id: 'room-1',
        name: 'Test',
        type: 'group',
        mutedUntil: futureTimestamp,
      );

      expect(room.isMuted, isTrue);
    });

    test('should return false when mutedUntil is in the past', () {
      final pastTimestamp =
          DateTime.now().millisecondsSinceEpoch -
          (60 * 60 * 1000); // 1 hour ago
      final room = domain.Room(
        id: 'room-1',
        name: 'Test',
        type: 'group',
        mutedUntil: pastTimestamp,
      );

      expect(room.isMuted, isFalse);
    });
  });

  group('Room.muteTimeRemaining getter', () {
    test('should return null when not muted', () {
      const room = domain.Room(id: 'room-1', name: 'Test', type: 'group');

      expect(room.muteTimeRemaining, equals(null));
    });

    test('should return Forever when muted forever', () {
      const room = domain.Room(
        id: 'room-1',
        name: 'Test',
        type: 'group',
        mutedUntil: 0,
      );

      expect(room.muteTimeRemaining, equals('Forever'));
    });

    test('should return time remaining when muted with future timestamp', () {
      final futureTimestamp =
          DateTime.now().millisecondsSinceEpoch +
          (2 * 60 * 60 * 1000); // 2 hours from now
      final room = domain.Room(
        id: 'room-1',
        name: 'Test',
        type: 'group',
        mutedUntil: futureTimestamp,
      );

      final remaining = room.muteTimeRemaining;
      expect(remaining, isNot(equals(null)));
      // Should show hours format
      expect(remaining!.contains('h'), isTrue);
    });

    test('should return null when mute has expired', () {
      final pastTimestamp =
          DateTime.now().millisecondsSinceEpoch -
          (60 * 60 * 1000); // 1 hour ago
      final room = domain.Room(
        id: 'room-1',
        name: 'Test',
        type: 'group',
        mutedUntil: pastTimestamp,
      );

      expect(room.muteTimeRemaining, equals(null));
    });
  });
}
