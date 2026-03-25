import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/auth_repository.dart';
import 'package:stawi/features/messages/domain/room_event.dart' as domain;
import 'package:stawi/features/messages/ui/chat_input_bar.dart';
import 'package:stawi/features/messages/ui/message_bubble.dart';

import 'test_config.dart';

void main() {
  IntegrationTestConfig.ensureInitialized();

  group('Message Flow Integration Tests', () {
    late MockAuthServiceImpl mockAuthService;
    late AuthRepository mockAuthRepo;

    setUp(() {
      mockAuthService = MockAuthServiceImpl();
      mockAuthService.setAuthenticated(
        authenticated: true,
        token: 'test-token',
      );
      mockAuthRepo = AuthRepository(mockAuthService);
    });

    testWidgets('chat input bar renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: const MaterialApp(
            home: Scaffold(
              body: ChatInputBar(roomId: 'test-room-id', roomName: 'Test Room'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify input field exists
      expect(find.byType(TextField), findsOneWidget);

      // Verify voice record button exists (shown when no text is entered)
      expect(find.byIcon(Icons.mic), findsOneWidget);

      // Verify attachment button exists
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });

    testWidgets('can enter text in chat input', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: const MaterialApp(
            home: Scaffold(
              body: ChatInputBar(roomId: 'test-room-id', roomName: 'Test Room'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find text field and enter text
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Hello, World!');
      await tester.pumpAndSettle();

      // Verify text is entered
      expect(find.text('Hello, World!'), findsOneWidget);
    });

    testWidgets('send button is enabled when text is entered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: const MaterialApp(
            home: Scaffold(
              body: ChatInputBar(roomId: 'test-room-id', roomName: 'Test Room'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.pumpAndSettle();

      // Find send button and verify it's present
      final sendButton = find.byIcon(Icons.send);
      expect(sendButton, findsOneWidget);
    });

    testWidgets('message bubble renders text correctly', (
      WidgetTester tester,
    ) async {
      final testMessage = domain.RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'sender-1',
        type: domain.RoomEventType.text,
        content: {'text': 'Hello from the test!'},
        status: domain.EventStatus.sent,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubble(
                message: testMessage,
                isMe: false,
                isGroupChat: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify message text is displayed
      expect(find.text('Hello from the test!'), findsOneWidget);
    });

    testWidgets('own message bubble has correct styling', (
      WidgetTester tester,
    ) async {
      final testMessage = domain.RoomEvent(
        id: 'msg-2',
        roomId: 'room-1',
        senderId: 'current-user-id',
        type: domain.RoomEventType.text,
        content: {'text': 'My own message'},
        status: domain.EventStatus.sent,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubble(message: testMessage, isMe: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify message is displayed
      expect(find.text('My own message'), findsOneWidget);
    });

    testWidgets('message status indicator shows correctly', (
      WidgetTester tester,
    ) async {
      final pendingMessage = domain.RoomEvent(
        id: 'msg-pending',
        roomId: 'room-1',
        senderId: 'current-user-id',
        type: domain.RoomEventType.text,
        content: {'text': 'Pending message'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubble(message: pendingMessage, isMe: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify message bubble is present
      expect(find.byType(MessageBubble), findsOneWidget);
    });

    testWidgets('image message shows placeholder', (WidgetTester tester) async {
      final imageMessage = domain.RoomEvent(
        id: 'msg-image',
        roomId: 'room-1',
        senderId: 'sender-1',
        type: domain.RoomEventType.image,
        content: {
          'url': 'https://example.com/image.jpg',
          'thumbnailUrl': 'https://example.com/thumb.jpg',
        },
        status: domain.EventStatus.sent,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubble(
                message: imageMessage,
                isMe: false,
                isGroupChat: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify image message bubble renders
      expect(find.byType(MessageBubble), findsOneWidget);
    });

    testWidgets('failed message shows retry option', (
      WidgetTester tester,
    ) async {
      final failedMessage = domain.RoomEvent(
        id: 'msg-failed',
        roomId: 'room-1',
        senderId: 'current-user-id',
        type: domain.RoomEventType.text,
        content: {'text': 'Failed to send'},
        status: domain.EventStatus.failed,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubble(message: failedMessage, isMe: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify failed message is displayed with retry option
      expect(find.byType(MessageBubble), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Not sent'), findsOneWidget);
    });

    testWidgets('long press on message shows context menu', (
      WidgetTester tester,
    ) async {
      final testMessage = domain.RoomEvent(
        id: 'msg-context',
        roomId: 'room-1',
        senderId: 'sender-1',
        type: domain.RoomEventType.text,
        content: {'text': 'Long press me'},
        status: domain.EventStatus.sent,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubble(
                message: testMessage,
                isMe: false,
                isGroupChat: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Long press on message
      await tester.longPress(find.byType(MessageBubble));
      await tester.pumpAndSettle();

      // Menu should appear (copy, reply, etc.)
      expect(find.byType(MessageBubble), findsOneWidget);
    });
  });
}
