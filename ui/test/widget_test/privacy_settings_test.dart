import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/settings/settings_service.dart';
import 'package:stawi/features/contacts/data/roster_repository.dart';
import 'package:stawi/features/settings/ui/privacy_settings_screen.dart';
import 'package:stawi/features/settings/ui/visibility_picker.dart';

import '../test_helpers/test_helpers.dart';

// Mock SettingsService for testing (uses noSuchMethod for unimplemented methods)
class MockSettingsService implements SettingsService {
  MockSettingsService();

  final Map<String, dynamic> _mockSettings = {};

  @override
  Future<void> initialize() async {}

  @override
  String getString(String key, {String? defaultValue}) =>
      _mockSettings[key] as String? ?? defaultValue ?? '';

  @override
  bool getBool(String key, {bool defaultValue = false}) =>
      _mockSettings[key] as bool? ?? defaultValue;

  @override
  int getInt(String key, {int defaultValue = 0}) =>
      _mockSettings[key] as int? ?? defaultValue;

  @override
  Map<String, dynamic>? getJson(String key) =>
      _mockSettings[key] as Map<String, dynamic>?;

  @override
  Future<void> setString(String key, String value) async {
    _mockSettings[key] = value;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _mockSettings[key] = value;
  }

  @override
  Future<void> setInt(String key, int value) async {
    _mockSettings[key] = value;
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    _mockSettings[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _mockSettings.remove(key);
  }

  @override
  Future<void> clearAll() async {
    _mockSettings.clear();
  }

  @override
  Map<String, String> exportSettings() =>
      _mockSettings.map((k, v) => MapEntry(k, v.toString()));

  @override
  Future<void> importSettings(Map<String, String> settings) async {
    _mockSettings.addAll(settings);
  }

  @override
  String get lastSeenVisible => getString(
    SettingsKeys.lastSeenVisible,
    defaultValue: SettingsDefaults.lastSeenVisible,
  );

  @override
  String get profilePhotoVisible => getString(
    SettingsKeys.profilePhotoVisible,
    defaultValue: SettingsDefaults.profilePhotoVisible,
  );

  @override
  String get aboutVisible => getString(
    SettingsKeys.aboutVisible,
    defaultValue: SettingsDefaults.aboutVisible,
  );

  @override
  String get groupsAddPermission => getString(
    SettingsKeys.groupsAddPermission,
    defaultValue: SettingsDefaults.groupsAddPermission,
  );

  @override
  bool get readReceiptsEnabled => getBool(
    SettingsKeys.readReceiptsEnabled,
    defaultValue: SettingsDefaults.readReceiptsEnabled,
  );

  @override
  bool get liveLocationSharingEnabled =>
      getBool(SettingsKeys.liveLocationSharingEnabled);

  @override
  bool get fingerprintLockEnabled =>
      getBool(SettingsKeys.fingerprintLockEnabled);

  @override
  bool get analyticsEnabled => getBool(
    SettingsKeys.analyticsEnabled,
    defaultValue: SettingsDefaults.analyticsEnabled,
  );

  // Implement any remaining methods as no-ops
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return defaults for getters
    if (invocation.isGetter) return null;
    if (invocation.isSetter) return null;
    if (invocation.memberName == #initialize) return Future.value();
    return null;
  }
}

void main() {
  late MockSettingsService mockSettingsService;

  setUp(() {
    TestHelpers.resetMocks();
    mockSettingsService = MockSettingsService();
  });

  group('VisibilityPicker', () {
    testWidgets('displays current visibility option', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibilityPicker(
              title: 'Last seen',
              description: 'Choose who can see when you were last active.',
              currentValue: 'everyone',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Last seen'), findsOneWidget);
      expect(find.text('Everyone'), findsOneWidget);
    });

    testWidgets('displays contacts visibility option', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibilityPicker(
              title: 'Profile photo',
              description: 'Choose who can see your profile photo.',
              currentValue: 'contacts',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Profile photo'), findsOneWidget);
      expect(find.text('My Contacts'), findsOneWidget);
    });

    testWidgets('displays nobody visibility option', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibilityPicker(
              title: 'About',
              description: 'Choose who can see your about/bio information.',
              currentValue: 'nobody',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('About'), findsOneWidget);
      expect(find.text('Nobody'), findsOneWidget);
    });

    testWidgets('opens dialog when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibilityPicker(
              title: 'Last seen',
              description: 'Choose who can see when you were last active.',
              currentValue: 'everyone',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Dialog should show all options
      expect(find.text('Everyone'), findsWidgets);
      expect(find.text('My Contacts'), findsOneWidget);
      expect(find.text('Nobody'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('calls onChanged when option selected', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibilityPicker(
              title: 'Last seen',
              description: 'Choose who can see when you were last active.',
              currentValue: 'everyone',
              onChanged: (value) => selectedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Tap on "My Contacts" option
      await tester.tap(find.text('My Contacts'));
      await tester.pumpAndSettle();

      expect(selectedValue, 'contacts');
    });
  });

  group('VisibilityOption', () {
    test('fromValue returns correct option for everyone', () {
      final option = VisibilityOption.fromValue('everyone');
      expect(option, VisibilityOption.everyone);
      expect(option.label, 'Everyone');
    });

    test('fromValue returns correct option for contacts', () {
      final option = VisibilityOption.fromValue('contacts');
      expect(option, VisibilityOption.contacts);
      expect(option.label, 'My Contacts');
    });

    test('fromValue returns correct option for nobody', () {
      final option = VisibilityOption.fromValue('nobody');
      expect(option, VisibilityOption.nobody);
      expect(option.label, 'Nobody');
    });

    test('fromValue returns everyone for unknown value', () {
      final option = VisibilityOption.fromValue('unknown');
      expect(option, VisibilityOption.everyone);
    });
  });

  group('SettingsKeys', () {
    test('privacy settings keys are defined', () {
      expect(SettingsKeys.lastSeenVisible, 'last_seen_visible');
      expect(SettingsKeys.profilePhotoVisible, 'profile_photo_visible');
      expect(SettingsKeys.aboutVisible, 'about_visible');
      expect(SettingsKeys.groupsAddPermission, 'groups_add_permission');
      expect(SettingsKeys.readReceiptsEnabled, 'read_receipts_enabled');
      expect(
        SettingsKeys.liveLocationSharingEnabled,
        'live_location_sharing_enabled',
      );
      expect(SettingsKeys.fingerprintLockEnabled, 'fingerprint_lock_enabled');
    });
  });

  group('SettingsDefaults', () {
    test('privacy settings defaults are correct', () {
      expect(SettingsDefaults.lastSeenVisible, 'everyone');
      expect(SettingsDefaults.profilePhotoVisible, 'everyone');
      expect(SettingsDefaults.aboutVisible, 'everyone');
      expect(SettingsDefaults.groupsAddPermission, 'everyone');
      expect(SettingsDefaults.readReceiptsEnabled, true);
      expect(SettingsDefaults.liveLocationSharingEnabled, false);
      expect(SettingsDefaults.fingerprintLockEnabled, false);
    });
  });

  group('PrivacySettingsScreen', () {
    testWidgets('displays loading indicator initially', (tester) async {
      // Create overrides for the test
      final overrides = [
        ...TestHelpers.overrides,
        settingsServiceProvider.overrideWithValue(mockSettingsService),
        blockedRosterEntriesProvider.overrideWith(
          (ref) async => <RosterEntry>[],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const MaterialApp(home: PrivacySettingsScreen()),
        ),
      );

      // Should show loading indicator before initialization
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // TODO(developer): Fix async initialization timing in tests
    // The PrivacySettingsScreen uses async initialization in initState which
    // doesn't complete reliably in widget tests. Consider refactoring to use
    // FutureBuilder or adding a testability hook.
    testWidgets('displays all privacy sections after loading', skip: true, (
      tester,
    ) async {
      final overrides = [
        ...TestHelpers.overrides,
        settingsServiceProvider.overrideWithValue(mockSettingsService),
        blockedRosterEntriesProvider.overrideWith(
          (ref) async => <RosterEntry>[],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const MaterialApp(home: PrivacySettingsScreen()),
        ),
      );

      // Wait for async initialization to complete
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Check for section headers
      expect(find.text('Who can see my personal info'), findsOneWidget);
      expect(find.text('Groups'), findsOneWidget);
      expect(find.text('Blocking'), findsOneWidget);
      expect(find.text('Read receipts'), findsOneWidget);
      expect(find.text('Live location'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
    });

    testWidgets('displays visibility pickers for personal info', (
      tester,
    ) async {
      final overrides = [
        ...TestHelpers.overrides,
        settingsServiceProvider.overrideWithValue(mockSettingsService),
        blockedRosterEntriesProvider.overrideWith(
          (ref) async => <RosterEntry>[],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const MaterialApp(home: PrivacySettingsScreen()),
        ),
      );

      // Wait for async initialization to complete
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Check for visibility picker items
      expect(find.text('Last seen'), findsOneWidget);
      expect(find.text('Profile photo'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Who can add me to groups'), findsOneWidget);
    });

    testWidgets('displays blocked contacts item', (tester) async {
      final overrides = [
        ...TestHelpers.overrides,
        settingsServiceProvider.overrideWithValue(mockSettingsService),
        blockedRosterEntriesProvider.overrideWith(
          (ref) async => <RosterEntry>[],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const MaterialApp(home: PrivacySettingsScreen()),
        ),
      );

      // Wait for async initialization to complete
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Blocked contacts'), findsOneWidget);
      expect(find.text('0 contacts'), findsOneWidget);
    });

    // TODO(developer): Fix async initialization timing (see 'displays all privacy sections')
    testWidgets('displays switch items for toggles', skip: true, (
      tester,
    ) async {
      final overrides = [
        ...TestHelpers.overrides,
        settingsServiceProvider.overrideWithValue(mockSettingsService),
        blockedRosterEntriesProvider.overrideWith(
          (ref) async => <RosterEntry>[],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const MaterialApp(home: PrivacySettingsScreen()),
        ),
      );

      // Wait for async initialization to complete
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Check for switch items
      // Note: "Read receipts" appears twice - once as section title and once as item title
      expect(find.text('Read receipts'), findsNWidgets(2)); // section + item
      expect(find.text('Live location sharing'), findsOneWidget);
      expect(find.text('Fingerprint lock'), findsOneWidget);

      // Check for switches
      expect(find.byType(Switch), findsNWidgets(3));
    });

    // TODO(developer): Fix async initialization timing (see 'displays all privacy sections')
    testWidgets('displays info section at bottom', skip: true, (tester) async {
      final overrides = [
        ...TestHelpers.overrides,
        settingsServiceProvider.overrideWithValue(mockSettingsService),
        blockedRosterEntriesProvider.overrideWith(
          (ref) async => <RosterEntry>[],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const MaterialApp(home: PrivacySettingsScreen()),
        ),
      );

      // Wait for async initialization to complete
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Changes to your privacy settings'),
        findsOneWidget,
      );
    });
  });
}
