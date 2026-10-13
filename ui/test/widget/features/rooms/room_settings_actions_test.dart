import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/notifications/mute_service.dart';
import 'package:stawi/features/rooms/data/detail_panel_providers.dart';
import 'package:stawi/features/rooms/data/room_providers.dart';
import 'package:stawi/features/rooms/domain/room.dart';
import 'package:stawi/features/rooms/ui/room_detail_panel.dart';

class _Unmuted extends RoomMuteState {
  @override
  Future<bool> build(String roomId) async => false;
}

void main() {
  test('group actions are offered only where the server allows them', () {
    expect(offersGroupActions('group'), isTrue);
    expect(offersGroupActions('direct'), isFalse);
    expect(offersGroupActions('bot'), isFalse);
    expect(offersGroupActions(null), isFalse);
  });

  for (final (type, offered) in [
    ('group', true),
    ('direct', false),
    ('bot', false),
  ]) {
    testWidgets('a $type room\'s settings ${offered ? 'offer' : 'hide'} '
        'Stawi and Add Members', (tester) async {
      tester.view
        ..physicalSize = const Size(1200, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Future<void> settle() async {
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomByIdProvider.overrideWith(
              (ref, id) async => Room(id: id, name: 'R', type: type),
            ),
            roomMuteStateProvider.overrideWith(_Unmuted.new),
            roomMembersProvider.overrideWith((ref, id) async => const []),
            roomMediaProvider.overrideWith((ref, id) => Stream.value(const [])),
          ],
          child: const MaterialApp(
            home: RoomDetailPanel(roomId: 'r1', roomName: 'R'),
          ),
        ),
      );
      await settle();
      await tester.tap(find.byTooltip('Room Settings'));
      await settle();
      final matcher = offered ? findsOneWidget : findsNothing;
      expect(find.byKey(const Key('room-settings-stawi')), matcher);
      expect(find.byKey(const Key('room-settings-add-members')), matcher);
      expect(find.text('Edit Room Info'), findsOneWidget);
    });
  }
}
