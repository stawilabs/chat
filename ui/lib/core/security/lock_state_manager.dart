import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../logging/app_logger.dart';
import 'biometric_service.dart';

part 'lock_state_manager.g.dart';

/// Represents the current lock state of the app
enum LockState {
  /// App is unlocked and accessible
  unlocked,

  /// App is locked and requires authentication
  locked,

  /// App is in the process of locking (grace period)
  locking,
}

/// Manages the lock state of the application based on user activity
/// and app lifecycle events.
class LockStateManager extends ChangeNotifier with WidgetsBindingObserver {
  LockStateManager(this._biometricService) {
    WidgetsBinding.instance.addObserver(this);
  }

  final BiometricService _biometricService;

  /// Current lock state
  LockState _lockState = LockState.unlocked;
  LockState get lockState => _lockState;

  /// Whether the app is currently locked
  bool get isLocked => _lockState == LockState.locked;

  /// Timer for lock timeout
  Timer? _lockTimer;

  /// Timestamp when the app was last active
  DateTime? _lastActiveTime;

  /// Whether we're in a quick reply context (bypasses lock)
  bool _isQuickReplyActive = false;

  /// Initialize the lock state manager
  void initialize() {
    _checkInitialLockState();
    AppLogger.debug('LockStateManager initialized');
  }

  /// Check if the app should be locked on startup
  void _checkInitialLockState() {
    if (!_biometricService.isBiometricEnabled()) {
      _lockState = LockState.unlocked;
      return;
    }

    // If biometric is enabled, start locked
    _lockState = LockState.locked;
    notifyListeners();
    AppLogger.info('App started in locked state');
  }

  /// Called when the app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _onAppBackgrounded();
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is being destroyed or hidden, no action needed
        break;
    }
  }

  /// Called when the app comes to the foreground
  void _onAppResumed() {
    // Cancel any pending lock timer
    _lockTimer?.cancel();
    _lockTimer = null;

    // Skip lock check if in quick reply mode
    if (_isQuickReplyActive) {
      AppLogger.debug('Quick reply active, skipping lock check');
      return;
    }

    // Check if biometric lock is enabled
    if (!_biometricService.isBiometricEnabled()) {
      if (_lockState != LockState.unlocked) {
        _lockState = LockState.unlocked;
        notifyListeners();
      }
      return;
    }

    // Check if we should lock based on timeout
    if (_lastActiveTime != null) {
      final timeoutMinutes = _biometricService.getLockTimeoutMinutes();
      final elapsed = DateTime.now().difference(_lastActiveTime!);

      if (elapsed.inMinutes >= timeoutMinutes) {
        _lock();
      }
    }

    AppLogger.debug('App resumed', data: {'lockState': _lockState.name});
  }

  /// Called when the app goes to the background
  void _onAppBackgrounded() {
    // Skip if biometric lock is disabled
    if (!_biometricService.isBiometricEnabled()) {
      return;
    }

    // Record the time when the app was backgrounded
    _lastActiveTime = DateTime.now();

    final timeoutMinutes = _biometricService.getLockTimeoutMinutes();

    // If timeout is 0, lock immediately
    if (timeoutMinutes == 0) {
      _lock();
      return;
    }

    // Start a timer to lock the app after the timeout
    _lockTimer?.cancel();
    _lockTimer = Timer(Duration(minutes: timeoutMinutes), _lock);

    // Set state to "locking" to indicate grace period
    if (_lockState == LockState.unlocked) {
      _lockState = LockState.locking;
      notifyListeners();
    }

    AppLogger.debug(
      'App backgrounded, will lock in $timeoutMinutes minutes',
      data: {'timeoutMinutes': timeoutMinutes},
    );
  }

  /// Lock the app
  void _lock() {
    if (_lockState == LockState.locked) return;

    _lockState = LockState.locked;
    _lockTimer?.cancel();
    _lockTimer = null;
    notifyListeners();

    AppLogger.info('App locked');
  }

  /// Unlock the app after successful authentication
  void unlock() {
    if (_lockState == LockState.unlocked) return;

    _lockState = LockState.unlocked;
    _lastActiveTime = DateTime.now();
    notifyListeners();

    AppLogger.info('App unlocked');
  }

  /// Force lock the app immediately
  void forceLock() {
    _lock();
    AppLogger.info('App force locked');
  }

  /// Set quick reply mode (bypasses lock)
  void setQuickReplyMode(bool active) {
    _isQuickReplyActive = active;
    AppLogger.debug('Quick reply mode: $active');
  }

  /// Record user activity (resets the lock timer)
  void recordActivity() {
    _lastActiveTime = DateTime.now();
  }

  /// Check if biometric lock is enabled and should be shown
  bool shouldShowLockScreen() {
    return _biometricService.isBiometricEnabled() &&
        _lockState == LockState.locked;
  }

  /// Dispose resources
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockTimer?.cancel();
    super.dispose();
  }
}

/// Provider for LockStateManager
@riverpod
LockStateManager lockStateManager(Ref ref) {
  final biometricService = ref.watch(biometricServiceProvider);

  final manager = LockStateManager(biometricService);
  manager.initialize();

  ref.onDispose(manager.dispose);

  return manager;
}

/// Provider that exposes whether the app is currently locked
@riverpod
bool isAppLocked(Ref ref) {
  final manager = ref.watch(lockStateManagerProvider);
  // Listen to changes in the manager
  manager.addListener(() {
    ref.invalidateSelf();
  });
  return manager.isLocked;
}

/// Provider that exposes whether the lock screen should be shown
@riverpod
bool shouldShowLockScreen(Ref ref) {
  final manager = ref.watch(lockStateManagerProvider);
  // Listen to changes in the manager
  manager.addListener(() {
    ref.invalidateSelf();
  });
  return manager.shouldShowLockScreen();
}
