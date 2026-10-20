/// Changing a Stawi room's rules after its genesis: a POLICY_CHANGE vote on
/// the rules settlement compiles from the values the person chose
/// (settlement RoomProposeParams.rule_changes, stawi v0.2.6).
///
/// Settlement compiles the new constitution, its three policy documents and
/// the chain's SecurityParams, and proposes
/// GovernanceModule.policyChangePayloadHash of them. Nothing is signed on its
/// word: the device checks the documents hash to the hashes, that the new
/// constitution is the one finance holds in force with exactly the chosen
/// rules changed, that the voting params follow from it and nothing else in
/// them moved, and rebuilds the payload hash the proposal must carry.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_api/well_known.dart' as wkt;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import 'governance_requests.dart';
import 'proposal_documents.dart';
import 'signing_checks.dart';
import 'stawi_money.dart' show formatBps;

/// How a rule is entered and shown.
enum RuleUnit {
  /// A share, typed as a percentage with up to two decimals (basis points on
  /// the wire).
  percent,

  /// Whole days (seconds on the wire).
  days,

  /// Whole hours (seconds on the wire).
  hours,

  /// A count of people.
  people,
}

const int _day = 86400;
const int _hour = 3600;

/// One rule a policy vote may change (settlement PolicyRuleNames), with the
/// range settlement's templates accept (pkg/policy/templates Rules).
enum GroupRule {
  quorum(
    'quorum_bps',
    'Quorum',
    'How many members must vote for a decision to count',
    RuleUnit.percent,
    1000,
    10000,
  ),
  approval(
    'pass_bps',
    'Approval needed',
    'Share of the votes a decision needs to pass',
    RuleUnit.percent,
    5001,
    10000,
  ),
  votingPeriod(
    'voting_period',
    'Voting time',
    'How long a vote stays open',
    RuleUnit.days,
    _day,
    30 * _day,
  ),
  timelock(
    'timelock',
    'Waiting time after a vote passes',
    'How long a passed decision waits before it takes effect',
    RuleUnit.hours,
    0,
    30 * _day,
  ),
  voterLookback(
    'voter_lookback',
    'Who may vote',
    'Only people who were members this long before a proposal vote on it',
    RuleUnit.days,
    _day,
    30 * _day,
  ),
  minimumActive(
    'minimum_active_members',
    'Fewest active members',
    'With fewer active members the group goes inactive',
    RuleUnit.people,
    1,
    200,
  ),
  maxMembers(
    'max_members',
    'Most members',
    'The most members the group admits',
    RuleUnit.people,
    1,
    10000,
  ),
  withdrawalFee(
    'withdrawal_fee_bps',
    'Withdrawal fee',
    'The protocol fee on a group withdrawal (0 charges none)',
    RuleUnit.percent,
    0,
    100,
  );

  const GroupRule(
    this.key,
    this.label,
    this.help,
    this.unit,
    this.min,
    this.max,
  );

  /// The rule_values key settlement reads.
  final String key;
  final String label;
  final String help;
  final RuleUnit unit;

  /// Inclusive bounds in the wire unit (basis points, seconds, people).
  final int min;
  final int max;

  static GroupRule? byKey(String key) =>
      values.where((r) => r.key == key).firstOrNull;

  int get _scale => switch (unit) {
    RuleUnit.percent => 100,
    RuleUnit.days => _day,
    RuleUnit.hours => _hour,
    RuleUnit.people => 1,
  };

  /// The rule's value in force in [policy], in the wire unit; null when the
  /// constitution does not hold the rule (it cannot be changed then).
  int? current(finance.RoomPolicy policy) {
    final g = policy.governance;
    switch (this) {
      case GroupRule.quorum:
        return g.hasStandard() ? g.standard.quorumBps : null;
      case GroupRule.approval:
        return g.hasStandard() ? g.standard.passBps : null;
      case GroupRule.votingPeriod:
        return g.hasStandard() ? g.standard.votingPeriodSeconds.toInt() : null;
      case GroupRule.timelock:
        return g.hasStandard() ? g.standard.timelockSeconds.toInt() : null;
      case GroupRule.voterLookback:
        return g.hasVoterLookback() ? g.voterLookback.seconds.toInt() : null;
      case GroupRule.minimumActive:
        return g.hasLiveness() ? g.liveness.minimumActiveMembers : null;
      case GroupRule.maxMembers:
        return policy.hasMembership() ? policy.membership.maxMembers : null;
      case GroupRule.withdrawalFee:
        return withdrawalFeeRule(policy)?.bps ?? 0;
    }
  }

  /// What the group runs under when its constitution leaves the rule out.
  String get defaultWords => switch (this) {
    GroupRule.voterLookback =>
      'a day in a private group, a week in a public one',
    _ => 'the template\'s',
  };

  /// [value] (wire unit) as people read it: "60%", "3 days", "12 hours".
  String show(int value) => switch (unit) {
    RuleUnit.percent => formatBps(value),
    RuleUnit.days =>
      value % _day == 0
          ? _plural(value ~/ _day, 'day')
          : _plural((value / _hour).round(), 'hour'),
    RuleUnit.hours =>
      value % _hour == 0
          ? _plural(value ~/ _hour, 'hour')
          : _plural((value / 60).round(), 'minute'),
    RuleUnit.people => _plural(value, 'member'),
  };

  /// What the person types for [value] (wire unit), when it is a whole
  /// number of the unit (else the nearest).
  String typed(int value) => switch (unit) {
    RuleUnit.percent =>
      value % 100 == 0
          ? '${value ~/ 100}'
          : (value / 100).toStringAsFixed(2).replaceFirst(RegExp(r'0$'), ''),
    _ => '${(value / _scale).round()}',
  };

  /// What the person typed, in the wire unit; a [FormatException] says what
  /// is wrong.
  int parse(String text) {
    final t = text.trim();
    final int value;
    if (unit == RuleUnit.percent) {
      final m = RegExp(r'^(0|[1-9][0-9]{0,2})(?:\.([0-9]{1,2}))?$')
          .firstMatch(t);
      if (m == null) {
        throw const FormatException('Type a percentage, like 60 or 66.67');
      }
      final frac = (m.group(2) ?? '').padRight(2, '0');
      value = int.parse(m.group(1)!) * 100 + int.parse(frac);
    } else {
      if (!RegExp(r'^(0|[1-9][0-9]{0,6})$').hasMatch(t)) {
        throw const FormatException('Type a whole number');
      }
      value = int.parse(t) * _scale;
    }
    if (value < min) throw FormatException('At least ${show(min)}');
    if (value > max) throw FormatException('At most ${show(max)}');
    return value;
  }
}

String _plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

/// The constitution's protocol fee on withdrawals, the rule
/// withdrawal_fee_bps sets; null when it charges none.
finance.FeeRule? withdrawalFeeRule(finance.RoomPolicy policy) => policy
    .fees
    .rules
    .where(
      (r) =>
          r.type == finance.FeeType.FEE_TYPE_PROTOCOL_FEE &&
          r.chargedOn.contains(finance.IntentType.INTENT_TYPE_WITHDRAWAL),
    )
    .firstOrNull;

/// The rule values a change sends: each rule whose chosen value differs
/// from the one in force, keyed by settlement's names, canonical decimals.
Map<String, String> ruleValuesOf(
  Map<GroupRule, int> chosen,
  finance.RoomPolicy inForce,
) => {
  for (final e in chosen.entries)
    if (e.key.current(inForce) != e.value) e.key.key: '${e.value}',
};

/// [policy] with [values] applied as settlement's templates apply them
/// (pkg/policy/templates ApplyRuleValues), in key order. A rule the
/// constitution cannot hold is refused.
finance.RoomPolicy applyRuleValues(
  finance.RoomPolicy policy,
  Map<String, String> values,
) {
  final p = policy.deepCopy();
  for (final key in values.keys.toList()..sort()) {
    final rule = GroupRule.byKey(key);
    final v = int.tryParse(values[key]!);
    if (rule == null || v == null || '$v' != values[key]) {
      throw SigningRefused('"$key" is not a rule a vote may change');
    }
    final g = p.governance;
    switch (rule) {
      case GroupRule.quorum:
        g.standard.quorumBps = v;
      case GroupRule.approval:
        g.standard.passBps = v;
      case GroupRule.votingPeriod:
        g.standard.votingPeriodSeconds = Int64(v);
      case GroupRule.timelock:
        g.standard.timelockSeconds = Int64(v);
      case GroupRule.voterLookback:
        g.voterLookback = wkt.Duration(seconds: Int64(v));
      case GroupRule.minimumActive:
        g.liveness.minimumActiveMembers = v;
      case GroupRule.maxMembers:
        p.membership.maxMembers = v;
      case GroupRule.withdrawalFee:
        final fee = withdrawalFeeRule(p);
        if (fee == null) {
          throw const SigningRefused('the group charges no withdrawal fee');
        }
        if (v == 0) {
          p.fees.rules.remove(fee);
        } else {
          fee.bps = v;
        }
    }
  }
  return p;
}

/// keccak256(abi.encode(RoomTypes.SecurityParams)): the 27 static words in
/// field order (Go stawi.ParamsHash).
Uint8List securityParamsHash(finance.RoomSecurityParams p) {
  BigInt u(Int64 v) => BigInt.parse(v.toStringUnsigned());
  BigInt dec(String s, String name) {
    final v = BigInt.tryParse(s.isEmpty ? '0' : s);
    if (v == null || v.isNegative || v.bitLength > 256) {
      throw SigningRefused('the group\'s $name could not be read');
    }
    return v;
  }

  final words = <BigInt>[
    BigInt.from(p.quorumBps),
    BigInt.from(p.passBps),
    BigInt.from(p.passOfElectorate ? 1 : 0),
    BigInt.from(p.governanceThresholdBps),
    BigInt.from(p.minQuorumBpsOfTotal),
    u(p.votingPeriod),
    u(p.revealWindow),
    u(p.timelock),
    u(p.delegationCooldown),
    BigInt.from(p.maxDelegatedWeightBps),
    BigInt.from(p.maxDelegators),
    u(p.inactiveAfter),
    u(p.periodSeconds),
    u(p.periodEpochStart),
    dec(p.secretBallotKinds, 'secret ballot kinds'),
    BigInt.from(p.foundingQuorumBps),
    BigInt.from(p.penaltyBps),
    BigInt.from(p.maxPenaltyDays),
    BigInt.from(p.maxFeeBps),
    BigInt.from(p.loanFundSplitBps),
    BigInt.from(p.emergencySplitBps),
    u(p.obligationShiftSeconds),
    u(p.principalExitTimelock),
    dec(p.complianceMinAmount, 'compliance minimum'),
    BigInt.from(p.freezeApprovals),
    u(p.freezeSeconds),
    u(p.voterLookback),
  ];
  return keccak256([for (final w in words) ...bigIntToBytes(w, 32)]);
}

/// Why a rules change that is not the one asked for is refused.
const String notTheRuleChange = 'this would not make the rule change you chose';

/// The params a rule change may move, by the rule that moves them.
const Map<String, Set<String>> _paramsOfRule = {
  'quorum_bps': {'quorumBps'},
  'pass_bps': {'passBps'},
  'voting_period': {'votingPeriod', 'revealWindow'},
  'timelock': {'timelock'},
  'voter_lookback': {'voterLookback'},
  'withdrawal_fee_bps': {'maxFeeBps'},
};

Map<String, Object> _paramsMap(finance.RoomSecurityParams p) => {
  'quorumBps': p.quorumBps,
  'passBps': p.passBps,
  'passOfElectorate': p.passOfElectorate,
  'governanceThresholdBps': p.governanceThresholdBps,
  'minQuorumBpsOfTotal': p.minQuorumBpsOfTotal,
  'votingPeriod': p.votingPeriod,
  'revealWindow': p.revealWindow,
  'timelock': p.timelock,
  'delegationCooldown': p.delegationCooldown,
  'maxDelegatedWeightBps': p.maxDelegatedWeightBps,
  'maxDelegators': p.maxDelegators,
  'inactiveAfter': p.inactiveAfter,
  'periodSeconds': p.periodSeconds,
  'periodEpochStart': p.periodEpochStart,
  'secretBallotKinds': p.secretBallotKinds,
  'foundingQuorumBps': p.foundingQuorumBps,
  'penaltyBps': p.penaltyBps,
  'maxPenaltyDays': p.maxPenaltyDays,
  'maxFeeBps': p.maxFeeBps,
  'loanFundSplitBps': p.loanFundSplitBps,
  'emergencySplitBps': p.emergencySplitBps,
  'obligationShiftSeconds': p.obligationShiftSeconds,
  'principalExitTimelock': p.principalExitTimelock,
  'complianceMinAmount': p.complianceMinAmount,
  'freezeApprovals': p.freezeApprovals,
  'freezeSeconds': p.freezeSeconds,
  'voterLookback': p.voterLookback,
};

/// The voting params [c] fixes (pkg/policy.ChainSecurityParams): each must
/// equal [p]'s.
bool _paramsFollow(finance.RoomPolicy c, finance.RoomSecurityParams p) {
  final std = c.governance.standard;
  final gov = c.governance.governance;
  final reveal = std.revealWindowSeconds == Int64.ZERO
      ? std.votingPeriodSeconds
      : std.revealWindowSeconds;
  return p.quorumBps == std.quorumBps &&
      p.passBps == std.passBps &&
      p.passOfElectorate == std.ofElectorate &&
      p.governanceThresholdBps == gov.passBps &&
      p.minQuorumBpsOfTotal == c.governance.liveness.minQuorumBpsOfTotal &&
      p.votingPeriod == std.votingPeriodSeconds &&
      p.revealWindow == reveal &&
      p.timelock == std.timelockSeconds &&
      p.principalExitTimelock == gov.timelockSeconds &&
      p.periodSeconds == c.periodModel.periodSeconds &&
      p.periodEpochStart == c.periodModel.epochStart &&
      p.penaltyBps == c.savings.failure.penaltyBps &&
      (!c.governance.hasVoterLookback() ||
          c.governance.voterLookback.seconds <= Int64.ZERO ||
          p.voterLookback == c.governance.voterLookback.seconds);
}

/// Whether [a] and [b] state the same constitution: equal proto3 JSON,
/// keys in order (a field set to its default, such as a duration's zero
/// nanos, is the same as one left unset).
bool samePolicy(finance.RoomPolicy a, finance.RoomPolicy b) =>
    jsonEncode(_sorted(a.toProto3Json())) ==
    jsonEncode(_sorted(b.toProto3Json()));

Object? _sorted(Object? v) => switch (v) {
  final Map<dynamic, dynamic> m => {
    for (final k in m.keys.map((k) => '$k').toList()..sort()) k: _sorted(m[k]),
  },
  final List<dynamic> l => [for (final e in l) _sorted(e)],
  _ => v,
};

finance.RoomPolicy? _constitutionOf(List<int> document) {
  try {
    return finance.RoomPolicy()
      ..mergeFromProto3Json(jsonDecode(utf8.decode(document)));
  } on Object {
    return null;
  }
}

/// The payload hash a POLICY_CHANGE proposal of [values] must carry, once
/// [prepared]'s compiled change is checked against the policy in force as
/// finance holds it ([inForce]) and the room's custody: the three documents
/// hash to the three hashes; the change was proposed under finance's policy
/// epoch and constitution; the new constitution is finance's with exactly
/// [values] applied; its voting params follow from it and, beside the ones
/// the chosen rules move, equal the params in force. Throws [SigningRefused]
/// otherwise.
Uint8List checkedPolicyChange({
  required settlement.PrepareRoomCallResponse prepared,
  required Map<String, String> values,
  required finance.PolicyVersion inForce,
  required Uint8List custody,
}) {
  if (!prepared.call.hasPolicyChange()) {
    throw const SigningRefused(notTheRuleChange);
  }
  final pc = prepared.call.policyChange;
  final asked = Map<String, String>.of(pc.ruleValues);
  if (asked.length != values.length ||
      values.entries.any((e) => asked[e.key] != e.value)) {
    throw const SigningRefused(notTheRuleChange);
  }
  final docs = pc.documents;
  if (docs.length != 3 ||
      !bytesEqual(keccak256(docs[0]), pc.constitutionHash) ||
      !bytesEqual(keccak256(docs[1]), pc.financePolicyHash) ||
      !bytesEqual(keccak256(docs[2]), pc.securityPolicyHash)) {
    throw const SigningRefused(
      'the new rules\' documents do not match their hashes',
    );
  }
  if (inForce.constitutionHash.isEmpty ||
      !bytesEqual(pc.previousConstitutionHash, inForce.constitutionHash) ||
      pc.policyEpoch != inForce.policyEpoch) {
    throw const SigningRefused(
      'the group\'s rules in force are not the ones this phone reads; try '
      'again in a minute',
    );
  }
  final proposed = _constitutionOf(docs[0]);
  if (proposed == null ||
      !samePolicy(proposed, applyRuleValues(inForce.constitution, values))) {
    throw const SigningRefused(notTheRuleChange);
  }
  if (!pc.hasSecurityParams() ||
      !pc.hasPreviousSecurityParams() ||
      !_paramsFollow(proposed, pc.securityParams)) {
    throw const SigningRefused(notTheRuleChange);
  }
  final movable = {for (final k in values.keys) ...?_paramsOfRule[k]};
  final before = _paramsMap(pc.previousSecurityParams);
  final after = _paramsMap(pc.securityParams);
  for (final name in before.keys) {
    if (!movable.contains(name) && before[name] != after[name]) {
      throw const SigningRefused(notTheRuleChange);
    }
  }
  if (custody.length != 20 || pc.capabilityIds.any((id) => id.length != 32)) {
    throw const SigningRefused(notTheRuleChange);
  }
  return payloadHashOf(
    policyChangeDocument(
      custody: custody,
      constitutionHash: pc.constitutionHash,
      financePolicyHash: pc.financePolicyHash,
      securityPolicyHash: pc.securityPolicyHash,
      paramsHash: securityParamsHash(pc.securityParams),
      capabilityIds: pc.capabilityIds,
    ),
  );
}

/// One rule's change as the review lists it: "Quorum", "50% → 60%".
(String, String) ruleChangeLine(GroupRule rule, int? from, int to) => (
  rule.label,
  from == null ? rule.show(to) : '${rule.show(from)} → ${rule.show(to)}',
);

/// Proposes changing the group's rules to [values] (rule_values, wire
/// units) from the policy in force [inForce]; the members vote on it.
/// Signed only once [checkedPolicyChange] holds for what settlement
/// compiled.
GovernanceRequest proposeRuleChangeRequest({
  required Map<String, String> values,
  required finance.PolicyVersion inForce,
}) {
  if (values.isEmpty) {
    throw ArgumentError.value(values, 'values', 'change at least one rule');
  }
  final lines = <(String, String)>[
    for (final key in values.keys.toList()..sort())
      if (GroupRule.byKey(key) case final rule?)
        ruleChangeLine(
          rule,
          rule.current(inForce.constitution),
          int.parse(values[key]!),
        ),
  ];
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE,
    params: settlement.RoomCallParams(
      propose: settlement.RoomProposeParams(
        ruleChanges: settlement.RoomRuleChanges(ruleValues: values.entries),
      ),
    ),
    summary: 'Propose changing the group\'s rules',
    expected: (room, prepared) => RoomCallExpected.propose(
      proposalKind: ProposalKinds.policyChange,
      payloadHash: checkedPolicyChange(
        prepared: prepared,
        values: values,
        inForce: inForce,
        custody:
            room.custody ??
            (throw const SigningRefused(roomContractsUnknownReason)),
      ),
    ),
    lines: lines,
  );
}

/// What the person is told before a rules change about the votes it ends:
/// the contracts carry out a proposal only under the rules it was proposed
/// under, so once the change takes effect every other open vote must be
/// proposed again.
String openVotesWarning(int? open) => switch (open) {
  null =>
    'Votes still open in this group when the new rules take effect will '
        'have to be proposed again: the group\'s contracts only carry out a '
        'decision under the rules it was proposed under.',
  0 =>
    'No other vote is open in this group now. Any vote opened before the '
        'new rules take effect will have to be proposed again.',
  _ =>
    '$open open ${open == 1 ? 'vote' : 'votes'} in this group will have to '
        'be proposed again once the new rules take effect: the group\'s '
        'contracts only carry out a decision under the rules it was proposed '
        'under. Consider waiting until ${open == 1 ? 'it is' : 'they are'} '
        'decided.',
};

/// The loan vote threshold is set when lending is set up and cannot be
/// changed by a vote yet: the loan book's contract has no way to change a
/// loan form.
const String loanThresholdNote =
    'The amount above which a loan goes to a vote is fixed when lending is '
    'set up; it cannot be changed by a vote yet.';
