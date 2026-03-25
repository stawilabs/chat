import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/rooms/ui/group_settings_screen.dart';

import '../test_helpers/test_helpers.dart';

void main() {
  setUp(TestHelpers.resetMocks);

  group('GroupSettingsScreen', () {
    testWidgets('displays group name field', (WidgetTester tester) async {
      await tester.pumpWidgetWithMocks(
        const MaterialApp(
          home: Scaffold(
            body: GroupSettingsScreen(
              roomId: 'test-room-123',
              roomName: 'Test Group',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find a TextField for group name
      expect(find.byType(TextField), findsWidgets);

      // Should have text 'Test Group' as the initial value
      expect(find.text('Test Group'), findsWidgets);
    });

    testWidgets('displays group description field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetWithMocks(
        const MaterialApp(
          home: Scaffold(
            body: GroupSettingsScreen(
              roomId: 'test-room-123',
              roomName: 'Test Group',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find the description hint text
      expect(find.text('Enter group description (optional)'), findsOneWidget);
    });

    testWidgets('displays permission dropdowns', (WidgetTester tester) async {
      await tester.pumpWidgetWithMocks(
        const MaterialApp(
          home: Scaffold(
            body: GroupSettingsScreen(
              roomId: 'test-room-123',
              roomName: 'Test Group',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find the permission section titles
      expect(find.text('Who can edit group info'), findsOneWidget);
      expect(find.text('Who can send messages'), findsOneWidget);
      expect(find.text('Who can add members'), findsOneWidget);

      // Should find the dropdowns (DropdownButton)
      expect(find.byType(DropdownButton<String>), findsNWidgets(3));
    });

    testWidgets('name field enforces character limit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetWithMocks(
        const MaterialApp(
          home: Scaffold(
            body: GroupSettingsScreen(
              roomId: 'test-room-123',
              roomName: 'Test Group',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the name text field (first TextField)
      final nameField = find.byType(TextField).first;

      // Enter a long name (100 characters is the limit)
      await tester.enterText(nameField, 'A' * 100);
      await tester.pump();

      // The counter should show 100/100
      expect(find.text('100/100'), findsOneWidget);
    });

    testWidgets('shows save button when changes are made', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetWithMocks(
        const MaterialApp(
          home: Scaffold(
            body: GroupSettingsScreen(
              roomId: 'test-room-123',
              roomName: 'Test Group',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, save button should not be visible
      expect(find.text('Save'), findsNothing);

      // Find the name text field (first TextField) and change the text
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Updated Group Name');
      await tester.pump();

      // Now save button should be visible
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('displays section headers', (WidgetTester tester) async {
      await tester.pumpWidgetWithMocks(
        const MaterialApp(
          home: Scaffold(
            body: GroupSettingsScreen(
              roomId: 'test-room-123',
              roomName: 'Test Group',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find the section headers
      expect(find.text('Group Name'), findsOneWidget);
      expect(find.text('Group Description'), findsOneWidget);
      expect(find.text('Group Permissions'), findsOneWidget);
    });

    testWidgets('app bar displays correct title', (WidgetTester tester) async {
      await tester.pumpWidgetWithMocks(
        const MaterialApp(
          home: Scaffold(
            body: GroupSettingsScreen(
              roomId: 'test-room-123',
              roomName: 'Test Group',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find the app bar title
      expect(find.text('Group Settings'), findsOneWidget);
    });

    testWidgets('dropdown shows options when tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetWithMocks(
        const MaterialApp(
          home: Scaffold(
            body: GroupSettingsScreen(
              roomId: 'test-room-123',
              roomName: 'Test Group',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the first dropdown and tap it
      final dropdown = find.byType(DropdownButton<String>).first;
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Should show dropdown options
      expect(find.text('Only admins'), findsWidgets);
      expect(find.text('All members'), findsWidgets);
    });
  });
}
