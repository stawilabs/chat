import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;

import '../data/stawi_account_service.dart';
import '../domain/money_review.dart';
import 'stawi_feedback.dart';

/// Shows [review]; true when the person confirmed. Dismissing it, or
/// cancelling, is false.
Future<bool> showMoneyReview(BuildContext context, MoneyReview review) async {
  var closed = false;
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          void close(bool confirmed) {
            if (closed) return;
            closed = true;
            Navigator.of(context).pop(confirmed);
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                key: const Key('money-review'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    review.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final (label, value) in review.lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(label)),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(value, textAlign: TextAlign.end),
                          ),
                        ],
                      ),
                    ),
                  for (final note in review.notes)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        note,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Checked on this device: this is what you asked for, from '
                    'your account.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  // The sheet closes once: a second tap on either button would
                  // otherwise pop the screen underneath.
                  FilledButton(
                    key: const Key('money-review-sign'),
                    onPressed: () => close(true),
                    child: Text(review.signLabel),
                  ),
                  TextButton(
                    key: const Key('money-review-cancel'),
                    onPressed: () => close(false),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          );
        },
      ) ??
      false;
}

/// Shows [prepared]'s review and, once confirmed, signs and submits it.
/// Null when the person cancelled or the submit failed (a snack bar says why).
Future<settlement.AccountCall?> reviewAndSubmit(
  BuildContext context,
  WidgetRef ref,
  PreparedMoneyCall prepared,
) async {
  if (!await showMoneyReview(context, prepared.review) || !context.mounted) {
    return null;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  final call = await runStawiAction(
    context,
    () => ref.read(stawiAccountServiceProvider).submit(prepared),
    success: sentWaitingMessage,
  );
  if (call != null) {
    _outcomes[call] = _Outcome(messenger, prepared.review.done);
  }
  return call;
}

/// Said when a call is submitted: nothing is done until the chain says so.
const String sentWaitingMessage = 'Sent; waiting for confirmation';

/// Said when a call was followed but is not final yet.
const String notConfirmedMessage =
    'Not confirmed yet; it may still go through. Check again shortly';

/// What to say once a submitted call was followed to [last]: its review's
/// [done] only when it is final; why it failed or expired; otherwise that it
/// is not confirmed yet (null: it could not be read).
String outcomeMessage(settlement.AccountCall? last, String done) =>
    switch (last?.state) {
      settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL => done,
      settlement.AccountCallState.ACCOUNT_CALL_STATE_FAILED ||
      settlement.AccountCallState.ACCOUNT_CALL_STATE_EXPIRED =>
        last!.failureReason.isEmpty
            ? 'It did not go through; try again'
            : 'Not done: ${last.failureReason}',
      _ => notConfirmedMessage,
    };

/// Where a submitted call's outcome is said, and what it says once final.
final class _Outcome {
  const _Outcome(this.messenger, this.done);

  final ScaffoldMessengerState? messenger;
  final String done;
}

/// The outcome still to be said for each call [reviewAndSubmit] submitted,
/// held weakly by the call itself.
final Expando<_Outcome> _outcomes = Expando('money outcome');

/// Says how [submitted] ended, once it was followed to [last]: the review's
/// "done" only when it is final, the failure otherwise. Said once per call;
/// a call not submitted through [reviewAndSubmit] says nothing.
void reportOutcome(
  settlement.AccountCall submitted,
  settlement.AccountCall? last,
) {
  final outcome = _outcomes[submitted];
  if (outcome == null) return;
  _outcomes[submitted] = null;
  outcome.messenger?.showSnackBar(
    SnackBar(content: Text(outcomeMessage(last, outcome.done))),
  );
}

/// Says [submitted] is done: a follow that reads past the call (a loan
/// followed until it is active) found it final.
void reportDone(settlement.AccountCall submitted) => reportOutcome(
  submitted,
  settlement.AccountCall(
    state: settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL,
  ),
);

/// prepare → review → device lock → submit, with errors in a snack bar; null
/// when nothing was signed.
Future<settlement.AccountCall?> runMoneyAction(
  BuildContext context,
  WidgetRef ref,
  Future<PreparedMoneyCall> Function() prepare,
) async {
  final prepared = await runStawiAction(context, prepare);
  if (prepared == null || !context.mounted) return null;
  return reviewAndSubmit(context, ref, prepared);
}
