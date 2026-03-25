import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared lock to prevent concurrent token refresh operations
/// between TokenRefreshService and SyncEngine
class TokenRefreshLock {
  Completer<void>? _refreshCompleter;
  bool _isRefreshing = false;

  /// Check if a refresh is currently in progress
  bool get isRefreshing => _isRefreshing;

  /// Acquire the lock and execute the refresh operation
  /// If another refresh is in progress, waits for it to complete and returns null
  /// Otherwise, executes the callback and returns its result
  Future<T?> acquireAndRefresh<T>(Future<T> Function() refreshCallback) async {
    // If already refreshing, wait for completion and return null
    if (_isRefreshing && _refreshCompleter != null) {
      await _refreshCompleter!.future;
      return null; // Another refresh was in progress, don't repeat
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<void>();

    try {
      final result = await refreshCallback();
      return result;
    } finally {
      _isRefreshing = false;
      _refreshCompleter?.complete();
      _refreshCompleter = null;
    }
  }
}

/// Global provider for token refresh lock
final tokenRefreshLockProvider = Provider<TokenRefreshLock>((ref) {
  return TokenRefreshLock();
});
