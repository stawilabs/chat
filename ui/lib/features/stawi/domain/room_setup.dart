/// A room's lending setup, as the device checks and the room shows it. Once
/// a room is on chain settlement proposes three votes from a founder's own
/// signatures: the RulesEngine's grant, the LoanBook's grant (for a
/// merry-go-round, the RotationModule's instead) and the rules template the
/// founders chose. The founder signs them beside the genesis
/// (or later, when settlement asks), and every member votes on them.
library;

import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import 'proposal_documents.dart';
import 'signing_checks.dart';

/// The setup steps in the order they are proposed, with the proposal kind
/// each one is.
const Map<settlement.RoomSetupStepKind, int> setupStepProposalKinds = {
  settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE:
      capabilityGrantProposalKind,
  settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_GRANT_LOAN_ENGINE:
      capabilityGrantProposalKind,
  settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_GRANT_ROTATION:
      capabilityGrantProposalKind,
  settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE:
      scheduleProposalKind,
};

/// Checks the setup proposals a founder is asked to sign and returns the
/// digests to sign, index-aligned with [digests].
///
/// Each digest is rebuilt on the device: the proposal kind its step is, the
/// payload hash of its own document, a grant document granting a protocol
/// engine to the room's custody with no limits and no expiry, a template
/// document for that custody installing on the engines the grants grant,
/// and the typed hash of GovernanceModule.proposeBySig on [governance] by
/// [account] at its nonce and deadline (stawi_finance_sdk
/// roomCallTypedHash), wrapped for the account (accountWrappedHash). The
/// nonces run one after another from [firstNonce] (0 at genesis: a fresh
/// module) or from the first digest's. A deadline that has passed, a step
/// twice, or anything else is refused: nothing is signed on settlement's
/// word.
List<Uint8List> checkedSetupDigests({
  required List<settlement.RoomSetupDigest> digests,
  required List<int> governance,
  required List<int> custody,
  required Uint8List account,
  required BigInt chainId,
  required DateTime now,
  int? firstNonce,
}) {
  if (digests.isEmpty) return const [];
  if (governance.length != 20 || governance.every((b) => b == 0)) {
    throw const SigningRefused('the room\'s governance is not known');
  }
  if (custody.length != 20 || custody.every((b) => b == 0)) {
    throw const SigningRefused('the room\'s custody is not known');
  }
  if (account.length != 20 || account.every((b) => b == 0)) {
    throw const SigningRefused(noAccountReason);
  }
  final seen = <settlement.RoomSetupStepKind>{};
  final engines = <settlement.RoomSetupStepKind, Uint8List>{};
  TemplateHeader? template;
  final nowSeconds = BigInt.from(now.toUtc().millisecondsSinceEpoch ~/ 1000);
  var nonce = firstNonce == null
      ? BigInt.parse(digests.first.nonce.toStringUnsigned())
      : BigInt.from(firstNonce);
  final out = <Uint8List>[];
  for (final d in digests) {
    final kind = setupStepProposalKinds[d.step];
    if (kind == null || !seen.add(d.step)) {
      throw const SigningRefused('settlement asked for an unknown setup step');
    }
    if (d.proposalKind != kind) {
      throw const SigningRefused(
        'a setup step proposes another kind of decision',
      );
    }
    if (!bytesEqual(payloadHashOf(d.payloadDocument), d.payloadHash)) {
      throw const SigningRefused(
        'a setup step\'s document is not the one it proposes',
      );
    }
    if (kind == capabilityGrantProposalKind) {
      final engine = grantedEngine(d.payloadDocument, custody: custody);
      if (engine == null) {
        throw const SigningRefused(
          'a setup grant is not an engine grant to this room',
        );
      }
      engines[d.step] = engine;
    } else {
      template = templateHeader(d.payloadDocument);
      if (template == null || !bytesEqual(template.custody, custody)) {
        throw const SigningRefused(
          'the setup\'s rules are not a template for this room',
        );
      }
    }
    if (BigInt.parse(d.nonce.toStringUnsigned()) != nonce) {
      throw const SigningRefused('the setup steps are not signed in order');
    }
    final deadline = BigInt.from(d.deadline.seconds.toInt());
    if (deadline <= nowSeconds) {
      throw const SigningRefused('the setup signatures have expired');
    }
    final Uint8List typed;
    try {
      typed = roomCallTypedHash(
        SignedCallKind.propose,
        verifier: governance,
        chainId: chainId,
        member: account,
        nonce: nonce,
        deadline: deadline,
        params: [...bigIntToBytes(BigInt.from(kind), 32), ...d.payloadHash],
      );
      // ignore: avoid_catching_errors
    } on ArgumentError {
      throw const SigningRefused('a setup step is malformed');
    }
    if (!bytesEqual(typed, d.typedHash)) {
      throw const SigningRefused(
        'a setup step is not the proposal it describes',
      );
    }
    final digest = accountWrappedHash(account, chainId, typed);
    if (!bytesEqual(digest, d.digest)) {
      throw const SigningRefused(
        'a setup digest is not your account wrapping of its proposal',
      );
    }
    out.add(digest);
    nonce += BigInt.one;
  }
  final rules =
      engines[settlement
          .RoomSetupStepKind
          .ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE];
  final loans =
      engines[settlement
          .RoomSetupStepKind
          .ROOM_SETUP_STEP_KIND_GRANT_LOAN_ENGINE];
  final rotation =
      engines[settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_GRANT_ROTATION];
  if (loans != null && rotation != null) {
    throw const SigningRefused(
      'a setup grants both the loan book and the rotation',
    );
  }
  final second = loans ?? rotation;
  if (rules != null && second != null && bytesEqual(rules, second)) {
    throw const SigningRefused('both setup grants grant the same engine');
  }
  final t = template;
  if (t != null &&
      ((rules != null && !bytesEqual(t.rulesEngine, rules)) ||
          (loans != null && !bytesEqual(t.loanBook, loans)))) {
    throw const SigningRefused(
      'the setup\'s rules name other engines than its grants',
    );
  }
  return out;
}

/// Whether a room's setup runs a rotation (a merry_go_round_weekly room:
/// its second grant is the RotationModule's).
bool setupRunsRotation(settlement.RoomSetup setup) => setup.steps.any(
  (s) =>
      s.step ==
      settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_GRANT_ROTATION,
);

/// A chain id as the protos carry it.
BigInt chainIdOf(Int64 id) => BigInt.parse(id.toStringUnsigned());

/// The setup as the room reads it: where it stands in a sentence, and the
/// steps a member can vote on now.
final class RoomSetupProgress {
  const RoomSetupProgress(this.setup);

  final settlement.RoomSetup setup;

  settlement.RoomSetupState get state => setup.state;

  /// Whether there is a setup to show at all.
  bool get shown =>
      state != settlement.RoomSetupState.ROOM_SETUP_STATE_UNSPECIFIED &&
      state != settlement.RoomSetupState.ROOM_SETUP_STATE_NONE;

  bool get ready => state == settlement.RoomSetupState.ROOM_SETUP_STATE_READY;

  /// Whether a founder's signatures are asked for, and this reader (a
  /// founder: needs_signatures are their own) can give them.
  bool get asksMe =>
      state == settlement.RoomSetupState.ROOM_SETUP_STATE_AWAITING_SIGNATURE &&
      setup.needsSignatures.isNotEmpty;

  /// The steps open for a vote now, in order.
  List<settlement.RoomSetupStep> get voting => [
    for (final s in setup.steps)
      if (s.state ==
              settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_VOTING &&
          s.onchainProposalId > Int64.ZERO)
        s,
  ];

  /// "Setting up lending: vote 1 of 3, closes in 2 days".
  String headline(DateTime now) {
    final total = setup.steps.length;
    final rotation = setupRunsRotation(setup);
    final what = rotation ? 'the rotation' : 'lending';
    switch (state) {
      case settlement.RoomSetupState.ROOM_SETUP_STATE_READY:
        return rotation
            ? 'The rotation is set up: the room takes dues and can start a '
                  'rotation'
            : 'Lending is set up: the room takes dues and lends';
      case settlement.RoomSetupState.ROOM_SETUP_STATE_STALLED:
        final why = setup.failureReason;
        return why.isEmpty
            ? 'Setting up $what stopped: a vote did not pass'
            : 'Setting up $what stopped: $why';
      case settlement.RoomSetupState.ROOM_SETUP_STATE_AWAITING_GENESIS:
        return rotation
            ? 'The rotation is set up once the room is on chain'
            : 'Lending is set up once the room is on chain';
      case settlement.RoomSetupState.ROOM_SETUP_STATE_AWAITING_SIGNATURE:
        return 'Setting up $what: a founder needs to sign the setup';
      case settlement.RoomSetupState.ROOM_SETUP_STATE_APPLYING:
        final at = setup.hasReadyAt() ? setup.readyAt.toDateTime() : null;
        return at == null
            ? 'Setting up $what: every vote passed, applying the rules'
            : 'Setting up $what: every vote passed, ready in '
                  '${durationWords(at.difference(now))}';
      default:
    }
    final steps = setup.steps;
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      if (s.state ==
          settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_VOTING) {
        final closes = s.hasVotingClosesAt()
            ? ', closes in ${durationWords(s.votingClosesAt.toDateTime().difference(now))}'
            : '';
        return 'Setting up $what: vote ${i + 1} of $total$closes';
      }
    }
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      if (s.state ==
              settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_WAITING ||
          s.state ==
              settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_PROPOSING) {
        final opens = s.hasVotingClosesAt() && setup.votingPeriodSeconds > 0
            ? ', opens in ${durationWords(s.votingClosesAt.toDateTime().subtract(Duration(seconds: setup.votingPeriodSeconds.toInt())).difference(now))}'
            : '';
        return 'Setting up $what: vote ${i + 1} of $total$opens';
      }
    }
    return 'Setting up $what';
  }
}

/// Where one step stands, in words.
String setupStepStateLabel(
  settlement.RoomSetupStep s,
  DateTime now,
) => switch (s.state) {
  settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_WAITING => 'Waiting',
  settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_PROPOSING =>
    'Being proposed',
  settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_VOTING =>
    s.hasVotingClosesAt()
        ? 'Voting, closes in '
              '${durationWords(s.votingClosesAt.toDateTime().difference(now))}'
        : 'Voting',
  settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_QUEUED =>
    s.hasAppliesAt()
        ? 'Passed, applies in '
              '${durationWords(s.appliesAt.toDateTime().difference(now))}'
        : 'Passed',
  settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_APPLIED => 'Done',
  settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_DEFEATED => 'Voted down',
  settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_FAILED =>
    s.failureReason.isEmpty ? 'Failed' : 'Failed: ${s.failureReason}',
  _ => '',
};

/// A step's name: settlement's, else one from its kind.
String setupStepTitle(settlement.RoomSetupStep s) {
  if (s.title.trim().isNotEmpty) return s.title.trim();
  return switch (s.step) {
    settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE =>
      'Turn on the rules engine',
    settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_GRANT_LOAN_ENGINE =>
      'Turn on the loan book',
    settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_GRANT_ROTATION =>
      'Turn on the rotation payouts',
    settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE =>
      'Adopt the room\'s dues and loan rules',
    _ => 'Setup step',
  };
}

/// "2 days", "5 hours", "12 minutes", "a moment".
String durationWords(Duration d) {
  if (d.inDays >= 2) return '${d.inDays} days';
  if (d.inHours >= 2) return '${d.inHours} hours';
  if (d.inMinutes >= 2) return '${d.inMinutes} minutes';
  return 'a moment';
}
