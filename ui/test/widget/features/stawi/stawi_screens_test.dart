import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/current_user_provider.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/rooms/data/detail_panel_providers.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/domain/stawi_payloads.dart';
import 'package:stawi/features/stawi/ui/convert_room_screen.dart';
import 'package:stawi/features/stawi/ui/stawi_account_screen.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';

void main() {
  final account = Uint8List.fromList(List.generate(20, (i) => i + 1));
  final digest = keccak256(Uint8List.fromList([9]));

  group('StawiAccountScreen', () {
    late FakeConnectTransport transport;
    late DeviceKeyStore keys;
    late DeviceKeyHandle key;

    setUp(() async {
      transport = FakeConnectTransport();
      keys = DeviceKeyStore(vaultWith('p1', anvilKey));
      key = (await keys.load('p1'))!;
    });

    Future<void> pump(
      WidgetTester tester, {
      required settlement.AccountState state,
      GenesisSessionProofs? proofs,
    }) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          stawiAccountStatusProvider.overrideWith(
            (ref) async => StawiAccountStatus(
              account: StawiAccountRef(address: account, primary: true),
              state: state,
              deviceKey: key,
            ),
          ),
          stawiAccountServiceProvider.overrideWithValue(
            StawiAccountService(
              accounts: settlement.AccountServiceClient(transport),
              keys: keys,
              proofs:
                  proofs ??
                  ({required Uint8List deviceAddress}) async =>
                      Uint8List.fromList([1, 2, 3]),
              identity: () async => identityWith('p1', account),
            ),
          ),
        ],
        child: const MaterialApp(home: StawiAccountScreen()),
      ),
    );

    void fakeDeploy() {
      transport
        ..on(
          settlement.AccountService.prepareDeployAccount,
          (req) => settlement.PrepareDeployAccountResponse(
            genesisDigest: digest,
            device: key.address,
            chainId: Int64(146),
          ),
        )
        ..on(
          settlement.AccountService.deployAccount,
          (req) => settlement.DeployAccountResponse(genesisState: 'PENDING'),
        );
    }

    testWidgets('shows the account, the device key and deploys', (
      tester,
    ) async {
      fakeDeploy();
      await pump(tester, state: settlement.AccountState(deployed: false));
      await tester.pumpAndSettle();

      expect(find.text(bytesToHex0x(account)), findsOneWidget);
      expect(find.textContaining(key.keyId), findsOneWidget);
      expect(find.text('Not deployed yet'), findsOneWidget);

      await tester.tap(find.byKey(const Key('stawi-deploy-account')));
      await tester.pumpAndSettle();

      final deploy = transport
          .requestsTo(settlement.AccountService.deployAccount)
          .single;
      expect(recoverDeviceAddress(digest, deploy.deviceSignature), key.address);
      expect(find.text('Deployment requested'), findsOneWidget);
    });

    testWidgets('says why deployment cannot complete', (tester) async {
      fakeDeploy();
      await pump(
        tester,
        state: settlement.AccountState(deployed: false),
        proofs: unavailableGenesisSessionProof,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stawi-deploy-account')));
      await tester.pumpAndSettle();
      expect(find.textContaining('genesis session proof'), findsOneWidget);
      expect(
        transport.requestsTo(settlement.AccountService.deployAccount),
        isEmpty,
      );
    });

    testWidgets('a registered device can add another key', (tester) async {
      await pump(
        tester,
        state: settlement.AccountState(
          deployed: true,
          keys: [settlement.AccountKey(key: key.address, active: true)],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Deployed on chain'), findsOneWidget);
      expect(find.byKey(const Key('stawi-deploy-account')), findsNothing);
      expect(find.byKey(const Key('stawi-add-device-key')), findsOneWidget);
    });
  });

  testWidgets('ConvertRoomScreen sends the chosen template and founders', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1080, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sender = RecordingActSender();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stawiTemplatesProvider.overrideWith(
            (ref) async => [
              finance.PolicyTemplate(
                templateId: 'ug_savings_basic',
                name: 'Uganda savings room',
                description: 'Weekly savings',
              ),
            ],
          ),
          roomMembersProvider.overrideWith(
            (ref, roomId) async => [
              RoomSubscriptionInfo(
                id: 'sub-me',
                profileId: 'p1',
                contactId: null,
                name: 'Me',
                avatarUrl: null,
                role: 'owner',
                joinedAt: 0,
              ),
              RoomSubscriptionInfo(
                id: 'sub-2',
                profileId: 'p2',
                contactId: null,
                name: 'Amina',
                avatarUrl: null,
                role: 'member',
                joinedAt: 1,
              ),
            ],
          ),
          currentProfileIdProvider.overrideWith((ref) async => 'p1'),
          stawiRoomServiceProvider.overrideWithValue(
            StawiRoomService(
              rooms: settlement.RoomServiceClient(FakeConnectTransport()),
              keys: DeviceKeyStore(MemoryDeviceKeyVault()),
              identity: () async => identityWith('p1', account),
              send: sender.call,
            ),
          ),
        ],
        child: const MaterialApp(home: ConvertRoomScreen(roomId: roomId)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('stawi-send-conversion')))
          .onPressed,
      isNull,
      reason: 'no template chosen yet',
    );
    await tester.tap(find.byKey(const Key('template-ug_savings_basic')));
    await tester.tap(find.byKey(const Key('founder-sub-2')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('stawi-send-conversion')));
    await tester.tap(find.byKey(const Key('stawi-send-conversion')));
    await tester.pumpAndSettle();

    final act = sender.sent.single;
    expect(act.type, RoomEventType.stawiRoomConversion);
    final view = StawiConversionView.fromContent(act.content);
    expect(view.templateId, 'ug_savings_basic');
    expect(view.founderSubscriptionIds, unorderedEquals(['sub-me', 'sub-2']));
    expect(view.joinPolicy, StawiJoinPolicy.private);
  });
}
