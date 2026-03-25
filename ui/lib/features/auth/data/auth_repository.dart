import 'package:antinvestor_api_common/antinvestor_api_common.dart'
    show TokenRefreshResult;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_service.dart';

part 'auth_repository.g.dart';

/// Repository for authentication operations
///
/// Provides a high-level interface for authentication including:
/// - OAuth2/OIDC login and logout
/// - Token management and refresh
/// - User profile information retrieval
///
/// Example:
/// ```dart
/// final authRepo = ref.watch(authRepositoryProvider);
/// await authRepo.login();
/// final isLoggedIn = await authRepo.isLoggedIn();
/// ```
class AuthRepository {
  AuthRepository(this._authService);
  final AuthService _authService;

  Future<void> login() async {
    final token = await _authService.authenticate();
    if (token == null) {
      // On IO platforms, authenticate() should always return a token
      // On web, it might return null due to redirect flow
      throw Exception('Authentication did not return a token');
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<bool> isLoggedIn() async => _authService.isAuthenticated();

  Future<bool> isTokenExpired() async => _authService.isTokenExpired();

  Future<void> refreshToken() async {
    await _authService.refreshToken();
  }

  /// Refresh token with detailed result information
  /// Returns result type, token if successful, and error message if failed
  Future<({TokenRefreshResult result, dynamic token, String? error})>
  refreshTokenWithResult() async => _authService.refreshTokenWithResult();

  /// Get the time until a token refresh is needed
  /// Returns null if no expiry info available
  Future<Duration?> getTimeUntilRefreshNeeded() async =>
      _authService.getTimeUntilRefreshNeeded();

  /// Get the token expiry time
  Future<DateTime?> getTokenExpiryTime() async =>
      _authService.getTokenExpiryTime();

  Future<Map<String, dynamic>?> getUserInfo() async =>
      _authService.getUserInfo();

  /// Get the current profile ID from the JWT token ('sub' claim)
  /// Returns the profile ID of the authenticated profile, or null if not authenticated
  Future<String?> getCurrentProfileId() async {
    final claims = await getUserInfo();
    return claims?['sub'] as String?;
  }

  /// Get the current contact ID from the JWT token ('contact_id' claim)
  /// Returns the contact ID of the authenticated user, or null if not authenticated
  Future<String?> getCurrentContactId() async {
    final claims = await getUserInfo();
    return claims?['contact_id'] as String?;
  }

  Future<String?> getAccessToken() async => _authService.getAccessToken();

  /// Ensure we have a valid access token, refreshing if necessary
  /// Returns the access token if successful, null if user needs to re-login
  Future<String?> ensureValidAccessToken() async =>
      _authService.ensureValidAccessToken();

  /// Ensure valid access token with detailed status
  /// Returns token and whether re-login is needed
  Future<({String? token, bool needsRelogin})>
  ensureValidAccessTokenWithStatus({
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async => _authService.ensureValidAccessTokenWithStatus(
    maxRetries: maxRetries,
    retryDelay: retryDelay,
  );

  /// Check if we have a valid, usable access token right now
  Future<bool> hasValidAccessToken() async =>
      _authService.hasValidAccessToken();
}

@riverpod
AuthRepository authRepository(Ref ref) {
  // Use centralized API config for OAuth2 settings
  const issuerUrl = 'https://oauth2.stawi.org';
  const clientId = '9bsv0s0hijjg02qk7l1g';

  const storage = FlutterSecureStorage();
  final authService = AuthService(
    storage,
    issuerUrl: issuerUrl,
    clientId: clientId,
  );

  return AuthRepository(authService);
}

@riverpod
Future<String?> currentProfileId(Ref ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getCurrentProfileId();
}
