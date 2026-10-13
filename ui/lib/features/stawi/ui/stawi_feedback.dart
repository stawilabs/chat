import 'package:connectrpc/connect.dart' as connect;
import 'package:flutter/material.dart';

import '../data/stawi_counterparty.dart';
import '../data/stawi_identity.dart';
import '../domain/signing_checks.dart';

/// What to tell the member when settlement asks them to retry a member
/// action because their account is still being settled (an engine's
/// SettleAgain): nothing failed; the same action goes through shortly.
const String accountCatchingUpMessage =
    'Your account is being brought up to date; try again shortly';

/// Whether [error] is settlement's retryable answer to a member action whose
/// account is being brought up to date (Unavailable, from SettleAgain).
bool isAccountCatchingUp(Object error) =>
    error is connect.ConnectException &&
    error.code == connect.Code.unavailable &&
    error.message.contains('being brought up to date');

/// What to tell the member when a Stawi action fails.
String stawiErrorMessage(Object error) => switch (error) {
  _ when isAccountCatchingUp(error) => accountCatchingUpMessage,
  SigningRefused(:final reason) => 'Not signed: $reason',
  StawiUnavailable(:final message) => message,
  DirectPartnerRefused() => DirectPartnerRefused.messageFor('They'),
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
