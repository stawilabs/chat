/// Automatic dues, as the device checks and words them.
library;

import 'dart:typed_data';

import 'package:stawi_api/finance_v1.dart' as finance;

import 'intent_bridge.dart';
import 'signing_checks.dart';

/// Whether a plan still collects, or will once its grant is signed.
bool duesPlanLive(finance.PlanState state) => switch (state) {
  finance.PlanState.PLAN_STATE_PENDING_AUTHORIZATION ||
  finance.PlanState.PLAN_STATE_ACTIVE ||
  finance.PlanState.PLAN_STATE_PAUSED => true,
  _ => false,
};

/// The digest to sign for the standing grant a dues plan installs: the
/// intent recomputed on the device (stawi_finance_sdk), and only when it is
/// a DIRECT_SIGNATURE AUTHORIZATION_GRANT on the member's own [account], on
/// the room's chain, naming the room's custody as where the grant pays and
/// moving nothing itself.
Uint8List checkedDuesGrant(
  finance.FinancialIntent intent, {
  required Uint8List account,
  required RoomContracts room,
}) {
  final checked = _checkedIntent(
    intent,
    account: account,
    type: finance.IntentType.INTENT_TYPE_AUTHORIZATION_GRANT,
  );
  if (BigInt.parse(intent.domain.chainId.toStringUnsigned()) != room.chainId) {
    throw const SigningRefused('the grant is for another chain');
  }
  if (intent.destination.kind !=
          finance.LocationKind.LOCATION_KIND_ROOM_CUSTODY ||
      room.custody == null ||
      !bytesEqual(intent.destination.address, room.custody!)) {
    throw const SigningRefused('the grant does not pay this room');
  }
  if (checked.amount != BigInt.zero) {
    throw const SigningRefused('installing the grant would move money');
  }
  return checked.digest;
}

/// The digest to sign for revoking a dues plan's grant: a DIRECT_SIGNATURE
/// AUTHORIZATION_REVOKE on the member's own [account] that moves nothing.
Uint8List checkedDuesRevoke(
  finance.FinancialIntent intent, {
  required Uint8List account,
}) {
  final checked = _checkedIntent(
    intent,
    account: account,
    type: finance.IntentType.INTENT_TYPE_AUTHORIZATION_REVOKE,
  );
  if (checked.amount != BigInt.zero) {
    throw const SigningRefused('revoking the grant would move money');
  }
  return checked.digest;
}

({Uint8List digest, BigInt amount}) _checkedIntent(
  finance.FinancialIntent intent, {
  required Uint8List account,
  required finance.IntentType type,
}) {
  if (intent.type != type) {
    throw const SigningRefused('finance prepared another kind of intent');
  }
  if (intent.mode !=
      finance.AuthorizationMode.AUTHORIZATION_MODE_DIRECT_SIGNATURE) {
    throw const SigningRefused('the intent is not for your signature');
  }
  if (!bytesEqual(intent.account, account)) {
    throw const SigningRefused('the intent is not on your account');
  }
  final decoded = sdkIntentOf(intent);
  final digest = intentDigestOf(decoded);
  if (intent.intentDigest.isNotEmpty &&
      !bytesEqual(intent.intentDigest, digest)) {
    throw const SigningRefused(
      'the intent digest is not the one its contents give',
    );
  }
  return (digest: digest, amount: decoded.amount);
}

/// The plan's cadence for a room's calendar ([calendar]): a day, a week, two
/// weeks or a month; null for a calendar no plan cadence follows.
finance.Cadence? cadenceFor(finance.RoomCalendar calendar) => switch ((
  calendar.unit,
  calendar.length,
)) {
  (finance.PeriodUnit.PERIOD_UNIT_DAY, 1) => finance.Cadence.CADENCE_DAILY,
  (finance.PeriodUnit.PERIOD_UNIT_WEEK, 1) => finance.Cadence.CADENCE_WEEKLY,
  (finance.PeriodUnit.PERIOD_UNIT_WEEK, 2) ||
  (finance.PeriodUnit.PERIOD_UNIT_DAY, 14) => finance.Cadence.CADENCE_BIWEEKLY,
  (finance.PeriodUnit.PERIOD_UNIT_MONTH, 1) => finance.Cadence.CADENCE_MONTHLY,
  (finance.PeriodUnit.PERIOD_UNIT_DAY, 7) => finance.Cadence.CADENCE_WEEKLY,
  _ => null,
};

/// "day", "week", "two weeks", "month".
String cadenceLabel(finance.Cadence c) => switch (c) {
  finance.Cadence.CADENCE_DAILY => 'Day',
  finance.Cadence.CADENCE_WEEKLY => 'Week',
  finance.Cadence.CADENCE_BIWEEKLY => 'Two weeks',
  finance.Cadence.CADENCE_MONTHLY => 'Month',
  _ => 'Period',
};

/// What a plan collects each period: the dues of one period across the
/// room's products ([finance.MemberDues] next due amounts), in their asset;
/// null when there are none.
finance.Money? duesPerPeriod(finance.MemberDues dues) {
  var total = BigInt.zero;
  String? asset;
  for (final p in dues.products) {
    final amount = BigInt.tryParse(p.nextDueAmount.amount) ?? BigInt.zero;
    if (amount <= BigInt.zero) continue;
    if (asset != null && asset != p.nextDueAmount.assetId) return null;
    asset = p.nextDueAmount.assetId;
    total += amount;
  }
  if (asset == null || total <= BigInt.zero) return null;
  return finance.Money(assetId: asset, amount: total.toString());
}

/// The 20-character id of a 12-byte xid (finance's intent ids): base32hex,
/// lower case, no padding.
String intentIdOf(List<int> id) {
  if (id.length != 12) {
    throw const SigningRefused('the intent has no id');
  }
  const alphabet = '0123456789abcdefghijklmnopqrstuv';
  final out = StringBuffer();
  var buffer = 0;
  var bits = 0;
  for (final b in id) {
    buffer = (buffer << 8) | b;
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      out.write(alphabet[(buffer >> bits) & 31]);
    }
  }
  if (bits > 0) out.write(alphabet[(buffer << (5 - bits)) & 31]);
  return out.toString();
}

/// What the switch's review says the plan does.
const String duesAutoPayNote =
    'Each period settlement collects what you owe in dues from your wallet, '
    'up to this amount. Keep enough in your wallet; turn it off any time.';

/// What the device checked before the plan's grant or revoke is signed.
const String duesGrantCheckedNote =
    'Checked on this device: the authorization is on your account, pays only '
    'this room, and moves no money by itself.';
