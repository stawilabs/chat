import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stawi/core/db/database.dart' hide Room;
import 'package:stawi/features/messages/data/draft_repository.dart';
import 'package:stawi/features/rooms/data/direct_room_opener.dart';
import 'package:stawi/features/rooms/data/room_id_remap.dart';
import 'package:stawi/features/rooms/data/room_repository.dart';
import 'package:stawi/features/rooms/domain/room.dart';
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;

import '../../../test_helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late RoomRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = RoomRepository(db);
  });
  tearDown(() => db.close());

  group('openDirectRoomOnline', () {
    test('opens the pair\'s existing DM with no placeholder room', () async {
      pb.CreateRoomRequest? sent;
      final room = await openDirectRoomOnline(
        roomRepo: repo,
        name: 'Ann',
        contactIds: ['c1'],
        call: (req) async {
          sent = req;
          return pb.CreateRoomResponse(room: pb.Room(id: 'existing-dm'));
        },
      );

      expect(room!.id, 'existing-dm');
      expect(sent!.id, isEmpty);
      expect(sent!.type, pb.RoomType.ROOM_TYPE_DIRECT);
      final rooms = await repo.getAllRooms();
      expect(rooms.map((r) => r.id), ['existing-dm']);
    });

    test('returns null on timeout so the offline flow takes over', () async {
      final room = await openDirectRoomOnline(
        roomRepo: repo,
        name: 'Ann',
        contactIds: ['c1'],
        timeout: const Duration(milliseconds: 20),
        call: (_) => Completer<pb.CreateRoomResponse>().future,
      );
      expect(room, isNull);
      expect(await repo.getAllRooms(), isEmpty);
    });

    test('a server rejection throws', () async {
      expect(
        openDirectRoomOnline(
          roomRepo: repo,
          name: 'Ann',
          contactIds: ['c1'],
          call: (_) async =>
              pb.CreateRoomResponse(error: pb.ErrorDetail(message: 'no')),
        ),
        throwsException,
      );
    });
  });

  group('room id remap', () {
    test('moves the draft to the server room', () async {
      await repo.insertRoom(const Room(id: 'local', name: '', type: 'direct'));
      await DraftRepository(db).saveDraft(roomId: 'local', content: 'hello');

      await repo.adoptServerRoomId('local', 'server');

      final drafts = DraftRepository(db);
      expect(await drafts.getDraft('local'), isNull);
      expect((await drafts.getDraft('server'))!.content, 'hello');
    });

    testWidgets('re-routes an open chat screen to the new id', (tester) async {
      final router = GoRouter(
        initialLocation: '/chat/local?name=Ann',
        routes: [
          GoRoute(
            path: '/chat/:roomId',
            builder: (context, state) => RoomIdRemapListener(
              roomId: state.pathParameters['roomId']!,
              roomName: 'Ann',
              child: Text('chat ${state.pathParameters['roomId']}'),
            ),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      expect(find.text('chat local'), findsOneWidget);

      announceRoomIdRemap('other', 'x');
      await tester.pumpAndSettle();
      expect(find.text('chat local'), findsOneWidget);

      announceRoomIdRemap('local', 'server');
      await tester.pumpAndSettle();
      expect(find.text('chat server'), findsOneWidget);
    });
  });
}
