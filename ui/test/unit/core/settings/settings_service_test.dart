import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/db/database.dart';
import 'package:stawi/core/settings/settings_service.dart';

import '../../../test_helpers/test_database.dart';

void main() {
  late AppDatabase testDb;
  late SettingsService settingsService;

  setUp(() {
    testDb = createTestDatabase();
    settingsService = SettingsService(testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  group('SettingsService', () {
    group('initialization', () {
      test('initialize loads settings from database', () async {
        // Pre-populate database with a setting
        await testDb
            .into(testDb.userSettings)
            .insert(
              UserSettingsCompanion.insert(
                key: 'test_key',
                value: 'test_value',
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );

        await settingsService.initialize();

        expect(settingsService.getString('test_key'), equals('test_value'));
      });

      test('initialize only runs once', () async {
        await settingsService.initialize();
        await settingsService.initialize(); // Should be no-op

        // Should not throw
        expect(true, isTrue);
      });

      test('initialize handles empty database', () async {
        await settingsService.initialize();
        expect(settingsService.getString('nonexistent'), equals(''));
      });
    });

    group('getString', () {
      test('returns cached value', () async {
        await settingsService.setString('key', 'value');
        expect(settingsService.getString('key'), equals('value'));
      });

      test('returns default value when key not found', () {
        expect(
          settingsService.getString('missing', defaultValue: 'default'),
          equals('default'),
        );
      });

      test('returns empty string when no default provided', () {
        expect(settingsService.getString('missing'), equals(''));
      });
    });

    group('getBool', () {
      test('returns true for "true" string', () async {
        await settingsService.setBool('bool_key', true);
        expect(settingsService.getBool('bool_key'), isTrue);
      });

      test('returns false for "false" string', () async {
        await settingsService.setBool('bool_key', false);
        expect(settingsService.getBool('bool_key'), isFalse);
      });

      test('returns true for "1" string', () async {
        await settingsService.setString('bool_key', '1');
        expect(settingsService.getBool('bool_key'), isTrue);
      });

      test('returns default value when key not found', () {
        expect(settingsService.getBool('missing', defaultValue: true), isTrue);
      });

      test('returns false when no default provided', () {
        expect(settingsService.getBool('missing'), isFalse);
      });
    });

    group('getInt', () {
      test('returns parsed integer', () async {
        await settingsService.setInt('int_key', 42);
        expect(settingsService.getInt('int_key'), equals(42));
      });

      test('returns default value for invalid integer', () async {
        await settingsService.setString('int_key', 'not_a_number');
        expect(settingsService.getInt('int_key'), equals(0));
      });

      test('returns default value when key not found', () {
        expect(
          settingsService.getInt('missing', defaultValue: 100),
          equals(100),
        );
      });
    });

    group('getJson', () {
      test('returns parsed JSON map', () async {
        await settingsService.setJson('json_key', {'name': 'test', 'count': 5});
        final result = settingsService.getJson('json_key');
        expect(result, isNotNull);
        expect(result!['name'], equals('test'));
        expect(result['count'], equals(5));
      });

      test('returns null for invalid JSON', () async {
        await settingsService.setString('json_key', 'invalid json');
        expect(settingsService.getJson('json_key'), isNull);
      });

      test('returns null when key not found', () {
        expect(settingsService.getJson('missing'), isNull);
      });
    });

    group('setString', () {
      test('updates cache immediately', () async {
        await settingsService.setString('key', 'value');
        expect(settingsService.getString('key'), equals('value'));
      });

      test('persists to database', () async {
        await settingsService.setString('key', 'value');

        // Verify in database
        final stored = await (testDb.select(
          testDb.userSettings,
        )..where((s) => s.key.equals('key'))).getSingle();
        expect(stored.value, equals('value'));
      });

      test('updates existing value', () async {
        await settingsService.setString('key', 'old_value');
        await settingsService.setString('key', 'new_value');

        expect(settingsService.getString('key'), equals('new_value'));

        // Verify only one entry in database
        final entries = await (testDb.select(
          testDb.userSettings,
        )..where((s) => s.key.equals('key'))).get();
        expect(entries.length, equals(1));
        expect(entries.first.value, equals('new_value'));
      });
    });

    group('remove', () {
      test('removes from cache', () async {
        await settingsService.setString('key', 'value');
        await settingsService.remove('key');
        expect(settingsService.getString('key'), equals(''));
      });

      test('removes from database', () async {
        await settingsService.setString('key', 'value');
        await settingsService.remove('key');

        final entries = await (testDb.select(
          testDb.userSettings,
        )..where((s) => s.key.equals('key'))).get();
        expect(entries, isEmpty);
      });
    });

    group('clearAll', () {
      test('clears all settings from cache', () async {
        await settingsService.setString('key1', 'value1');
        await settingsService.setString('key2', 'value2');
        await settingsService.clearAll();

        expect(settingsService.getString('key1'), equals(''));
        expect(settingsService.getString('key2'), equals(''));
      });

      test('clears all settings from database', () async {
        await settingsService.setString('key1', 'value1');
        await settingsService.setString('key2', 'value2');
        await settingsService.clearAll();

        final entries = await testDb.select(testDb.userSettings).get();
        expect(entries, isEmpty);
      });
    });

    group('exportSettings', () {
      test('returns all cached settings', () async {
        await settingsService.setString('key1', 'value1');
        await settingsService.setString('key2', 'value2');

        final exported = settingsService.exportSettings();

        expect(exported['key1'], equals('value1'));
        expect(exported['key2'], equals('value2'));
      });

      test('returns copy of settings', () async {
        await settingsService.setString('key', 'value');
        final exported = settingsService.exportSettings();

        // Modifying exported should not affect original
        exported['key'] = 'modified';
        expect(settingsService.getString('key'), equals('value'));
      });
    });

    group('importSettings', () {
      test('imports all settings', () async {
        await settingsService.importSettings({
          'key1': 'value1',
          'key2': 'value2',
        });

        expect(settingsService.getString('key1'), equals('value1'));
        expect(settingsService.getString('key2'), equals('value2'));
      });

      test('persists imported settings to database', () async {
        await settingsService.importSettings({'key': 'value'});

        final stored = await (testDb.select(
          testDb.userSettings,
        )..where((s) => s.key.equals('key'))).getSingle();
        expect(stored.value, equals('value'));
      });

      test('imports empty settings map', () async {
        await settingsService.setString('existing', 'value');
        await settingsService.importSettings({});

        // Existing settings should remain
        expect(settingsService.getString('existing'), equals('value'));
      });

      test('overwrites existing settings on import', () async {
        await settingsService.setString('key', 'old_value');
        await settingsService.importSettings({'key': 'new_value'});

        expect(settingsService.getString('key'), equals('new_value'));
      });

      test('imports boolean settings as strings', () async {
        await settingsService.importSettings({
          'bool_true': 'true',
          'bool_false': 'false',
        });

        expect(settingsService.getBool('bool_true'), isTrue);
        expect(settingsService.getBool('bool_false'), isFalse);
      });

      test('imports integer settings as strings', () async {
        await settingsService.importSettings({
          'int_positive': '42',
          'int_zero': '0',
          'int_negative': '-10',
        });

        expect(settingsService.getInt('int_positive'), equals(42));
        expect(settingsService.getInt('int_zero'), equals(0));
        expect(settingsService.getInt('int_negative'), equals(-10));
      });

      test('imports JSON settings as encoded strings', () async {
        await settingsService.importSettings({
          'json_data': '{"name":"test","count":5}',
        });

        final json = settingsService.getJson('json_data');
        expect(json, isNotNull);
        expect(json!['name'], equals('test'));
        expect(json['count'], equals(5));
      });

      test('preserves existing settings not in import', () async {
        await settingsService.setString('unchanged', 'stays');
        await settingsService.importSettings({'new_key': 'new_value'});

        expect(settingsService.getString('unchanged'), equals('stays'));
        expect(settingsService.getString('new_key'), equals('new_value'));
      });
    });

    group('export/import roundtrip', () {
      test('exported settings can be reimported', () async {
        await settingsService.setString('str', 'value');
        await settingsService.setBool('bool', true);
        await settingsService.setInt('int', 42);
        await settingsService.setJson('json', {'key': 'value'});

        final exported = settingsService.exportSettings();

        // Clear and reimport
        await settingsService.clearAll();
        await settingsService.importSettings(exported);

        expect(settingsService.getString('str'), equals('value'));
        expect(settingsService.getBool('bool'), isTrue);
        expect(settingsService.getInt('int'), equals(42));
        expect(settingsService.getJson('json')!['key'], equals('value'));
      });

      test('roundtrip preserves all typed settings', () async {
        // Set all typed settings
        await settingsService.setThemeMode('dark');
        await settingsService.setFontSize('large');
        await settingsService.setNotificationSound(false);
        await settingsService.setAutoDownloadWifi(false);
        await settingsService.setLockTimeoutMinutes(15);
        await settingsService.setBackupFrequency('daily');

        final exported = settingsService.exportSettings();
        await settingsService.clearAll();
        await settingsService.importSettings(exported);

        expect(settingsService.themeMode, equals('dark'));
        expect(settingsService.fontSize, equals('large'));
        expect(settingsService.notificationSound, isFalse);
        expect(settingsService.autoDownloadWifi, isFalse);
        expect(settingsService.lockTimeoutMinutes, equals(15));
        expect(settingsService.backupFrequency, equals('daily'));
      });

      test('multiple export/import cycles preserve data', () async {
        await settingsService.setString('key', 'original');

        for (var i = 0; i < 3; i++) {
          final exported = settingsService.exportSettings();
          await settingsService.clearAll();
          await settingsService.importSettings(exported);
        }

        expect(settingsService.getString('key'), equals('original'));
      });
    });

    group('typed convenience getters/setters', () {
      test('themeMode getter and setter', () async {
        expect(settingsService.themeMode, equals(SettingsDefaults.themeMode));

        await settingsService.setThemeMode('dark');
        expect(settingsService.themeMode, equals('dark'));
      });

      test('fontSize getter and setter', () async {
        expect(settingsService.fontSize, equals(SettingsDefaults.fontSize));

        await settingsService.setFontSize('large');
        expect(settingsService.fontSize, equals('large'));
      });

      test('notificationSound getter and setter', () async {
        expect(
          settingsService.notificationSound,
          equals(SettingsDefaults.notificationSound),
        );

        await settingsService.setNotificationSound(false);
        expect(settingsService.notificationSound, isFalse);
      });

      test('notificationVibrate getter and setter', () async {
        expect(
          settingsService.notificationVibrate,
          equals(SettingsDefaults.notificationVibrate),
        );

        await settingsService.setNotificationVibrate(false);
        expect(settingsService.notificationVibrate, isFalse);
      });

      test('autoDownloadWifi getter and setter', () async {
        expect(
          settingsService.autoDownloadWifi,
          equals(SettingsDefaults.autoDownloadWifi),
        );

        await settingsService.setAutoDownloadWifi(false);
        expect(settingsService.autoDownloadWifi, isFalse);
      });

      test('autoDownloadMobile getter and setter', () async {
        expect(
          settingsService.autoDownloadMobile,
          equals(SettingsDefaults.autoDownloadMobile),
        );

        await settingsService.setAutoDownloadMobile(true);
        expect(settingsService.autoDownloadMobile, isTrue);
      });

      test('readReceiptsEnabled getter and setter', () async {
        expect(
          settingsService.readReceiptsEnabled,
          equals(SettingsDefaults.readReceiptsEnabled),
        );

        await settingsService.setReadReceiptsEnabled(false);
        expect(settingsService.readReceiptsEnabled, isFalse);
      });

      test('typingIndicatorsEnabled getter and setter', () async {
        expect(
          settingsService.typingIndicatorsEnabled,
          equals(SettingsDefaults.typingIndicatorsEnabled),
        );

        await settingsService.setTypingIndicatorsEnabled(false);
        expect(settingsService.typingIndicatorsEnabled, isFalse);
      });

      test('lastSeenVisible getter and setter', () async {
        expect(
          settingsService.lastSeenVisible,
          equals(SettingsDefaults.lastSeenVisible),
        );

        await settingsService.setLastSeenVisible('contacts');
        expect(settingsService.lastSeenVisible, equals('contacts'));
      });

      test('profilePhotoVisible getter and setter', () async {
        expect(
          settingsService.profilePhotoVisible,
          equals(SettingsDefaults.profilePhotoVisible),
        );

        await settingsService.setProfilePhotoVisible('nobody');
        expect(settingsService.profilePhotoVisible, equals('nobody'));
      });

      test('aboutVisible getter and setter', () async {
        expect(
          settingsService.aboutVisible,
          equals(SettingsDefaults.aboutVisible),
        );

        await settingsService.setAboutVisible('contacts');
        expect(settingsService.aboutVisible, equals('contacts'));
      });

      test('groupsAddPermission getter and setter', () async {
        expect(
          settingsService.groupsAddPermission,
          equals(SettingsDefaults.groupsAddPermission),
        );

        await settingsService.setGroupsAddPermission('contacts');
        expect(settingsService.groupsAddPermission, equals('contacts'));
      });

      test('biometricEnabled getter and setter', () async {
        expect(
          settingsService.biometricEnabled,
          equals(SettingsDefaults.biometricEnabled),
        );

        await settingsService.setBiometricEnabled(true);
        expect(settingsService.biometricEnabled, isTrue);
      });

      test('lockTimeoutMinutes getter and setter', () async {
        expect(
          settingsService.lockTimeoutMinutes,
          equals(SettingsDefaults.lockTimeoutMinutes),
        );

        await settingsService.setLockTimeoutMinutes(5);
        expect(settingsService.lockTimeoutMinutes, equals(5));
      });

      test('backupEnabled getter and setter', () async {
        expect(
          settingsService.backupEnabled,
          equals(SettingsDefaults.backupEnabled),
        );

        await settingsService.setBackupEnabled(true);
        expect(settingsService.backupEnabled, isTrue);
      });

      test('backupFrequency getter and setter', () async {
        expect(
          settingsService.backupFrequency,
          equals(SettingsDefaults.backupFrequency),
        );

        await settingsService.setBackupFrequency('daily');
        expect(settingsService.backupFrequency, equals('daily'));
      });

      test('chatWallpaper getter and setter', () async {
        // Initially null when not set
        expect(settingsService.chatWallpaper, isNull);

        await settingsService.setChatWallpaper('/path/to/wallpaper.jpg');
        expect(settingsService.chatWallpaper, equals('/path/to/wallpaper.jpg'));

        // Test removal - returns null when removed
        await settingsService.setChatWallpaper(null);
        expect(settingsService.chatWallpaper, isNull);
      });

      test('accentColor getter and setter', () async {
        // Initially null when not set
        expect(settingsService.accentColor, isNull);

        await settingsService.setAccentColor('#FF5733');
        expect(settingsService.accentColor, equals('#FF5733'));

        // Test removal - returns null when removed
        await settingsService.setAccentColor(null);
        expect(settingsService.accentColor, isNull);
      });
    });
  });

  group('SettingsKeys', () {
    test('all keys are unique', () {
      final keys = [
        SettingsKeys.themeMode,
        SettingsKeys.fontSize,
        SettingsKeys.chatWallpaper,
        SettingsKeys.accentColor,
        SettingsKeys.notificationSound,
        SettingsKeys.notificationVibrate,
        SettingsKeys.autoDownloadWifi,
        SettingsKeys.autoDownloadMobile,
        SettingsKeys.readReceiptsEnabled,
        SettingsKeys.typingIndicatorsEnabled,
        SettingsKeys.lastSeenVisible,
        SettingsKeys.profilePhotoVisible,
        SettingsKeys.aboutVisible,
        SettingsKeys.groupsAddPermission,
        SettingsKeys.biometricEnabled,
        SettingsKeys.lockTimeoutMinutes,
        SettingsKeys.backupEnabled,
        SettingsKeys.backupFrequency,
      ];

      final uniqueKeys = keys.toSet();
      expect(uniqueKeys.length, equals(keys.length));
    });
  });

  group('SettingsDefaults', () {
    test('has reasonable defaults', () {
      expect(SettingsDefaults.themeMode, equals('system'));
      expect(SettingsDefaults.fontSize, equals('medium'));
      expect(SettingsDefaults.notificationSound, isTrue);
      expect(SettingsDefaults.notificationVibrate, isTrue);
      expect(SettingsDefaults.autoDownloadWifi, isTrue);
      expect(SettingsDefaults.autoDownloadMobile, isFalse);
      expect(SettingsDefaults.readReceiptsEnabled, isTrue);
      expect(SettingsDefaults.typingIndicatorsEnabled, isTrue);
      expect(SettingsDefaults.lastSeenVisible, equals('everyone'));
      expect(SettingsDefaults.profilePhotoVisible, equals('everyone'));
      expect(SettingsDefaults.aboutVisible, equals('everyone'));
      expect(SettingsDefaults.groupsAddPermission, equals('everyone'));
      expect(SettingsDefaults.biometricEnabled, isFalse);
      expect(SettingsDefaults.lockTimeoutMinutes, equals(1));
      expect(SettingsDefaults.backupEnabled, isFalse);
      expect(SettingsDefaults.backupFrequency, equals('weekly'));
    });
  });

  group('Providers', () {
    test('settingsServiceProvider is available', () {
      expect(settingsServiceProvider, isNotNull);
    });

    test('settingsInitializedProvider is available', () {
      expect(settingsInitializedProvider, isNotNull);
    });
  });
}
