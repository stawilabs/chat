import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;

import '../data/money_call_fate.dart';
import '../data/open_money_calls.dart';
import '../data/stawi_account_service.dart';
import '../domain/money_review.dart';
import 'loan_widgets.dart' show moneyProviders, settleThenRefresh;
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
/// Null when the person cancelled, the call was not paid, or its fate is not
/// known yet (a snack bar says which).
///
/// The signed call is kept (in the app database, across restarts) before it
/// is sent. A submit that fails without a clear refusal may still have been
/// taken, so the call is followed: read, and submitted again as the same
/// signed call while settlement has not taken it. It is never prepared
/// again, which would take the next nonce and pay twice. Until its fate is
/// known no other call is prepared or reviewed
/// ([StawiAccountService.refuseWhileUnconfirmed]).
///
/// Before the review, settlement's open calls of the same kind are read
/// ([StawiAccountService.refuseOpenCalls]), which covers a call sent from
/// another device or before a reinstall. When the same payment is already
/// on its way, that call is answered (and its outcome said once it is
/// followed) and nothing new is signed; when they cannot be read, nothing is
/// signed either.
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

  final container = moneyContainer(context);

  // Prepares already refuse while an earlier call is unconfirmed; this
  // covers one held by another flow since [prepared] was prepared. Then
  // settlement's open calls: one this device has no record of (sent from
  // another device, or before a reinstall or cleared data) is followed, not
  // paid again. Any doubt stops here, before anything is signed.
  try {
    await service.refuseWhileUnconfirmed(heldBack: heldBackBy(prepared.kind));
    await service.refuseOpenCalls(prepared);
  } on EarlierMoneyCall catch (earlier) {
    say(stawiErrorMessage(earlier));
    if (earlier.fate case CallTaken(:final call)) {
      if (matchOpenCall(call, prepared.intended) == OpenCallMatch.samePayment) {
        _outcomes[call] = _Outcome(messenger, prepared.review.done);
        return call;
      }
      _followEarlier(container, service, call, messenger, earlier.title);
    }
    return null;
  } on OpenMoneyCall catch (open) {
    say(stawiErrorMessage(open));
    if (open.fate case CallTaken(:final call)) {
      if (open.samePayment) {
        _outcomes[call] = _Outcome(messenger, prepared.review.done);
        return call;
      }
      _followEarlier(container, service, call, messenger, null);
    }
    return null;
  } on Object catch (error) {
    say(stawiErrorMessage(error));
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

  say(checkingSubmitMessage);
  final MoneyCallFate fate;
  try {
    fate = await service.submitHeld(signed);
  } on Object catch (error) {
    say(stawiErrorMessage(error));
    return null;
  }
  switch (fate) {
    case CallTaken(:final call):
      say(sentWaitingMessage);
      _outcomes[call] = _Outcome(messenger, prepared.review.done);
      return call;
    case final CallNotPaid notPaid:
      say(notPaidMessage(notPaid));
      return null;
    case CallUnknown():
      say(notConfirmedSubmitMessage);
      return null;
  }
}

/// Said while a submit is sent and, without a clear answer, checked.
const String checkingSubmitMessage = 'Checking whether it went through…';

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

/// Said once an earlier call found taken is final: [title] names it, when
/// known.
String earlierDoneMessage(String? title) =>
    title == null ? 'The earlier payment is done' : 'Done: “$title”';

/// Follows [call], an earlier call found taken that is not the one asked for
/// now, until it ends, then reads the money views again and says how it
/// ended: its own outcome, so the person learns when they may go on.
void _followEarlier(
  ProviderContainer container,
  StawiAccountService service,
  settlement.AccountCall call,
  ScaffoldMessengerState? messenger,
  String? title,
) {
  // One follow per call, however often the person taps meanwhile.
  if (!_followingEarlier.add(call.callId)) return;
  _outcomes[call] = _Outcome(messenger, earlierDoneMessage(title));
  unawaited(
    settleThenRefresh(
      container,
      service,
      call,
      moneyProviders(),
    ).whenComplete(() => _followingEarlier.remove(call.callId)),
  );
}

/// The earlier calls [_followEarlier] is following now.
final Set<String> _followingEarlier = {};

/// Runs [prepare], with errors in a snack bar; null when nothing was
/// prepared. An earlier call found taken instead is followed until it ends,
/// and its outcome said.
Future<PreparedMoneyCall?> prepareMoneyCall(
  BuildContext context,
  WidgetRef ref,
  Future<PreparedMoneyCall> Function() prepare,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final container = moneyContainer(context);
  final service = ref.read(stawiAccountServiceProvider);
  try {
    return await prepare();
  } on Object catch (error) {
    messenger?.showSnackBar(SnackBar(content: Text(stawiErrorMessage(error))));
    if (error case EarlierMoneyCall(
      :final title,
      fate: CallTaken(:final call),
    )) {
      _followEarlier(container, service, call, messenger, title);
    }
    return null;
  }
}

/// prepare → review → device lock → submit, with errors in a snack bar; null
/// when nothing was signed. The call it answers is followed by the caller:
/// the new one, or the same payment found already sent.
Future<settlement.AccountCall?> runMoneyAction(
  BuildContext context,
  WidgetRef ref,
  Future<PreparedMoneyCall> Function() prepare,
) async {
  final prepared = await prepareMoneyCall(context, ref, prepare);
  if (prepared == null || !context.mounted) return null;
  return reviewAndSubmit(context, ref, prepared);
}
