import 'dart:io';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../logging/app_logger.dart';
import '../storage/key_manager.dart';

part 'screenshot_prevention_service.g.dart';

/// Service for preventing screenshots and screen recording
///
/// Uses platform-specific methods:
/// - Android: FLAG_SECURE to prevent screenshots and screen recording
/// - iOS: Overlay view to obscure content in app switcher
///
/// This feature can be enabled/disabled by users in privacy settings.
class ScreenshotPreventionService {
  ScreenshotPreventionService(this._keyManager);

  final KeyManager _keyManager;

  static const _methodChannel = MethodChannel('chat.app/screenshot_prevention');
  static const _enabledKey = 'screenshot_prevention_enabled';

  bool _isEnabled = false;
  bool _isApplied = false;

  /// Whether screenshot prevention is currently enabled
  bool get isEnabled => _isEnabled;

  /// Initialize the service and apply saved settings
  Future<void> initialize() async {
    try {
      _isEnabled = await _keyManager.getBool(_enabledKey) ?? false;
      if (_isEnabled) {
        await enableScreenshotPrevention();
      }
      AppLogger.debug(
        'Screenshot prevention initialized',
        data: {'enabled': _isEnabled},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to initialize screenshot prevention',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Enable screenshot prevention
  ///
  /// On Android: Sets FLAG_SECURE on the window
  /// On iOS: Adds a secure text field overlay
  Future<bool> enableScreenshotPrevention() async {
    if (_isApplied) return true;

    try {
      if (Platform.isAndroid) {
        await _methodChannel.invokeMethod('enableSecureFlag');
      } else if (Platform.isIOS) {
        await _methodChannel.invokeMethod('enableSecureField');
      }
      _isApplied = true;
      _isEnabled = true;
      await _keyManager.setBool(_enabledKey, true);
      AppLogger.info('Screenshot prevention enabled');
      return true;
    } on PlatformException catch (e) {
      AppLogger.error('Failed to enable screenshot prevention', error: e);
      return false;
    } on MissingPluginException {
      // Platform channel not available, log and continue
      AppLogger.warning('Screenshot prevention not available on this platform');
      _isEnabled = true;
      await _keyManager.setBool(_enabledKey, true);
      return true;
    }
  }

  /// Disable screenshot prevention
  Future<bool> disableScreenshotPrevention() async {
    if (!_isApplied && !_isEnabled) return true;

    try {
      if (Platform.isAndroid) {
        await _methodChannel.invokeMethod('disableSecureFlag');
      } else if (Platform.isIOS) {
        await _methodChannel.invokeMethod('disableSecureField');
      }
      _isApplied = false;
      _isEnabled = false;
      await _keyManager.setBool(_enabledKey, false);
      AppLogger.info('Screenshot prevention disabled');
      return true;
    } on PlatformException catch (e) {
      AppLogger.error('Failed to disable screenshot prevention', error: e);
      return false;
    } on MissingPluginException {
      // Platform channel not available, log and continue
      _isEnabled = false;
      await _keyManager.setBool(_enabledKey, false);
      return true;
    }
  }

  /// Toggle screenshot prevention
  Future<bool> toggle() async {
    if (_isEnabled) {
      return disableScreenshotPrevention();
    } else {
      return enableScreenshotPrevention();
    }
  }

  /// Temporarily disable screenshot prevention (e.g., for sharing)
  ///
  /// Call [restoreScreenshotPrevention] to re-enable if it was previously
  /// enabled.
  Future<void> temporarilyDisable() async {
    if (_isEnabled && _isApplied) {
      try {
        if (Platform.isAndroid) {
          await _methodChannel.invokeMethod('disableSecureFlag');
        } else if (Platform.isIOS) {
          await _methodChannel.invokeMethod('disableSecureField');
        }
        _isApplied = false;
        AppLogger.debug('Screenshot prevention temporarily disabled');
      } catch (e) {
        AppLogger.warning(
          'Failed to temporarily disable screenshot prevention',
        );
      }
    }
  }

  /// Restore screenshot prevention if it was enabled
  Future<void> restoreScreenshotPrevention() async {
    if (_isEnabled && !_isApplied) {
      await enableScreenshotPrevention();
    }
  }
}

/// Provider for ScreenshotPreventionService
@riverpod
ScreenshotPreventionService screenshotPreventionService(Ref ref) {
  final keyManager = ref.watch(keyManagerProvider);
  final service = ScreenshotPreventionService(keyManager);

  // Initialize asynchronously
  Future.microtask(service.initialize);

  return service;
}

/// Provider for screenshot prevention enabled state
@riverpod
class ScreenshotPreventionEnabled extends _$ScreenshotPreventionEnabled {
  @override
  bool build() {
    final service = ref.watch(screenshotPreventionServiceProvider);
    return service.isEnabled;
  }

  Future<void> toggle() async {
    final service = ref.read(screenshotPreventionServiceProvider);
    await service.toggle();
    state = service.isEnabled;
  }

  Future<void> enable() async {
    final service = ref.read(screenshotPreventionServiceProvider);
    await service.enableScreenshotPrevention();
    state = true;
  }

  Future<void> disable() async {
    final service = ref.read(screenshotPreventionServiceProvider);
    await service.disableScreenshotPrevention();
    state = false;
  }
}
