import 'dart:async';

import 'package:connectrpc/connect.dart' as connect;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stawi/core/db/database.dart' show Profile;
import 'package:stawi/core/networking/client.dart';
import 'package:stawi/features/auth/data/current_user_provider.dart';
import 'package:stawi/features/messages/data/message_providers.dart';
import 'package:stawi/features/messages/data/typing_provider.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/messages/ui/chat_screen.dart';
import 'package:stawi/features/profile/data/profile_providers.dart';
import 'package:stawi/features/rooms/data/detail_panel_providers.dart';
import 'package:stawi/features/rooms/data/room_providers.dart';
import 'package:stawi/features/rooms/data/room_subscription_service.dart';
import 'package:stawi/features/rooms/data/room_sync_state.dart';
import 'package:stawi/features/rooms/domain/room.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/signing_gate.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_agent_invitations.dart';
import 'package:stawi/features/stawi/data/stawi_clients.dart';
import 'package:stawi/features/stawi/data/stawi_counterparty.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/data/stawi_timeline_providers.dart';
import 'package:stawi/features/stawi/ui/my_money_screen.dart';
import 'package:stawi/features/stawi/ui/stawi_room_screen.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../support/stawi_fakes.dart';

/// The Go engine-call vectors' device key, account, vault and loan book
/// (stawi_finance_sdk test/vectors/go_engine_calls.json).
final String vectorDeviceKey = GoEngineCallVector.load().first.devicePrivateKey;
final Uint8List myAccount = hexToBytes(
  '0xa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3',
);
final Uint8List bobAccount = hexToBytes(
  '0xb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3',
);
final Uint8List myVault = hexToBytes(
  '0x909192939495969798999a9b9c9d9e9fa0a1a2a3',
);
final Uint8List loanBook = hexToBytes(
  '0x101112131415161718191a1b1c1d1e1f20212223',
);

/// 1760000000 − 7 days: a 7-day offer or ask expires at the vectors'
/// 1760000000.
final DateTime journeyNow = DateTime.utc(2025, 10, 2, 8, 53, 20);

/// The Go engine call named [name].
GoEngineCallVector engineVector(String name) =>
    GoEngineCallVector.load().firstWhere((v) => v.name == name);

/// The Go standing-order grant named [name].
GoStandingGrantVector grantVector(String name) =>
    GoVaultVectors.load().standingGrants.firstWhere((g) => g.name == name);

finance.Money usdUnits(Object units) =>
    finance.Money(amount: '$units', assetId: 'USDC.146');

/// The Typing notifier without the sync engine: nobody types.
class _QuietTyping extends Typing {
  @override
  Set<TypingUser> build(String roomId) => {};
}

/// The whole app around a journey: the real screens, services and device
/// checks, with settlement, finance and chat answered by fake transports and
/// the chat's local store by in-memory rooms and timelines. The device key is
/// the Go vectors' own, so a signature over a vector's digest is the
/// vector's signature.
class JourneyHarness {
  JourneyHarness({
    this.profileId = 'p-me',
    Uint8List? account,
    String? deviceKey,
    DateTime? now,
  }) : account = account ?? myAccount,
       deviceKey = deviceKey ?? vectorDeviceKey,
       now = now ?? journeyNow {
    _serveDefaults();
  }

  final String profileId;
  final Uint8List account;
  final String deviceKey;
  final DateTime now;

  final FakeConnectTransport settlementApi = FakeConnectTransport();
  final FakeConnectTransport financeApi = FakeConnectTransport();
  final FakeConnectTransport chatApi = FakeConnectTransport();
  final RecordingSigningGate gate = RecordingSigningGate();
  final RecordingActSender acts = RecordingActSender();

  /// The chat rooms the device knows.
  final Map<String, Room> rooms = {};

  /// Each room's members, as the local store lists them.
  final Map<String, List<RoomSubscriptionInfo>> members = {};

  /// Profiles the local store holds.
  final Map<String, Profile> profiles = {};

  /// Chat's answer for each DM: the partner's profile and account; a DM
  /// missing here is refused (the partner has not written).
  final Map<String, ({String profileId, Uint8List account})> dmPartners = {};

  /// Chat's Stawi binding of each room.
  final Map<String, pb.StawiRoomBinding> bindings = {};

  /// Finance's read of each Stawi room; any other room names only its USDC.
  final Map<String, finance.Room> financeRooms = {};

  /// Finance's members of each Stawi room.
  final Map<String, List<finance.Member>> financeMembers = {};

  /// Each Stawi room's loan forms.
  final Map<String, List<finance.RoomLoanProduct>> loanProducts = {};

  /// The constitution templates a room is converted with.
  List<finance.PolicyTemplate> templates = const [];

  final Map<String, List<RoomEvent>> _timelines = {};
  final StreamController<String> _changed = StreamController.broadcast();

  /// What settlement prepares for each PrepareAccountCall.
  FutureOr<settlement.PrepareAccountCallResponse> Function(
    settlement.PrepareAccountCallRequest req,
  )?
  prepare;

  /// The loans finance lists and reads.
  List<finance.Loan> Function(finance.ListLoansRequest req) listLoans = (_) =>
      const [];
  finance.GetLoanResponse Function(finance.GetLoanRequest req)? getLoan;

  /// The person's vault pockets.
  List<finance.SavingsPocket> pockets = [];

  /// The account's policy asset: the asset of the Go grants.
  Uint8List policyAsset = grantVector('self_flat_weekly').asset;

  /// What settlement answered each PrepareAccountCall with, in order.
  final List<settlement.PrepareAccountCallResponse> preparedAnswers = [];

  /// Every SubmitAccountCall, in order.
  List<settlement.SubmitAccountCallRequest> get submitted =>
      settlementApi.requestsTo(settlement.AccountService.submitAccountCall);

  /// Every PrepareAccountCall, in order.
  List<settlement.PrepareAccountCallRequest> get prepared =>
      settlementApi.requestsTo(settlement.AccountService.prepareAccountCall);

  /// The device's signature over [digest]: what a submitted authorization
  /// must be.
  Uint8List signatureOver(List<int> digest) =>
      signPreparedCall(digest, hexToBytes(deviceKey));

  StawiIdentity get identity => identityWith(profileId, account);

  /// Adds a room the chat list holds.
  void addRoom(
    String id,
    String name, {
    required String type,
    List<RoomSubscriptionInfo> roomMembers = const [],
  }) {
    rooms[id] = Room(id: id, name: name, type: type);
    members[id] = roomMembers;
    _timelines.putIfAbsent(id, () => []);
  }

  /// A DM with [name], whose partner chat names (once they have written) as
  /// [partnerProfileId] holding [partnerAccount]; without one, chat refuses.
  void addDm(
    String id,
    String name, {
    String? partnerProfileId,
    Uint8List? partnerAccount,
  }) {
    addRoom(id, name, type: 'direct');
    if (partnerProfileId != null) {
      dmPartners[id] = (
        profileId: partnerProfileId,
        account: partnerAccount ?? Uint8List(0),
      );
    }
  }

  /// Posts [event] into its room's timeline, as sync would.
  void post(RoomEvent event) {
    _timelines.putIfAbsent(event.roomId, () => []).add(event);
    _changed.add(event.roomId);
  }

  Stream<List<RoomEvent>> _timeline(String roomId) async* {
    // Newest first, as the message store lists them.
    List<RoomEvent> now() => (_timelines[roomId] ?? const []).reversed.toList();
    yield now();
    await for (final changed in _changed.stream) {
      if (changed == roomId) yield now();
    }
  }

  /// A finance card posted into [roomId], already read.
  RoomEvent card(
    String roomId, {
    required String id,
    required String kind,
    required String title,
    String body = '',
    Map<String, String> data = const {},
  }) => RoomEvent(
    id: id,
    roomId: roomId,
    senderId: '',
    type: RoomEventType.financeCard,
    createdAt: now.millisecondsSinceEpoch,
    status: EventStatus.read,
    content: {
      'cardId': id,
      'kind': kind,
      'title': title,
      'body': body,
      'data': data,
    },
  );

  void _serveDefaults() {
    settlementApi
      ..on(settlement.AccountService.getAccount, (req) async {
        final device = await deviceAddressOf(deviceKey);
        return settlement.GetAccountResponse(
          account: settlement.AccountState(
            address: req.address,
            deployed: true,
            keys: [settlement.AccountKey(key: device, active: true)],
            balance: '1000000000',
            policy: settlement.AccountPolicy(asset: policyAsset),
          ),
        );
      })
      ..on(
        settlement.AccountService.getAsset,
        (req) => settlement.GetAssetResponse(asset: usdcInfo),
      )
      ..on(settlement.AccountService.prepareAccountCall, (req) async {
        final answer = prepare;
        if (answer == null) {
          throw connect.ConnectException(
            connect.Code.unimplemented,
            'nothing prepared',
          );
        }
        final prepared = await answer(req);
        preparedAnswers.add(prepared);
        return prepared;
      })
      ..on(
        settlement.AccountService.submitAccountCall,
        (req) => settlement.SubmitAccountCallResponse(
          call: settlement.AccountCall(
            callId: req.callId,
            state: settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
          ),
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
    financeApi
      ..on(
        finance.VaultService.getPersonalTargets,
        (req) => finance.GetPersonalTargetsResponse(
          vault: myVault,
          loanBooks: [loanBook],
        ),
      )
      ..on(
        finance.VaultService.getVault,
        (req) => finance.GetVaultResponse(pockets: pockets),
      )
      ..on(
        finance.LoanService.listLoans,
        (req) => finance.ListLoansResponse(loans: listLoans(req)),
      )
      ..on(finance.LoanService.getLoan, (req) {
        final answer = getLoan;
        if (answer == null) {
          throw connect.ConnectException(connect.Code.notFound, 'no loan');
        }
        return answer(req);
      })
      ..on(finance.LoanService.quoteLoan, _quote)
      ..on(
        finance.RoomService.getRoom,
        (req) => finance.GetRoomResponse(
          room:
              financeRooms[req.roomId] ??
              finance.Room(roomId: req.roomId, assets: [usdcInfo]),
        ),
      )
      ..on(
        finance.RoomService.listMembers,
        (req) => finance.ListMembersResponse(
          members: financeMembers[req.roomId] ?? const [],
        ),
      )
      ..on(
        finance.RoomService.getPolicy,
        (req) => finance.GetPolicyResponse(
          policyVersion: finance.PolicyVersion(
            constitution: finance.RoomPolicy(
              treasury: finance.Treasury(
                buckets: [
                  finance.Bucket(name: 'savings', assetIds: ['USDC.146']),
                ],
              ),
            ),
          ),
        ),
      )
      ..on(
        finance.RoomService.listPolicyTemplates,
        (req) => finance.ListPolicyTemplatesResponse(templates: templates),
      )
      ..on(
        finance.SavingsService.listRoomProducts,
        (req) => finance.ListRoomProductsResponse(
          loanProducts: loanProducts[req.roomId] ?? const [],
        ),
      )
      ..on(
        finance.GovernanceService.listProposals,
        (req) => finance.ListProposalsResponse(),
      )
      ..on(
        finance.LoanService.getCreditRecord,
        (req) => finance.GetCreditRecordResponse(
          others: finance.CreditRecord(loans: 2, onTime: 2),
          own: finance.CreditRecord(loans: 1, onTime: 1),
        ),
      );
    chatApi
      ..on(pb.ChatService.getDirectPartnerAccount, (req) {
        final partner = dmPartners[req.roomId];
        if (partner == null) {
          throw connect.ConnectException(
            connect.Code.permissionDenied,
            'not a direct message you share',
          );
        }
        return pb.GetDirectPartnerAccountResponse(
          profileId: partner.profileId,
          account: partner.account,
          deployed: partner.account.isNotEmpty,
        );
      })
      ..on(
        pb.ChatService.getRoom,
        (req) => pb.GetRoomResponse(
          room: pb.Room(id: req.roomId, stawi: bindings[req.roomId]),
        ),
      );
  }

  /// A plain quote of a personal loan: equal principal, 2.5% interest.
  finance.QuoteLoanResponse _quote(finance.QuoteLoanRequest req) {
    final amount = BigInt.parse(req.amount);
    final n = req.kind == finance.LoanKind.LOAN_KIND_GROUP
        ? req.instalments
        : req.terms.instalments;
    final each = amount ~/ BigInt.from(n);
    final interest = amount * BigInt.from(25) ~/ BigInt.from(1000);
    return finance.QuoteLoanResponse(
      instalments: [
        for (var i = 0; i < n; i++)
          finance.LoanInstalment(
            index: i,
            principal: usdUnits(each),
            interest: usdUnits(interest),
            fee: usdUnits(0),
            paid: usdUnits(0),
          ),
      ],
      totalRepayable: usdUnits(amount + interest * BigInt.from(n)),
      paidOut: usdUnits(amount),
      // A group loan's quote names the Stawi fee on its interest: 10%.
      protocolFeeBps: req.kind == finance.LoanKind.LOAN_KIND_GROUP
          ? 1000
          : null,
      protocolFeeOnInterest: req.kind == finance.LoanKind.LOAN_KIND_GROUP
          ? usdUnits(interest * BigInt.from(n) ~/ BigInt.from(10))
          : null,
    );
  }

  List<Override> overrides() {
    final keys = MemoryDeviceKeyVault();
    keys.entries['stawi.device_key.v1.$profileId'] = bytesToHex(
      hexToBytes(deviceKey),
    );
    final chat = pb.ChatServiceClient(chatApi);
    return [
      // Who is signed in, and this device.
      currentProfileIdProvider.overrideWith((ref) async => profileId),
      stawiIdentityProvider.overrideWith((ref) async => identity),
      signingGateProvider.overrideWithValue(gate),
      deviceKeyStoreProvider.overrideWith(
        (ref) => DeviceKeyStore(keys, gate: ref.watch(signingGateProvider)),
      ),
      stawiClockProvider.overrideWithValue(() => now),
      // The account is deployed: no genesis session is asked for.
      genesisSessionProofsProvider.overrideWithValue(refusingSessionProofs),
      // The services, over the fake transports.
      settlementAccountsProvider.overrideWithValue(
        settlement.AccountServiceClient(settlementApi),
      ),
      settlementRoomsProvider.overrideWithValue(
        settlement.RoomServiceClient(settlementApi),
      ),
      financeRoomsProvider.overrideWithValue(
        finance.RoomServiceClient(financeApi),
      ),
      financeTreasuryProvider.overrideWithValue(
        finance.TreasuryServiceClient(financeApi),
      ),
      financeGovernanceProvider.overrideWithValue(
        finance.GovernanceServiceClient(financeApi),
      ),
      financeSavingsProvider.overrideWithValue(
        finance.SavingsServiceClient(financeApi),
      ),
      financeLoansProvider.overrideWithValue(
        finance.LoanServiceClient(financeApi),
      ),
      financeVaultProvider.overrideWithValue(
        finance.VaultServiceClient(financeApi),
      ),
      chatServiceClientProvider.overrideWith((ref) async => chat),
      // Room acts are recorded, not queued for chat.
      stawiRoomServiceProvider.overrideWith(
        (ref) => StawiRoomService(
          rooms: ref.watch(settlementRoomsProvider),
          keys: ref.watch(deviceKeyStoreProvider),
          identity: () => ref.read(stawiIdentityProvider.future),
          send: acts.call,
          agentAccounts: ref.watch(dmPartnerAccountOfProvider),
        ),
      ),
      // The chat's local store: rooms, members, profiles and timelines.
      roomByIdProvider.overrideWith((ref, id) async => rooms[id]),
      roomMembersProvider.overrideWith(
        (ref, id) async => members[id] ?? const [],
      ),
      profileByIdProvider.overrideWith((ref, id) async => profiles[id]),
      directRoomListerProvider.overrideWithValue(
        () async => [
          for (final r in rooms.values)
            if (r.type == 'direct') DirectRoomRef(roomId: r.id, name: r.name),
        ],
      ),
      paginatedMessagesStreamProvider.overrideWith(
        (ref, params) => _timeline(params.roomId),
      ),
      stawiOutcomesProvider.overrideWith(
        (ref, id) => Stream.value(const <RoomEvent>[]),
      ),
      stawiGenesisSignaturesProvider.overrideWith(
        (ref, id) => Stream.value(const <RoomEvent>[]),
      ),
      currentUserSubscriptionIdProvider.overrideWith(
        (ref, roomId) async => 'sub-me',
      ),
      // Agent invitations go into the DM's timeline here; what is read back
      // is that timeline's invitations and acceptances, oldest first.
      agentActSenderProvider.overrideWithValue(acts.call),
      agentEventsSourceProvider.overrideWithValue(
        (dmRoomId) => _timeline(dmRoomId).map(
          (events) => [
            for (final e in events.reversed)
              if (e.type == RoomEventType.stawiAgentInvitation ||
                  e.type == RoomEventType.stawiAgentAcceptance)
                e,
          ],
        ),
      ),
      syncRoomMembersOnEntryProvider.overrideWith((ref, roomId) async {}),
      roomSyncStatusProvider.overrideWith(
        (ref, roomId) =>
            Stream.value(const RoomSyncStatus(state: RoomSyncState.ready)),
      ),
      typingProvider.overrideWith2((_) => _QuietTyping()),
    ];
  }

  /// Pumps the app on [location]: the chat of a room (`/chat/<id>`), My
  /// money (`/money`), each route as the app has it.
  Future<void> pumpApp(WidgetTester tester, String location) async {
    tester.view
      ..physicalSize = const Size(1080, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // The chat asks for the notification permission: already granted.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async => call.method == 'checkPermissionStatus' ? 1 : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        null,
      ),
    );
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(path: '/', builder: (context, state) => const Text('Chats')),
        GoRoute(
          path: '/chat/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ChatScreen(roomId: id, roomName: rooms[id]?.name ?? '');
          },
        ),
        GoRoute(
          path: '/room/:id/stawi',
          builder: (context, state) => StawiRoomScreen(
            roomId: state.pathParameters['id']!,
            roomName: state.uri.queryParameters['name'] ?? '',
          ),
        ),
        GoRoute(
          path: '/money',
          builder: (context, state) => MyMoneyScreen(showTestFunds: false),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await settle(tester);
  }
}

/// Lets the app run: frames, fake time for quotes, polls and follows.
Future<void> settle(WidgetTester tester, {int frames = 30}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapAndSettle(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f.first);
  await tester.pump();
  await tester.tap(f.first);
  await settle(tester);
}

/// [text] in the review sheet.
Finder inReview(String text) => find.descendant(
  of: find.byKey(const Key('money-review')),
  matching: find.text(text),
);

/// The value next to [label] in the review sheet.
String reviewLine(WidgetTester tester, String label) {
  final row = find.ancestor(of: inReview(label), matching: find.byType(Row));
  final texts = tester
      .widgetList<Text>(
        find.descendant(of: row.first, matching: find.byType(Text)),
      )
      .map((t) => t.data ?? '')
      .toList();
  return texts.last;
}
