import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/messages/ui/date_header.dart';
import 'package:stawi/features/messages/ui/message_bubble.dart';

import '../test_helpers/test_helpers.dart';

void main() {
  setUp(TestHelpers.resetMocks);

  group('DateHeader Widget', () {
    testWidgets('shows "Today" for today\'s timestamp', (
      WidgetTester tester,
    ) async {
      final today = DateTime.now();
      final timestamp = today.millisecondsSinceEpoch;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DateHeader(timestamp: timestamp)),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('shows "Yesterday" for yesterday\'s timestamp', (
      WidgetTester tester,
    ) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final timestamp = yesterday.millisecondsSinceEpoch;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DateHeader(timestamp: timestamp)),
        ),
      );

      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('shows day name for timestamps within this week', (
      WidgetTester tester,
    ) async {
      // Pick a day 3 days ago (should show day name if within 7 days)
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final timestamp = threeDaysAgo.millisecondsSinceEpoch;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DateHeader(timestamp: timestamp)),
        ),
      );

      // Should show a day name (Monday, Tuesday, etc.)
      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final expectedDayName = dayNames[threeDaysAgo.weekday - 1];

      expect(find.text(expectedDayName), findsOneWidget);
    });

    testWidgets('shows date format for older timestamps', (
      WidgetTester tester,
    ) async {
      // Pick a day 10 days ago (outside this week)
      final oldDate = DateTime.now().subtract(const Duration(days: 10));
      final timestamp = oldDate.millisecondsSinceEpoch;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DateHeader(timestamp: timestamp)),
        ),
      );

      // Should show date in d/m/yyyy format
      final expectedDate = '${oldDate.day}/${oldDate.month}/${oldDate.year}';
      expect(find.text(expectedDate), findsOneWidget);
    });

    testWidgets('renders divider lines', (WidgetTester tester) async {
      final today = DateTime.now();
      final timestamp = today.millisecondsSinceEpoch;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DateHeader(timestamp: timestamp)),
        ),
      );

      // Should have Container widgets for divider lines
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders correctly in dark theme', (WidgetTester tester) async {
      final today = DateTime.now();
      final timestamp = today.millisecondsSinceEpoch;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(body: DateHeader(timestamp: timestamp)),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
    });
  });

  group('MessageBubble Widget - Text Messages', () {
    RoomEvent createTextMessage({
      String id = 'msg-1',
      String text = 'Hello, World!',
      String senderId = 'user-1',
      EventStatus status = EventStatus.sent,
      bool isDeleted = false,
      bool isEdited = false,
      bool isForwarded = false,
    }) {
      return RoomEvent(
        id: id,
        roomId: 'room-1',
        senderId: senderId,
        type: RoomEventType.text,
        content: {'text': text},
        createdAt: DateTime.now().millisecondsSinceEpoch,
        status: status,
        redacted: isDeleted,
        editedAt: isEdited ? DateTime.now().millisecondsSinceEpoch : null,
        forwardedFromEvent: isForwarded ? 'original-event-id' : null,
      );
    }

    testWidgets('renders sent message with text content', (
      WidgetTester tester,
    ) async {
      final message = createTextMessage(text: 'Test message');

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: true)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('renders received message with text content', (
      WidgetTester tester,
    ) async {
      final message = createTextMessage(
        text: 'Received message',
        senderId: 'other-user',
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: false)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Received message'), findsOneWidget);
    });

    testWidgets('sent message aligns to the right', (
      WidgetTester tester,
    ) async {
      final message = createTextMessage();

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: true)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('received message aligns to the left', (
      WidgetTester tester,
    ) async {
      final message = createTextMessage(senderId: 'other-user');

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: false)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('shows timestamp', (WidgetTester tester) async {
      final now = DateTime.now();
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.text,
        content: {'text': 'Hello'},
        createdAt: now.millisecondsSinceEpoch,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: true)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Timestamp should be visible (format: HH:mm)
      final expectedTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      expect(find.textContaining(expectedTime), findsOneWidget);
    });

    testWidgets('shows edited indicator for edited messages', (
      WidgetTester tester,
    ) async {
      final message = createTextMessage(isEdited: true);

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: true)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('edited'), findsOneWidget);
    });

    testWidgets('shows forwarded indicator for forwarded messages', (
      WidgetTester tester,
    ) async {
      final message = createTextMessage(isForwarded: true);

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: true)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Forwarded'), findsOneWidget);
      expect(find.byIcon(Icons.shortcut), findsOneWidget);
    });

    testWidgets('shows deleted message placeholder', (
      WidgetTester tester,
    ) async {
      final message = createTextMessage(isDeleted: true);

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: true)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('You deleted this message'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('shows different message for received deleted message', (
      WidgetTester tester,
    ) async {
      final message = createTextMessage(
        isDeleted: true,
        senderId: 'other-user',
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: false)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('This message was deleted'), findsOneWidget);
    });
  });

  group('MessageBubble Widget - Status Indicators', () {
    testWidgets('shows pending status', (WidgetTester tester) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.text,
        content: {'text': 'Pending message'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: true)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Pending message bubble should render
      expect(find.text('Pending message'), findsOneWidget);
    });

    testWidgets('shows sent status', (WidgetTester tester) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.text,
        content: {'text': 'Sent message'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
        status: EventStatus.sent,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: true)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Sent message bubble should render
      expect(find.text('Sent message'), findsOneWidget);
    });

    testWidgets('shows delivered status indicator', (
      WidgetTester tester,
    ) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.text,
        content: {'text': 'Delivered message'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
        status: EventStatus.delivered,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: true)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Delivered message bubble should render
      expect(find.text('Delivered message'), findsOneWidget);
    });

    testWidgets('shows read status indicator', (WidgetTester tester) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.text,
        content: {'text': 'Read message'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
        status: EventStatus.read,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: true)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Read message bubble should render
      expect(find.text('Read message'), findsOneWidget);
    });

    testWidgets('shows failed status with retry option', (
      WidgetTester tester,
    ) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.text,
        content: {'text': 'Failed message'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
        status: EventStatus.failed,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(message: message, isMe: true, onRetry: () {}),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Failed status shows error icon and retry info
      expect(find.byIcon(Icons.error_outline), findsAtLeast(1));
      expect(find.textContaining('Not sent'), findsOneWidget);
    });
  });

  group('MessageBubble Widget - Different Message Types', () {
    testWidgets('renders image message placeholder', (
      WidgetTester tester,
    ) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.image,
        content: {'url': 'https://example.com/image.jpg'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: true)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should render the bubble
      expect(find.byType(MessageBubble), findsOneWidget);
    });

    testWidgets('renders file message with filename', (
      WidgetTester tester,
    ) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.file,
        content: {
          'fileName': 'document.pdf',
          'fileSize': 1024 * 1024, // 1 MB
          'url': 'https://example.com/document.pdf',
        },
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: true)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('document.pdf'), findsOneWidget);
      expect(find.text('1.0 MB'), findsOneWidget);
      expect(find.byIcon(Icons.insert_drive_file), findsOneWidget);
    });

    testWidgets('renders reaction message with emoji', (
      WidgetTester tester,
    ) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.reaction,
        content: {'emoji': '👍'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message, isMe: true)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('👍'), findsOneWidget);
    });
  });

  group('MessageBubble Widget - Interactions', () {
    testWidgets('long press shows message menu', (WidgetTester tester) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.text,
        content: {'text': 'Test message'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: message,
              isMe: true,
              onReply: (id, text) {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Find and long press on the gesture detector
      await tester.longPress(find.text('Test message'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Bottom sheet should appear with options
      expect(find.text('Reply'), findsOneWidget);
    });

    testWidgets('shows copy option for text messages', (
      WidgetTester tester,
    ) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.text,
        content: {'text': 'Copyable text'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: message,
              isMe: true,
              onReply: (id, text) {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.longPress(find.text('Copyable text'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('shows forward option when enabled', (
      WidgetTester tester,
    ) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.text,
        content: {'text': 'Forward me'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: message,
              isMe: true,
              canForward: true,
              onForward: (msg) {},
              onReply: (id, text) {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.longPress(find.text('Forward me'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Forward'), findsOneWidget);
    });

    testWidgets('shows edit option for own messages when enabled', (
      WidgetTester tester,
    ) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.text,
        content: {'text': 'Edit me'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: message,
              isMe: true,
              canEdit: true,
              onEdit: (id, text) {},
              onReply: (id, text) {},
            ),
          ),
        ),
      );

      // Use pump with duration instead of pumpAndSettle to avoid animation timeout
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.longPress(find.text('Edit me'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('shows delete options for own messages', (
      WidgetTester tester,
    ) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.text,
        content: {'text': 'Delete me'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: message,
              isMe: true,
              canDelete: true,
              onDelete: (id, {required forEveryone}) {},
              onReply: (id, text) {},
            ),
          ),
        ),
      );

      // Use pump with duration instead of pumpAndSettle to avoid animation timeout
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.longPress(find.text('Delete me'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Delete for me'), findsOneWidget);
      expect(find.text('Delete for everyone'), findsOneWidget);
    });
  });

  group('MessageBubble Widget - Avatar Display', () {
    testWidgets('shows avatar for received messages in group chats', (
      WidgetTester tester,
    ) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'other-user',
        type: RoomEventType.text,
        content: {'text': 'Hello'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: message,
              isMe: false,
              isGroupChat: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should show CircleAvatar for received messages in group chats
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('hides avatar when grouped with previous message', (
      WidgetTester tester,
    ) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'other-user',
        type: RoomEventType.text,
        content: {'text': 'Hello'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: message,
              isMe: false,
              shouldGroupWithPrevious: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Avatar should not be directly visible when grouped
      // (replaced with SizedBox placeholder)
      final avatars = find.byType(CircleAvatar);
      expect(avatars, findsNothing);
    });
  });

  group('Theme Support', () {
    testWidgets('MessageBubble renders in light theme', (
      WidgetTester tester,
    ) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.text,
        content: {'text': 'Light theme message'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(body: MessageBubble(message: message, isMe: true)),
        ),
      );

      // Use pump with duration instead of pumpAndSettle to avoid animation timeout
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Light theme message'), findsOneWidget);
    });

    testWidgets('MessageBubble renders in dark theme', (
      WidgetTester tester,
    ) async {
      final message = RoomEvent(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        type: RoomEventType.text,
        content: {'text': 'Dark theme message'},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidgetWithMocks(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(body: MessageBubble(message: message, isMe: true)),
        ),
      );

      // Use pump with duration instead of pumpAndSettle to avoid animation timeout
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dark theme message'), findsOneWidget);
    });

    testWidgets('DateHeader renders in light theme', (
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

    testWidgets('DateHeader renders in dark theme', (
      WidgetTester tester,
    ) async {
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
}
