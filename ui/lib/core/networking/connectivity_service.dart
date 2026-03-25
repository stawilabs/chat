import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../sync/sync_engine.dart';

/// Monitors network connectivity and triggers sync when coming back online
///
/// Features:
/// - Debounces rapid connectivity changes to prevent excessive sync restarts
/// - Tracks offline/online transitions
/// - Triggers SyncEngine restart when coming back online
class ConnectivityService {
  ConnectivityService(this._connectivity, this._syncEngine);
  final Connectivity _connectivity;
  final SyncEngine _syncEngine;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _wasOffline = false;
  bool _isInitialized = false;

  // Debouncing configuration
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 1500);
  bool _pendingSync = false;

  /// Start monitoring connectivity changes
  void start() {
    if (_isInitialized) return;
    _isInitialized = true;

    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );

    // Check initial connectivity
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _wasOffline = !_hasConnection(results);
      AppLogger.info(
        'Initial connectivity check',
        data: {
          'hasConnection': !_wasOffline,
          'results': results.map((r) => r.name).toList(),
        },
      );
    } catch (e) {
      AppLogger.error('Failed to check initial connectivity', error: e);
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final hasConnection = _hasConnection(results);

    AppLogger.info(
      'Connectivity changed',
      data: {
        'hasConnection': hasConnection,
        'wasOffline': _wasOffline,
        'results': results.map((r) => r.name).toList(),
      },
    );

    if (hasConnection && _wasOffline) {
      // Just came back online - schedule debounced sync
      _scheduleDebouncedSync();
    } else if (!hasConnection) {
      // Going offline - cancel any pending sync
      _cancelPendingSync();
    }

    _wasOffline = !hasConnection;
  }

  /// Schedule a debounced sync to prevent rapid reconnection cycles
  void _scheduleDebouncedSync() {
    _pendingSync = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (_pendingSync) {
        AppLogger.info('Debounced sync triggered after stable connection');
        _triggerSync();
        _pendingSync = false;
      }
    });
  }

  /// Cancel any pending sync (called when going offline)
  void _cancelPendingSync() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    if (_pendingSync) {
      AppLogger.info('Cancelled pending sync due to connection loss');
      _pendingSync = false;
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) => results.any(
    (result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet,
  );

  void _triggerSync() {
    // Restart the sync engine to process pending jobs
    // Use async stop to ensure clean shutdown before restart
    _syncEngine.stopAsync().then((_) {
      _syncEngine.start();
    });
  }

  /// Check if currently connected to the internet
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _hasConnection(results);
    } catch (e) {
      AppLogger.error('Failed to check connectivity', error: e);
      return false;
    }
  }

  void stop() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
  }
}

/// Provider for connectivity service
final connectivityServiceProvider = FutureProvider<ConnectivityService>((
  ref,
) async {
  final syncEngine = await ref.watch(syncEngineProvider.future);
  final service = ConnectivityService(Connectivity(), syncEngine);

  ref.onDispose(service.stop);

  return service;
});

/// Provider for current connectivity status
final isConnectedProvider = FutureProvider<bool>((ref) async {
  final service = await ref.watch(connectivityServiceProvider.future);
  return service.isConnected();
});

/// Stream provider for connectivity changes
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();

  return connectivity.onConnectivityChanged.map(
    (results) => results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    ),
  );
});
