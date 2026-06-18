/// API Client providers and transport configuration
///
/// This module provides Riverpod providers for all API clients used
/// in the application, including authentication, token management,
/// and service-specific clients.
library;

import 'package:antinvestor_api_common/antinvestor_api_common.dart';
import 'package:antinvestor_api_device/antinvestor_api_device.dart';
import 'package:antinvestor_api_files/antinvestor_api_files.dart'
    hide
        Struct,
        Value,
        ListValue,
        NullValue,
        Timestamp,
        ContactLink,
        PageCursor;
import 'package:antinvestor_api_profile/antinvestor_api_profile.dart'
    hide
        DeviceClient,
        newDeviceClient,
        Struct,
        Value,
        ListValue,
        NullValue,
        Timestamp;
import 'package:antinvestor_auth_runtime/antinvestor_auth_runtime.dart';
import 'package:connectrpc/connect.dart' as connect;
import 'package:connectrpc/io.dart' as connect_io;
import 'package:connectrpc/protobuf.dart' as connect_protobuf;
import 'package:connectrpc/protocol/connect.dart' as connect_protocol;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stawi_api_chat/stawi_api_chat.dart'
    hide
        Struct,
        Value,
        ListValue,
        NullValue,
        Timestamp,
        ContactLink,
        PageCursor;

import 'api_config.dart';
import 'certificate_pinning.dart';
import 'runtime_transport.dart';

// ============================================================================
// Client type aliases and factory functions
//
// These were previously exported by stawi_api_chat and
// antinvestor_api_files but were removed in v1.54.0.
// ============================================================================

/// Type alias for Chat client for convenience.
typedef ChatClient = ConnectClientBase<ChatServiceClient>;

/// Type alias for Gateway client for convenience.
typedef GatewayClient = ConnectClientBase<GatewayServiceClient>;

/// Type alias for Files client for convenience.
typedef FilesClient = ConnectClientBase<FilesServiceClient>;

/// Creates a new Chat service client. Auth is handled by the transport
/// (RuntimeTransport routes through AuthRuntime.fetch); SDK auth interceptors
/// are not wired.
Future<ChatClient> newChatClient({
  required TransportFactory createTransport,
  String? endpoint,
}) {
  return newClient<ChatServiceClient>(
    defaultEndpoint: endpoint ?? 'https://chat.stawi.org',
    createServiceClient: ChatServiceClient.new,
    createTransport: createTransport,
    endpoint: endpoint,
  );
}

/// Creates a new Gateway service client.
Future<GatewayClient> newGatewayClient({
  required TransportFactory createTransport,
  String? endpoint,
}) {
  return newClient<GatewayServiceClient>(
    defaultEndpoint: endpoint ?? 'https://gateway.stawi.org',
    createServiceClient: GatewayServiceClient.new,
    createTransport: createTransport,
    endpoint: endpoint,
  );
}

/// Creates a new Files service client.
Future<FilesClient> newFilesClient({
  required TransportFactory createTransport,
  String? endpoint,
}) {
  return newClient<FilesServiceClient>(
    defaultEndpoint: endpoint ?? 'https://files.stawi.org',
    createServiceClient: FilesServiceClient.new,
    createTransport: createTransport,
    endpoint: endpoint,
  );
}

/// Secure storage provider for token access
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Bridge [TokenManager] that exposes `accessToken` to the few remaining
/// direct-HTTP call sites (link previews, account service, content
/// resolver) that have not yet moved to `runtime.fetch`. The Connect RPC
/// clients go through [RuntimeTransport] and do not touch this manager.
///
/// The manager reads `access_token` from secure storage on `initialize`
/// — the AuthRuntime writes that key as part of its own persistence
/// cycle, giving the direct-HTTP callers a synchronous accessor without
/// needing them to own the runtime. Refresh/logout hooks are intentionally
/// absent: the runtime owns both.
final tokenManagerProvider = Provider<TokenManager>((ref) {
  final storage = ref.watch(secureStorageProvider);

  final tokenManager = TokenManager(
    loadTokens: () async {
      final accessToken = await storage.read(key: 'access_token');
      final refreshToken = await storage.read(key: 'refresh_token');
      if (accessToken != null) {
        return TokenPair(accessToken: accessToken, refreshToken: refreshToken);
      }
      return null;
    },
  );

  ref.onDispose(tokenManager.dispose);

  return tokenManager;
});

/// Creates a transport factory that uses the provided CertificatePinning instance
///
/// This enables dependency injection of the CertificatePinning service
/// while maintaining compatibility with the client factory function signature.
typedef CreateTransportFn =
    connect.Transport Function(
      Uri baseUrl,
      List<connect.Interceptor> interceptors,
    );

/// Creates a transport factory bound to a CertificatePinning instance
///
/// Parameters:
/// - [certificatePinning]: The CertificatePinning instance to use
///
/// Returns a function that creates transports with certificate pinning enabled.
CreateTransportFn createTransportFactory(
  CertificatePinning certificatePinning,
) => (Uri baseUrl, List<connect.Interceptor> interceptors) {
  final httpClient = certificatePinning.createPinnedHttpClient();
  return connect_protocol.Transport(
    baseUrl: baseUrl.toString(),
    codec: const connect_protobuf.ProtoCodec(),
    httpClient: connect_io.createHttpClient(httpClient),
    interceptors: interceptors,
  );
};

/// Creates a Connect transport for API communication with certificate pinning
///
/// Configures HTTP client with appropriate timeouts, connection pooling,
/// and TLS certificate pinning for optimal performance and security.
///
/// Parameters:
/// - [baseUrl]: The base URL for the API endpoint
/// - [interceptors]: List of interceptors for auth, logging, etc.
///
/// Returns a configured [connect.Transport] instance with certificate pinning.
///
/// Note: Prefer using [createTransportFactory] with dependency injection
/// for better testability and single instance management.
///
/// Example:
/// ```dart
/// final transport = createTransport(
///   Uri.parse('https://api.example.com'),
///   [authInterceptor],
/// );
/// ```
connect.Transport createTransport(
  Uri baseUrl,
  List<connect.Interceptor> interceptors,
) {
  // Fallback: create a new instance (for backwards compatibility)
  final certificatePinning = CertificatePinning();
  final httpClient = certificatePinning.createPinnedHttpClient();

  return connect_protocol.Transport(
    baseUrl: baseUrl.toString(),
    codec: const connect_protobuf.ProtoCodec(),
    httpClient: connect_io.createHttpClient(httpClient),
    interceptors: interceptors,
  );
}

/// Builds a [TransportFactory] that routes every Connect RPC through
/// `AuthRuntime.fetch` via `RuntimeTransport`.
///
/// Replaces [createTransportFactory] for the `*ClientProvider` family.
/// Certificate pinning is no longer applied here because the runtime
/// owns the underlying http client (pinning will be threaded into the
/// runtime in a later dispatch).
CreateTransportFn createRuntimeTransportFactory(AuthRuntime runtime) {
  return (Uri baseUrl, List<connect.Interceptor> interceptors) {
    return RuntimeTransport(
      runtime: runtime,
      baseUrl: baseUrl,
      interceptors: interceptors,
    );
  };
}

// ============================================================================
// Service Client Providers
// ============================================================================

/// Warms [tokenManagerProvider] from secure storage. The Connect RPC path
/// never reads the manager (RuntimeTransport handles auth), but the
/// direct-HTTP bridges (link previews, account service, content resolver)
/// read `accessToken` synchronously and therefore need the in-memory cache
/// populated before first use. Keyed off `chatClientProvider` so any
/// consumer that watches the chat client also warms the manager.
Future<void> _warmTokenManager(Ref ref) async {
  await ref.watch(tokenManagerProvider).initialize();
}

/// Chat client provider - Connect transport routes through `AuthRuntime.fetch`
/// via `RuntimeTransport`.
final chatClientProvider = FutureProvider<ChatClient>((ref) async {
  final runtime = ref.watch(authRuntimeProvider);
  await _warmTokenManager(ref);

  return newChatClient(
    createTransport: createRuntimeTransportFactory(runtime),
    endpoint: ApiConfig.chatBaseUrl,
  );
});

/// Gateway client provider - Connect transport routes through runtime.fetch.
final gatewayClientProvider = FutureProvider<GatewayClient>((ref) async {
  final runtime = ref.watch(authRuntimeProvider);
  await _warmTokenManager(ref);

  return newGatewayClient(
    createTransport: createRuntimeTransportFactory(runtime),
    endpoint: ApiConfig.gatewayBaseUrl,
  );
});

/// Device client provider - Connect transport routes through runtime.fetch.
final deviceClientProvider = FutureProvider<DeviceClient>((ref) async {
  final runtime = ref.watch(authRuntimeProvider);
  await _warmTokenManager(ref);

  return newDeviceClient(
    createTransport: createRuntimeTransportFactory(runtime),
    endpoint: ApiConfig.devicesBaseUrl,
  );
});

/// Profile client provider - Connect transport routes through runtime.fetch.
final profileClientProvider = FutureProvider<ProfileClient>((ref) async {
  final runtime = ref.watch(authRuntimeProvider);
  await _warmTokenManager(ref);

  return newProfileClient(
    createTransport: createRuntimeTransportFactory(runtime),
    endpoint: ApiConfig.profileBaseUrl,
  );
});

/// Files client provider - Connect transport routes through runtime.fetch.
final filesClientProvider = FutureProvider<FilesClient>((ref) async {
  final runtime = ref.watch(authRuntimeProvider);
  await _warmTokenManager(ref);

  return newFilesClient(
    createTransport: createRuntimeTransportFactory(runtime),
    endpoint: ApiConfig.filesBaseUrl,
  );
});

/// Legacy providers for backward compatibility - expose the underlying service clients
final chatServiceClientProvider = FutureProvider<ChatServiceClient>((
  ref,
) async {
  final client = await ref.watch(chatClientProvider.future);
  return client.stub;
});

final gatewayServiceClientProvider = FutureProvider<GatewayServiceClient>((
  ref,
) async {
  final client = await ref.watch(gatewayClientProvider.future);
  return client.stub;
});

final deviceServiceClientProvider = FutureProvider<DeviceServiceClient>((
  ref,
) async {
  final client = await ref.watch(deviceClientProvider.future);
  return client.stub;
});

final profileServiceClientProvider = FutureProvider<ProfileServiceClient>((
  ref,
) async {
  final client = await ref.watch(profileClientProvider.future);
  return client.stub;
});

final filesServiceClientProvider = FutureProvider<FilesServiceClient>((
  ref,
) async {
  final client = await ref.watch(filesClientProvider.future);
  return client.stub;
});
