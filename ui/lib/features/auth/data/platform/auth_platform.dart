import 'package:openid_client/openid_client.dart';

/// Abstract class for platform-specific authentication logic
abstract class AuthPlatform {
  /// Initialize the platform-specific client
  Future<void> initialize(String issuerUrl, String clientId);

  /// Authenticate the user
  /// Returns a [TokenResponse] on success.
  /// On Web, this triggers a redirect and may return null.
  Future<TokenResponse?> authenticate(List<String> scopes);

  /// Check for redirect result (Web only)
  Future<TokenResponse?> getRedirectResult();

  /// Cancel any ongoing authentication flow
  /// This is a no-op on platforms that don't support cancellation
  Future<void> cancelAuthentication() async {}

  /// Get the client instance (if initialized)
  Client? get client;

  /// Get the issuer instance (if initialized)
  Issuer? get issuer;
}
