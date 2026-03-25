import 'dart:async';
import 'dart:convert';

import 'package:antinvestor_api_common/antinvestor_api_common.dart'
    show TokenRefreshResult;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openid_client/openid_client.dart';

import '../../../core/logging/app_logger.dart';
import 'platform/auth_platform.dart';
import 'platform/auth_platform_stub.dart'
    if (dart.library.io) 'platform/auth_platform_io.dart'
    if (dart.library.html) 'platform/auth_platform_web.dart';

/// OAuth2/OIDC authentication service
///
/// Handles user authentication using OpenID Connect with secure
/// token storage. Supports both mobile (deep link) and web (redirect)
/// authentication flows.
///
/// Features:
/// - OAuth2 login with PKCE
/// - Token refresh with mutex to prevent concurrent refreshes
/// - Secure credential storage using flutter_secure_storage
/// - Platform-specific authentication flows (mobile vs web)
///
/// Example:
/// ```dart
/// final authService = AuthService(
///   storage,
///   issuerUrl: 'https://auth.example.com',
///   clientId: 'my-app',
/// );
/// await authService.authenticate();
/// final token = await authService.getAccessToken();
/// ```
class AuthService {
  AuthService(
    this._storage, {
    required String issuerUrl,
    required String clientId,
  }) : _issuerUrl = issuerUrl,
       _clientId = clientId;
  final FlutterSecureStorage _storage;
  final String _issuerUrl;
  final String _clientId;
  final AuthPlatform _platform = getAuthPlatform();

  /// Initialize OIDC issuer and client
  Future<void> _ensureInitialized() async {
    await _platform.initialize(_issuerUrl, _clientId);
  }

  /// Authenticate user with OIDC provider
  ///
  /// Returns [TokenResponse] on success, null if redirect-based flow (web).
  /// Throws on error.
  Future<TokenResponse?> authenticate() async {
    try {
      AppLogger.info(
        'Starting OIDC authentication',
        data: {'issuerUrl': _issuerUrl},
      );
      await _ensureInitialized();

      final token = await _platform.authenticate([
        'openid',
        'profile',
        'contact',
        'offline_access',
      ]);

      if (token != null) {
        // Validate that we actually got an access token
        if (token.accessToken == null || token.accessToken!.isEmpty) {
          AppLogger.error(
            'Token response missing access token',
            data: {'hasRefreshToken': token.refreshToken != null},
          );
          throw Exception('Authentication failed: No access token received');
        }

        await _saveTokens(token);

        // Verify the token was actually saved
        final savedToken = await getAccessToken();
        if (savedToken == null) {
          AppLogger.error('Failed to save token to secure storage');
          throw Exception('Authentication failed: Could not save credentials');
        }

        AppLogger.info('User authenticated successfully');
        return token;
      } else {
        // On Web, this might be null due to redirect
        AppLogger.info(
          'Authentication initiated (expecting redirect or popup)',
        );
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Authentication failed',
        error: e,
        stackTrace: stackTrace,
        data: {'issuerUrl': _issuerUrl},
      );
      rethrow;
    }
  }

  /// Cancel any ongoing authentication flow
  ///
  /// Call this if the user wants to abort authentication or if the app
  /// needs to clean up before starting a new auth flow.
  Future<void> cancelAuthentication() async {
    try {
      await _platform.cancelAuthentication();
      AppLogger.debug('Authentication cancelled');
    } catch (e) {
      AppLogger.debug('Error cancelling authentication: $e');
    }
  }

  // Default token lifetime when server doesn't provide expiry (1 hour)
  static const _defaultTokenLifetime = Duration(hours: 1);

  /// Save tokens to secure storage
  Future<void> _saveTokens(TokenResponse token) async {
    await _storage.write(key: 'access_token', value: token.accessToken);
    await _storage.write(key: 'refresh_token', value: token.refreshToken);
    try {
      // idToken may throw on access if not present
      await _storage.write(
        key: 'id_token',
        value: token.idToken.toCompactSerialization(),
      );
    } catch (_) {
      // ID token might be missing or throw on access
      AppLogger.debug('No ID token in response');
    }

    // Store token expiry timestamp - use default if server doesn't provide one
    final expiresAt =
        token.expiresAt ?? DateTime.now().add(_defaultTokenLifetime);
    await _storage.write(
      key: 'token_expires_at',
      value: expiresAt.millisecondsSinceEpoch.toString(),
    );

    AppLogger.debug(
      'Tokens saved to secure storage',
      data: {
        'expiresAt': expiresAt.toIso8601String(),
        'usingDefault': token.expiresAt == null,
      },
    );
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    return _storage.read(key: 'access_token');
  }

  /// Get current refresh token
  Future<String?> getRefreshToken() async =>
      _storage.read(key: 'refresh_token');

  /// Get ID token
  Future<String?> getIdToken() async => _storage.read(key: 'id_token');

  /// Check if access token is expired or about to expire
  /// Returns true if token expires within the specified buffer time
  Future<bool> isTokenExpired({
    Duration buffer = const Duration(minutes: 2),
  }) async {
    final expiresAtStr = await _storage.read(key: 'token_expires_at');
    if (expiresAtStr == null) {
      // If we don't have expiry info, assume expired to trigger refresh
      return true;
    }

    try {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        int.parse(expiresAtStr),
      );
      final now = DateTime.now();
      return now.isAfter(expiresAt.subtract(buffer));
    } catch (e) {
      // If we can't parse the expiry, assume expired
      AppLogger.warning(
        'Failed to parse token expiry',
        data: {'error': e.toString()},
      );
      return true;
    }
  }

  /// Get the token expiry time
  Future<DateTime?> getTokenExpiryTime() async {
    final expiresAtStr = await _storage.read(key: 'token_expires_at');
    if (expiresAtStr == null) return null;
    try {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(expiresAtStr));
    } catch (e) {
      return null;
    }
  }

  /// Calculate optimal refresh time (refresh when 75% of token lifetime has passed)
  Future<Duration?> getTimeUntilRefreshNeeded() async {
    final expiresAtStr = await _storage.read(key: 'token_expires_at');
    if (expiresAtStr == null) return null;

    try {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        int.parse(expiresAtStr),
      );
      final now = DateTime.now();

      // Refresh 5 minutes before expiry
      const refreshBuffer = Duration(minutes: 5);
      final refreshAt = expiresAt.subtract(refreshBuffer);

      if (now.isAfter(refreshAt)) {
        // Already past refresh time
        return Duration.zero;
      }

      return refreshAt.difference(now);
    } catch (e) {
      return Duration.zero; // Refresh immediately on error
    }
  }

  // Mutex to prevent concurrent refresh attempts
  // Stores the full result so waiters can get the token too
  Completer<({TokenRefreshResult result, TokenResponse? token, String? error})>?
  _refreshCompleter;

  /// Refresh the access token using refresh token
  /// Returns a [TokenRefreshResult] indicating success or type of failure
  /// Does NOT automatically logout - caller decides based on result
  ///
  /// This method is safe to call concurrently - if a refresh is already in progress,
  /// callers will wait for the existing operation to complete and receive the same result.
  Future<({TokenRefreshResult result, TokenResponse? token, String? error})>
  refreshTokenWithResult() async {
    // Prevent concurrent refresh attempts - return existing operation if in progress
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      AppLogger.debug(
        'Token refresh already in progress, waiting for existing operation...',
      );
      // Wait for the in-progress refresh and return its result
      final existingResult = await _refreshCompleter!.future;
      AppLogger.debug(
        'Refresh completed by another caller',
        data: {'result': existingResult.result.toString()},
      );
      return existingResult;
    }

    _refreshCompleter =
        Completer<
          ({TokenRefreshResult result, TokenResponse? token, String? error})
        >();

    try {
      // The finally block below guarantees _refreshCompleter is always
      // completed and nulled, even if a future code change adds an
      // unhandled exception path.
      final refreshTokenValue = await getRefreshToken();
      if (refreshTokenValue == null) {
        AppLogger.warning('No refresh token available for token refresh');
        const noTokenResult = (
          result: TokenRefreshResult.permanentError,
          token: null as TokenResponse?,
          error: 'No refresh token',
        );
        _refreshCompleter!.complete(noTokenResult);
        return noTokenResult;
      }

      // Log refresh attempt with masked refresh token for debugging
      final maskedRefreshToken = refreshTokenValue.length > 10
          ? '${refreshTokenValue.substring(0, 5)}...${refreshTokenValue.substring(refreshTokenValue.length - 5)}'
          : '***';
      AppLogger.debug(
        'Attempting to refresh access token',
        data: {
          'refreshTokenPrefix': maskedRefreshToken,
          'refreshTokenLength': refreshTokenValue.length,
        },
      );

      try {
        await _ensureInitialized();
      } catch (e) {
        // Network error during initialization - transient
        AppLogger.warning(
          'Failed to initialize OIDC client for refresh',
          data: {'error': e.toString()},
        );
        final initFailResult = (
          result: TokenRefreshResult.transientError,
          token: null as TokenResponse?,
          error: 'OIDC initialization failed: $e',
        );
        _refreshCompleter!.complete(initFailResult);
        return initFailResult;
      }

      if (_platform.client == null) {
        const clientNullResult = (
          result: TokenRefreshResult.transientError,
          token: null as TokenResponse?,
          error: 'Auth client not initialized',
        );
        _refreshCompleter!.complete(clientNullResult);
        return clientNullResult;
      }

      final credential = _platform.client!.createCredential(
        accessToken: await getAccessToken(),
        refreshToken: refreshTokenValue,
      );

      // Refresh the token with timeout - pass forceRefresh=true to actually refresh
      final newCredential = await credential
          .getTokenResponse(true)
          .timeout(const Duration(seconds: 30));

      // Validate that we actually got a new access token
      if (newCredential.accessToken == null ||
          newCredential.accessToken!.isEmpty) {
        AppLogger.error(
          'Token refresh returned empty access token',
          data: {
            'hasRefreshToken': newCredential.refreshToken != null,
            'expiresAt': newCredential.expiresAt?.toIso8601String(),
            'refreshTokenUsed': maskedRefreshToken,
          },
        );
        const emptyTokenResult = (
          result: TokenRefreshResult.permanentError,
          token: null as TokenResponse?,
          error: 'Refresh returned empty access token',
        );
        _refreshCompleter!.complete(emptyTokenResult);
        return emptyTokenResult;
      }

      // Save tokens including any new refresh token issued
      await _saveTokens(newCredential);

      // Verify the token was actually saved
      final savedToken = await getAccessToken();
      if (savedToken == null || savedToken.isEmpty) {
        AppLogger.error(
          'Failed to save refreshed token to storage',
          data: {'refreshTokenUsed': maskedRefreshToken},
        );
        const saveFailResult = (
          result: TokenRefreshResult.transientError,
          token: null as TokenResponse?,
          error: 'Failed to save refreshed token',
        );
        _refreshCompleter!.complete(saveFailResult);
        return saveFailResult;
      }

      // Log success with details
      AppLogger.info(
        'Access token refreshed successfully',
        data: {
          'expiresAt': newCredential.expiresAt?.toIso8601String(),
          'newRefreshTokenIssued':
              newCredential.refreshToken != null &&
              newCredential.refreshToken != refreshTokenValue,
          'accessTokenLength': newCredential.accessToken!.length,
        },
      );

      final successResult = (
        result: TokenRefreshResult.success,
        token: newCredential,
        error: null as String?,
      );
      _refreshCompleter!.complete(successResult);
      return successResult;
    } on TimeoutException {
      AppLogger.warning('Token refresh timed out');
      const timeoutResult = (
        result: TokenRefreshResult.transientError,
        token: null as TokenResponse?,
        error: 'Refresh timed out',
      );
      _refreshCompleter!.complete(timeoutResult);
      return timeoutResult;
    } catch (e, stackTrace) {
      final errorStr = e.toString().toLowerCase();
      final isPermanentError = _isPermanentRefreshError(errorStr);

      if (isPermanentError) {
        AppLogger.error(
          'Token refresh failed permanently - re-authentication required',
          error: e,
          stackTrace: stackTrace,
        );
        final permErrorResult = (
          result: TokenRefreshResult.permanentError,
          token: null as TokenResponse?,
          error: e.toString(),
        );
        _refreshCompleter!.complete(permErrorResult);
        return permErrorResult;
      } else {
        AppLogger.warning(
          'Token refresh failed with transient error',
          data: {'error': e.toString()},
        );
        final transientResult = (
          result: TokenRefreshResult.transientError,
          token: null as TokenResponse?,
          error: e.toString(),
        );
        _refreshCompleter!.complete(transientResult);
        return transientResult;
      }
    } finally {
      // Guarantee the completer is completed and cleared so concurrent
      // waiters never deadlock and subsequent calls create a fresh completer.
      if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
        _refreshCompleter!.completeError(
          StateError('Token refresh exited without completing'),
        );
      }
      _refreshCompleter = null;
    }
  }

  /// Check if an error indicates permanent refresh failure
  /// We are EXTREMELY conservative here - only truly permanent errors cause logout.
  /// Network issues, timeouts, and ambiguous errors are treated as transient.
  ///
  /// DESIGN PRINCIPLE: It is FAR better to retry unnecessarily than to
  /// incorrectly log out a user. A logged-out user loses their session
  /// and must re-authenticate, which is a poor user experience.
  ///
  /// Permanent errors (user must re-authenticate):
  /// - invalid_grant: Refresh token is invalid or expired (OAuth2 standard)
  /// - invalid_client: Client credentials are wrong (should never happen)
  /// - unauthorized_client: Client not allowed for this grant type
  /// - access_denied: User explicitly denied/revoked access
  /// - Explicit refresh token revocation messages from OAuth server
  ///
  /// Transient errors (retry later):
  /// - Network errors, connection refused, DNS failures
  /// - Timeouts (connection, read, write)
  /// - Server errors (5xx, 503, 502, etc.)
  /// - Rate limiting (429)
  /// - TLS/SSL errors
  /// - Any ambiguous "expired" or "invalid" without OAuth2 error code context
  /// - ANY error we're not 100% sure about
  bool _isPermanentRefreshError(String errorStr) {
    // FIRST: Check for known transient error patterns
    // If any of these are present, it's definitely NOT permanent
    const transientPatterns = [
      'timeout',
      'timed out',
      'connection refused',
      'connection reset',
      'connection closed',
      'no route to host',
      'network is unreachable',
      'host not found',
      'dns',
      'socket',
      'eof',
      'broken pipe',
      'ssl',
      'tls',
      'certificate',
      'handshake',
      '5xx',
      '500',
      '502',
      '503',
      '504',
      '429', // Rate limiting
      'too many requests',
      'rate limit',
      'temporarily unavailable',
      'service unavailable',
      'try again',
      'retry',
    ];

    for (final pattern in transientPatterns) {
      if (errorStr.contains(pattern)) {
        AppLogger.debug(
          'Transient error pattern detected, not treating as permanent',
          data: {'pattern': pattern},
        );
        return false;
      }
    }

    // OAuth2 standard error codes that indicate permanent failure
    // These are the ONLY error codes from RFC 6749 that indicate
    // the refresh token itself is invalid
    const permanentOAuthErrors = [
      'invalid_grant', // Refresh token expired/invalid (the main one)
      'invalid_client', // Wrong client credentials (shouldn't happen in production)
      'unauthorized_client', // Client not allowed for this grant type
      'access_denied', // User explicitly denied access
    ];

    // Check for OAuth2 standard errors
    for (final error in permanentOAuthErrors) {
      if (errorStr.contains(error)) {
        AppLogger.debug('Permanent OAuth2 error detected: $error');
        return true;
      }
    }

    // Check for VERY explicit refresh token revocation messages
    // These must be exact phrases that OAuth servers return
    const permanentMessages = [
      'refresh token has been revoked',
      'refresh token was revoked',
      'refresh_token has been revoked',
      'the refresh token is no longer valid',
      'refresh token is no longer active',
    ];

    for (final message in permanentMessages) {
      if (errorStr.contains(message)) {
        AppLogger.debug('Permanent refresh token error detected: $message');
        return true;
      }
    }

    // NOTE: We do NOT check for generic "refresh" + "invalid/expired" patterns
    // because these could be network error messages that happen to contain
    // these words. Only explicit OAuth2 error codes should trigger logout.

    // All other errors are transient - be conservative to avoid unnecessary logouts
    AppLogger.debug(
      'Error not recognized as permanent, treating as transient',
      data: {
        'errorPreview': errorStr.substring(0, errorStr.length.clamp(0, 100)),
      },
    );
    return false;
  }

  /// Legacy refresh method for backward compatibility
  /// Prefer [refreshTokenWithResult] for new code
  Future<TokenResponse?> refreshToken() async {
    final result = await refreshTokenWithResult();
    if (result.result == TokenRefreshResult.success) {
      return result.token;
    }
    // Only logout on permanent errors
    if (result.result == TokenRefreshResult.permanentError) {
      await logout();
    }
    return null;
  }

  /// Get user information from ID token
  Future<Map<String, dynamic>?> getUserInfo() async {
    final idToken = await getIdToken();
    if (idToken == null) return null;

    try {
      // Decode JWT (ID token is in format: header.payload.signature)
      final parts = idToken.split('.');
      if (parts.length != 3) return null;

      // Decode the payload (second part)
      final payload = parts[1];

      // Add padding if needed for base64 decoding
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));

      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to decode ID token',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Check if user is authenticated
  /// Returns true if user has a valid access token OR a refresh token that can be used
  Future<bool> isAuthenticated() async {
    // Check for redirect result first (only matters for web)
    await _handleRedirectResult();

    final accessToken = await getAccessToken();
    if (accessToken != null) {
      return true;
    }

    // No access token, but check if we have a refresh token
    // If so, the user is still "logged in" and we can recover the session
    final refreshTokenValue = await getRefreshToken();
    return refreshTokenValue != null;
  }

  /// Check if user has a valid, usable access token
  /// This is different from isAuthenticated - this checks if we can make API calls right now
  Future<bool> hasValidAccessToken() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) {
      return false;
    }

    // Check if token is expired
    final expired = await isTokenExpired();
    return !expired;
  }

  /// Ensure we have a valid access token, refreshing if necessary
  /// Returns a tuple with the access token (if successful) and whether re-login is needed
  /// This method implements retry logic for transient errors
  Future<({String? token, bool needsRelogin})>
  ensureValidAccessTokenWithStatus({
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    final accessToken = await getAccessToken();

    // If we have a token and it's not expired, return it
    if (accessToken != null) {
      final expired = await isTokenExpired();
      if (!expired) {
        return (token: accessToken, needsRelogin: false);
      }
    }

    // Token is missing or expired, try to refresh
    final refreshTokenValue = await getRefreshToken();
    if (refreshTokenValue == null) {
      AppLogger.debug('No refresh token available, user needs to login');
      return (token: null, needsRelogin: true);
    }

    // Attempt refresh with retries for transient errors
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      AppLogger.debug(
        'Access token missing/expired, attempting refresh',
        data: {'attempt': attempt, 'maxRetries': maxRetries},
      );

      final result = await refreshTokenWithResult();

      switch (result.result) {
        case TokenRefreshResult.success:
          return (
            token: result.token?.accessToken ?? await getAccessToken(),
            needsRelogin: false,
          );

        case TokenRefreshResult.permanentError:
          AppLogger.error('Permanent refresh error, user must re-login');
          await logout();
          return (token: null, needsRelogin: true);

        case TokenRefreshResult.transientError:
          if (attempt < maxRetries) {
            final delay = retryDelay * attempt; // Linear backoff
            AppLogger.info(
              'Transient refresh error, retrying in ${delay.inSeconds}s',
              data: {'attempt': attempt, 'error': result.error},
            );
            await Future.delayed(delay);
          } else {
            AppLogger.warning(
              'Max refresh retries reached, but not logging out (transient error)',
            );
            // Don't logout on transient errors - might recover on next attempt
            return (token: null, needsRelogin: false);
          }
      }
    }

    return (token: null, needsRelogin: false);
  }

  /// Legacy method for backward compatibility
  Future<String?> ensureValidAccessToken() async {
    final result = await ensureValidAccessTokenWithStatus();
    return result.token;
  }

  /// Handle redirect result from Web authentication
  ///
  /// Returns true if a valid session was recovered from redirect.
  Future<bool> _handleRedirectResult() async {
    try {
      await _ensureInitialized();
      final token = await _platform.getRedirectResult();
      if (token != null) {
        AppLogger.info('Recovered session from redirect');
        await _saveTokens(token);
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      // Log the error but don't rethrow - we might not be returning from redirect
      AppLogger.warning(
        'Error handling redirect result',
        data: {'error': e.toString()},
      );
      AppLogger.debug(
        'Redirect error details',
        data: {'stackTrace': stackTrace.toString()},
      );
      return false;
    }
  }

  /// Logout and clear all stored tokens
  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'id_token');
    await _storage.delete(key: 'token_expires_at');
  }
}
