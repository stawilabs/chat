import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/networking/client.dart';
import 'package:stawi/features/rooms/data/room_id_remap.dart';
import 'package:stawi/features/stawi/data/stawi_counterparty.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/ui/stawi_feedback.dart';
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../../../support/stawi_fakes.dart';

void main() {
  late FakeConnectTransport chat;
  late ProviderContainer container;

  setUp(() {
    chat = FakeConnectTransport();
    final client = pb.ChatServiceClient(chat);
    container = ProviderContainer(
      overrides: [
        chatServiceClientProvider.overrideWith((ref) async => client),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<StawiContactAccount?> lookup(String roomId) {
    final sub = container.listen(
      counterpartyAccountProvider(roomId),
      (_, _) {},
    );
    addTearDown(sub.close);
    return container.read(counterpartyAccountProvider(roomId).future);
  }

  final bob = Uint8List.fromList(List.filled(20, 0xb0));

  test('the DM partner resolves through chat, by the DM\'s room id', () async {
    chat.on(
      pb.ChatService.getDirectPartnerAccount,
      (req) => pb.GetDirectPartnerAccountResponse(
        profileId: 'p-bob',
        account: bob,
        deployed: true,
      ),
    );
    final contact = await lookup('dm-bob');
    expect(contact!.address, bob);
    expect(contact.profileId, 'p-bob');
    expect(contact.deployed, isTrue);
    expect(contact.named('Bob').name, 'Bob');
    expect(contact.named('Bob').address, bob);
    expect(
      chat.requestsTo(pb.ChatService.getDirectPartnerAccount).single.roomId,
      'dm-bob',
    );
  });

  test('a partner without a Stawi account is null, not an error', () async {
    chat.on(
      pb.ChatService.getDirectPartnerAccount,
      (req) => pb.GetDirectPartnerAccountResponse(profileId: 'p-bob'),
    );
    expect(await lookup('dm-bob'), isNull);
  });

  test('chat\'s refusal asks for the partner to write first', () async {
    chat.on(
      pb.ChatService.getDirectPartnerAccount,
      (req) => throw connect.ConnectException(
        connect.Code.permissionDenied,
        'this is not a direct message you share with one other person',
      ),
    );
    await expectLater(lookup('dm-new'), throwsA(isA<DirectPartnerRefused>()));
    expect(
      DirectPartnerRefused.messageFor('Bob'),
      'Bob needs to send you a message first',
    );
  });

  test('a settlement outage asks the person to try again', () async {
    chat.on(
      pb.ChatService.getDirectPartnerAccount,
      (req) => throw connect.ConnectException(
        connect.Code.unavailable,
        'the partner\'s Stawi account cannot be read right now',
      ),
    );
    await expectLater(
      lookup('dm-bob'),
      throwsA(
        isA<StawiUnavailable>().having(
          (e) => e.message,
          'message',
          contains('try again'),
        ),
      ),
    );
  });

  group('partner lookups are kept for the session', () {
    late List<String> asked;
    late Map<String, Object> answers;
    late DateTime now;
    late ProviderContainer c;

    setUp(() {
      asked = [];
      now = DateTime.utc(2026, 10, 13, 12);
      answers = {
        'dm-ann': DirectPartnerAccount(
          profileId: 'p-ann',
          account: Uint8List.fromList(List.filled(20, 0xa1)),
        ),
        'dm-bob': DirectPartnerAccount(profileId: 'p-bob', account: bob),
      };
      c = ProviderContainer(
        overrides: [
          counterpartyAccountsProvider.overrideWithValue((roomId) async {
            asked.add(roomId);
            final a = answers[roomId];
            if (a is DirectPartnerAccount) return a;
            throw (a ?? const DirectPartnerRefused()) as Exception;
          }),
          directRoomListerProvider.overrideWithValue(
            () async => const [
              DirectRoomRef(roomId: 'dm-ann', name: 'Ann'),
              DirectRoomRef(roomId: 'dm-down', name: 'Down'),
              DirectRoomRef(roomId: 'dm-bob', name: 'Bob'),
            ],
          ),
          partnerLookupClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(c.dispose);
    });

    Future<StawiContactAccount?> read(String roomId) async {
      final sub = c.listen(counterpartyAccountProvider(roomId), (_, _) {});
      try {
        return await c.read(counterpartyAccountProvider(roomId).future);
      } finally {
        sub.close();
      }
    }

    test('one call per DM, even after the screen that asked is gone', () async {
      expect((await read('dm-bob'))!.address, bob);
      await Future<void>.delayed(Duration.zero);
      expect((await read('dm-bob'))!.address, bob);
      expect(asked, ['dm-bob']);
    });

    test('a DM remapped to the server\'s id is asked again', () async {
      await read('dm-bob');
      announceRoomIdRemap('dm-bob', 'dm-bob-server');
      await Future<void>.delayed(Duration.zero);
      await read('dm-bob');
      expect(asked, ['dm-bob', 'dm-bob']);
    });

    test(
      'too many lookups back off: nothing is asked, each reads "—"',
      () async {
        answers['dm-ann'] = const PartnerLookupsExhausted();
        await expectLater(
          read('dm-ann'),
          throwsA(isA<PartnerLookupsExhausted>()),
        );
        expect(stawiErrorMessage(const PartnerLookupsExhausted()), '—');
        await expectLater(
          read('dm-bob'),
          throwsA(isA<PartnerLookupsExhausted>()),
        );
        expect(asked, ['dm-ann'], reason: 'nothing more is asked meanwhile');
        // The walk for a loan's name stops too.
        final name = await c.read(
          counterpartyNameProvider(bytesToHex0x(bob).toLowerCase()).future,
        );
        expect(name.name, isNull);
        expect(asked, ['dm-ann']);
        // Once the minute has passed, lookups are asked again.
        now = now.add(partnerLookupBackoff);
        c.read(partnerLookupBackoffProvider).until = null;
        c.invalidate(partnerLookupProvider('dm-bob'));
        expect((await read('dm-bob'))!.address, bob);
      },
    );

    test('a DM that cannot be answered is skipped, not the end', () async {
      answers['dm-down'] = const StawiUnavailable('down');
      final account = await c.read(dmPartnerAccountOfProvider)('p-bob');
      expect(account, bob);
      expect(asked, ['dm-ann', 'dm-down', 'dm-bob']);
    });

    test(
      'a loan is named by a DM only when its partner is that account',
      () async {
        final named = await c.read(
          counterpartyNameProvider(bytesToHex0x(bob).toLowerCase()).future,
        );
        expect(named.name, 'Bob');
        expect(named.label, 'Bob');
        final stranger = Uint8List.fromList(List.filled(20, 0xdd));
        final unknown = await c.read(
          counterpartyNameProvider(bytesToHex0x(stranger).toLowerCase()).future,
        );
        expect(unknown.name, isNull);
        expect(unknown.label, '0xdddd…dddd ($notOneOfYourChats)');
        // Each DM was asked once for both names.
        expect(asked, ['dm-ann', 'dm-down', 'dm-bob']);
      },
    );
  });
}
