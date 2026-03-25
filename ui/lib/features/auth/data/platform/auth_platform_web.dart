import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:openid_client/openid_client.dart';
import 'package:web/web.dart' as web;

import '../../../../core/logging/app_logger.dart';
import 'auth_platform.dart';

AuthPlatform getAuthPlatform() => AuthPlatformWeb();

class AuthPlatformWeb implements AuthPlatform {
  static const String _stateKey = 'openid_client:state';
  static const String _codeVerifierKey = 'openid_client:code_verifier';
  static const String _timestampKey = 'openid_client:timestamp';
  static const Duration _stateExpiry = Duration(minutes: 10);
  static const Duration _tokenExchangeTimeout = Duration(seconds: 30);

  Issuer? _issuer;
  Client? _client;

  @override
  Issuer? get issuer => _issuer;

  @override
  Client? get client => _client;

  @override
  Future<void> initialize(String issuerUrl, String clientId) async {
    if (_issuer == null || _client == null) {
      try {
        _issuer = await Issuer.discover(Uri.parse(issuerUrl));
        _client = Client(_issuer!, clientId);
      } catch (e) {
        AppLogger.error(
          'Failed to discover OIDC issuer',
          error: e,
          data: {'url': issuerUrl},
        );
        rethrow;
      }
    }
  }

  @override
  Future<TokenResponse?> authenticate(List<String> scopes) async {
    if (_client == null) {
      throw StateError('AuthPlatformWeb not initialized');
    }

    // Clean up any stale auth state before starting new flow
    _cleanupStaleState();

    // Get base redirect URI (strip query params and fragment)
    final currentUri = Uri.parse(web.window.location.href);
    final redirectUri = Uri(
      scheme: currentUri.scheme,
      host: currentUri.host,
      port: currentUri.port,
      path: currentUri.path,
    );

    final codeVerifier = _generateCodeVerifier();
    final flow =
        Flow.authorizationCodeWithPKCE(_client!, codeVerifier: codeVerifier)
          ..scopes.addAll(scopes)
          ..redirectUri = redirectUri;

    // Store state, code_verifier, and timestamp for PKCE callback
    web.window.localStorage.setItem(_stateKey, flow.state);
    web.window.localStorage.setItem(_codeVerifierKey, codeVerifier);
    web.window.localStorage.setItem(
      _timestampKey,
      DateTime.now().millisecondsSinceEpoch.toString(),
    );

    AppLogger.debug(
      'Starting web auth flow',
      data: {'redirectUri': redirectUri.toString(), 'state': flow.state},
    );

    // Redirect to authorization endpoint
    web.window.location.href = flow.authenticationUri.toString();

    // This won't return as the page redirects
    return null;
  }

  @override
  Future<TokenResponse?> getRedirectResult() async {
    if (_client == null) return null;

    final uri = Uri.parse(web.window.location.href);
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];
    final error = uri.queryParameters['error'];
    final errorDescription = uri.queryParameters['error_description'];

    // Check for OAuth error response
    if (error != null) {
      AppLogger.error(
        'OAuth error from provider',
        data: {'error': error, 'description': errorDescription},
      );
      _clearAuthState();
      // Clean up URL
      _cleanUrl(uri);
      throw Exception('Authentication failed: ${errorDescription ?? error}');
    }

    if (code == null || state == null) return null;

    final storedState = web.window.localStorage.getItem(_stateKey);
    final storedCodeVerifier = web.window.localStorage.getItem(
      _codeVerifierKey,
    );
    final storedTimestamp = web.window.localStorage.getItem(_timestampKey);

    // Validate state
    if (storedState != state) {
      AppLogger.warning(
        'OIDC state mismatch',
        data: {'expected': storedState, 'received': state},
      );
      _clearAuthState();
      _cleanUrl(uri);
      return null;
    }

    if (storedCodeVerifier == null) {
      AppLogger.warning('Missing code verifier for PKCE');
      _clearAuthState();
      _cleanUrl(uri);
      return null;
    }

    // Check if state has expired
    if (storedTimestamp != null) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(storedTimestamp) ?? 0,
      );
      if (DateTime.now().difference(timestamp) > _stateExpiry) {
        AppLogger.warning('Auth state expired');
        _clearAuthState();
        _cleanUrl(uri);
        return null;
      }
    }

    try {
      AppLogger.debug('Processing auth callback', data: {'state': state});

      // Clean up URL first to prevent re-processing
      _cleanUrl(uri);

      // Get base redirect URI
      final redirectUri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.port,
        path: uri.path,
      );

      // Recreate flow with stored code verifier for token exchange
      final flow = Flow.authorizationCodeWithPKCE(
        _client!,
        state: storedState,
        codeVerifier: storedCodeVerifier,
      )..redirectUri = redirectUri;

      // Exchange code for tokens with timeout
      final credential = await flow
          .callback({'code': code, 'state': state})
          .timeout(
            _tokenExchangeTimeout,
            onTimeout: () {
              throw TimeoutException('Token exchange timed out');
            },
          );

      final tokenResponse = await credential.getTokenResponse().timeout(
        _tokenExchangeTimeout,
        onTimeout: () {
          throw TimeoutException('Getting token response timed out');
        },
      );

      // Clear auth state only after successful token exchange
      _clearAuthState();

      AppLogger.info('Web authentication successful');
      return tokenResponse;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to exchange code for tokens',
        error: e,
        stackTrace: stackTrace,
      );
      _clearAuthState();
      rethrow;
    }
  }

  /// Clean up the URL by removing OAuth query parameters
  void _cleanUrl(Uri uri) {
    final cleanUri = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.port,
      path: uri.path,
    );
    web.window.history.replaceState(null, '', cleanUri.toString());
  }

  /// Clear all stored auth state
  void _clearAuthState() {
    web.window.localStorage.removeItem(_stateKey);
    web.window.localStorage.removeItem(_codeVerifierKey);
    web.window.localStorage.removeItem(_timestampKey);
  }

  /// Clean up stale auth state (older than expiry duration)
  void _cleanupStaleState() {
    final storedTimestamp = web.window.localStorage.getItem(_timestampKey);
    if (storedTimestamp != null) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(storedTimestamp) ?? 0,
      );
      if (DateTime.now().difference(timestamp) > _stateExpiry) {
        AppLogger.debug('Cleaning up stale auth state');
        _clearAuthState();
      }
    }
  }

  @override
  Future<void> cancelAuthentication() async {
    // On web, we just clear the stored auth state
    _clearAuthState();
    AppLogger.debug('Web auth state cleared');
  }

  /// Generate a cryptographically random code verifier for PKCE
  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }
}
