import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/current_user_provider.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/rooms/data/detail_panel_providers.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/signing_gate.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_custody.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/data/stawi_timeline_providers.dart';
import 'package:stawi/features/stawi/domain/stawi_payloads.dart';
import 'package:stawi/features/stawi/ui/contribute_screen.dart';
import 'package:stawi/features/stawi/ui/convert_room_screen.dart';
import 'package:stawi/features/stawi/ui/stawi_account_screen.dart';
import 'package:stawi/features/stawi/ui/stawi_room_screen.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';

void main() {
  // settlement_default: the anvil-0 device key deploying account 0x…acc7.
  final genesis = GoGenesisVector.load().firstWhere(
    (v) => v.name == 'settlement_default',
  );
  final account = genesis.account;

  group('StawiAccountScreen', () {
    late FakeConnectTransport transport;
    late DeviceKeyStore keys;
    late DeviceKeyHandle key;

    setUp(() async {
      transport = FakeConnectTransport();
      keys = DeviceKeyStore(vaultWith('p1', anvilKey), gate: SigningGate.open);
      key = (await keys.load('p1'))!;
    });

    Future<void> pump(
      WidgetTester tester, {
      required settlement.AccountState state,
      GenesisSessionProofs? proofs,
      bool showTestFunds = false,
    }) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          stawiAccountStatusProvider.overrideWith(
            (ref) async => StawiAccountStatus(
              account: genesis.identity('p1').primary,
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
              identity: () async => genesis.identity('p1'),
            ),
          ),
        ],
        child: MaterialApp(
          home: StawiAccountScreen(showTestFunds: showTestFunds),
        ),
      ),
    );

    void fakeDeploy() {
      transport
        ..on(
          settlement.AccountService.prepareDeployAccount,
          (req) => genesis.prepared,
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
      expect(bytesToHex0x(deploy.deviceSignature), genesis.signature);
      expect(find.text('Deployment requested'), findsOneWidget);
    });

    testWidgets('says why deployment cannot complete', (tester) async {
      fakeDeploy();
      await pump(
        tester,
        state: settlement.AccountState(deployed: false),
        proofs: refusingSessionProofs,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stawi-deploy-account')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('no live authenticated session'),
        findsOneWidget,
      );
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

  group('test funds', () {
    late FakeConnectTransport transport;
    late DeviceKeyHandle key;

    setUp(() async {
      transport = FakeConnectTransport()
        ..on(
          settlement.AccountService.getAsset,
          (_) =>
              settlement.GetAssetResponse(asset: usdcInfo, faucetEnabled: true),
        )
        ..on(
          settlement.AccountService.fundTestAccount,
          (req) => settlement.FundTestAccountResponse(
            amount: req.amount,
            mintedToday: req.amount,
            dailyLimit: '5000000000',
            asset: usdcInfo,
          ),
        );
      key = (await DeviceKeyStore(
        vaultWith('p1', anvilKey),
        gate: SigningGate.open,
      ).load('p1'))!;
    });

    Widget screen({required bool showTestFunds}) => ProviderScope(
      overrides: [
        stawiAccountStatusProvider.overrideWith(
          (ref) async => StawiAccountStatus(
            account: StawiAccountRef(address: account, primary: true),
            state: settlement.AccountState(deployed: true),
            deviceKey: key,
          ),
        ),
        stawiAccountServiceProvider.overrideWithValue(
          StawiAccountService(
            accounts: settlement.AccountServiceClient(transport),
            keys: DeviceKeyStore(
              MemoryDeviceKeyVault(),
              gate: SigningGate.open,
            ),
            proofs: refusingSessionProofs,
            identity: () async => identityWith('p1', account),
          ),
        ),
      ],
      child: MaterialApp(
        home: StawiAccountScreen(showTestFunds: showTestFunds),
      ),
    );

    testWidgets('are hidden where the faucet is off', (tester) async {
      await tester.pumpWidget(screen(showTestFunds: false));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('stawi-test-funds')), findsNothing);
      expect(transport.requestsTo(settlement.AccountService.getAsset), isEmpty);
    });

    testWidgets('are hidden where the deployment has no faucet', (
      tester,
    ) async {
      transport.on(
        settlement.AccountService.getAsset,
        (_) => settlement.GetAssetResponse(asset: usdcInfo),
      );
      await tester.pumpWidget(screen(showTestFunds: true));
      await tester.pumpAndSettle();
      expect(
        transport.requestsTo(settlement.AccountService.getAsset),
        isNotEmpty,
      );
      expect(find.byKey(const Key('stawi-test-funds')), findsNothing);
    });

    testWidgets('mint to the account on testnet builds', (tester) async {
      await tester.pumpWidget(screen(showTestFunds: true));
      await tester.pumpAndSettle();
      expect(find.text('Get test USDC (testnet)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('stawi-test-funds')));
      await tester.pumpAndSettle();
      expect(find.text('USDC'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('stawi-test-funds-amount')),
        '2.5555555',
      );
      await tester.tap(find.byKey(const Key('stawi-test-funds-confirm')));
      await tester.pumpAndSettle();
      expect(find.textContaining('at most 6 decimals'), findsOneWidget);
      expect(
        transport.requestsTo(settlement.AccountService.fundTestAccount),
        isEmpty,
      );

      await tester.enterText(
        find.byKey(const Key('stawi-test-funds-amount')),
        '2.5',
      );
      await tester.tap(find.byKey(const Key('stawi-test-funds-confirm')));
      await tester.pumpAndSettle();

      final request = transport
          .requestsTo(settlement.AccountService.fundTestAccount)
          .single;
      expect(request.address, account);
      expect(request.amount, '2500000');
      expect(
        find.textContaining('Minting 2.50 USDC (2.50 USDC of 5,000.00 USDC'),
        findsOneWidget,
      );
    });
  });

  testWidgets('ContributeScreen signs a contribution to the room custody', (
    tester,
  ) async {
    final custody = Uint8List.fromList(List.filled(20, 0xc0));
    final digest = keccak256(Uint8List.fromList([7]));
    final transport = FakeConnectTransport()
      ..on(
        settlement.AccountService.prepareAccountCall,
        (req) => settlement.PrepareAccountCallResponse(
          callId: 'acct000000000000000c',
          intentDigest: digest,
          financialIntent: finance.FinancialIntent(
            type: finance.IntentType.INTENT_TYPE_CONTRIBUTION,
            destination: finance.ValueLocation(
              kind: finance.LocationKind.LOCATION_KIND_ROOM_CUSTODY,
              address: req.params.room,
            ),
            amount: req.params.amount,
          ),
          call: settlement.AccountCall(
            callId: 'acct000000000000000c',
            address: req.address,
            kind: req.kind,
          ),
        ),
      )
      ..on(
        settlement.AccountService.submitAccountCall,
        (req) => settlement.SubmitAccountCallResponse(
          call: settlement.AccountCall(callId: req.callId),
        ),
      )
      ..on(
        settlement.AccountService.getAccountCall,
        (req) => settlement.GetAccountCallResponse(
          call: settlement.AccountCall(
            callId: req.callId,
            state: settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL,
          ),
        ),
      );
    final keys = DeviceKeyStore(
      vaultWith('p1', anvilKey),
      gate: SigningGate.open,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomCustodyProvider.overrideWith((ref, id) async => custody),
          stawiRoomAssetProvider.overrideWith((ref, id) async => usdc),
          stawiRoomAssetsProvider.overrideWith((ref, id) async => usdcAssets),
          stawiAccountServiceProvider.overrideWithValue(
            StawiAccountService(
              accounts: settlement.AccountServiceClient(transport),
              keys: keys,
              proofs: refusingSessionProofs,
              identity: () async => identityWith('p1', account),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ContributeScreen(roomId: roomId, roomName: 'Chama'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('contribute-amount')), '500');
    await tester.tap(find.byKey(const Key('contribute-submit')));
    await tester.pumpAndSettle();

    final prepare = transport
        .requestsTo(settlement.AccountService.prepareAccountCall)
        .single;
    expect(prepare.params.room, custody);
    expect(prepare.params.amount, '500000000');
    final submit = transport
        .requestsTo(settlement.AccountService.submitAccountCall)
        .single;
    expect(
      recoverDeviceAddress(digest, submit.authorization),
      (await keys.load('p1'))!.address,
    );
    expect(find.text('Confirmed on chain'), findsOneWidget);
  });

  testWidgets('an active Stawi room offers contributing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stawiRoomPhaseProvider.overrideWith(
            (ref, id) => const AsyncValue.data(StawiRoomPhase.active),
          ),
        ],
        child: const MaterialApp(
          home: StawiRoomScreen(roomId: roomId, roomName: 'Chama'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stawi-contribute')), findsOneWidget);
    expect(find.byKey(const Key('stawi-statement')), findsOneWidget);
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
              keys: DeviceKeyStore(
                MemoryDeviceKeyVault(),
                gate: SigningGate.open,
              ),
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

  testWidgets('ConvertRoomScreen holds the founding quorum to the founders', (
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
                policy: finance.RoomPolicy(
                  governance: finance.Governance(foundingQuorum: 3),
                ),
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
              keys: DeviceKeyStore(
                MemoryDeviceKeyVault(),
                gate: SigningGate.open,
              ),
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

    // The template asks three founders to sign; only two are chosen.
    expect(find.byKey(const Key('founding-quorum-problem')), findsOneWidget);
    final send = find.byKey(const Key('stawi-send-conversion'));
    expect(tester.widget<FilledButton>(send).onPressed, isNull);

    await tester.tap(find.text('Rules'));
    await tester.pumpAndSettle();
    final quorum = find.widgetWithText(TextField, 'Founding quorum');
    await tester.enterText(quorum, '3');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(send).onPressed, isNull);

    await tester.enterText(quorum, '2');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('founding-quorum-problem')), findsNothing);
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();

    final view = StawiConversionView.fromContent(sender.sent.single.content);
    expect(view.ruleValues, {'founding_quorum': '2'});
    expect(view.founderSubscriptionIds, unorderedEquals(['sub-me', 'sub-2']));
  });
}
