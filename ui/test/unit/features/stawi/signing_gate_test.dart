import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/signing_gate.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi/features/stawi/ui/stawi_feedback.dart';

import '../../../support/stawi_fakes.dart';

/// A LocalAuthentication whose device support and authentication answers
/// are scripted, recording the prompts it was asked to show.
class _FakeAuth implements LocalAuthentication {
  _FakeAuth({this.supported = true, this.answer = true, this.supportError});

  final bool supported;
  final Exception? supportError;

  /// true or false, or an error to throw.
  final Object answer;
  final List<String> prompts = [];
  final List<bool> biometricOnly = [];

  @override
  Future<bool> isDeviceSupported() async {
    if (supportError != null) throw supportError!;
    return supported;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #authenticate) {
      prompts.add(invocation.namedArguments[#localizedReason] as String);
      biometricOnly.add(
        invocation.namedArguments[#biometricOnly] as bool? ?? false,
      );
      final a = answer;
      return a is bool ? Future<bool>.value(a) : Future<bool>.error(a);
    }
    return super.noSuchMethod(invocation);
  }
}

Matcher refusedWith(String reason) =>
    throwsA(isA<SigningRefused>().having((e) => e.reason, 'reason', reason));

void main() {
  group('LocalAuthSigningGate', () {
    test('a confirmed device lock lets the signature through', () async {
      final auth = _FakeAuth();
      await LocalAuthSigningGate(auth).confirm('Lend 300.00 USDC');
      expect(auth.prompts, ['Lend 300.00 USDC']);
      expect(auth.biometricOnly, [false], reason: 'the device PIN is allowed');
    });

    test('a device with no secure lock signs nothing', () async {
      final auth = _FakeAuth(supported: false);
      await expectLater(
        LocalAuthSigningGate(auth).confirm('x'),
        refusedWith(screenLockRequiredReason),
      );
      expect(auth.prompts, isEmpty);
      expect(
        screenLockRequiredReason,
        'Set a screen lock on this phone to sign',
      );
    });

    test('a lock that cannot be checked signs nothing', () async {
      final auth = _FakeAuth(supportError: PlatformException(code: 'x'));
      await expectLater(
        LocalAuthSigningGate(auth).confirm('x'),
        refusedWith(notConfirmedReason),
      );
      expect(auth.prompts, isEmpty);
    });

    for (final code in [
      LocalAuthExceptionCode.noCredentialsSet,
      LocalAuthExceptionCode.noBiometricsEnrolled,
    ]) {
      test('no passcode or biometrics set up (${code.name}) signs nothing', () {
        expect(
          LocalAuthSigningGate(
            _FakeAuth(answer: LocalAuthException(code: code)),
          ).confirm('x'),
          refusedWith(screenLockRequiredReason),
        );
      });
    }

    test('a refusal signs nothing', () {
      expect(
        LocalAuthSigningGate(_FakeAuth(answer: false)).confirm('x'),
        refusedWith(notConfirmedReason),
      );
    });

    for (final code in [
      LocalAuthExceptionCode.userCanceled,
      LocalAuthExceptionCode.systemCanceled,
      LocalAuthExceptionCode.timeout,
      LocalAuthExceptionCode.userRequestedFallback,
      LocalAuthExceptionCode.temporaryLockout,
      LocalAuthExceptionCode.biometricLockout,
      LocalAuthExceptionCode.authInProgress,
      LocalAuthExceptionCode.uiUnavailable,
      LocalAuthExceptionCode.noBiometricHardware,
      LocalAuthExceptionCode.deviceError,
      LocalAuthExceptionCode.unknownError,
    ]) {
      test('a cancel or failure (${code.name}) signs nothing', () {
        expect(
          LocalAuthSigningGate(
            _FakeAuth(answer: LocalAuthException(code: code)),
          ).confirm('x'),
          refusedWith(notConfirmedReason),
        );
      });
    }

    test('any other error signs nothing', () async {
      for (final error in [
        PlatformException(code: 'NotAvailable'),
        StateError('boom'),
        'thrown string',
      ]) {
        await expectLater(
          LocalAuthSigningGate(_FakeAuth(answer: error)).confirm('x'),
          refusedWith(notConfirmedReason),
        );
      }
    });

    test('the person reads why nothing was signed', () {
      expect(
        stawiErrorMessage(const SigningRefused(notConfirmedReason)),
        'Not signed: not confirmed on this device',
      );
    });
  });

  group('SigningGate constants', () {
    test('the open gate confirms without a prompt', () async {
      await SigningGate.open.confirm('x');
    });

    test('the refusing gate refuses', () {
      expect(
        SigningGate.refusing.confirm('x'),
        refusedWith(notConfirmedReason),
      );
    });
  });

  group('DeviceKeyStore.unlock', () {
    test('a refused device lock signs nothing', () async {
      final gate = RecordingSigningGate(refuse: true);
      final store = DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate);
      await expectLater(
        store.unlock('p1', reason: 'Lend 300.00 USDC'),
        throwsA(isA<SigningRefused>()),
      );
      expect(gate.reasons, ['Lend 300.00 USDC']);
    });

    test('a refused first signature generates no key', () async {
      final vault = MemoryDeviceKeyVault();
      final store = DeviceKeyStore(vault, gate: SigningGate.refusing);
      await expectLater(
        store.unlock('p1', reason: 'x'),
        throwsA(isA<SigningRefused>()),
      );
      expect(vault.writes, 0);
    });

    test('a confirmed gate hands out the key', () async {
      final gate = RecordingSigningGate();
      final store = DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate);
      expect(
        (await store.unlock('p1', reason: 'x')).address,
        (await store.loadOrCreate('p1')).address,
      );
      expect(gate.reasons, ['x']);
    });
  });
}
