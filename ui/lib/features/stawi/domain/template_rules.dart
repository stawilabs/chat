/// The rule values a Stawi room template takes when a chat room is converted
/// (settlement's pkg/policy/templates.Rules). Settlement parses and
/// range-checks every value when it compiles the constitution, and refuses a
/// bad one naming the key; the checks here only catch typing mistakes before a
/// conversion is sent. No API lists the rules yet, so the catalogue is kept
/// here and must follow settlement's.
library;

/// How a rule's value is written.
enum TemplateRuleKind {
  /// A canonical decimal whole number.
  number,

  /// Whole seconds, a canonical decimal.
  seconds,

  /// One of [TemplateRule.choices].
  choice,
}

class TemplateRule {
  const TemplateRule({
    required this.key,
    required this.label,
    required this.help,
    required this.kind,
    this.min,
    this.max,
    this.choices = const [],
  });

  /// The rule name settlement reads (the rule_values key).
  final String key;
  final String label;
  final String help;
  final TemplateRuleKind kind;

  /// Inclusive bounds, where settlement's are fixed. Null leaves the check
  /// to settlement (e.g. a uint256 amount).
  final BigInt? min;
  final BigInt? max;
  final List<String> choices;

  /// A problem with [value], or null when it is well-formed. An empty value
  /// means "keep the template's".
  String? validate(String value) {
    if (value.isEmpty) return null;
    if (kind == TemplateRuleKind.choice) {
      return choices.contains(value) ? null : 'Choose ${choices.join(', ')}';
    }
    if (!_canonicalDecimal.hasMatch(value)) {
      return 'Use a whole number without signs, spaces or leading zeros';
    }
    final n = BigInt.parse(value);
    if (min != null && n < min!) return 'At least $min';
    if (max != null && n > max!) return 'At most $max';
    return null;
  }
}

final RegExp _canonicalDecimal = RegExp(r'^(0|[1-9][0-9]*)$');

const int _day = 86400;

/// Every rule a template takes, in the order the form shows them.
final List<TemplateRule> templateRules = [
  const TemplateRule(
    key: 'contribution_amount',
    label: 'Contribution amount',
    help: 'Minimum contribution per period, in the asset minor units',
    kind: TemplateRuleKind.number,
  ),
  const TemplateRule(
    key: 'period',
    label: 'Contribution cadence',
    help: 'How often members contribute',
    kind: TemplateRuleKind.choice,
    choices: ['DAILY', 'WEEKLY', 'BIWEEKLY', 'MONTHLY'],
  ),
  TemplateRule(
    key: 'grace_days',
    label: 'Grace days',
    help: 'Days a contribution may be late before it fails',
    kind: TemplateRuleKind.number,
    min: BigInt.zero,
    max: BigInt.from(30),
  ),
  TemplateRule(
    key: 'penalty_bps',
    label: 'Late penalty (basis points per day)',
    help: 'Late-payment penalty per overdue day',
    kind: TemplateRuleKind.number,
    min: BigInt.zero,
    max: BigInt.from(10000),
  ),
  TemplateRule(
    key: 'quorum_bps',
    label: 'Quorum (basis points)',
    help: 'Share of members who must vote on a standard decision',
    kind: TemplateRuleKind.number,
    min: BigInt.from(1000),
    max: BigInt.from(10000),
  ),
  TemplateRule(
    key: 'pass_bps',
    label: 'Approval (basis points)',
    help: 'Share of votes a standard decision needs to pass',
    kind: TemplateRuleKind.number,
    min: BigInt.from(5001),
    max: BigInt.from(10000),
  ),
  TemplateRule(
    key: 'voting_period',
    label: 'Voting period (seconds)',
    help: 'How long a standard vote stays open',
    kind: TemplateRuleKind.seconds,
    min: BigInt.from(_day),
    max: BigInt.from(30 * _day),
  ),
  TemplateRule(
    key: 'timelock',
    label: 'Timelock (seconds)',
    help: 'Delay after a decision passes before it takes effect',
    kind: TemplateRuleKind.seconds,
    min: BigInt.zero,
    max: BigInt.from(30 * _day),
  ),
  TemplateRule(
    key: 'voter_lookback',
    label: 'Voter lookback (seconds)',
    help: 'How long before a proposal its electorate is read',
    kind: TemplateRuleKind.seconds,
    min: BigInt.from(_day),
    max: BigInt.from(30 * _day),
  ),
  TemplateRule(
    key: 'founding_quorum',
    label: 'Founding quorum',
    help: 'Founders who must sign the genesis',
    kind: TemplateRuleKind.number,
    min: BigInt.one,
    max: BigInt.from(200),
  ),
  TemplateRule(
    key: 'minimum_active_members',
    label: 'Minimum active members',
    help: 'Fewer active members than this and the room goes inactive',
    kind: TemplateRuleKind.number,
    min: BigInt.one,
    max: BigInt.from(200),
  ),
  const TemplateRule(
    key: 'rules_template',
    label: 'Lending rules',
    help: 'The dues and loan rules the room votes in once it is on chain',
    kind: TemplateRuleKind.choice,
    choices: lendingTemplates,
  ),
  const TemplateRule(
    key: 'loan_vote_above',
    label: 'Loans decided by vote above',
    help:
        'Loans above this amount (asset minor units) are decided by a room '
        'vote',
    kind: TemplateRuleKind.number,
  ),
  TemplateRule(
    key: 'max_members',
    label: 'Maximum members',
    help: 'Most members the room admits',
    kind: TemplateRuleKind.number,
    min: BigInt.one,
    max: BigInt.from(10000),
  ),
];

/// The lending rules templates settlement sets a room up with (pkg/rules
/// TemplateNames); "none" sets up no lending. Unset is vsla_52_weeks.
const List<String> lendingTemplates = [
  'vsla_52_weeks',
  'merry_go_round_weekly',
  'asca_monthly',
  'grameen_221',
  'investment_club',
  'welfare_levy',
  'none',
];

/// What a rule is pre-filled with for a room of [founders] founders: the
/// founding quorum and the minimum active members are at most the founders
/// (settlement's own default for the minimum), so a two-person room can sign
/// its genesis and does not go inactive at once. Null leaves the rule to the
/// template.
String? prefilledRule(
  String key, {
  required int founders,
  required int templateFoundingQuorum,
  required int templateMinimumActive,
}) {
  if (founders < 1) return null;
  int atMostFounders(int templateValue) =>
      templateValue <= 0 || templateValue > founders ? founders : templateValue;
  return switch (key) {
    'founding_quorum' => '${atMostFounders(templateFoundingQuorum)}',
    'minimum_active_members' => '${atMostFounders(templateMinimumActive)}',
    _ => null,
  };
}

/// The values to send: the non-empty ones, keyed by rule name. Throws
/// [FormatException] naming the first bad value.
Map<String, String> ruleValuesFrom(Map<String, String> entered) {
  final out = <String, String>{};
  for (final rule in templateRules) {
    final value = (entered[rule.key] ?? '').trim();
    if (value.isEmpty) continue;
    final problem = rule.validate(value);
    if (problem != null) {
      throw FormatException('${rule.label}: $problem', value);
    }
    out[rule.key] = value;
  }
  return out;
}

/// Why the founding quorum cannot be met by [founders] founders, or null.
/// [entered] is the founding_quorum rule as typed (empty keeps the template's
/// [templateDefault]; 0 declares none, and then one signature suffices).
/// Settlement refuses a genesis whose founding quorum is more than its
/// founders, since they could never sign it.
String? foundingQuorumProblem({
  required String entered,
  required int templateDefault,
  required int founders,
}) {
  final typed = entered.trim();
  final quorum = typed.isEmpty ? templateDefault : int.tryParse(typed);
  if (quorum == null || quorum <= founders) return null;
  return typed.isEmpty
      ? 'This template needs $quorum founders to sign the genesis; choose '
            'at least $quorum founders or set a lower founding quorum'
      : 'A founding quorum of $quorum is more than the $founders founders; '
            'choose more founders or lower it';
}
