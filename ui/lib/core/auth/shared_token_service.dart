import 'dart:async';

import 'package:antinvestor_api_common/antinvestor_api_common.dart'
    show JwtUtils, TokenManager, TokenRefreshResult;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/auth_service.dart';
import '../logging/app_logger.dart';
import '../networking/api_config.dart';

/// Result of a background token refresh operation.
class BackgroundRefreshResult {
  const BackgroundRefreshResult({
    required this.success,
    required this.result,
    this.accessToken,
    this.error,
  });

  /// Whether the refresh succeeded.
  final bool success;

  /// The underlying refresh result type.
  final TokenRefreshResult result;

  /// The new access token (if successful).
  final String? accessToken;

  /// Error message (if failed).
  final String? error;

  @override
  String toString() =>
      'BackgroundRefreshResult(success: $success, result: $result, '
      'hasToken: ${accessToken != null}, error: $error)';
}

/// Singleton token service accessible from both foreground and background.
///
/// This provides a unified interface for token access across the entire
/// application, solving the problem where foreground (Riverpod-based) and
/// background (WorkManager) contexts have different token access patterns.
///
/// ## The Problem This Solves
///
/// Previously:
/// - Foreground used TokenManager with automatic refresh via interceptors
/// - Background read directly from FlutterSecureStorage without validation
/// - Background could use expired tokens → "unauthenticated" errors
///
/// Now:
/// - Both contexts use SharedTokenService
/// - Token expiry is validated before use
/// - Background CAN refresh tokens using standalone AuthService
/// - Foreground uses TokenManager for coordinated refresh
///
/// ## Usage
///
/// ### Foreground (App Startup)
/// ```dart
/// // In tokenManagerProvider or startup:
/// SharedTokenService.instance.setTokenManager(tokenManager);
/// ```
///
/// ### Background (WorkManager Task)
/// ```dart
/// final token = await SharedTokenService.instance.getAccessToken(
///   tryRefresh: true, // Will refresh in background if expired!
/// );
/// if (token == null) {
///   return true; // Skip sync, refresh failed permanently
/// }
/// ```
///
/// ### Foreground API Calls
/// ```dart
/// final token = await SharedTokenService.instance.getAccessToken();
/// ```
class SharedTokenService {
  SharedTokenService._();

  /// Singleton instance accessible from anywhere
  static final instance = SharedTokenService._();

  final _storage = const FlutterSecureStorage();

  /// TokenManager reference - only available in foreground context
  TokenManager? _tokenManager;

  /// Standalone AuthService for background refresh
  AuthService? _backgroundAuthService;

  /// Mutex to prevent concurrent background refreshes
  Completer<BackgroundRefreshResult>? _backgroundRefreshCompleter;

  /// Buffer duration before expiry to consider token expired.
  /// Prevents using tokens that will expire during the request.
  static const _expiryBuffer = Duration(minutes: 2);

  /// Whether we're running in foreground context (have TokenManager)
  bool get isInForeground => _tokenManager != null;

  /// Initialize with TokenManager (call from foreground app startup).
  ///
  /// This should be called when the TokenManager is created in the
  /// Riverpod provider. It enables foreground-specific features like
  /// coordinated token refresh through TokenRefreshCoordinator.
  void setTokenManager(TokenManager tokenManager) {
    _tokenManager = tokenManager;
    AppLogger.debug('SharedTokenService: TokenManager set');
  }

  /// Clear TokenManager reference (call on logout or dispose).
  ///
  /// After this, the service falls back to background mode
  /// (standalone AuthService for refresh).
  void clearTokenManager() {
    _tokenManager = null;
    AppLogger.debug('SharedTokenService: TokenManager cleared');
  }

  /// Get or create AuthService for background refresh.
  AuthService _getBackgroundAuthService() {
    _backgroundAuthService ??= AuthService(
      _storage,
      issuerUrl: ApiConfig.oauth2IssuerUrl,
      clientId: ApiConfig.oauth2ClientId,
    );
    return _backgroundAuthService!;
  }

  /// Get access token for API calls.
  ///
  /// This is the primary method for obtaining tokens. It handles both
  /// foreground and background contexts appropriately.
  ///
  /// ## Parameters
  ///
  /// - [ensureValid]: If true (default), validates token expiry before
  ///   returning. Returns null if the token is expired and refresh fails.
  ///
  /// - [tryRefresh]: If true (default), attempts to refresh an expired token.
  ///   In foreground: uses TokenManager/TokenRefreshCoordinator.
  ///   In background: uses standalone AuthService.
  ///
  /// ## Returns
  ///
  /// The access token if available and valid, or null if:
  /// - No token is stored
  /// - Token is expired and refresh failed or was not attempted
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // Background with refresh (recommended)
  /// final token = await SharedTokenService.instance.getAccessToken();
  ///
  /// // Background without refresh (skip if expired)
  /// final token = await SharedTokenService.instance.getAccessToken(
  ///   tryRefresh: false,
  /// );
  ///
  /// // Foreground: uses TokenManager with coordinated refresh
  /// final token = await SharedTokenService.instance.getAccessToken();
  /// ```
  Future<String?> getAccessToken({
    bool ensureValid = true,
    bool tryRefresh = true,
  }) async {
    // Foreground path: use TokenManager for coordinated refresh
    if (_tokenManager != null && tryRefresh) {
      if (ensureValid) {
        // This will refresh if expired via TokenRefreshCoordinator
        return _tokenManager!.ensureValidToken();
      }
      return _tokenManager!.accessToken;
    }

    // Background path: read from storage
    final token = await _storage.read(key: 'access_token');

    if (token == null) {
      AppLogger.debug('SharedTokenService: No access token in storage');
      return null;
    }

    // Check if token is valid
    final isExpired = JwtUtils.isTokenExpired(
      token,
      bufferDuration: _expiryBuffer,
    );

    if (!isExpired) {
      // Token is valid, return it
      return token;
    }

    // Token is expired
    if (!ensureValid) {
      // Caller doesn't care about validity
      return token;
    }

    if (!tryRefresh) {
      // Caller doesn't want refresh
      AppLogger.debug(
        'SharedTokenService: Token expired, refresh not requested',
        data: {'expiry': JwtUtils.getTokenExpiry(token)?.toIso8601String()},
      );
      return null;
    }

    // Attempt background refresh
    AppLogger.info(
      'SharedTokenService: Token expired, attempting background refresh',
    );
    final refreshResult = await refreshTokenInBackground();

    if (refreshResult.success) {
      return refreshResult.accessToken;
    }

    // Refresh failed
    AppLogger.warning(
      'SharedTokenService: Background refresh failed',
      data: {
        'result': refreshResult.result.toString(),
        'error': refreshResult.error,
      },
    );

    // For permanent errors, return null (caller should handle gracefully)
    // For transient errors, also return null (will retry on next sync)
    return null;
  }

  /// Refresh the token in background context using standalone AuthService.
  ///
  /// This method can be called from WorkManager tasks or other contexts
  /// where Riverpod providers are not available.
  ///
  /// Uses mutex to prevent concurrent refresh attempts - if a refresh is
  /// already in progress, waits for it and returns that result.
  ///
  /// ## Returns
  ///
  /// A [BackgroundRefreshResult] indicating success or failure.
  Future<BackgroundRefreshResult> refreshTokenInBackground() async {
    // Prevent concurrent refresh attempts
    if (_backgroundRefreshCompleter != null &&
        !_backgroundRefreshCompleter!.isCompleted) {
      AppLogger.debug(
        'SharedTokenService: Waiting for in-progress background refresh',
      );
      return _backgroundRefreshCompleter!.future;
    }

    _backgroundRefreshCompleter = Completer<BackgroundRefreshResult>();

    try {
      final result = await _doBackgroundRefresh();
      _backgroundRefreshCompleter!.complete(result);
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(
        'SharedTokenService: Unexpected error during background refresh',
        error: e,
        stackTrace: stackTrace,
      );
      final errorResult = BackgroundRefreshResult(
        success: false,
        result: TokenRefreshResult.transientError,
        error: e.toString(),
      );
      _backgroundRefreshCompleter!.complete(errorResult);
      return errorResult;
    }
  }

  /// Perform the actual background token refresh.
  Future<BackgroundRefreshResult> _doBackgroundRefresh() async {
    final authService = _getBackgroundAuthService();

    try {
      final refreshResult = await authService.refreshTokenWithResult();

      if (refreshResult.result == TokenRefreshResult.success) {
        // Get the new token from storage (AuthService already saved it)
        final newToken = await _storage.read(key: 'access_token');

        if (newToken == null || newToken.isEmpty) {
          return const BackgroundRefreshResult(
            success: false,
            result: TokenRefreshResult.transientError,
            error: 'Token not found in storage after refresh',
          );
        }

        AppLogger.info(
          'SharedTokenService: Background refresh successful',
          data: {
            'tokenLength': newToken.length,
            'expiry': JwtUtils.getTokenExpiry(newToken)?.toIso8601String(),
          },
        );

        // If we're in foreground (TokenManager available), update its cache too
        if (_tokenManager != null) {
          await _tokenManager!.setAccessToken(newToken);
          AppLogger.debug(
            'SharedTokenService: Updated TokenManager cache after background refresh',
          );
        }

        return BackgroundRefreshResult(
          success: true,
          result: TokenRefreshResult.success,
          accessToken: newToken,
        );
      }

      // Refresh failed
      return BackgroundRefreshResult(
        success: false,
        result: refreshResult.result,
        error: refreshResult.error,
      );
    } on TimeoutException {
      return const BackgroundRefreshResult(
        success: false,
        result: TokenRefreshResult.transientError,
        error: 'Refresh timed out',
      );
    } catch (e) {
      // Classify the error
      final errorStr = e.toString().toLowerCase();
      final isPermanent = _isPermanentError(errorStr);

      return BackgroundRefreshResult(
        success: false,
        result: isPermanent
            ? TokenRefreshResult.permanentError
            : TokenRefreshResult.transientError,
        error: e.toString(),
      );
    }
  }

  /// Check if an error indicates permanent failure (requires re-login).
  bool _isPermanentError(String errorStr) {
    return errorStr.contains('invalid_grant') ||
        errorStr.contains('invalid_client') ||
        errorStr.contains('unauthorized_client') ||
        errorStr.contains('access_denied') ||
        errorStr.contains('invalid refresh token') ||
        errorStr.contains('refresh token expired') ||
        errorStr.contains('refresh token is invalid') ||
        errorStr.contains('refresh token has been revoked') ||
        errorStr.contains('token has been revoked');
  }

  /// Check if a valid (non-expired) token is available.
  ///
  /// This does not attempt to refresh the token. Use this for quick
  /// checks before starting work that requires authentication.
  ///
  /// ## Returns
  ///
  /// True if a valid token exists in storage, false otherwise.
  Future<bool> hasValidToken() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      return false;
    }
    return !JwtUtils.isTokenExpired(token, bufferDuration: _expiryBuffer);
  }

  /// Get the ID token from storage.
  ///
  /// The ID token contains user identity claims and is useful for
  /// extracting the profile ID in background context.
  Future<String?> getIdToken() {
    return _storage.read(key: 'id_token');
  }

  /// Get the refresh token from storage.
  ///
  /// Note: In most cases, you should not need to access the refresh
  /// token directly. Use [getAccessToken] with [tryRefresh: true]
  /// for automatic refresh handling.
  Future<String?> getRefreshToken() {
    return _storage.read(key: 'refresh_token');
  }

  /// Get the profile ID from the stored ID token.
  ///
  /// This extracts the 'sub' (subject) claim from the ID token,
  /// which contains the user's profile ID.
  ///
  /// ## Returns
  ///
  /// The profile ID if available, null otherwise.
  Future<String?> getProfileId() async {
    final idToken = await getIdToken();
    if (idToken == null) {
      return null;
    }
    return JwtUtils.getSubject(idToken);
  }

  /// Get token expiry information for debugging/logging.
  ///
  /// Returns a map with expiry details, useful for diagnostics.
  Future<Map<String, dynamic>> getTokenInfo() async {
    final accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null) {
      return {'hasToken': false};
    }

    final expiry = JwtUtils.getTokenExpiry(accessToken);
    final timeUntilExpiry = JwtUtils.getTimeUntilExpiry(accessToken);
    final isExpired = JwtUtils.isTokenExpired(
      accessToken,
      bufferDuration: _expiryBuffer,
    );

    return {
      'hasToken': true,
      'expiry': expiry?.toIso8601String(),
      'timeUntilExpiry': timeUntilExpiry?.inSeconds,
      'isExpired': isExpired,
      'isInForeground': _tokenManager != null,
    };
  }
}
