import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_dues_plan_service.dart';
import 'package:stawi/features/stawi/domain/dues_plan.dart';
import 'package:stawi/features/stawi/domain/intent_bridge.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi/features/stawi/domain/stawi_money.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart'
    show recoverDeviceAddress;
import 'package:xid/xid.dart';

import '../../../support/stawi_fakes.dart';

void main() {
  final v = GoEngineCallVector.load().firstWhere(
    (v) => v.name == 'loan_request',
  );
  final account = v.account;
  final custody = Uint8List(20)..[19] = 0x31;
  final room = RoomContracts(
    governance: Uint8List(20)..[19] = 0x30,
    custody: custody,
    chainId: BigInt.parse(v.intent.domain.chainId.toStringUnsigned()),
  );
  final intentId = Xid.fromString('d3m1q8n2v0s4c5k6p7a0');
  final usdc = StawiAsset.fromInfo(
    finance.AssetInfo(assetId: 'usdc', symbol: 'USDC', decimals: 6),
  );

  /// The plan's AUTHORIZATION_GRANT as finance builds it: on the member's
  /// account, paying the room's custody, moving nothing.
  finance.FinancialIntent grant({
    finance.IntentType type =
        finance.IntentType.INTENT_TYPE_AUTHORIZATION_GRANT,
    List<int>? to,
    String amount = '0',
    List<int>? on,
  }) {
    final i = v.intent.deepCopy()
      ..intentId = intentId.toBytes()
      ..type = type
      ..mode = finance.AuthorizationMode.AUTHORIZATION_MODE_DIRECT_SIGNATURE
      ..account = on ?? account
      ..destination = finance.ValueLocation(
        kind: finance.LocationKind.LOCATION_KIND_ROOM_CUSTODY,
        address: to ?? custody,
        bucket: 'savings',
      )
      ..amount = amount;
    return i..intentDigest = intentDigestOf(sdkIntentOf(i));
  }

  group('checkedDuesGrant', () {
    test('signs the grant finance built for this room', () {
      final i = grant();
      expect(checkedDuesGrant(i, account: account, room: room), i.intentDigest);
    });

    void refuses(finance.FinancialIntent i, String reason) => expect(
      () => checkedDuesGrant(i, account: account, room: room),
      throwsA(isA<SigningRefused>().having((e) => e.reason, 'r', reason)),
    );

    test('refuses a grant to another room', () {
      refuses(
        grant(to: Uint8List(20)..[19] = 0x99),
        'the grant does not pay this room',
      );
    });

    test('refuses a grant that moves money, or on another account', () {
      refuses(grant(amount: '5'), 'installing the grant would move money');
      refuses(
        grant(on: Uint8List(20)..[19] = 0x01),
        'the intent is not on your account',
      );
    });

    test('refuses another intent, or a digest its contents do not give', () {
      refuses(
        grant(type: finance.IntentType.INTENT_TYPE_TRANSFER),
        'finance prepared another kind of intent',
      );
      refuses(
        grant()..intentDigest = Uint8List(32),
        'the intent digest is not the one its contents give',
      );
    });

    test('a revoke is checked the same way', () {
      final i = grant(
        type: finance.IntentType.INTENT_TYPE_AUTHORIZATION_REVOKE,
      );
      expect(checkedDuesRevoke(i, account: account), i.intentDigest);
      expect(
        () => checkedDuesRevoke(grant(), account: account),
        throwsA(isA<SigningRefused>()),
      );
    });
  });

  test('an intent id is its xid', () {
    expect(intentIdOf(intentId.toBytes()), intentId.toString());
    final fresh = Xid();
    expect(intentIdOf(fresh.toBytes()), fresh.toString());
  });

  test('a plan follows the room\'s calendar and its period\'s dues', () {
    expect(
      cadenceFor(
        finance.RoomCalendar(
          unit: finance.PeriodUnit.PERIOD_UNIT_WEEK,
          length: 1,
        ),
      ),
      finance.Cadence.CADENCE_WEEKLY,
    );
    expect(
      cadenceFor(
        finance.RoomCalendar(
          unit: finance.PeriodUnit.PERIOD_UNIT_MONTH,
          length: 1,
        ),
      ),
      finance.Cadence.CADENCE_MONTHLY,
    );
    expect(
      cadenceFor(
        finance.RoomCalendar(
          unit: finance.PeriodUnit.PERIOD_UNIT_WEEK,
          length: 3,
        ),
      ),
      isNull,
    );
    final dues = finance.MemberDues(
      products: [
        finance.MemberProductDues(
          nextDueAmount: finance.Money(assetId: 'usdc', amount: '1000'),
        ),
        finance.MemberProductDues(
          nextDueAmount: finance.Money(assetId: 'usdc', amount: '250'),
        ),
      ],
    );
    expect(duesPerPeriod(dues)!.amount, '1250');
    expect(duesPerPeriod(finance.MemberDues()), isNull);
  });

  group('StawiDuesPlanService', () {
    late FakeConnectTransport transport;
    late RecordingSigningGate gate;
    const roomId = 'room00000000000000aa';
    final member = finance.Member(memberId: 'mem00000000000000001');

    StawiDuesPlanService service() => StawiDuesPlanService(
      savings: finance.SavingsServiceClient(transport),
      intents: finance.IntentServiceClient(transport),
      keys: DeviceKeyStore(vaultWith('p1', v.devicePrivateKey), gate: gate),
      identity: () async => identityWith('p1', account),
      membership: (_) async => member,
      contracts: (_) async => room,
      newKey: () => 'key',
    );

    setUp(() {
      transport = FakeConnectTransport();
      gate = RecordingSigningGate();
    });

    test(
      'turning it on creates the plan, checks and signs its grant',
      () async {
        transport
          ..on(
            finance.SavingsService.createPlan,
            (req) => finance.CreatePlanResponse(
              plan: finance.SavingsPlan(planId: 'plan0000000000000001'),
              authorizationIntent: finance.IntentRecord(intent: grant()),
            ),
          )
          ..on(
            finance.IntentService.authorizeIntent,
            (req) => finance.AuthorizeIntentResponse(),
          );
        final s = service();
        final prepared = await s.prepareTurnOn(
          roomId: roomId,
          perPeriod: finance.Money(assetId: 'usdc', amount: '1250000'),
          cadence: finance.Cadence.CADENCE_WEEKLY,
          asset: usdc,
          roomName: 'Chama',
        );
        expect(gate.reasons, isEmpty);
        expect(prepared.review.title, 'Pay my dues in Chama automatically');
        expect(prepared.review.lines.first, ('Collects up to', '1.25 USDC'));
        final create = transport
            .requestsTo(finance.SavingsService.createPlan)
            .single;
        expect(create.roomId, roomId);
        expect(create.memberId, member.memberId);
        expect(create.account, account);
        expect(create.cadence, finance.Cadence.CADENCE_WEEKLY);
        expect(create.amountPerPeriod.amount, '1250000');

        await s.authorize(prepared);
        expect(gate.reasons, [prepared.review.title]);
        final auth = transport
            .requestsTo(finance.IntentService.authorizeIntent)
            .single;
        expect(auth.intentId, intentId.toString());
        expect(auth.intentDigest, grant().intentDigest);
        expect(
          recoverDeviceAddress(
            auth.intentDigest,
            auth.authorization.deviceSignature.signature,
          ),
          await deviceAddressOf(v.devicePrivateKey),
        );
      },
    );

    test('a grant to another room is never signed', () async {
      transport.on(
        finance.SavingsService.createPlan,
        (req) => finance.CreatePlanResponse(
          authorizationIntent: finance.IntentRecord(
            intent: grant(to: Uint8List(20)..[19] = 0x99),
          ),
        ),
      );
      await expectLater(
        service().prepareTurnOn(
          roomId: roomId,
          perPeriod: finance.Money(assetId: 'usdc', amount: '1'),
          cadence: finance.Cadence.CADENCE_WEEKLY,
          asset: usdc,
        ),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        transport.requestsTo(finance.IntentService.authorizeIntent),
        isEmpty,
      );
    });

    test('turning it off cancels the plan and signs the revoke', () async {
      transport
        ..on(
          finance.SavingsService.cancelPlan,
          (req) => finance.CancelPlanResponse(
            revokeIntent: finance.IntentRecord(
              intent: grant(
                type: finance.IntentType.INTENT_TYPE_AUTHORIZATION_REVOKE,
              ),
            ),
          ),
        )
        ..on(
          finance.IntentService.authorizeIntent,
          (req) => finance.AuthorizeIntentResponse(),
        );
      final s = service();
      final prepared = await s.prepareTurnOff(
        roomId: roomId,
        plan: finance.SavingsPlan(planId: 'plan0000000000000001'),
      );
      await s.authorize(prepared);
      expect(
        transport.requestsTo(finance.SavingsService.cancelPlan).single.planId,
        'plan0000000000000001',
      );
      expect(
        transport.requestsTo(finance.IntentService.authorizeIntent),
        hasLength(1),
      );
    });

    test('the live plan is the one not cancelled', () async {
      transport.on(
        finance.SavingsService.listPlans,
        (req) => finance.ListPlansResponse(
          plans: [
            finance.SavingsPlan(
              planId: 'a',
              state: finance.PlanState.PLAN_STATE_CANCELLED,
            ),
            finance.SavingsPlan(
              planId: 'b',
              state: finance.PlanState.PLAN_STATE_ACTIVE,
            ),
          ],
        ),
      );
      expect((await service().myPlan(roomId))!.planId, 'b');
    });
  });
}
