import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/networking/client.dart';
import 'package:stawi/features/stawi/data/stawi_counterparty.dart';
import 'package:stawi/features/stawi/ui/dm_partner_picker.dart';
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;

import '../../../support/stawi_fakes.dart';

void main() {
  final bob = Uint8List.fromList(List.filled(20, 0xb0));

  late FakeConnectTransport chat;

  setUp(() {
    chat = FakeConnectTransport()
      ..on(pb.ChatService.getDirectPartnerAccount, (req) {
        switch (req.roomId) {
          case 'dm-bob':
            return pb.GetDirectPartnerAccountResponse(
              profileId: 'p-bob',
              account: bob,
              deployed: true,
            );
          case 'dm-carol':
            return pb.GetDirectPartnerAccountResponse(profileId: 'p-carol');
          default:
            throw connect.ConnectException(
              connect.Code.permissionDenied,
              'this is not a direct message you share with one other person',
            );
        }
      });
  });

  /// Pumps a button that opens the picker; [chosen] receives its result.
  Future<void> pumpPicker(
    WidgetTester tester,
    List<DirectRoomRef> rooms,
    void Function(StawiContactAccount?) chosen,
  ) async {
    final client = pb.ChatServiceClient(chat);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatServiceClientProvider.overrideWith((ref) async => client),
          directRoomsProvider.overrideWith((ref) async => rooms),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    chosen(await showDmPartnerPicker(context)),
                child: const Text('Choose'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
  }

  testWidgets('a DM partner with an account resolves and can be chosen', (
    tester,
  ) async {
    StawiContactAccount? chosen;
    await pumpPicker(tester, const [
      DirectRoomRef(roomId: 'dm-bob', name: 'Bob'),
    ], (c) => chosen = c);

    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('0xb0b0…b0b0'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dm-partner-dm-bob')));
    await tester.pumpAndSettle();

    expect(chosen!.address, bob);
    expect(chosen!.name, 'Bob');
    expect(chosen!.profileId, 'p-bob');
    expect(
      chat.requestsTo(pb.ChatService.getDirectPartnerAccount).single.roomId,
      'dm-bob',
      reason: 'looked up by the DM, never by a profile id',
    );
  });

  testWidgets('a partner without an account says so and cannot be chosen', (
    tester,
  ) async {
    StawiContactAccount? chosen;
    var closed = false;
    await pumpPicker(
      tester,
      const [DirectRoomRef(roomId: 'dm-carol', name: 'Carol')],
      (c) {
        chosen = c;
        closed = true;
      },
    );

    expect(find.text('Carol has no Stawi account yet'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dm-partner-dm-carol')));
    await tester.pumpAndSettle();
    expect(closed, isFalse, reason: 'the row is disabled');
    expect(chosen, isNull);
  });

  testWidgets(
    'a partner who has not written yet is asked for, and cannot be chosen',
    (tester) async {
      var closed = false;
      await pumpPicker(tester, const [
        DirectRoomRef(roomId: 'dm-gone', name: 'Dan'),
        DirectRoomRef(roomId: 'dm-bob', name: 'Bob'),
      ], (_) => closed = true);

      expect(
        find.text('Dan needs to send you a message first'),
        findsOneWidget,
      );
      expect(
        find.text('0xb0b0…b0b0'),
        findsOneWidget,
        reason: 'others resolve',
      );
      await tester.tap(find.byKey(const Key('dm-partner-dm-gone')));
      await tester.pumpAndSettle();
      expect(closed, isFalse);
    },
  );

  testWidgets('without DMs it says how to get one', (tester) async {
    await pumpPicker(tester, const [], (_) {});
    expect(
      find.text('Start a direct message with someone to send them money'),
      findsOneWidget,
    );
    expect(chat.calls, isEmpty);
  });
}
