import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/auth_repository.dart';
import 'package:stawi/features/rooms/domain/room_with_last_message.dart';
import 'package:stawi/features/rooms/ui/room_list_screen.dart';
import 'package:stawi/features/rooms/ui/room_list_tile.dart';

import 'test_config.dart';

void main() {
  IntegrationTestConfig.ensureInitialized();

  group('Room Flow Integration Tests', () {
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

    testWidgets('room list screen renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: const MaterialApp(home: RoomListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify room list screen is displayed
      expect(find.byType(RoomListScreen), findsOneWidget);
    });

    testWidgets('room list tile renders room information', (
      WidgetTester tester,
    ) async {
      const testRoom = RoomWithLastMessage(
        id: 'room-1',
        name: 'Test Group Chat',
        type: 'group',
        unreadCount: 5,
        lastMessageText: 'Hello everyone!',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: RoomListTile(room: testRoom, onTap: () {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify room name is displayed
      expect(find.text('Test Group Chat'), findsOneWidget);

      // Verify unread count is displayed
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('room list tile shows unread badge', (
      WidgetTester tester,
    ) async {
      const unreadRoom = RoomWithLastMessage(
        id: 'room-unread',
        name: 'Unread Room',
        type: 'group',
        unreadCount: 10,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: RoomListTile(room: unreadRoom, onTap: () {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify unread badge shows
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('room list tile is tappable', (WidgetTester tester) async {
      var wasTapped = false;
      const testRoom = RoomWithLastMessage(
        id: 'room-tap',
        name: 'Tappable Room',
        type: 'direct',
        unreadCount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: RoomListTile(
                room: testRoom,
                onTap: () {
                  wasTapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the room tile
      await tester.tap(find.byType(RoomListTile));
      await tester.pumpAndSettle();

      // Verify tap was registered
      expect(wasTapped, isTrue);
    });

    testWidgets('room list handles empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: const MaterialApp(home: RoomListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Screen should render with empty state
      expect(find.byType(RoomListScreen), findsOneWidget);
      // Verify empty state message is shown
      expect(find.text('No conversations yet'), findsOneWidget);
    });

    testWidgets('room list tile handles direct message room type', (
      WidgetTester tester,
    ) async {
      const directRoom = RoomWithLastMessage(
        id: 'room-direct',
        name: 'John Doe',
        type: 'direct',
        unreadCount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: RoomListTile(room: directRoom, onTap: () {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify direct message room name is displayed
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('room tile shows last message preview', (
      WidgetTester tester,
    ) async {
      const roomWithMessage = RoomWithLastMessage(
        id: 'room-preview',
        name: 'Preview Room',
        type: 'group',
        unreadCount: 1,
        lastMessageText: 'Hey, how are you?',
        lastMessageTimestamp: 1700000000000,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: RoomListTile(room: roomWithMessage, onTap: () {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify room tile renders
      expect(find.byType(RoomListTile), findsOneWidget);
      // Verify last message preview
      expect(find.text('Hey, how are you?'), findsOneWidget);
    });

    testWidgets('room list scrolls with many rooms', (
      WidgetTester tester,
    ) async {
      // Create a list with many room tiles
      final rooms = List.generate(
        20,
        (i) => RoomWithLastMessage(
          id: 'room-$i',
          name: 'Room $i',
          type: 'group',
          unreadCount: i,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  return RoomListTile(room: rooms[index], onTap: () {});
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify first room is visible
      expect(find.text('Room 0'), findsOneWidget);

      // Scroll down
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Some later room should be visible now
      expect(find.byType(RoomListTile), findsWidgets);
    });
  });
}
