import 'package:flutter/services.dart';

import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../logging/app_logger.dart';
import '../settings/settings_service.dart';

part 'biometric_service.g.dart';

/// Types of biometric authentication available
enum AppBiometricType { fingerprint, face, iris, none }

/// Result of a biometric authentication attempt
enum BiometricAuthResult {
  success,
  failed,
  cancelled,
  notAvailable,
  notEnrolled,
  lockedOut,
  error,
}

/// Service for handling biometric authentication
class BiometricService {
  BiometricService(this._localAuth, this._settingsService);

  final LocalAuthentication _localAuth;
  final SettingsService _settingsService;

  /// Cache for biometric availability check
  bool? _isBiometricAvailable;
  List<AppBiometricType>? _availableBiometrics;

  /// Check if the device supports any biometric authentication
  Future<bool> isBiometricAvailable() async {
    if (_isBiometricAvailable != null) {
      return _isBiometricAvailable!;
    }

    try {
      // Check if the device can check biometrics
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      // Check if the device is capable of checking biometrics or has device PIN
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      _isBiometricAvailable = canCheckBiometrics || isDeviceSupported;

      AppLogger.debug(
        'Biometric availability check',
        data: {
          'canCheckBiometrics': canCheckBiometrics,
          'isDeviceSupported': isDeviceSupported,
          'isAvailable': _isBiometricAvailable,
        },
      );

      return _isBiometricAvailable!;
    } on PlatformException catch (e) {
      AppLogger.error(
        'Error checking biometric availability',
        error: e,
        data: {'code': e.code, 'message': e.message},
      );
      _isBiometricAvailable = false;
      return false;
    }
  }

  /// Get the list of available biometric types on this device
  Future<List<AppBiometricType>> getAvailableBiometrics() async {
    if (_availableBiometrics != null) {
      return _availableBiometrics!;
    }

    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      _availableBiometrics = availableBiometrics.map((bio) {
        switch (bio) {
          case BiometricType.fingerprint:
            return AppBiometricType.fingerprint;
          case BiometricType.face:
            return AppBiometricType.face;
          case BiometricType.iris:
            return AppBiometricType.iris;
          default:
            return AppBiometricType.none;
        }
      }).toList();

      AppLogger.debug(
        'Available biometrics',
        data: {'types': _availableBiometrics!.map((b) => b.name).toList()},
      );

      return _availableBiometrics!;
    } on PlatformException catch (e) {
      AppLogger.error(
        'Error getting available biometrics',
        error: e,
        data: {'code': e.code, 'message': e.message},
      );
      _availableBiometrics = [];
      return [];
    }
  }

  /// Check if biometric lock is enabled in settings
  bool isBiometricEnabled() {
    return _settingsService.biometricEnabled;
  }

  /// Get the lock timeout in minutes
  int getLockTimeoutMinutes() {
    return _settingsService.lockTimeoutMinutes;
  }

  /// Check if notifications should be shown when locked
  bool shouldShowNotificationsWhenLocked() {
    return _settingsService.showNotificationsLocked;
  }

  /// Enable or disable biometric lock
  Future<void> setBiometricEnabled(bool enabled) async {
    await _settingsService.setBiometricEnabled(enabled);
    AppLogger.info('Biometric lock ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Set the lock timeout in minutes
  Future<void> setLockTimeoutMinutes(int minutes) async {
    await _settingsService.setLockTimeoutMinutes(minutes);
    AppLogger.info('Lock timeout set to $minutes minutes');
  }

  /// Set whether notifications should be shown when locked
  Future<void> setShowNotificationsWhenLocked(bool show) async {
    await _settingsService.setShowNotificationsLocked(show);
    AppLogger.info('Show notifications when locked: $show');
  }

  /// Authenticate using biometrics or device credentials (PIN/password)
  ///
  /// [localizedReason] - The message shown to the user explaining why
  /// authentication is required.
  ///
  /// [allowDeviceCredentials] - If true, allows fallback to device PIN/password
  /// when biometrics are not available or fail.
  Future<BiometricAuthResult> authenticate({
    String localizedReason = 'Please authenticate to access the app',
    bool allowDeviceCredentials = true,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        AppLogger.warning('Biometric authentication not available');
        return BiometricAuthResult.notAvailable;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        persistAcrossBackgrounding: true,
        biometricOnly: !allowDeviceCredentials,
      );

      if (didAuthenticate) {
        AppLogger.info('Biometric authentication successful');
        return BiometricAuthResult.success;
      } else {
        AppLogger.info('Biometric authentication failed');
        return BiometricAuthResult.failed;
      }
    } on PlatformException catch (e) {
      AppLogger.error(
        'Biometric authentication error',
        error: e,
        data: {'code': e.code, 'message': e.message},
      );

      // Handle specific error codes
      switch (e.code) {
        case 'NotAvailable':
          return BiometricAuthResult.notAvailable;
        case 'NotEnrolled':
          return BiometricAuthResult.notEnrolled;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          return BiometricAuthResult.lockedOut;
        case 'UserCanceled':
          return BiometricAuthResult.cancelled;
        default:
          return BiometricAuthResult.error;
      }
    }
  }

  /// Stop any ongoing authentication
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } on PlatformException catch (e) {
      AppLogger.error(
        'Error stopping authentication',
        error: e,
        data: {'code': e.code, 'message': e.message},
      );
    }
  }

  /// Clear cached values (useful for testing or after settings change)
  void clearCache() {
    _isBiometricAvailable = null;
    _availableBiometrics = null;
  }

  /// Get a human-readable description of available biometric types
  Future<String> getBiometricDescription() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.isEmpty) {
      return 'No biometric authentication available';
    }

    final types = <String>[];
    if (biometrics.contains(AppBiometricType.fingerprint)) {
      types.add('Fingerprint');
    }
    if (biometrics.contains(AppBiometricType.face)) {
      types.add('Face ID');
    }
    if (biometrics.contains(AppBiometricType.iris)) {
      types.add('Iris');
    }

    if (types.isEmpty) {
      return 'Device PIN/Password';
    }

    return types.join(', ');
  }
}

/// Provider for LocalAuthentication instance
@riverpod
LocalAuthentication localAuthentication(Ref ref) => LocalAuthentication();

/// Provider for BiometricService
@riverpod
BiometricService biometricService(Ref ref) {
  final localAuth = ref.watch(localAuthenticationProvider);
  final settingsService = ref.watch(settingsServiceProvider);
  return BiometricService(localAuth, settingsService);
}

/// Provider that checks if biometric authentication is available
@riverpod
Future<bool> isBiometricAvailable(Ref ref) async {
  final biometricService = ref.watch(biometricServiceProvider);
  return biometricService.isBiometricAvailable();
}

/// Provider that gets available biometric types
@riverpod
Future<List<AppBiometricType>> availableBiometrics(Ref ref) async {
  final biometricService = ref.watch(biometricServiceProvider);
  return biometricService.getAvailableBiometrics();
}

/// Provider that gets the biometric description
@riverpod
Future<String> biometricDescription(Ref ref) async {
  final biometricService = ref.watch(biometricServiceProvider);
  return biometricService.getBiometricDescription();
}
