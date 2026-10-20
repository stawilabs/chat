/// A rotation (merry-go-round): every period each member pays into the room,
/// and one member at a time, in the order the group voted, receives the pot.
/// The device checks the cycle settlement prepares before it signs the vote
/// that opens it, and reads the cycle back from finance to show where it
/// stands.
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import 'governance_requests.dart';
import 'signing_checks.dart';
import 'stawi_money.dart';

/// A member as a rotation names them: their membership and account.
final class RotationPick {
  const RotationPick({
    required this.memberId,
    required this.profileId,
    required this.name,
    required this.account,
  });

  final String memberId;
  final String profileId;
  final String name;
  final Uint8List account;
}

/// The members a rotation may name: ACTIVE on chain with an account,
/// named by their chat name (else "Member 0x1234…abcd").
List<RotationPick> rotationCandidates(
  Iterable<({String? profileId, String name})> chat,
  Iterable<finance.Member> onChain,
) {
  final names = {
    for (final c in chat)
      if (c.profileId case final id? when id.isNotEmpty) id: c.name,
  };
  return [
    for (final m in onChain)
      if (m.state == finance.MemberState.MEMBER_STATE_ACTIVE &&
          m.accountAddress.length == 20 &&
          m.accountAddress.any((b) => b != 0))
        RotationPick(
          memberId: m.memberId,
          profileId: m.profileId,
          name:
              names[m.profileId] ?? 'Member ${shortAccount(m.accountAddress)}',
          account: Uint8List.fromList(m.accountAddress),
        ),
  ];
}

/// [order] shuffled with [random] (a fresh secure one by default): the
/// order the person sees and the group votes on.
List<T> shuffledOrder<T>(List<T> order, [Random? random]) =>
    List<T>.of(order)..shuffle(random ?? Random.secure());

/// The fewest and most members a rotation names (settlement's bounds).
const int minRotationMembers = 2;
const int maxRotationMembers = 256;

/// How far settlement's clock may be from the device's when it fixes the
/// first turn.
const Duration rotationClockSlack = Duration(minutes: 10);

/// The module's least timelock and settlement's hour to apply a passed vote.
const int _minTimelockSeconds = 3600;
const int _applySlackSeconds = 3600;

/// When period [q] of the room's clock [m] begins, in unix seconds.
int periodStartSeconds(finance.PeriodModel m, int q) =>
    m.epochStart.toInt() + q * m.periodSeconds.toInt();

/// The first period of [m] that begins at or after [fromSeconds] (Go
/// settlement rotationFirstPeriod).
int firstPeriodFrom(finance.PeriodModel m, int fromSeconds) {
  final seconds = m.periodSeconds.toInt();
  final epoch = m.epochStart.toInt();
  var q = fromSeconds < epoch ? 0 : (fromSeconds - epoch) ~/ seconds;
  if (periodStartSeconds(m, q) < fromSeconds) q++;
  return q;
}

int _unix(DateTime t) => t.toUtc().millisecondsSinceEpoch ~/ 1000;

DateTime _at(int seconds) =>
    DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

/// When turn [turn] of [r] becomes payable on its period clock.
DateTime rotationTurnStarts(settlement.RoomRotation r, int turn) => _at(
  r.periodEpochStart.toInt() + (r.firstPeriod + turn) * r.periodSeconds.toInt(),
);

/// Shown when settlement's cycle is not the rotation the person chose.
const String notTheRotation =
    'settlement prepared another rotation than the one you chose';

/// Checks the cycle settlement's rotation PROPOSE opens (RoomCall.rotation)
/// against what the person chose, and returns it:
///   - the members' accounts in exactly the order chosen;
///   - the pot is [contribution] × the members;
///   - a 32-byte cycle id;
///   - the period clock is the room's, as the constitution finance holds in
///     force states it ([inForce]'s period model);
///   - the first turn is the first period beginning at or after [startsAt]
///     or, with none, the first one after the vote can apply (voting
///     period, reveal window, timelock and settlement's hour, within
///     [rotationClockSlack] of [now]).
/// The payload hash is then rebuilt from these values by the SDK
/// (RoomCallExpected.proposeRotation), so the proposal signed is this cycle.
settlement.RoomRotation checkedRotation({
  required settlement.PrepareRoomCallResponse prepared,
  required List<Uint8List> order,
  required BigInt contribution,
  required finance.RoomPolicy inForce,
  required DateTime now,
  DateTime? startsAt,
}) {
  if (!prepared.call.hasRotation()) {
    throw const SigningRefused(
      'settlement did not say which rotation it opens',
    );
  }
  final r = prepared.call.rotation;
  if (r.order.length != order.length ||
      [for (var i = 0; i < order.length; i++) i]
          .any((i) => !bytesEqual(r.order[i], order[i]))) {
    throw const SigningRefused(
      'the rotation\'s turn order is not the one you chose',
    );
  }
  final pot = BigInt.tryParse(r.pot);
  if (pot == null || pot != contribution * BigInt.from(order.length)) {
    throw const SigningRefused('the rotation\'s pot is not what you chose');
  }
  if (r.cycleId.length != 32 || r.cycleId.every((b) => b == 0)) {
    throw const SigningRefused('the rotation names no cycle');
  }
  final clock = inForce.periodModel;
  if (clock.periodSeconds <= Int64.ZERO ||
      r.periodSeconds != clock.periodSeconds ||
      r.periodEpochStart != clock.epochStart) {
    throw const SigningRefused(
      'the rotation\'s periods are not the room\'s periods',
    );
  }
  final first = r.firstPeriod;
  final starts = periodStartSeconds(clock, first);
  final before = first == 0 ? null : periodStartSeconds(clock, first - 1);
  final skew = rotationClockSlack.inSeconds;
  if (startsAt != null) {
    final from = _unix(startsAt);
    if (starts < from || (before != null && before >= from)) {
      throw const SigningRefused(
        'the rotation does not start in the period you chose',
      );
    }
  } else {
    final std = inForce.governance.standard;
    final voting = std.votingPeriodSeconds.toInt();
    final reveal = std.revealWindowSeconds == Int64.ZERO
        ? voting
        : std.revealWindowSeconds.toInt();
    final timelock = max(std.timelockSeconds.toInt(), _minTimelockSeconds);
    final at = _unix(now);
    final earliest = at + voting + timelock + _applySlackSeconds - skew;
    final latest = at + voting + reveal + timelock + _applySlackSeconds + skew;
    if (starts < earliest || (before != null && before >= latest)) {
      throw const SigningRefused(
        'the rotation does not start once the vote can take effect',
      );
    }
  }
  return r;
}

/// The vote that opens a rotation: [order] the members in turn order, each
/// paying [contribution] minor units of [asset] per period, from the first
/// period at or after [startsAt] (none: as soon as the vote can apply).
/// Settlement prepares the cycle; the device checks it ([checkedRotation])
/// and the SDK rebuilds the proposal from it.
GovernanceRequest proposeRotationRequest({
  required List<RotationPick> order,
  required BigInt contribution,
  required finance.PolicyVersion inForce,
  required StawiAsset asset,
  DateTime? startsAt,
  DateTime Function() clock = DateTime.now,
}) {
  if (order.length < minRotationMembers || order.length > maxRotationMembers) {
    throw ArgumentError.value(order.length, 'order', 'names 2 to 256 members');
  }
  if (contribution <= BigInt.zero) {
    throw ArgumentError.value(contribution, 'contribution', 'is positive');
  }
  final accounts = [for (final p in order) p.account];
  final pot = contribution * BigInt.from(order.length);
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE,
    params: settlement.RoomCallParams(
      propose: settlement.RoomProposeParams(
        rotation: settlement.RoomRotationTerms(
          members: [
            for (final a in accounts) settlement.RoomMemberRef(account: a),
          ],
          contribution: contribution.toString(),
          startsAt: startsAt == null
              ? null
              : Timestamp.fromDateTime(startsAt.toUtc()),
        ),
      ),
    ),
    summary: 'Propose a rotation of ${order.length} members',
    expected: (room, prepared) {
      final r = checkedRotation(
        prepared: prepared,
        order: accounts,
        contribution: contribution,
        inForce: inForce.constitution,
        now: clock(),
        startsAt: startsAt,
      );
      return RoomCallExpected.proposeRotation(
        custody:
            room.custody ??
            (throw const SigningRefused(roomContractsUnknownReason)),
        cycleId: r.cycleId,
        order: r.order,
        pot: BigInt.parse(r.pot),
        firstPeriod: r.firstPeriod,
      );
    },
    lines: [
      ('Each member pays', '${formatUnits(contribution, asset)} a period'),
      ('Each turn receives', formatUnits(pot, asset)),
      for (final (i, p) in order.indexed) ('Turn ${i + 1}', p.name),
    ],
    linesOf: (prepared) {
      final r = prepared.call.rotation;
      return [
        ('First payout from', dayWords(rotationTurnStarts(r, 0))),
        (
          'Last payout from',
          dayWords(rotationTurnStarts(r, r.order.length - 1)),
        ),
      ];
    },
  );
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "12 Oct 2026" in the device's local time.
String dayWords(DateTime t) {
  final l = t.toLocal();
  return '${l.day} ${_months[l.month - 1]} ${l.year}';
}

/// The room's period in words: "week", "2 weeks", "day", "30 days".
String periodWords(finance.PeriodModel m) {
  final s = m.periodSeconds.toInt();
  const day = 86400;
  if (s <= 0) return 'period';
  if (s % (7 * day) == 0) {
    final w = s ~/ (7 * day);
    return w == 1 ? 'week' : '$w weeks';
  }
  if (s % day == 0) {
    final d = s ~/ day;
    return d == 1 ? 'day' : '$d days';
  }
  final h = (s / 3600).round();
  return h == 1 ? 'hour' : '$h hours';
}

/// One rotation cycle as the room reads it.
final class RotationStatus {
  const RotationStatus(this.cycle);

  final finance.RotationCycle cycle;

  bool get completed =>
      cycle.state == finance.RotationCycleState.ROTATION_CYCLE_STATE_COMPLETED;

  finance.RotationTurn? turn(int k) =>
      cycle.turns.where((t) => t.turn == k).firstOrNull;

  /// The turn under way: the first not yet paid or skipped.
  finance.RotationTurn? get current =>
      completed ? null : turn(cycle.currentTurn);

  /// The turn after it.
  finance.RotationTurn? get next =>
      completed ? null : turn(cycle.currentTurn + 1);

  /// The turns already paid, in order.
  List<finance.RotationTurn> get payouts => [
    for (final t in cycle.turns)
      if (t.state == finance.RotationTurnState.ROTATION_TURN_STATE_PAID) t,
  ];

  /// The members late with their contribution when settlement last looked.
  List<finance.RotationMember> get late => [
    for (final m in cycle.members)
      if (m.late) m,
  ];

  /// Whether the members' dues were read live (GetRotation include_dues).
  bool get duesRead => cycle.members.any((m) => m.hasDues());

  /// Paid up for this period: their dues read live stand CURRENT.
  bool paidUp(finance.RotationMember m) =>
      m.hasDues() &&
      m.dues.standing ==
          finance.MemberDuesStanding.MEMBER_DUES_STANDING_CURRENT;

  /// The member [turn] pays.
  finance.RotationMember? memberOf(finance.RotationTurn t) =>
      cycle.members.where((m) => bytesEqual(m.account, t.account)).firstOrNull;
}

/// A turn's state in words.
String turnStateWords(finance.RotationTurn t) => switch (t.state) {
  finance.RotationTurnState.ROTATION_TURN_STATE_UPCOMING => 'Upcoming',
  finance.RotationTurnState.ROTATION_TURN_STATE_DUE => 'Due now',
  finance.RotationTurnState.ROTATION_TURN_STATE_WAITING =>
    'Waiting on late contributions',
  finance.RotationTurnState.ROTATION_TURN_STATE_PAID => 'Paid',
  finance.RotationTurnState.ROTATION_TURN_STATE_SKIPPED => 'Passed over',
  _ => '',
};

/// The rotation chat cards (finance projection money_cards).
abstract final class RotationCards {
  static const String started = 'ROTATION_STARTED';
  static const String turn = 'ROTATION_TURN';
  static const String late = 'ROTATION_LATE';
  static const String skipped = 'ROTATION_SKIPPED';
  static const String payout = 'ROTATION_PAYOUT';

  static const Set<String> all = {started, turn, late, skipped, payout};
}

/// The 20-byte accounts a comma-separated 0x list names (a card's `late`
/// or `order`), skipping anything else.
List<Uint8List> accountsOfList(String? list) => [
  for (final s in (list ?? '').split(','))
    if (RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(s.trim())) hexToBytes(s.trim()),
];

/// A card's single account (its `recipient`), or null.
Uint8List? accountOf(String? hex) {
  final list = accountsOfList(hex);
  return list.length == 1 ? list.single : null;
}
