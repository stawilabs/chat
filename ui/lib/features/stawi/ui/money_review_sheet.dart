import 'package:connectrpc/connect.dart' as connect;
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
/// Null when the person cancelled, the submit was refused, or its fate is not
/// known yet (a snack bar says which).
///
/// The signed call is kept (in the app database, across restarts) before it
/// is sent. A submit that fails without a clear refusal may still have been
/// taken, so the call is followed: read, and submitted again as the same
/// signed call while settlement has not taken it. It is never prepared
/// again, which would take the next nonce and pay twice. Until its fate is
/// known no other call is reviewed: the next attempt checks it first.
Future<settlement.AccountCall?> reviewAndSubmit(
  BuildContext context,
  WidgetRef ref,
  PreparedMoneyCall prepared,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final service = ref.read(stawiAccountServiceProvider);
  void say(String message) => messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  // Kept across restarts: a call signed before the app stopped is checked
  // first, and re-submitted as signed while settlement has not taken it.
  final SignedMoneyCall? earlier;
  try {
    earlier = await service.unconfirmedCall();
  } on Object catch (error) {
    say(stawiErrorMessage(error));
    return null;
  }
  if (earlier != null) {
    say(checkingSubmitMessage);
    try {
      if (await _followSigned(service, earlier) == null) {
        say(notConfirmedSubmitMessage);
        return null;
      }
      await service.clearUnconfirmed(earlier);
      say(earlierCallSentMessage(earlier.title));
    } on Object catch (error) {
      await service.clearUnconfirmed(earlier);
      say(stawiErrorMessage(error));
    }
    return null;
  }

  if (!context.mounted ||
      !await showMoneyReview(context, prepared.review) ||
      !context.mounted) {
    return null;
  }
  final signed = await runStawiAction(
    context,
    () => service.signCall(prepared),
  );
  if (signed == null || !context.mounted) return null;
  // Kept before it is sent, so a submit cut short (the app stopped, the
  // answer lost) is followed as this call, never prepared again; forgotten
  // only once its fate is known. Nothing is sent if it cannot be kept.
  if (await runStawiAction(context, () => service.holdUnconfirmed(signed)) ==
      null) {
    return null;
  }

  settlement.AccountCall? call;
  try {
    call = await service.submitSigned(signed);
  } on Object catch (error) {
    if (isDefiniteRefusal(error)) {
      await service.clearUnconfirmed(signed);
      say(stawiErrorMessage(error));
      return null;
    }
    say(checkingSubmitMessage);
    try {
      call = await _followSigned(service, signed);
    } on Object catch (refused) {
      await service.clearUnconfirmed(signed);
      say(stawiErrorMessage(refused));
      return null;
    }
    if (call == null) {
      say(notConfirmedSubmitMessage);
      return null;
    }
  }
  await service.clearUnconfirmed(signed);
  say(sentWaitingMessage);
  _outcomes[call] = _Outcome(messenger, prepared.review.done);
  return call;
}

/// Finds out whether settlement took [signed]: the call as it stands once it
/// is past PREPARED, submitting the same signed call again while it is not.
/// Null when no answer came in [attempts] tries; a clear refusal is thrown.
Future<settlement.AccountCall?> _followSigned(
  StawiAccountService service,
  SignedMoneyCall signed, {
  int attempts = 3,
}) async {
  for (var i = 0; i < attempts; i++) {
    if (i > 0) await Future<void>.delayed(service.followEvery);
    try {
      final call = await service.accountCall(signed.callId);
      if (call.state !=
          settlement.AccountCallState.ACCOUNT_CALL_STATE_PREPARED) {
        return call;
      }
      return await service.submitSigned(signed);
    } on Object catch (error) {
      if (isDefiniteRefusal(error)) rethrow;
    }
  }
  return null;
}

/// Whether [error] is settlement's clear answer that it did not take a call:
/// it refused it, or the account is catching up (the call stays prepared).
/// Anything else (unreachable, timed out, a lost connection) may have been
/// taken before the answer was lost.
bool isDefiniteRefusal(Object error) => switch (error) {
  _ when isAccountCatchingUp(error) => true,
  connect.ConnectException(:final code) => switch (code) {
    connect.Code.invalidArgument ||
    connect.Code.notFound ||
    connect.Code.alreadyExists ||
    connect.Code.permissionDenied ||
    connect.Code.failedPrecondition ||
    connect.Code.outOfRange ||
    connect.Code.unauthenticated ||
    connect.Code.unimplemented ||
    connect.Code.resourceExhausted => true,
    _ => false,
  },
  _ => false,
};

/// Said while a submit without a clear answer is checked.
const String checkingSubmitMessage = 'Checking whether it went through…';

/// Said when a submit's fate could not be found out.
const String notConfirmedSubmitMessage =
    'Could not confirm it went through; it may still. Do not send it again; '
    'check again shortly';

/// Said when a call whose submit got no clear answer turns out to be taken.
String earlierCallSentMessage(String title) =>
    '“$title” was sent; waiting for confirmation. Check it before sending '
    'again';

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
