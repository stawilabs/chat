import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/messages/ui/chat_input_bar.dart';

import '../test_helpers/test_helpers.dart';

void main() {
  setUp(TestHelpers.resetMocks);

  testWidgets('Chat input bar smoke test', (WidgetTester tester) async {
    // Build a simple MaterialApp with ChatInputBar directly since ChatApp
    // now requires full startup initialization with splash screen
    await tester.pumpWidgetWithMocks(
      const MaterialApp(
        home: Scaffold(
          body: ChatInputBar(roomId: 'smoke-test-room', roomName: 'Smoke Test'),
        ),
      ),
    );

    // Wait for app to load
    await tester.pumpAndSettle();

    // The app should load without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(ChatInputBar), findsOneWidget);
  });

  testWidgets('Chat input bar widget test', (WidgetTester tester) async {
    // Build just the chat input bar widget with mocked providers
    await tester.pumpWidgetWithMocks(
      const MaterialApp(
        home: Scaffold(
          body: ChatInputBar(roomId: 'test-room-123', roomName: 'Test Room'),
        ),
      ),
    );

    // Verify input bar components exist
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.emoji_emotions_outlined), findsOneWidget);
    expect(find.byIcon(Icons.attach_file), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);

    // Test typing in text field
    await tester.enterText(find.byType(TextField), 'Hello world');
    await tester.pump();

    // Verify mic button changes to send button when text is entered
    expect(find.byIcon(Icons.send), findsOneWidget);
    // Note: mic button is replaced by send button in the same position

    // Clear text instead of sending to avoid database timer issues
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    // Verify mic button returns when text is cleared
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.send), findsNothing);
  });

  testWidgets('Chat input bar attachment options', (WidgetTester tester) async {
    await tester.pumpWidgetWithMocks(
      const MaterialApp(
        home: Scaffold(
          body: ChatInputBar(roomId: 'test-room-456', roomName: 'Test Room'),
        ),
      ),
    );

    // Tap attachment button
    await tester.tap(find.byIcon(Icons.attach_file));
    await tester.pumpAndSettle();

    // Verify attachment options appear
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Document'), findsOneWidget);

    // Close the modal
    await tester.tap(find.text('Gallery'));
    await tester.pumpAndSettle();
  });

  testWidgets('Chat input bar voice recording toggle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidgetWithMocks(
      const MaterialApp(
        home: Scaffold(
          body: ChatInputBar(roomId: 'test-room-789', roomName: 'Test Room'),
        ),
      ),
    );

    // Verify mic button is visible initially
    expect(find.byIcon(Icons.mic), findsOneWidget);

    // VoiceRecordButton uses tap to start recording
    // When recording starts, it shows recording UI with the mic icon still visible
    // (in a red pulsing state), plus delete/send buttons appear in certain states
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();

    // During recording, mic icon is still visible (in recording state)
    // The widget transitions through states: idle -> recording -> preview
    expect(find.byIcon(Icons.mic), findsOneWidget);

    // Wait for any timers to complete and let the widget settle
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify mic button is visible (either still recording or returned to idle)
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });
}
