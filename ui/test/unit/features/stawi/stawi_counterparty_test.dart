import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/networking/client.dart';
import 'package:stawi/features/stawi/data/stawi_counterparty.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;

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
}
