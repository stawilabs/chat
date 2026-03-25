import 'dart:io' show Platform;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/db/database.dart';
import 'package:stawi/core/settings/settings_service.dart';
import 'package:stawi/features/notifications/badge_service.dart';

import '../../../test_helpers/test_database.dart';

void main() {
  late AppDatabase testDb;
  late SettingsService settingsService;
  late BadgeService badgeService;

  setUp(() {
    testDb = createTestDatabase();
    settingsService = SettingsService(testDb);
    badgeService = BadgeService(testDb, settingsService);
  });

  tearDown(() async {
    badgeService.dispose();
    await testDb.close();
  });

  group('BadgeService', () {
    group('isSupported', () {
      test('returns true on Android', () {
        // This test documents the expected behavior
        if (Platform.isAndroid) {
          expect(
            BadgeService.isSupported,
            isTrue,
            reason: 'Android should support app badges',
          );
        }
      });

      test('returns true on iOS', () {
        // This test documents the expected behavior
        if (Platform.isIOS) {
          expect(
            BadgeService.isSupported,
            isTrue,
            reason: 'iOS should support app badges',
          );
        }
      });

      test('returns false on desktop platforms', () {
        // This test documents the expected behavior
        if (Platform.isLinux) {
          expect(
            BadgeService.isSupported,
            isFalse,
            reason: 'Linux should not support app badges',
          );
        }
        if (Platform.isMacOS) {
          expect(
            BadgeService.isSupported,
            isTrue,
            reason: 'macOS should support app badges via app_badge_plus',
          );
        }
        if (Platform.isWindows) {
          expect(
            BadgeService.isSupported,
            isFalse,
            reason: 'Windows should not support app badges',
          );
        }
      });

      test('returns correct value based on current platform', () {
        final isSupported = BadgeService.isSupported;

        if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
          expect(isSupported, isTrue);
        } else {
          expect(isSupported, isFalse);
        }
      });
    });

    group('initialization', () {
      test('isInitialized returns false before initialize', () {
        expect(badgeService.isInitialized, isFalse);
      });

      test('initialize sets isInitialized to true', () async {
        await badgeService.initialize();
        expect(badgeService.isInitialized, isTrue);
      });

      test('initialize can be called multiple times safely', () async {
        await badgeService.initialize();
        await badgeService.initialize(); // Should be no-op
        expect(badgeService.isInitialized, isTrue);
      });

      test('currentBadgeCount starts at 0', () {
        expect(badgeService.currentBadgeCount, equals(0));
      });
    });

    group('providers', () {
      test('badgeServiceProvider is available', () {
        expect(badgeServiceProvider, isNotNull);
      });

      test('badgeServiceInitializedProvider is available', () {
        expect(badgeServiceInitializedProvider, isNotNull);
      });
    });

    group('settings keys', () {
      test('kBadgeIncludeMutedChats constant is defined', () {
        expect(kBadgeIncludeMutedChats, equals('badge_include_muted_chats'));
      });

      test('kBadgeIncludeMutedChatsDefault is true', () {
        expect(kBadgeIncludeMutedChatsDefault, isTrue);
      });
    });

    group('dispose', () {
      test('dispose resets isInitialized', () async {
        await badgeService.initialize();
        expect(badgeService.isInitialized, isTrue);

        badgeService.dispose();
        expect(badgeService.isInitialized, isFalse);
      });

      test('dispose can be called multiple times safely', () async {
        await badgeService.initialize();
        badgeService.dispose();
        badgeService.dispose(); // Should not throw
        expect(badgeService.isInitialized, isFalse);
      });
    });

    group('database integration', () {
      test('unread count query returns 0 for empty database', () async {
        // Query total unread count directly
        final query = testDb.selectOnly(testDb.rooms)
          ..addColumns([testDb.rooms.unreadCount.sum()]);

        final row = await query.getSingle();
        final totalUnread = row.read(testDb.rooms.unreadCount.sum());

        expect(totalUnread, isNull); // No rooms = null sum
      });

      test('unread count query sums all room unread counts', () async {
        // Insert test rooms with unread counts
        await testDb
            .into(testDb.rooms)
            .insert(
              RoomsCompanion.insert(
                id: 'room-1',
                name: const Value('Test Room 1'),
                unreadCount: const Value(5),
              ),
            );
        await testDb
            .into(testDb.rooms)
            .insert(
              RoomsCompanion.insert(
                id: 'room-2',
                name: const Value('Test Room 2'),
                unreadCount: const Value(3),
              ),
            );
        await testDb
            .into(testDb.rooms)
            .insert(
              RoomsCompanion.insert(
                id: 'room-3',
                name: const Value('Test Room 3'),
                unreadCount: const Value(2),
              ),
            );

        // Query total unread count
        final query = testDb.selectOnly(testDb.rooms)
          ..addColumns([testDb.rooms.unreadCount.sum()]);

        final row = await query.getSingle();
        final totalUnread = row.read(testDb.rooms.unreadCount.sum());

        expect(totalUnread, equals(10)); // 5 + 3 + 2 = 10
      });

      test('unread count updates when room is modified', () async {
        // Insert a room
        await testDb
            .into(testDb.rooms)
            .insert(
              RoomsCompanion.insert(
                id: 'room-1',
                name: const Value('Test Room'),
                unreadCount: const Value(5),
              ),
            );

        // Update unread count
        await (testDb.update(testDb.rooms)..where((r) => r.id.equals('room-1')))
            .write(const RoomsCompanion(unreadCount: Value(0)));

        // Query total
        final query = testDb.selectOnly(testDb.rooms)
          ..addColumns([testDb.rooms.unreadCount.sum()]);

        final row = await query.getSingle();
        final totalUnread = row.read(testDb.rooms.unreadCount.sum());

        expect(totalUnread, equals(0));
      });

      test('settings can store badge muted chats preference', () async {
        await settingsService.initialize();

        // Default should be true
        expect(
          settingsService.getBool(
            kBadgeIncludeMutedChats,
            defaultValue: kBadgeIncludeMutedChatsDefault,
          ),
          isTrue,
        );

        // Set to false
        await settingsService.setBool(kBadgeIncludeMutedChats, false);
        expect(
          settingsService.getBool(
            kBadgeIncludeMutedChats,
            defaultValue: kBadgeIncludeMutedChatsDefault,
          ),
          isFalse,
        );

        // Set to true
        await settingsService.setBool(kBadgeIncludeMutedChats, true);
        expect(
          settingsService.getBool(
            kBadgeIncludeMutedChats,
            defaultValue: kBadgeIncludeMutedChatsDefault,
          ),
          isTrue,
        );
      });
    });

    group('clearBadge', () {
      test('clearBadge resets currentBadgeCount to 0', () async {
        // We can't test actual badge updates without mocking FlutterAppBadger
        // but we can verify the internal state
        await badgeService.clearBadge();
        expect(badgeService.currentBadgeCount, equals(0));
      });
    });

    group('refreshBadge', () {
      test('refreshBadge works on uninitialized service (no-op)', () async {
        // Should not throw
        await badgeService.refreshBadge();
        expect(badgeService.currentBadgeCount, equals(0));
      });
    });
  });

  group('Platform support verification', () {
    test('mobile platforms are supported', () {
      if (Platform.isAndroid) {
        expect(
          BadgeService.isSupported,
          isTrue,
          reason: 'Android should support app badges',
        );
      }
      if (Platform.isIOS) {
        expect(
          BadgeService.isSupported,
          isTrue,
          reason: 'iOS should support app badges',
        );
      }
    });

    test('some desktop platforms are not supported', () {
      if (Platform.isLinux) {
        expect(
          BadgeService.isSupported,
          isFalse,
          reason: 'Linux should not support app badges',
        );
      }
      if (Platform.isWindows) {
        expect(
          BadgeService.isSupported,
          isFalse,
          reason: 'Windows should not support app badges',
        );
      }
    });

    test('macOS is supported', () {
      if (Platform.isMacOS) {
        expect(
          BadgeService.isSupported,
          isTrue,
          reason: 'macOS should support app badges via app_badge_plus',
        );
      }
    });
  });

  group('Unread count aggregation', () {
    test('correctly sums unread counts from multiple rooms', () async {
      // Create rooms with various unread counts
      final testCases = [
        {'id': 'room-a', 'unread': 1},
        {'id': 'room-b', 'unread': 10},
        {'id': 'room-c', 'unread': 0},
        {'id': 'room-d', 'unread': 25},
        {'id': 'room-e', 'unread': 100},
      ];

      for (final testCase in testCases) {
        await testDb
            .into(testDb.rooms)
            .insert(
              RoomsCompanion.insert(
                id: testCase['id']! as String,
                name: Value('Room ${testCase['id']}'),
                unreadCount: Value(testCase['unread']! as int),
              ),
            );
      }

      // Query total
      final query = testDb.selectOnly(testDb.rooms)
        ..addColumns([testDb.rooms.unreadCount.sum()]);

      final row = await query.getSingle();
      final totalUnread = row.read(testDb.rooms.unreadCount.sum());

      // Expected: 1 + 10 + 0 + 25 + 100 = 136
      expect(totalUnread, equals(136));
    });

    test('handles large unread counts', () async {
      // Create room with large unread count
      await testDb
          .into(testDb.rooms)
          .insert(
            RoomsCompanion.insert(
              id: 'room-large',
              name: const Value('Large Room'),
              unreadCount: const Value(999999),
            ),
          );

      final query = testDb.selectOnly(testDb.rooms)
        ..addColumns([testDb.rooms.unreadCount.sum()]);

      final row = await query.getSingle();
      final totalUnread = row.read(testDb.rooms.unreadCount.sum());

      expect(totalUnread, equals(999999));
    });

    test('handles zero unread counts across all rooms', () async {
      // Create rooms with zero unread counts
      await testDb
          .into(testDb.rooms)
          .insert(
            RoomsCompanion.insert(
              id: 'room-1',
              name: const Value('Room 1'),
              unreadCount: const Value(0),
            ),
          );
      await testDb
          .into(testDb.rooms)
          .insert(
            RoomsCompanion.insert(
              id: 'room-2',
              name: const Value('Room 2'),
              unreadCount: const Value(0),
            ),
          );

      final query = testDb.selectOnly(testDb.rooms)
        ..addColumns([testDb.rooms.unreadCount.sum()]);

      final row = await query.getSingle();
      final totalUnread = row.read(testDb.rooms.unreadCount.sum());

      expect(totalUnread, equals(0));
    });
  });
}
