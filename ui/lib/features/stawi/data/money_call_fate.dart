import 'package:connectrpc/connect.dart' as connect;
import 'package:stawi_api/settlement_v1.dart' as settlement;

/// What became of a signed money call, as far as settlement has said.
sealed class MoneyCallFate {
  const MoneyCallFate();
}

/// Settlement took the call: it is submitted, included or final, and is
/// followed as such.
final class CallTaken extends MoneyCallFate {
  const CallTaken(this.call);

  final settlement.AccountCall call;
}

/// Why a call was not paid.
enum NotPaidReason {
  /// Settlement refused the submit ([CallNotPaid.error] says why).
  refused,

  /// The call's validity passed before it went through.
  expired,

  /// It went through and failed on the chain ([CallNotPaid.failureReason]).
  failed,

  /// Settlement no longer knows the call: it expired and was let go, or was
  /// never prepared.
  gone,
}

/// Definitely not paid: nothing moved.
final class CallNotPaid extends MoneyCallFate {
  const CallNotPaid.refused(Object this.error)
    : reason = NotPaidReason.refused,
      failureReason = '';
  const CallNotPaid.expired()
    : reason = NotPaidReason.expired,
      error = null,
      failureReason = '';
  const CallNotPaid.failed(this.failureReason)
    : reason = NotPaidReason.failed,
      error = null;
  const CallNotPaid.gone()
    : reason = NotPaidReason.gone,
      error = null,
      failureReason = '';

  final NotPaidReason reason;
  final Object? error;
  final String failureReason;
}

/// No answer yet: the call may still be taken, so it is kept and checked
/// again before any other money call.
final class CallUnknown extends MoneyCallFate {
  const CallUnknown();
}

/// What a new account call held back by an earlier one would have done.
enum HeldBack {
  /// Money (or any account call but a key change).
  money,

  /// Adding a device key.
  keyChange,
}

/// A new account call was asked for while an earlier signed call's fate was
/// unknown. The earlier call was followed first ([fate]) and no new call was
/// prepared.
final class EarlierMoneyCall implements Exception {
  const EarlierMoneyCall(
    this.title,
    this.fate, {
    this.heldBack = HeldBack.money,
  });

  /// The earlier call's review title.
  final String title;
  final MoneyCallFate fate;

  /// What the new call would have done.
  final HeldBack heldBack;

  @override
  String toString() => 'an earlier money call ("$title") was checked first';
}

/// A call of the same kind is still open on the account in settlement
/// (submitted, included, or signed and not yet sent), perhaps from another
/// device, a reinstall or cleared app data. Nothing new is reviewed or
/// signed while it is.
final class OpenMoneyCall implements Exception {
  const OpenMoneyCall(
    this.call,
    this.fate, {
    required this.samePayment,
    required this.title,
    this.heldBack = HeldBack.money,
  });

  /// The open call, as settlement listed it.
  final settlement.AccountCall call;

  /// [CallTaken] while it is submitted or included; [CallUnknown] for a
  /// signed call settlement has not sent yet.
  final MoneyCallFate fate;

  /// Whether it is the very payment asked for again (same account, kind,
  /// target and amount); otherwise only its kind is known to match.
  final bool samePayment;

  /// The review title of the call asked for now.
  final String title;

  /// What the new call would have done.
  final HeldBack heldBack;

  @override
  String toString() => 'an open call of this kind was found (${call.callId})';
}

/// Settlement's open calls could not be read, so it is not known whether
/// this payment was already sent (from another device, say). Nothing new is
/// signed until they can be read.
final class OpenCallsUnknown implements Exception {
  const OpenCallsUnknown([this.error]);

  /// Why they could not be read; null when there were too many to read.
  final Object? error;

  @override
  String toString() => 'the open calls could not be read ($error)';
}

/// The fate a call's state tells, or null for one that says nothing yet
/// (PREPARED, unspecified).
MoneyCallFate? fateOfCall(settlement.AccountCall call) => switch (call.state) {
  settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED ||
  settlement.AccountCallState.ACCOUNT_CALL_STATE_INCLUDED ||
  settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL => CallTaken(call),
  settlement.AccountCallState.ACCOUNT_CALL_STATE_EXPIRED =>
    const CallNotPaid.expired(),
  settlement.AccountCallState.ACCOUNT_CALL_STATE_FAILED => CallNotPaid.failed(
    call.failureReason,
  ),
  _ => null,
};

/// Whether [error] is settlement's answer to a member action whose account
/// is being brought up to date (Unavailable, from SettleAgain): the call
/// stays prepared and unsigned, so nothing was taken.
bool isAccountCatchingUp(Object error) =>
    error is connect.ConnectException &&
    error.code == connect.Code.unavailable &&
    error.message.contains('being brought up to date');

/// Whether [error], from submitting a held call again, is settlement's own
/// clear answer that it did not take the call. Narrower than
/// [isSubmitRefusal]: unauthenticated, resourceExhausted and unimplemented
/// come from interceptors or the gateway and describe this request, not the
/// call, which an earlier submit still in flight may yet commit.
bool isResubmitRefusal(Object error) => switch (error) {
  _ when isAccountCatchingUp(error) => true,
  connect.ConnectException(:final code) => switch (code) {
    connect.Code.invalidArgument ||
    connect.Code.notFound ||
    connect.Code.permissionDenied ||
    connect.Code.failedPrecondition ||
    connect.Code.outOfRange => true,
    _ => false,
  },
  _ => false,
};

/// Whether [error], from SubmitAccountCall, is settlement's clear answer that
/// it did not take the call. AlreadyExists is not: it means the call was
/// already submitted. Anything else (unreachable, timed out, a lost
/// connection) may have been taken before the answer was lost.
bool isSubmitRefusal(Object error) => switch (error) {
  _ when isAccountCatchingUp(error) => true,
  connect.ConnectException(:final code) => switch (code) {
    connect.Code.invalidArgument ||
    connect.Code.notFound ||
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
