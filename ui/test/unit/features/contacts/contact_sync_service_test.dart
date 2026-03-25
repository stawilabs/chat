import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/db/database.dart';
import 'package:stawi/core/settings/settings_service.dart';
import 'package:stawi/features/contacts/services/contact_sync_service.dart';

import '../../../test_helpers/test_database.dart';
import 'mock_roster_repository.dart';

void main() {
  late AppDatabase testDb;
  late SettingsService settingsService;
  late MockRosterRepository mockRosterRepository;
  late ContactSyncService syncService;

  setUp(() async {
    testDb = createTestDatabase();
    settingsService = SettingsService(testDb);
    await settingsService.initialize();
    mockRosterRepository = MockRosterRepository();
    syncService = ContactSyncService(
      syncRepository: mockRosterRepository,
      settingsService: settingsService,
    );
  });

  tearDown(() async {
    await testDb.close();
  });

  group('ContactSyncService', () {
    group('settings management', () {
      test('isAutoSyncEnabled returns default true when not set', () {
        expect(syncService.isAutoSyncEnabled, isTrue);
      });

      test('setAutoSyncEnabled persists the setting', () async {
        await syncService.setAutoSyncEnabled(false);
        expect(syncService.isAutoSyncEnabled, isFalse);

        await syncService.setAutoSyncEnabled(true);
        expect(syncService.isAutoSyncEnabled, isTrue);
      });

      test('lastSyncTime returns null when never synced', () {
        expect(syncService.lastSyncTime, isNull);
      });

      test('syncIntervalHours returns default 24 when not set', () {
        expect(syncService.syncIntervalHours, equals(24));
      });

      test('setSyncIntervalHours enforces minimum of 1 hour', () async {
        await syncService.setSyncIntervalHours(0);
        expect(syncService.syncIntervalHours, equals(1));

        await syncService.setSyncIntervalHours(-5);
        expect(syncService.syncIntervalHours, equals(1));
      });

      test('setSyncIntervalHours enforces maximum of 168 hours', () async {
        await syncService.setSyncIntervalHours(200);
        expect(syncService.syncIntervalHours, equals(168));
      });

      test('setSyncIntervalHours accepts valid values', () async {
        await syncService.setSyncIntervalHours(12);
        expect(syncService.syncIntervalHours, equals(12));

        await syncService.setSyncIntervalHours(48);
        expect(syncService.syncIntervalHours, equals(48));
      });

      test('syncOnlyOnWifi returns default false when not set', () {
        expect(syncService.syncOnlyOnWifi, isFalse);
      });

      test('setSyncOnlyOnWifi persists the setting', () async {
        await syncService.setSyncOnlyOnWifi(true);
        expect(syncService.syncOnlyOnWifi, isTrue);

        await syncService.setSyncOnlyOnWifi(false);
        expect(syncService.syncOnlyOnWifi, isFalse);
      });
    });

    group('isSyncDue', () {
      test('returns true when never synced', () {
        expect(syncService.isSyncDue(), isTrue);
      });

      test('returns false immediately after sync', () async {
        // Simulate a sync by setting last sync time
        await settingsService.setInt(
          ContactSyncSettings.lastSyncTime,
          DateTime.now().millisecondsSinceEpoch,
        );

        // Recreate service to pick up the setting
        syncService = ContactSyncService(
          syncRepository: mockRosterRepository,
          settingsService: settingsService,
        );

        expect(syncService.isSyncDue(), isFalse);
      });

      test('returns true when interval has passed', () async {
        // Set last sync time to 25 hours ago
        final pastTime = DateTime.now().subtract(const Duration(hours: 25));
        await settingsService.setInt(
          ContactSyncSettings.lastSyncTime,
          pastTime.millisecondsSinceEpoch,
        );

        // Recreate service to pick up the setting
        syncService = ContactSyncService(
          syncRepository: mockRosterRepository,
          settingsService: settingsService,
        );

        expect(syncService.isSyncDue(), isTrue);
      });

      test('respects custom sync interval', () async {
        // Set sync interval to 12 hours
        await syncService.setSyncIntervalHours(12);

        // Set last sync time to 13 hours ago
        final pastTime = DateTime.now().subtract(const Duration(hours: 13));
        await settingsService.setInt(
          ContactSyncSettings.lastSyncTime,
          pastTime.millisecondsSinceEpoch,
        );

        // Recreate service to pick up the setting
        syncService = ContactSyncService(
          syncRepository: mockRosterRepository,
          settingsService: settingsService,
        );

        expect(syncService.isSyncDue(), isTrue);
      });
    });

    group('performFullSync', () {
      test('returns successful result', () async {
        mockRosterRepository.setSyncResult([]);

        final result = await syncService.performFullSync();

        expect(result.success, isTrue);
        expect(result.isIncremental, isFalse);
        expect(result.error, isNull);
        expect(result.duration, isNotNull);
      });

      test('updates last sync time on success', () async {
        mockRosterRepository.setSyncResult([]);

        expect(syncService.lastSyncTime, isNull);

        await syncService.performFullSync();

        expect(syncService.lastSyncTime, isNotNull);
      });

      test('reports correct synced count', () async {
        mockRosterRepository.setSyncResult(
          mockRosterRepository.createMockEntries(10),
        );

        final result = await syncService.performFullSync();

        expect(result.syncedCount, equals(10));
      });

      test('reports correct foundOnPlatform count', () async {
        final entries = mockRosterRepository.createMockEntries(10);
        // Mark 5 entries as having a profile (on platform)
        for (var i = 0; i < 5; i++) {
          entries[i] = entries[i].copyWith(profileId: 'profile_$i');
        }
        mockRosterRepository.setSyncResult(entries);

        final result = await syncService.performFullSync();

        expect(result.foundOnPlatform, equals(5));
      });

      test('returns error result on failure', () async {
        mockRosterRepository.setShouldThrow(true);

        final result = await syncService.performFullSync();

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(result.syncedCount, equals(0));
      });

      test('isSyncing flag is set during sync', () async {
        mockRosterRepository.setSyncResult([]);
        mockRosterRepository.setDelay(const Duration(milliseconds: 100));

        expect(syncService.isSyncing, isFalse);

        final future = syncService.performFullSync();
        await Future.delayed(const Duration(milliseconds: 10));

        expect(syncService.isSyncing, isTrue);

        await future;

        expect(syncService.isSyncing, isFalse);
      });
    });

    group('performIncrementalSync', () {
      test('skips sync when no changes detected', () async {
        mockRosterRepository.setNeedsSync(false);

        final result = await syncService.performIncrementalSync();

        expect(result.success, isTrue);
        expect(result.isIncremental, isTrue);
        expect(result.syncedCount, equals(0));
        expect(mockRosterRepository.syncContactsCalled, isFalse);
      });

      test('performs sync when changes detected', () async {
        mockRosterRepository.setNeedsSync(true);
        mockRosterRepository.setSyncResult([]);

        final result = await syncService.performIncrementalSync();

        expect(result.success, isTrue);
        expect(result.isIncremental, isTrue);
        expect(mockRosterRepository.syncContactsCalled, isTrue);
      });

      test('updates last sync time even when no changes', () async {
        mockRosterRepository.setNeedsSync(false);

        expect(syncService.lastSyncTime, isNull);

        await syncService.performIncrementalSync();

        expect(syncService.lastSyncTime, isNotNull);
      });
    });

    group('performBackgroundSync', () {
      test('skips sync when auto sync is disabled', () async {
        await syncService.setAutoSyncEnabled(false);

        final result = await syncService.performBackgroundSync();

        expect(result.success, isTrue);
        expect(result.syncedCount, equals(0));
        expect(mockRosterRepository.syncContactsCalled, isFalse);
      });

      test('skips sync when not due', () async {
        // Set recent sync time
        await settingsService.setInt(
          ContactSyncSettings.lastSyncTime,
          DateTime.now().millisecondsSinceEpoch,
        );

        // Recreate service
        syncService = ContactSyncService(
          syncRepository: mockRosterRepository,
          settingsService: settingsService,
        );

        final result = await syncService.performBackgroundSync();

        expect(result.success, isTrue);
        expect(result.syncedCount, equals(0));
        expect(mockRosterRepository.syncContactsCalled, isFalse);
      });

      test('performs sync when due', () async {
        mockRosterRepository.setNeedsSync(true);
        mockRosterRepository.setSyncResult([]);

        // Set old sync time
        final oldTime = DateTime.now().subtract(const Duration(hours: 25));
        await settingsService.setInt(
          ContactSyncSettings.lastSyncTime,
          oldTime.millisecondsSinceEpoch,
        );

        // Recreate service
        syncService = ContactSyncService(
          syncRepository: mockRosterRepository,
          settingsService: settingsService,
        );

        final result = await syncService.performBackgroundSync();

        expect(result.success, isTrue);
        expect(mockRosterRepository.syncContactsCalled, isTrue);
      });
    });

    group('syncOnPermissionGrant', () {
      test('enables auto sync', () async {
        await syncService.setAutoSyncEnabled(false);
        mockRosterRepository.setSyncResult([]);

        await syncService.syncOnPermissionGrant();

        expect(syncService.isAutoSyncEnabled, isTrue);
      });

      test('performs full sync', () async {
        mockRosterRepository.setSyncResult([]);

        final result = await syncService.syncOnPermissionGrant();

        expect(result.isIncremental, isFalse);
        expect(mockRosterRepository.syncContactsCalled, isTrue);
      });
    });

    group('getStatus', () {
      test('returns correct status', () async {
        await syncService.setAutoSyncEnabled(true);
        await syncService.setSyncIntervalHours(12);
        await syncService.setSyncOnlyOnWifi(true);

        final status = syncService.getStatus();

        expect(status.isAutoSyncEnabled, isTrue);
        expect(status.syncIntervalHours, equals(12));
        expect(status.syncOnlyOnWifi, isTrue);
        expect(status.isSyncing, isFalse);
      });

      test('nextSyncDescription handles disabled auto sync', () async {
        await syncService.setAutoSyncEnabled(false);

        final status = syncService.getStatus();

        expect(status.nextSyncDescription, equals('Auto sync disabled'));
      });

      test('nextSyncDescription handles never synced', () {
        final status = syncService.getStatus();

        expect(status.nextSyncDescription, equals('Never synced'));
      });

      test('nextSyncDescription handles pending sync', () async {
        // Set old sync time
        final oldTime = DateTime.now().subtract(const Duration(hours: 25));
        await settingsService.setInt(
          ContactSyncSettings.lastSyncTime,
          oldTime.millisecondsSinceEpoch,
        );

        // Recreate service
        syncService = ContactSyncService(
          syncRepository: mockRosterRepository,
          settingsService: settingsService,
        );

        final status = syncService.getStatus();

        expect(status.nextSyncDescription, equals('Sync pending'));
      });
    });
  });

  group('ContactSyncSettings', () {
    test('has all required keys', () {
      expect(ContactSyncSettings.autoSyncEnabled, isNotEmpty);
      expect(ContactSyncSettings.lastSyncTime, isNotEmpty);
      expect(ContactSyncSettings.syncIntervalHours, isNotEmpty);
      expect(ContactSyncSettings.syncOnlyOnWifi, isNotEmpty);
    });

    test('keys are unique', () {
      final keys = [
        ContactSyncSettings.autoSyncEnabled,
        ContactSyncSettings.lastSyncTime,
        ContactSyncSettings.syncIntervalHours,
        ContactSyncSettings.syncOnlyOnWifi,
      ];
      final uniqueKeys = keys.toSet();
      expect(uniqueKeys.length, equals(keys.length));
    });
  });

  group('ContactSyncDefaults', () {
    test('has reasonable defaults', () {
      expect(ContactSyncDefaults.autoSyncEnabled, isTrue);
      expect(ContactSyncDefaults.syncIntervalHours, equals(24));
      expect(ContactSyncDefaults.syncOnlyOnWifi, isFalse);
    });
  });

  group('ContactSyncResult', () {
    test('toString includes all fields', () {
      const result = ContactSyncResult(
        success: true,
        syncedCount: 10,
        foundOnPlatform: 5,
        isIncremental: true,
        duration: Duration(milliseconds: 1234),
      );

      final str = result.toString();

      expect(str, contains('success: true'));
      expect(str, contains('syncedCount: 10'));
      expect(str, contains('foundOnPlatform: 5'));
      expect(str, contains('isIncremental: true'));
      expect(str, contains('1234ms'));
    });

    test('toString includes error when present', () {
      const result = ContactSyncResult(
        success: false,
        syncedCount: 0,
        foundOnPlatform: 0,
        error: 'Test error',
      );

      final str = result.toString();

      expect(str, contains('error: Test error'));
    });
  });
}
