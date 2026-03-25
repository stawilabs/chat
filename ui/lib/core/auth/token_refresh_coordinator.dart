import 'dart:async';

import 'package:antinvestor_api_common/antinvestor_api_common.dart'
    show JwtUtils, TokenManager, TokenRefreshResult;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../logging/app_logger.dart';
import 'token_refresh_lock.dart';

/// Result of a token refresh operation
class TokenRefreshCoordinatorResult {
  const TokenRefreshCoordinatorResult({
    required this.success,
    required this.result,
    this.accessToken,
    this.error,
    this.wasHandledByAnotherCaller = false,
  });

  /// Create a successful result
  factory TokenRefreshCoordinatorResult.success(String accessToken) {
    return TokenRefreshCoordinatorResult(
      success: true,
      result: TokenRefreshResult.success,
      accessToken: accessToken,
    );
  }

  /// Create a result for when another caller handled the refresh
  factory TokenRefreshCoordinatorResult.handledByAnotherCaller(
    String accessToken,
  ) {
    return TokenRefreshCoordinatorResult(
      success: true,
      result: TokenRefreshResult.success,
      accessToken: accessToken,
      wasHandledByAnotherCaller: true,
    );
  }

  /// Create a transient error result
  factory TokenRefreshCoordinatorResult.transientError(String error) {
    return TokenRefreshCoordinatorResult(
      success: false,
      result: TokenRefreshResult.transientError,
      error: error,
    );
  }

  /// Create a permanent error result
  factory TokenRefreshCoordinatorResult.permanentError(String error) {
    return TokenRefreshCoordinatorResult(
      success: false,
      result: TokenRefreshResult.permanentError,
      error: error,
    );
  }

  /// Whether the refresh succeeded (new token available)
  final bool success;

  /// The underlying refresh result type
  final TokenRefreshResult result;

  /// The new access token (if successful)
  final String? accessToken;

  /// Error message (if failed)
  final String? error;

  /// True if another concurrent refresh handled the operation
  final bool wasHandledByAnotherCaller;

  @override
  String toString() =>
      'TokenRefreshCoordinatorResult(success: $success, result: $result, '
      'hasToken: ${accessToken != null}, error: $error, '
      'wasHandledByAnotherCaller: $wasHandledByAnotherCaller)';
}

/// Event types for token refresh tracing
enum TokenRefreshEventType {
  /// Refresh operation started
  started,

  /// Waiting for another refresh to complete
  waitingForConcurrent,

  /// Refresh succeeded
  succeeded,

  /// Refresh failed with transient error (will retry)
  transientError,

  /// Refresh failed with permanent error (requires re-login)
  permanentError,

  /// TokenManager cache was updated
  cacheUpdated,
}

/// Event emitted during token refresh for tracing and debugging
class TokenRefreshEvent {
  const TokenRefreshEvent({
    required this.type,
    required this.timestamp,
    required this.source,
    this.error,
    this.details,
  });

  final TokenRefreshEventType type;
  final DateTime timestamp;

  /// Which component triggered the refresh (for tracing)
  final String source;

  /// Error message if applicable
  final String? error;

  /// Additional details for debugging
  final Map<String, dynamic>? details;

  @override
  String toString() =>
      'TokenRefreshEvent($type, source: $source, error: $error)';
}

/// Single source of truth for all token refresh operations.
///
/// This coordinator consolidates all token refresh logic into one place,
/// ensuring consistent behavior across the entire application:
/// - TokenManager's onRefreshToken callback (API 401 responses)
/// - SyncEngine's onTokenRefresh callback (streaming connection auth errors)
/// - TokenRefreshService's background proactive refresh
///
/// Benefits:
/// - Single implementation: All refresh logic in one testable class
/// - Atomic updates: Lock + OAuth + Storage + Cache updated together
/// - Traceable: Events stream for debugging and monitoring
/// - Robust: Consistent error handling everywhere
///
/// Usage:
/// ```dart
/// final result = await coordinator.refresh(source: 'SyncEngine');
/// if (result.success) {
///   // Token refreshed, cache already updated
/// } else if (result.result == TokenRefreshResult.permanentError) {
///   // User needs to re-login
/// }
/// ```
class TokenRefreshCoordinator {
  TokenRefreshCoordinator({
    required AuthRepository authRepo,
    required TokenRefreshLock refreshLock,
  }) : _authRepo = authRepo,
       _refreshLock = refreshLock;

  final AuthRepository _authRepo;
  final TokenRefreshLock _refreshLock;

  /// TokenManager reference - set after construction to avoid circular dependency
  TokenManager? _tokenManager;

  /// Set the TokenManager reference
  /// Must be called before any refresh operations
  void setTokenManager(TokenManager tokenManager) {
    _tokenManager = tokenManager;
  }

  /// Stream controller for refresh events
  final _eventController = StreamController<TokenRefreshEvent>.broadcast();

  /// Stream of refresh events for monitoring and debugging
  Stream<TokenRefreshEvent> get events => _eventController.stream;

  /// Perform a token refresh operation.
  ///
  /// This method:
  /// 1. Acquires the refresh lock to prevent concurrent refreshes
  /// 2. Calls AuthService to perform the OAuth token refresh
  /// 3. Updates secure storage (done by AuthService)
  /// 4. Updates TokenManager's in-memory cache
  /// 5. Returns the result
  ///
  /// If another refresh is in progress, waits for it and returns that result.
  ///
  /// [source] identifies what triggered the refresh (for tracing)
  Future<TokenRefreshCoordinatorResult> refresh({
    required String source,
  }) async {
    _emitEvent(TokenRefreshEventType.started, source);
    AppLogger.debug(
      'TokenRefreshCoordinator: Refresh requested',
      data: {'source': source},
    );

    try {
      final result = await _refreshLock.acquireAndRefresh(() async {
        AppLogger.debug(
          'TokenRefreshCoordinator: Lock acquired, performing refresh',
          data: {'source': source},
        );

        final refreshResult = await _authRepo.refreshTokenWithResult();

        if (refreshResult.result != TokenRefreshResult.success) {
          // Refresh failed - determine if transient or permanent
          if (refreshResult.result == TokenRefreshResult.permanentError) {
            _emitEvent(
              TokenRefreshEventType.permanentError,
              source,
              error: refreshResult.error,
            );
            return TokenRefreshCoordinatorResult.permanentError(
              refreshResult.error ?? 'Token refresh failed permanently',
            );
          } else {
            _emitEvent(
              TokenRefreshEventType.transientError,
              source,
              error: refreshResult.error,
            );
            return TokenRefreshCoordinatorResult.transientError(
              refreshResult.error ?? 'Token refresh failed (transient)',
            );
          }
        }

        // Get the new token from storage
        final newToken = await _authRepo.getAccessToken();
        if (newToken == null) {
          _emitEvent(
            TokenRefreshEventType.transientError,
            source,
            error: 'No token after refresh',
          );
          return TokenRefreshCoordinatorResult.transientError(
            'Failed to get new access token after refresh',
          );
        }

        // Update TokenManager's in-memory cache
        await _updateTokenManagerCache(newToken, source);

        // Log JWT claims for debugging "invalid authentication claims" errors
        try {
          final claims = JwtUtils.getClaims(newToken);
          final expiry = JwtUtils.getTokenExpiry(newToken);
          AppLogger.debug(
            'TokenRefreshCoordinator: New token claims',
            data: {
              'sub': claims['sub'],
              'iss': claims['iss'],
              'aud': claims['aud'],
              'scope': claims['scope'] ?? claims['scp'],
              'exp': expiry?.toIso8601String(),
              'azp': claims['azp'],
              'client_id': claims['client_id'],
            },
          );
        } catch (e) {
          AppLogger.warning(
            'TokenRefreshCoordinator: Failed to decode JWT claims',
            data: {'error': e.toString()},
          );
        }

        _emitEvent(
          TokenRefreshEventType.succeeded,
          source,
          details: {'tokenLength': newToken.length},
        );

        AppLogger.info(
          'TokenRefreshCoordinator: Refresh successful',
          data: {'source': source},
        );

        return TokenRefreshCoordinatorResult.success(newToken);
      });

      // If result is null, another refresh was in progress
      if (result == null) {
        _emitEvent(TokenRefreshEventType.waitingForConcurrent, source);
        AppLogger.debug(
          'TokenRefreshCoordinator: Refresh handled by another caller',
          data: {'source': source},
        );

        // Get the token from storage (should have been updated by the other caller)
        final newToken = await _authRepo.getAccessToken();
        if (newToken == null) {
          return TokenRefreshCoordinatorResult.transientError(
            'No access token available after concurrent refresh',
          );
        }

        // Still update our TokenManager cache to be safe
        await _updateTokenManagerCache(newToken, source);

        return TokenRefreshCoordinatorResult.handledByAnotherCaller(newToken);
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.error(
        'TokenRefreshCoordinator: Unexpected error during refresh',
        error: e,
        stackTrace: stackTrace,
        data: {'source': source},
      );

      _emitEvent(
        TokenRefreshEventType.transientError,
        source,
        error: e.toString(),
      );

      return TokenRefreshCoordinatorResult.transientError(e.toString());
    }
  }

  /// Update the TokenManager's in-memory cache with the new token
  Future<void> _updateTokenManagerCache(String token, String source) async {
    final manager = _tokenManager;
    if (manager != null) {
      await manager.setAccessToken(token);
      _emitEvent(
        TokenRefreshEventType.cacheUpdated,
        source,
        details: {'tokenLength': token.length},
      );
      AppLogger.debug(
        'TokenRefreshCoordinator: TokenManager cache updated',
        data: {'source': source},
      );
    } else {
      AppLogger.warning(
        'TokenRefreshCoordinator: TokenManager not set, cache not updated',
        data: {'source': source},
      );
    }
  }

  void _emitEvent(
    TokenRefreshEventType type,
    String source, {
    String? error,
    Map<String, dynamic>? details,
  }) {
    _eventController.add(
      TokenRefreshEvent(
        type: type,
        timestamp: DateTime.now(),
        source: source,
        error: error,
        details: details,
      ),
    );
  }

  /// Dispose of resources
  void dispose() {
    _eventController.close();
  }
}

/// Provider for the TokenRefreshCoordinator
///
/// This is a singleton that coordinates all token refresh operations
final tokenRefreshCoordinatorProvider = Provider<TokenRefreshCoordinator>((
  ref,
) {
  final authRepo = ref.watch(authRepositoryProvider);
  final refreshLock = ref.watch(tokenRefreshLockProvider);

  final coordinator = TokenRefreshCoordinator(
    authRepo: authRepo,
    refreshLock: refreshLock,
  );

  ref.onDispose(coordinator.dispose);

  return coordinator;
});

/// Callback type for token refresh that uses the coordinator
typedef CoordinatedTokenRefreshCallback =
    Future<String?> Function(String source);

/// Provider for a token refresh callback that uses the coordinator
///
/// Use this callback in TokenManager, SyncEngine, etc. instead of
/// implementing refresh logic inline.
final coordinatedTokenRefreshCallbackProvider =
    Provider<CoordinatedTokenRefreshCallback>((ref) {
      final coordinator = ref.watch(tokenRefreshCoordinatorProvider);

      return (String source) async {
        final result = await coordinator.refresh(source: source);
        if (result.success) {
          return result.accessToken;
        }
        if (result.result == TokenRefreshResult.permanentError) {
          throw TokenRefreshPermanentException(
            result.error ?? 'Token refresh failed permanently',
          );
        }
        // Transient error - return null to signal retry later
        return null;
      };
    });

/// Exception thrown when token refresh fails permanently
/// (user must re-authenticate)
class TokenRefreshPermanentException implements Exception {
  TokenRefreshPermanentException(this.message);
  final String message;

  @override
  String toString() => 'TokenRefreshPermanentException: $message';
}
