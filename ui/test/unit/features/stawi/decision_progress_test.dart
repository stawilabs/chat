import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/domain/decision_progress.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;

void main() {
  settlement.RoomCall call(settlement.RoomCallState state, [int id = 0]) =>
      settlement.RoomCall(state: state, onchainProposalId: Int64(id));
  finance.Proposal proposal(finance.ProposalState state) =>
      finance.Proposal(onchainProposalId: Int64(7), state: state);
  const finalCall = settlement.RoomCallState.ROOM_CALL_STATE_FINAL;

  test('a decision moves from sent to done as settlement finishes it', () {
    expect(
      DecisionProgress.of(
        call(settlement.RoomCallState.ROOM_CALL_STATE_SUBMITTED),
        null,
      ).stage,
      DecisionStage.sending,
    );
    // On chain but not indexed by finance yet.
    expect(
      DecisionProgress.of(call(finalCall, 7), null).stage,
      DecisionStage.sending,
    );
    for (final (state, stage) in [
      (finance.ProposalState.PROPOSAL_STATE_OPEN, DecisionStage.voting),
      (finance.ProposalState.PROPOSAL_STATE_REVEALING, DecisionStage.voting),
      (finance.ProposalState.PROPOSAL_STATE_PASSED, DecisionStage.waiting),
      (finance.ProposalState.PROPOSAL_STATE_QUEUED, DecisionStage.waiting),
      (finance.ProposalState.PROPOSAL_STATE_EXECUTED, DecisionStage.done),
    ]) {
      final p = DecisionProgress.of(call(finalCall, 7), proposal(state));
      expect(p.stage, stage, reason: '$state');
      expect(p.onchainProposalId, 7);
    }
    expect(
      DecisionProgress.of(
        call(finalCall, 7),
        proposal(finance.ProposalState.PROPOSAL_STATE_EXECUTED),
      ).settled,
      isTrue,
    );
  });

  test('a decision that will not take effect says why', () {
    final failed = DecisionProgress.of(
      settlement.RoomCall(
        state: settlement.RoomCallState.ROOM_CALL_STATE_FAILED,
        failureReason: 'StalePolicy',
      ),
      null,
    );
    expect(failed.stage, DecisionStage.failed);
    expect(failed.why, contains('StalePolicy'));
    for (final state in [
      finance.ProposalState.PROPOSAL_STATE_REJECTED,
      finance.ProposalState.PROPOSAL_STATE_EXPIRED,
      finance.ProposalState.PROPOSAL_STATE_CANCELLED,
      finance.ProposalState.PROPOSAL_STATE_EXECUTION_FAILED,
    ]) {
      final p = DecisionProgress.of(call(finalCall, 7), proposal(state));
      expect(p.stage, DecisionStage.failed, reason: '$state');
      expect(p.why, isNotEmpty);
      expect(p.settled, isTrue);
    }
  });

  test('only proposals are followed', () {
    expect(opensVote(settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE), isTrue);
    expect(
      opensVote(settlement.RoomCallKind.ROOM_CALL_KIND_ASSIGN_ROLE),
      isTrue,
    );
    expect(opensVote(settlement.RoomCallKind.ROOM_CALL_KIND_LEAVE), isFalse);
    expect(opensVote(settlement.RoomCallKind.ROOM_CALL_KIND_INVITE), isFalse);
  });
}
