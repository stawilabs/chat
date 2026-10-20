import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/stawi_finance_service.dart';
import '../data/stawi_room_service.dart';
import '../domain/decision_progress.dart';
import 'stawi_feedback.dart';

/// A signed decision's progress: its room call, then the proposal it opened.
final stawiDecisionProgressProvider = FutureProvider.autoDispose
    .family<DecisionProgress, ({String roomId, String callId})>((
      ref,
      key,
    ) async {
      final call = await ref
          .watch(stawiRoomServiceProvider)
          .roomCall(key.callId);
      final id = call.onchainProposalId.toInt();
      final proposal = id > 0
          ? await ref
                .watch(stawiFinanceServiceProvider)
                .proposalByOnchainId(key.roomId, id)
          : null;
      return DecisionProgress.of(call, proposal);
    }, retry: (_, _) => null);

/// Follows a proposal the person signed until it is carried out (or will not
/// be): sent, voted on, waiting its time, done. Settlement finishes passed
/// decisions itself, so there is nothing to press; the screen reads again
/// every [refreshEvery].
class DecisionProgressScreen extends ConsumerStatefulWidget {
  const DecisionProgressScreen({
    required this.roomId,
    required this.callId,
    required this.title,
    this.refreshEvery = const Duration(seconds: 15),
    super.key,
  });

  final String roomId;
  final String callId;
  final String title;
  final Duration refreshEvery;

  @override
  ConsumerState<DecisionProgressScreen> createState() =>
      _DecisionProgressScreenState();
}

class _DecisionProgressScreenState
    extends ConsumerState<DecisionProgressScreen> {
  Timer? _timer;

  ({String roomId, String callId}) get _key =>
      (roomId: widget.roomId, callId: widget.callId);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.refreshEvery, (_) {
      final now = ref.read(stawiDecisionProgressProvider(_key)).asData?.value;
      if (now != null && now.settled) {
        _timer?.cancel();
        return;
      }
      ref.invalidate(stawiDecisionProgressProvider(_key));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(stawiDecisionProgressProvider(_key));
    return Scaffold(
      appBar: AppBar(title: const Text('Decision')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          progress.when(
            skipLoadingOnReload: true,
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
              stawiErrorMessage(e),
              key: const Key('decision-progress-error'),
            ),
            data: (p) => _Stages(progress: p),
          ),
          const SizedBox(height: 16),
          Text(
            'Nobody needs to finish it by hand: once the vote passes and its '
            'waiting time is over, Stawi carries it out. If it ever stalls, '
            'a member can still run it from Group decisions, Advanced.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Stages extends StatelessWidget {
  const _Stages({required this.progress});

  final DecisionProgress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String? detail(DecisionStage s) => switch (s) {
      DecisionStage.sending when progress.onchainProposalId > 0 =>
        'Proposal #${progress.onchainProposalId}',
      DecisionStage.voting when progress.votingClosesAt != null =>
        'Voting closes ${_when(progress.votingClosesAt!)}',
      DecisionStage.waiting when progress.takesEffectAfter != null =>
        'Takes effect after ${_when(progress.takesEffectAfter!)}',
      _ => null,
    };
    return Column(
      key: Key('decision-stage-${progress.stage.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in decisionStageWords.keys) _step(s, scheme, detail(s)),
        if (progress.stage == DecisionStage.failed)
          Card(
            key: const Key('decision-failed'),
            color: scheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.block, color: scheme.onErrorContainer),
              title: Text(
                progress.why ?? 'It will not take effect.',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ),
      ],
    );
  }

  Widget _step(DecisionStage s, ColorScheme scheme, String? detail) {
    final failed = progress.stage == DecisionStage.failed;
    final done =
        progress.stage == DecisionStage.done ||
        (!failed && s.index < progress.stage.index);
    final current = s == progress.stage && !done;
    return ListTile(
      key: Key('decision-step-${s.name}'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        done
            ? Icons.check_circle
            : current
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color: done || current ? scheme.primary : scheme.outline,
      ),
      title: Text(decisionStageWords[s]!),
      subtitle: current && detail != null ? Text(detail) : null,
    );
  }
}

String _when(DateTime t) {
  final u = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${u.year}-${two(u.month)}-${two(u.day)} ${two(u.hour)}:'
      '${two(u.minute)}';
}

/// After a guided act is signed: a proposal is followed until it is carried
/// out ([DecisionProgressScreen] in place of the flow); anything else just
/// closes the flow.
Future<void> followDecision(
  BuildContext context,
  String roomId,
  PreparedRoomAct sent,
  String title,
) async {
  final navigator = Navigator.of(context);
  if (!opensVote(sent.kind)) {
    navigator.pop();
    return;
  }
  await navigator.pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => DecisionProgressScreen(
        roomId: roomId,
        callId: sent.callId,
        title: title,
      ),
    ),
  );
}
