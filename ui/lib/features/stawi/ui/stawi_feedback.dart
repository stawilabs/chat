import 'package:connectrpc/connect.dart' as connect;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderBase;

import '../data/money_call_fate.dart';
import '../data/stawi_counterparty.dart';
import '../data/stawi_identity.dart';
import '../domain/signing_checks.dart';

export '../data/money_call_fate.dart' show isAccountCatchingUp;

/// What to tell the member when settlement asks them to retry a member
/// action because their account is still being settled (an engine's
/// SettleAgain): nothing failed; the same action goes through shortly.
const String accountCatchingUpMessage =
    'Your account is being brought up to date; try again shortly';

/// Said when a submit's fate could not be found out.
const String notConfirmedSubmitMessage =
    'Could not confirm it went through; it may still. Do not send it again; '
    'check again shortly';

/// Said when a call whose submit got no clear answer turns out to be taken.
String earlierCallSentMessage(String title) =>
    '“$title” was sent; waiting for confirmation. Check it before sending '
    'again';

/// Said when a new money call waits on an earlier one whose fate is still
/// unknown.
String earlierCallUnconfirmedMessage(String title) =>
    'Could not confirm “$title” went through; it may still. Nothing new is '
    'sent until it is known; check again shortly';

/// Why [fate]'s call was not paid; nothing moved.
String notPaidMessage(CallNotPaid fate) => switch (fate.reason) {
  NotPaidReason.refused => stawiErrorMessage(fate.error!),
  NotPaidReason.expired =>
    'It expired before it went through; nothing was paid',
  NotPaidReason.failed =>
    fate.failureReason.isEmpty
        ? 'It did not go through; nothing was paid'
        : 'Not done: ${fate.failureReason}; nothing was paid',
  NotPaidReason.gone => 'It did not go through; nothing was paid',
};

/// What to say when a new money call was held back by an earlier one.
String earlierCallMessage(EarlierMoneyCall earlier) => switch (earlier.fate) {
  CallTaken() => earlierCallSentMessage(earlier.title),
  final CallNotPaid notPaid =>
    '“${earlier.title}” was not sent: ${notPaidMessage(notPaid)}',
  CallUnknown() => earlierCallUnconfirmedMessage(earlier.title),
};

/// What to tell the member when a Stawi action fails.
String stawiErrorMessage(Object error) => switch (error) {
  _ when isAccountCatchingUp(error) => accountCatchingUpMessage,
  final EarlierMoneyCall earlier => earlierCallMessage(earlier),
  SigningRefused(:final reason) => 'Not signed: $reason',
  StawiUnavailable(:final message) => message,
  DirectPartnerRefused() => DirectPartnerRefused.messageFor('They'),
  // Too many partner lookups for now: unknown, shown as "—" until they are
  // asked again.
  PartnerLookupsExhausted() => '—',
  connect.ConnectException(:final code, :final message) => switch (code) {
    connect.Code.unauthenticated => 'Sign in again to continue',
    connect.Code.permissionDenied => 'Not allowed: $message',
    connect.Code.unavailable => 'Stawi is unreachable; try again shortly',
    _ => message,
  },
  FormatException(:final message) => message,
  ArgumentError(:final message) => '$message',
  StateError(:final message) => message,
  _ => 'Something went wrong: $error',
};

/// Runs [action], reporting failure (and [success], when given) in a snack
/// bar. Returns the result, or null when the action failed.
Future<T?> runStawiAction<T>(
  BuildContext context,
  Future<T> Function() action, {
  String? success,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final result = await action();
    if (success != null) {
      messenger?.showSnackBar(SnackBar(content: Text(success)));
    }
    return result;
  } on Object catch (error) {
    messenger?.showSnackBar(SnackBar(content: Text(stawiErrorMessage(error))));
    return null;
  }
}

/// A short, readable form of a hex value: 0x1234…abcd.
String shortHex(String hex) => hex.length <= 14
    ? hex
    : '${hex.substring(0, 6)}…${hex.substring(hex.length - 4)}';

/// The provider container [context] is under, resolved now: money actions
/// take it before their first await, so what they refresh at the end is
/// refreshed even when the person has left the screen by then.
ProviderContainer moneyContainer(BuildContext context) =>
    ProviderScope.containerOf(context, listen: false);

/// Reads [providers] again through [container], which outlives any widget
/// (see [moneyContainer]), so this works after the screen is gone.
void invalidateAll(
  ProviderContainer container,
  Iterable<ProviderBase<Object?>> providers,
) {
  for (final p in providers) {
    container.invalidate(p);
  }
}
