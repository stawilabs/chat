/// Where a proposal a member signed stands, from the room call settlement
/// sent and the proposal finance indexed. Settlement queues and carries out
/// passed member, role, join-policy, room-binding and rules decisions itself
/// (stawi v0.2.6 proposal_queue / proposal_apply), so nobody has to finish
/// them by hand.
library;

import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;

/// A decision's stages, in order; [failed] ends it early.
enum DecisionStage {
  /// Signed; settlement is putting the proposal on chain.
  sending,

  /// On chain: the members vote.
  voting,

  /// The vote passed; it waits its time before it takes effect.
  waiting,

  /// Carried out.
  done,

  /// It will not take effect (refused, rejected, lapsed, cancelled or
  /// failed): [DecisionProgress.why] says which.
  failed,
}

/// A decision as the person follows it.
final class DecisionProgress {
  const DecisionProgress({
    required this.stage,
    this.onchainProposalId = 0,
    this.why,
    this.votingClosesAt,
    this.takesEffectAfter,
  });

  /// Reads [call] (settlement's room call) and [proposal] (finance's, once
  /// it indexed the on-chain proposal the call opened).
  factory DecisionProgress.of(
    settlement.RoomCall call,
    finance.Proposal? proposal,
  ) {
    DateTime? at(bool has, DateTime Function() t) => has ? t() : null;
    switch (call.state) {
      case settlement.RoomCallState.ROOM_CALL_STATE_FAILED:
        return DecisionProgress(
          stage: DecisionStage.failed,
          why: call.failureReason.isEmpty
              ? 'The proposal could not be put on chain.'
              : 'The proposal could not be put on chain: '
                    '${call.failureReason}',
        );
      case settlement.RoomCallState.ROOM_CALL_STATE_EXPIRED:
        return const DecisionProgress(
          stage: DecisionStage.failed,
          why: 'The proposal was not sent in time; propose it again.',
        );
      case settlement.RoomCallState.ROOM_CALL_STATE_FINAL:
        break;
      default:
        return const DecisionProgress(stage: DecisionStage.sending);
    }
    final id = call.onchainProposalId.toInt();
    if (id <= 0 || proposal == null) {
      return DecisionProgress(
        stage: DecisionStage.sending,
        onchainProposalId: id,
      );
    }
    final closes = at(
      proposal.hasVotingClosesAt(),
      () => proposal.votingClosesAt.toDateTime(),
    );
    final after = at(
      proposal.hasExecutionAfter(),
      () => proposal.executionAfter.toDateTime(),
    );
    DecisionProgress of(DecisionStage stage, [String? why]) => DecisionProgress(
      stage: stage,
      onchainProposalId: id,
      why: why,
      votingClosesAt: closes,
      takesEffectAfter: after,
    );
    return switch (proposal.state) {
      finance.ProposalState.PROPOSAL_STATE_CREATED ||
      finance.ProposalState.PROPOSAL_STATE_OPEN ||
      finance.ProposalState.PROPOSAL_STATE_REVEALING => of(
        DecisionStage.voting,
      ),
      finance.ProposalState.PROPOSAL_STATE_PASSED ||
      finance.ProposalState.PROPOSAL_STATE_QUEUED => of(DecisionStage.waiting),
      finance.ProposalState.PROPOSAL_STATE_EXECUTED => of(DecisionStage.done),
      finance.ProposalState.PROPOSAL_STATE_REJECTED => of(
        DecisionStage.failed,
        'The group voted it down.',
      ),
      finance.ProposalState.PROPOSAL_STATE_EXPIRED => of(
        DecisionStage.failed,
        'Too few members voted before the vote closed.',
      ),
      finance.ProposalState.PROPOSAL_STATE_CANCELLED => of(
        DecisionStage.failed,
        'It was cancelled.',
      ),
      finance.ProposalState.PROPOSAL_STATE_REJECTED_PRECHECK => of(
        DecisionStage.failed,
        'The group\'s rules refused it.',
      ),
      finance.ProposalState.PROPOSAL_STATE_EXECUTION_FAILED => of(
        DecisionStage.failed,
        'It passed but could not be carried out; a member can try from '
        'Advanced.',
      ),
      _ => of(DecisionStage.voting),
    };
  }

  final DecisionStage stage;

  /// The on-chain proposal, once the call opened it (0 before).
  final int onchainProposalId;
  final String? why;
  final DateTime? votingClosesAt;
  final DateTime? takesEffectAfter;

  /// Nothing further will happen.
  bool get settled =>
      stage == DecisionStage.done || stage == DecisionStage.failed;
}

/// The words for each stage of a decision a member follows.
const Map<DecisionStage, String> decisionStageWords = {
  DecisionStage.sending: 'Proposal sent',
  DecisionStage.voting: 'The group votes',
  DecisionStage.waiting: 'Passed: waiting its time',
  DecisionStage.done: 'Done: in effect',
};

/// What every guided proposal says happens once it is signed.
const String finishesItselfNote =
    'Once the vote passes and its waiting time is over, Stawi carries it '
    'out by itself; you can follow it after signing.';

/// Settlement's room call kinds that open a vote.
bool opensVote(settlement.RoomCallKind kind) => switch (kind) {
  settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE ||
  settlement.RoomCallKind.ROOM_CALL_KIND_ASSIGN_ROLE ||
  settlement.RoomCallKind.ROOM_CALL_KIND_REVOKE_ROLE => true,
  _ => false,
};

/// The finance proposal states still to be decided or carried out: what a
/// rules change would strand.
const List<finance.ProposalState> undecidedProposalStates = [
  finance.ProposalState.PROPOSAL_STATE_CREATED,
  finance.ProposalState.PROPOSAL_STATE_OPEN,
  finance.ProposalState.PROPOSAL_STATE_REVEALING,
  finance.ProposalState.PROPOSAL_STATE_PASSED,
  finance.ProposalState.PROPOSAL_STATE_QUEUED,
];
