import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:xid/xid.dart';

import '../domain/dues_plan.dart';
import '../domain/money_review.dart';
import '../domain/signing_checks.dart';
import '../domain/stawi_money.dart';
import '../domain/stawi_payloads.dart' show secp256k1Algorithm;
import 'device_key_store.dart';
import 'stawi_clients.dart';
import 'stawi_finance_service.dart';
import 'stawi_identity.dart';
import 'stawi_room_service.dart';

/// A room's "Pay my dues automatically": finance's savings plan for the
/// member and the standing grant it installs on their account, so
/// settlement collects each period's dues from the wallet (finance
/// SavingsService CreatePlan / CancelPlan, IntentService AuthorizeIntent).
/// Finance prepares the grant's intent; the device checks it and signs it.
class StawiDuesPlanService {
  StawiDuesPlanService({
    required this._savings,
    required this._intents,
    required this._keys,
    required this._identity,
    required this._membership,
    required this._contracts,
    String Function()? newKey,
  }) : _newKey = newKey ?? (() => Xid().toString());

  final finance.SavingsServiceClient _savings;
  final finance.IntentServiceClient _intents;
  final DeviceKeyStore _keys;
  final Future<StawiIdentity> Function() _identity;
  final Future<finance.Member?> Function(String roomId) _membership;
  final RoomContractsSource _contracts;
  final String Function() _newKey;

  /// The member's live plan in [roomId] (waiting for its grant, on, or
  /// paused); null when there is none.
  Future<finance.SavingsPlan?> myPlan(String roomId) async {
    final member = await _membership(roomId);
    if (member == null) return null;
    final plans = (await _savings.listPlans(
      finance.ListPlansRequest(roomId: roomId, memberId: member.memberId),
    )).plans;
    return plans.where((p) => duesPlanLive(p.state)).firstOrNull;
  }

  /// Turns automatic dues on: a plan of [perPeriod] each [cadence] period,
  /// and the AUTHORIZATION_GRANT intent finance returns, checked on the
  /// device ([checkedDuesGrant]). Nothing is signed yet.
  Future<PreparedPlanAuthorization> prepareTurnOn({
    required String roomId,
    required finance.Money perPeriod,
    required finance.Cadence cadence,
    required StawiAsset asset,
    String roomName = 'this room',
  }) async {
    final (member, account, room) = await _context(roomId);
    final created = await _savings.createPlan(
      finance.CreatePlanRequest(
        idempotencyKey: _newKey(),
        roomId: roomId,
        memberId: member.memberId,
        account: account,
        amountPerPeriod: perPeriod,
        cadence: cadence,
      ),
    );
    final record = created.authorizationIntent;
    final digest = checkedDuesGrant(
      record.intent,
      account: account,
      room: room,
    );
    final amount = BigInt.tryParse(perPeriod.amount) ?? BigInt.zero;
    return PreparedPlanAuthorization._(
      intentId: intentIdOf(record.intent.intentId),
      digest: digest,
      account: account,
      review: MoneyReview(
        title: 'Pay my dues in $roomName automatically',
        lines: [
          ('Collects up to', formatUnits(amount, asset)),
          ('Every', cadenceLabel(cadence)),
          ('From', 'Your Stawi wallet'),
        ],
        notes: const [duesAutoPayNote, duesGrantCheckedNote],
        signLabel: 'Confirm and sign',
        done: 'Automatic dues are on',
      ),
    );
  }

  /// Turns automatic dues off: cancels [plan] and checks the
  /// AUTHORIZATION_REVOKE intent finance returns. Nothing is signed yet.
  Future<PreparedPlanAuthorization> prepareTurnOff({
    required String roomId,
    required finance.SavingsPlan plan,
    String roomName = 'this room',
  }) async {
    final (_, account, _) = await _context(roomId);
    final cancelled = await _savings.cancelPlan(
      finance.CancelPlanRequest(
        idempotencyKey: _newKey(),
        planId: plan.planId,
        reason: 'turned off by the member',
      ),
    );
    if (!cancelled.hasRevokeIntent()) {
      // A plan whose grant was never installed has nothing to revoke.
      return PreparedPlanAuthorization._nothingToSign(account);
    }
    final digest = checkedDuesRevoke(
      cancelled.revokeIntent.intent,
      account: account,
    );
    return PreparedPlanAuthorization._(
      intentId: intentIdOf(cancelled.revokeIntent.intent.intentId),
      digest: digest,
      account: account,
      review: MoneyReview(
        title: 'Stop paying my dues in $roomName automatically',
        lines: const [('From now', 'Pay each period yourself')],
        notes: const [duesGrantCheckedNote],
        signLabel: 'Confirm and sign',
        done: 'Automatic dues are off',
      ),
    );
  }

  /// Signs the checked intent behind the device lock (its review title) and
  /// attaches the signature (AuthorizeIntent).
  Future<finance.IntentRecord?> authorize(
    PreparedPlanAuthorization prepared,
  ) async {
    if (prepared.digest == null) return null;
    final me = await _identity();
    final key = await _keys.unlock(me.profileId, reason: prepared.review.title);
    return (await _intents.authorizeIntent(
      finance.AuthorizeIntentRequest(
        idempotencyKey: _newKey(),
        intentId: prepared.intentId,
        intentDigest: prepared.digest,
        authorization: finance.Authorization(
          deviceSignature: finance.DeviceSignature(
            deviceKeyId: key.keyId,
            algorithm: secp256k1Algorithm,
            signature: key.sign(prepared.digest!),
          ),
        ),
      ),
    )).intent;
  }

  Future<(finance.Member, Uint8List, RoomContracts)> _context(
    String roomId,
  ) async {
    final me = await _identity();
    final account = me.primary;
    if (account == null) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
    final member = await _membership(roomId);
    if (member == null) {
      throw const StawiUnavailable('You are not a member of this room yet');
    }
    final room = await _contracts(roomId);
    if (room == null || room.custody == null) {
      throw const SigningRefused(roomContractsUnknownReason);
    }
    return (member, account.address, room);
  }
}

/// A plan's grant or revoke intent finance prepared and the device checked,
/// awaiting the person's review.
final class PreparedPlanAuthorization {
  const PreparedPlanAuthorization._({
    required this.intentId,
    required Uint8List this.digest,
    required this.account,
    required this.review,
  });

  PreparedPlanAuthorization._nothingToSign(this.account)
    : intentId = '',
      digest = null,
      review = const MoneyReview(
        title: 'Automatic dues are off',
        lines: [],
        signLabel: 'Done',
        done: 'Automatic dues are off',
      );

  final String intentId;

  /// The digest to sign; null when there is nothing to sign.
  final Uint8List? digest;
  final Uint8List account;
  final MoneyReview review;
}

final stawiDuesPlanServiceProvider = Provider<StawiDuesPlanService>((ref) {
  return StawiDuesPlanService(
    savings: ref.watch(financeSavingsProvider),
    intents: ref.watch(financeIntentsProvider),
    keys: ref.watch(deviceKeyStoreProvider),
    identity: () => ref.read(stawiIdentityProvider.future),
    membership: (roomId) =>
        ref.read(stawiFinanceServiceProvider).myMembership(roomId),
    contracts: financeContractsSource(ref.watch(financeRoomsProvider)),
  );
});

/// The member's live dues plan in a room; null when automatic dues are off.
final stawiDuesPlanProvider = FutureProvider.autoDispose
    .family<finance.SavingsPlan?, String>(
      (ref, roomId) => ref.watch(stawiDuesPlanServiceProvider).myPlan(roomId),
      retry: (_, _) => null,
    );
