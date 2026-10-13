import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../domain/signing_checks.dart';

/// Why a device with no screen lock signs nothing.
const String screenLockRequiredReason =
    'Set a screen lock on this phone to sign';

/// Why a signature the person cancelled or refused was not made.
const String notConfirmedReason = 'not confirmed on this device';

/// Asks the person holding the device to confirm with its lock (biometrics or
/// the device PIN) before a Stawi signature. It fails closed: a device with
/// no secure lock, a refusal, a cancel or any error signs nothing.
abstract interface class SigningGate {
  /// Completes when the person confirmed [reason] (what is about to be
  /// signed, in their words); throws [SigningRefused] otherwise.
  Future<void> confirm(String reason);

  /// No prompt. Tests only: production always injects [signingGateProvider].
  static const SigningGate open = _OpenGate();

  /// Refuses every signature.
  static const SigningGate refusing = _RefusingGate();
}

final class _OpenGate implements SigningGate {
  const _OpenGate();

  @override
  Future<void> confirm(String reason) async {}
}

final class _RefusingGate implements SigningGate {
  const _RefusingGate();

  @override
  Future<void> confirm(String reason) async =>
      throw const SigningRefused(notConfirmedReason);
}

/// The device lock codes that mean no PIN, pattern, passcode or biometric is
/// set up, so nothing could be confirmed.
const Set<LocalAuthExceptionCode> _noLockCodes = {
  LocalAuthExceptionCode.noCredentialsSet,
  LocalAuthExceptionCode.noBiometricsEnrolled,
};

/// [SigningGate] over the platform's device lock (local_auth).
final class LocalAuthSigningGate implements SigningGate {
  LocalAuthSigningGate(this._auth);

  final LocalAuthentication _auth;

  @override
  Future<void> confirm(String reason) async {
    final bool supported;
    try {
      supported = await _auth.isDeviceSupported();
    } on Object {
      throw const SigningRefused(notConfirmedReason);
    }
    if (!supported) throw const SigningRefused(screenLockRequiredReason);
    final bool ok;
    try {
      ok = await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      throw SigningRefused(
        _noLockCodes.contains(e.code)
            ? screenLockRequiredReason
            : notConfirmedReason,
      );
    } on Object {
      throw const SigningRefused(notConfirmedReason);
    }
    if (!ok) throw const SigningRefused(notConfirmedReason);
  }
}

final signingGateProvider = Provider<SigningGate>(
  (ref) => LocalAuthSigningGate(LocalAuthentication()),
);
