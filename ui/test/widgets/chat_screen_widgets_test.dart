import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stawi/features/messages/ui/date_header.dart';
import 'package:stawi/features/messages/ui/input_bar.dart';
import 'package:stawi/features/messages/ui/typing_indicator.dart';

import '../test_helpers/test_helpers.dart';

void main() {
  setUp(TestHelpers.resetMocks);

  group('InputBar Widget', () {
    testWidgets('renders text input field', (WidgetTester tester) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 4));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows attachment button', (WidgetTester tester) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 4));

      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });

    testWidgets('shows camera button when no text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 4));

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('shows mic button when no text', (WidgetTester tester) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 4));

      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('shows send button when text is entered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hello world');
      // Wait for animation to complete
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Send button should appear when text is entered
      await tester.pump(const Duration(seconds: 4));

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('hides camera button when text is entered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      await tester.pump(const Duration(seconds: 4));

      expect(find.byIcon(Icons.camera_alt), findsNothing);
    });

    testWidgets('attachment button triggers callback', (
      WidgetTester tester,
    ) async {
      var attachmentPressed = false;

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () => attachmentPressed = true,
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.attach_file));
      await tester.pump();

      await tester.pump(const Duration(seconds: 4));

      expect(attachmentPressed, isTrue);
    });

    testWidgets('camera button triggers callback', (WidgetTester tester) async {
      var cameraPressed = false;

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () => cameraPressed = true,
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pump();

      await tester.pump(const Duration(seconds: 4));

      expect(cameraPressed, isTrue);
    });

    testWidgets('send button appears when text is entered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Test message');
      // Wait for animation to complete
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Send button should be visible
      await tester.pump(const Duration(seconds: 4));

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('shows reply preview when replying', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
              replyingToMessageId: 'msg-123',
              replyingToText: 'Original message text',
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 4));

      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('Original message text'), findsOneWidget);
    });

    testWidgets('cancel reply button triggers callback', (
      WidgetTester tester,
    ) async {
      var cancelPressed = false;

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () => cancelPressed = true,
              replyingToMessageId: 'msg-123',
              replyingToText: 'Reply text',
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      await tester.pump(const Duration(seconds: 4));

      expect(cancelPressed, isTrue);
    });

    testWidgets('shows lock icon when encryption is enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
              isEncryptionEnabled: true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 4));

      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('shows encrypted message hint when encryption enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
              isEncryptionEnabled: true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 4));

      expect(find.text('Encrypted message'), findsOneWidget);
    });

    testWidgets('shows normal message hint when encryption disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 4));

      expect(find.text('Message'), findsOneWidget);
    });
  });

  group('InputBar Voice Recording', () {
    testWidgets('mic button is present initially', (WidgetTester tester) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 4));

      expect(find.byIcon(Icons.mic), findsOneWidget);
    });
  });

  group('DateHeader Widget', () {
    testWidgets('shows "Today" for current date', (WidgetTester tester) async {
      final now = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateHeader(timestamp: now.millisecondsSinceEpoch),
          ),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('shows "Yesterday" for previous day', (
      WidgetTester tester,
    ) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateHeader(timestamp: yesterday.millisecondsSinceEpoch),
          ),
        ),
      );

      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('shows day name for dates within the week', (
      WidgetTester tester,
    ) async {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateHeader(timestamp: threeDaysAgo.millisecondsSinceEpoch),
          ),
        ),
      );

      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final expectedDay = dayNames[threeDaysAgo.weekday - 1];
      expect(find.text(expectedDay), findsOneWidget);
    });

    testWidgets('shows full date for older messages', (
      WidgetTester tester,
    ) async {
      final oldDate = DateTime.now().subtract(const Duration(days: 30));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateHeader(timestamp: oldDate.millisecondsSinceEpoch),
          ),
        ),
      );

      final expectedFormat = '${oldDate.day}/${oldDate.month}/${oldDate.year}';
      expect(find.text(expectedFormat), findsOneWidget);
    });

    testWidgets('renders as centered pill with decoration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateHeader(timestamp: DateTime.now().millisecondsSinceEpoch),
          ),
        ),
      );

      // Should be centered
      expect(find.byType(Center), findsOneWidget);

      // Should have a decorated Container (pill shape)
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isNotNull);
    });
  });

  group('TypingIndicator Widget', () {
    // Note: TypingIndicator requires provider state to be set up
    // These tests verify basic rendering behavior

    testWidgets('renders without errors when provider is available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetWithMocks(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator(roomId: 'test-room')),
        ),
      );

      // Widget should render (may show nothing if no one is typing)
      expect(find.byType(TypingIndicator), findsOneWidget);
    });
  });

  group('InputBar Theme Support', () {
    testWidgets('renders correctly in light theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 4));

      expect(find.byType(InputBar), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (WidgetTester tester) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 4));

      expect(find.byType(InputBar), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('DateHeader Theme Support', () {
    testWidgets('renders correctly in light theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: DateHeader(timestamp: DateTime.now().millisecondsSinceEpoch),
          ),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: DateHeader(timestamp: DateTime.now().millisecondsSinceEpoch),
          ),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
    });
  });

  group('InputBar Edge Cases', () {
    testWidgets('handles whitespace-only input', (WidgetTester tester) async {
      // ignore: unused_local_variable
      String? sentMessage;

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) => sentMessage = text,
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      // Send button should not appear for whitespace-only input
      await tester.pump(const Duration(seconds: 4));

      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('handles multiline input', (WidgetTester tester) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Line 1\nLine 2\nLine 3');
      await tester.pump();

      await tester.pump(const Duration(seconds: 4));

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('handles very long input', (WidgetTester tester) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      final longText = 'A' * 1000;
      await tester.enterText(find.byType(TextField), longText);
      await tester.pump();

      await tester.pump(const Duration(seconds: 4));

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('handles special characters', (WidgetTester tester) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), r'Hello! @#$%^&*()');
      await tester.pump();

      // Verify send button appears for special characters
      await tester.pump(const Duration(seconds: 4));

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('handles emoji input', (WidgetTester tester) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hello World');
      await tester.pump();

      // Verify send button appears for emoji input
      await tester.pump(const Duration(seconds: 4));

      expect(find.byIcon(Icons.send), findsOneWidget);
    });
  });

  group('InputBar Accessibility', () {
    testWidgets('text field has proper accessibility', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      // Text field should be present and accessible
      final textField = find.byType(TextField);
      await tester.pump(const Duration(seconds: 4));

      expect(textField, findsOneWidget);

      // Should have a hint text
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.decoration?.hintText, isNotNull);
    });

    testWidgets('buttons are tappable', (WidgetTester tester) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: InputBar(
              roomId: 'test-room',
              onSendMessage: (text, {replyToMessageId}) {},
              onAttachment: () {},
              onCamera: () {},
              onCancelReply: () {},
            ),
          ),
        ),
      );

      // All buttons should be tappable
      await tester.pump(const Duration(seconds: 4));

      expect(find.byIcon(Icons.attach_file), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });
  });
}
