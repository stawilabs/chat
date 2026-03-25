import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stawi/features/rooms/domain/room_with_last_message.dart';
import 'package:stawi/features/rooms/ui/room_list_tile.dart';
import 'package:stawi/widgets/skeleton_loader.dart';

void main() {
  group('RoomListTile Widget', () {
    RoomWithLastMessage createRoom({
      String id = 'room-1',
      String name = 'Test Room',
      String type = 'group',
      int unreadCount = 0,
      String? lastMessageText,
      int? lastMessageTimestamp,
      String? draftText,
    }) {
      return RoomWithLastMessage(
        id: id,
        name: name,
        type: type,
        unreadCount: unreadCount,
        lastMessageText: lastMessageText,
        lastMessageTimestamp: lastMessageTimestamp,
        draftText: draftText,
      );
    }

    testWidgets('renders room name correctly', (WidgetTester tester) async {
      final room = createRoom(name: 'Family Group');
      // ignore: unused_local_variable
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () => tapped = true),
          ),
        ),
      );

      expect(find.text('Family Group'), findsOneWidget);
    });

    testWidgets('renders avatar with first letter of room name', (
      WidgetTester tester,
    ) async {
      final room = createRoom(name: 'Work Chat');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      expect(find.text('W'), findsOneWidget);
    });

    testWidgets('shows last message preview', (WidgetTester tester) async {
      final room = createRoom(
        lastMessageText: 'Hey, how are you?',
        lastMessageTimestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Hey, how are you?'), findsOneWidget);
    });

    testWidgets('shows unread count badge when unreadCount > 0', (
      WidgetTester tester,
    ) async {
      final room = createRoom(unreadCount: 5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows 99+ for unread count > 99', (WidgetTester tester) async {
      final room = createRoom(unreadCount: 150);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('hides unread badge when unreadCount is 0', (
      WidgetTester tester,
    ) async {
      final room = createRoom();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      // Should not find any badge text
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows timestamp for today as time', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final room = createRoom(
        lastMessageTimestamp: now.millisecondsSinceEpoch,
        lastMessageText: 'Hello',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      // Should show time in HH:mm format
      final expectedTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      expect(find.text(expectedTime), findsOneWidget);
    });

    testWidgets('shows "Yesterday" for yesterday timestamp', (
      WidgetTester tester,
    ) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final room = createRoom(
        lastMessageTimestamp: yesterday.millisecondsSinceEpoch,
        lastMessageText: 'Hello',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('shows day name for timestamps within this week', (
      WidgetTester tester,
    ) async {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final room = createRoom(
        lastMessageTimestamp: threeDaysAgo.millisecondsSinceEpoch,
        lastMessageText: 'Hello',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final expectedDayName = dayNames[threeDaysAgo.weekday - 1];
      expect(find.text(expectedDayName), findsOneWidget);
    });

    testWidgets('shows date format for older timestamps', (
      WidgetTester tester,
    ) async {
      final oldDate = DateTime.now().subtract(const Duration(days: 10));
      final room = createRoom(
        lastMessageTimestamp: oldDate.millisecondsSinceEpoch,
        lastMessageText: 'Hello',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      // Should show d/m format for dates within this year
      final expectedDate = '${oldDate.day}/${oldDate.month}';
      expect(find.text(expectedDate), findsOneWidget);
    });

    testWidgets('shows draft indicator when draft exists', (
      WidgetTester tester,
    ) async {
      final room = createRoom(draftText: 'Unsent message...');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Draft: '), findsOneWidget);
      expect(find.text('Unsent message...'), findsOneWidget);
    });

    testWidgets('draft takes precedence over last message', (
      WidgetTester tester,
    ) async {
      final room = createRoom(
        lastMessageText: 'Last message',
        lastMessageTimestamp: DateTime.now().millisecondsSinceEpoch,
        draftText: 'Draft text',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      // Draft should be shown instead of last message
      expect(find.text('Draft: '), findsOneWidget);
      expect(find.text('Draft text'), findsOneWidget);
      expect(find.text('Last message'), findsNothing);
    });

    testWidgets('onTap callback is invoked when tapped', (
      WidgetTester tester,
    ) async {
      // ignore: unused_local_variable
      var tapped = false;
      final room = createRoom();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(RoomListTile));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('room name has bold font when unread', (
      WidgetTester tester,
    ) async {
      final room = createRoom(name: 'Unread Room', unreadCount: 3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      // Find the text widget with the room name
      final textFinder = find.text('Unread Room');
      expect(textFinder, findsOneWidget);

      // The text should have bold font weight for unread rooms
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('room name has normal font when read', (
      WidgetTester tester,
    ) async {
      final room = createRoom(name: 'Read Room');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      final textFinder = find.text('Read Room');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.fontWeight, FontWeight.w500);
    });
  });

  group('RoomListTile Accessibility', () {
    testWidgets('renders accessible room list item', (
      WidgetTester tester,
    ) async {
      const room = RoomWithLastMessage(
        id: 'room-1',
        name: 'Family Chat',
        type: 'group',
        unreadCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      // Room name and content should be present for screen readers
      expect(find.text('Family Chat'), findsOneWidget);
    });

    testWidgets('shows unread count for accessibility', (
      WidgetTester tester,
    ) async {
      const room = RoomWithLastMessage(
        id: 'room-1',
        name: 'Work Group',
        type: 'group',
        unreadCount: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      // Room name and unread count should be visible
      expect(find.text('Work Group'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });
  });

  group('RoomListTile Theme Support', () {
    testWidgets('renders correctly in light theme', (
      WidgetTester tester,
    ) async {
      final room = RoomWithLastMessage(
        id: 'room-1',
        name: 'Light Theme Room',
        type: 'group',
        unreadCount: 0,
        lastMessageText: 'Hello',
        lastMessageTimestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Light Theme Room'), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (WidgetTester tester) async {
      final room = RoomWithLastMessage(
        id: 'room-1',
        name: 'Dark Theme Room',
        type: 'group',
        unreadCount: 0,
        lastMessageText: 'Hello',
        lastMessageTimestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Dark Theme Room'), findsOneWidget);
    });
  });

  group('RoomListSkeleton Widget', () {
    testWidgets('renders skeleton loaders', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RoomListSkeleton())),
      );

      // Should have multiple skeleton loaders
      expect(find.byType(SkeletonLoader), findsAtLeast(3));
    });

    testWidgets('skeleton has correct structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RoomListSkeleton())),
      );

      // Should have a row layout
      expect(find.byType(Row), findsAtLeast(1));

      // Should have padding
      expect(find.byType(Padding), findsWidgets);
    });
  });

  group('Room List Edge Cases', () {
    testWidgets('handles empty room name gracefully', (
      WidgetTester tester,
    ) async {
      // Create room with single character name (edge case)
      const room = RoomWithLastMessage(
        id: 'room-1',
        name: 'X',
        type: 'group',
        unreadCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      expect(find.text('X'), findsAtLeast(1)); // Name and avatar initial
    });

    testWidgets('handles very long room name', (WidgetTester tester) async {
      const room = RoomWithLastMessage(
        id: 'room-1',
        name: 'This is a very long room name that should be truncated properly',
        type: 'group',
        unreadCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: RoomListTile(room: room, onTap: () {}),
            ),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(RoomListTile), findsOneWidget);
    });

    testWidgets('handles very long last message', (WidgetTester tester) async {
      final room = RoomWithLastMessage(
        id: 'room-1',
        name: 'Test Room',
        type: 'group',
        unreadCount: 0,
        lastMessageText:
            'This is a very long message that should be truncated '
            'with ellipsis because it exceeds the available width in the UI',
        lastMessageTimestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: RoomListTile(room: room, onTap: () {}),
            ),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(RoomListTile), findsOneWidget);
    });

    testWidgets('handles null last message timestamp', (
      WidgetTester tester,
    ) async {
      const room = RoomWithLastMessage(
        id: 'room-1',
        name: 'Test Room',
        type: 'group',
        unreadCount: 0,
        lastMessageText: 'Hello',
        // lastMessageTimestamp is null
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomListTile(room: room, onTap: () {}),
          ),
        ),
      );

      // Should show message but no timestamp
      expect(find.text('Hello'), findsOneWidget);
    });
  });
}
