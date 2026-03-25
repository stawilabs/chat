import 'dart:io' as io;

import 'package:connectrpc/connect.dart' as connect;
import 'package:connectrpc/io.dart' as connect_io;
import 'package:connectrpc/protobuf.dart' as connect_protobuf;
import 'package:connectrpc/protocol/connect.dart' as connect_protocol;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../logging/app_logger.dart';
import 'api_config.dart';

/// Token provider abstraction for getting JWT tokens
abstract class TokenProvider {
  Future<String?> getAccessToken();
  Future<void> onTokenExpired();

  /// Ensure we have a valid access token, refreshing if necessary
  Future<String?> ensureValidAccessToken();
}

/// Default token provider using FlutterSecureStorage
class SecureStorageTokenProvider implements TokenProvider {
  SecureStorageTokenProvider(
    this._storage, {
    Future<void> Function()? onExpired,
    Future<String?> Function()? ensureValidToken,
  }) : _onExpired = onExpired,
       _ensureValidToken = ensureValidToken;
  final FlutterSecureStorage _storage;
  final Future<void> Function()? _onExpired;
  final Future<String?> Function()? _ensureValidToken;

  @override
  Future<String?> getAccessToken() async => _storage.read(key: 'access_token');

  @override
  Future<void> onTokenExpired() async {
    final callback = _onExpired;
    if (callback != null) {
      await callback();
    }
  }

  @override
  Future<String?> ensureValidAccessToken() async {
    final callback = _ensureValidToken;
    if (callback != null) {
      return callback();
    }
    // Fallback: just return current token
    return getAccessToken();
  }
}

/// Creates an authenticated HTTP client with JWT headers
/// Optimized for low-resource devices with connection pooling and timeouts
class AuthenticatedHttpClient {
  AuthenticatedHttpClient(this._tokenProvider)
    : _httpClient = _createOptimizedHttpClient();
  final TokenProvider _tokenProvider;
  final io.HttpClient _httpClient;

  static io.HttpClient _createOptimizedHttpClient() {
    final client = io.HttpClient();

    // Optimize for low-resource devices
    client.connectionTimeout = ApiConfig.connectionTimeout;
    client.idleTimeout = ApiConfig.idleTimeout;

    // Limit concurrent connections to reduce memory usage
    client.maxConnectionsPerHost = 4;

    // Enable automatic decompression
    client.autoUncompress = true;

    return client;
  }

  io.HttpClient get httpClient => _httpClient;

  /// Get authorization headers with JWT token
  /// Automatically refreshes token if expired
  Future<connect.Headers> getAuthHeaders() async {
    final headers = connect.Headers();
    // Use ensureValidAccessToken to auto-refresh if needed
    final token = await _tokenProvider.ensureValidAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void close() {
    _httpClient.close();
  }
}

/// Factory for creating authenticated transports for different services
class TransportFactory {
  TransportFactory(this._tokenProvider);
  final TokenProvider _tokenProvider;
  final Map<String, connect.Transport> _transports = {};
  AuthenticatedHttpClient? _httpClient;

  AuthenticatedHttpClient get httpClient {
    _httpClient ??= AuthenticatedHttpClient(_tokenProvider);
    return _httpClient!;
  }

  /// Create or get cached transport for a service
  connect.Transport getTransport(String baseUrl) =>
      _transports.putIfAbsent(baseUrl, () {
        AppLogger.debug('Creating transport for $baseUrl');
        return connect_protocol.Transport(
          baseUrl: baseUrl,
          codec: const connect_protobuf.ProtoCodec(),
          httpClient: connect_io.createHttpClient(httpClient.httpClient),
        );
      });

  /// Get transport for Chat service
  connect.Transport get chatTransport => getTransport(ApiConfig.chatBaseUrl);

  /// Get transport for Gateway service
  connect.Transport get gatewayTransport =>
      getTransport(ApiConfig.gatewayBaseUrl);

  /// Get transport for Device service
  connect.Transport get deviceTransport =>
      getTransport(ApiConfig.devicesBaseUrl);

  /// Get transport for File service
  connect.Transport get fileTransport => getTransport(ApiConfig.filesBaseUrl);

  /// Get transport for Profile service
  connect.Transport get profileTransport =>
      getTransport(ApiConfig.profileBaseUrl);

  /// Get auth headers for manual header injection
  Future<connect.Headers> getAuthHeaders() => httpClient.getAuthHeaders();

  /// Dispose all resources
  void dispose() {
    _httpClient?.close();
    _transports.clear();
  }
}

/// Wrapper that automatically injects auth headers into API calls
/// This provides a convenient way to make authenticated requests
class AuthenticatedClient<T> {
  AuthenticatedClient(this._client, this._transportFactory);
  final T _client;
  final TransportFactory _transportFactory;

  T get client => _client;

  /// Get auth headers to pass to RPC calls
  Future<connect.Headers> getHeaders() => _transportFactory.getAuthHeaders();
}
