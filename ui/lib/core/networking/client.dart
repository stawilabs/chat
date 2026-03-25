/// API Client providers and transport configuration
///
/// This module provides Riverpod providers for all API clients used
/// in the application, including authentication, token management,
/// and service-specific clients.
library;

import 'package:antinvestor_api_chat/antinvestor_api_chat.dart';
import 'package:antinvestor_api_common/antinvestor_api_common.dart';
import 'package:antinvestor_api_device/antinvestor_api_device.dart';
import 'package:antinvestor_api_files/antinvestor_api_files.dart';
import 'package:antinvestor_api_profile/antinvestor_api_profile.dart';
import 'package:connectrpc/connect.dart' as connect;
import 'package:connectrpc/io.dart' as connect_io;
import 'package:connectrpc/protobuf.dart' as connect_protobuf;
import 'package:connectrpc/protocol/connect.dart' as connect_protocol;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/auth_repository.dart';
import '../auth/shared_token_service.dart';
import '../auth/token_refresh_coordinator.dart';
import '../logging/app_logger.dart';
import 'api_config.dart';
import 'certificate_pinning.dart';

/// Secure storage provider for token access
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Token manager provider using antinvestor_api_common TokenManager
///
/// TokenManager handles:
/// - Persistent storage of tokens (access token only - refresh token managed by AuthService)
/// - Reactive refresh on 401 (via TokenRefreshCoordinator)
/// - Concurrent refresh prevention (via TokenRefreshCoordinator)
/// - Logout on permanent errors
///
/// All token refresh operations are delegated to [TokenRefreshCoordinator]
/// to ensure consistent behavior across the entire application.
final tokenManagerProvider = Provider<TokenManager>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final coordinator = ref.watch(tokenRefreshCoordinatorProvider);

  final tokenManager = TokenManager(
    persistTokens: (accessToken, refreshToken) async {
      // IMPORTANT: We only manage access token here.
      // Refresh token is managed exclusively by AuthService.
      //
      // Why? When OAuth server uses refresh token rotation, AuthService saves
      // the NEW refresh token to storage during refresh. But TokenManager's
      // setAccessToken() calls persistTokens with its OLD in-memory refresh
      // token, which would overwrite the fresh one - causing the next refresh
      // to fail and the user to be logged out unexpectedly.
      //
      // By only managing access token here, we avoid this race condition.
      // The only exception is logout (both tokens null) where we clear both.
      if (accessToken != null) {
        await storage.write(key: 'access_token', value: accessToken);
      } else {
        await storage.delete(key: 'access_token');
      }

      // Only clear refresh token during logout (when both tokens are null)
      if (accessToken == null && refreshToken == null) {
        await storage.delete(key: 'refresh_token');
      }
    },
    loadTokens: () async {
      final accessToken = await storage.read(key: 'access_token');
      final refreshToken = await storage.read(key: 'refresh_token');
      if (accessToken != null) {
        return TokenPair(accessToken: accessToken, refreshToken: refreshToken);
      }
      return null;
    },
    onRefreshToken: (String? refreshToken) async {
      // Delegate ALL token refresh logic to the coordinator
      // This ensures consistent behavior across TokenManager, SyncEngine,
      // and TokenRefreshService
      AppLogger.debug(
        'TokenManager: onRefreshToken called, delegating to coordinator',
      );

      final result = await coordinator.refresh(source: 'TokenManager');

      if (!result.success) {
        throw Exception(result.error ?? 'Token refresh failed');
      }

      // The coordinator already updated our in-memory cache via setAccessToken()
      // Just return the token for the external package's expectations
      return result.accessToken!;
    },
    onLogout: () async {
      // Clear auth state when permanent error occurs
      await authRepo.logout();
    },
  );

  // CRITICAL: Set the TokenManager reference on the coordinator
  // This allows the coordinator to update our in-memory cache after refresh
  coordinator.setTokenManager(tokenManager);

  // Set TokenManager on SharedTokenService for unified access
  // This enables both foreground and background to use the same service
  SharedTokenService.instance.setTokenManager(tokenManager);

  ref.onDispose(() {
    tokenManager.dispose();
    SharedTokenService.instance.clearTokenManager();
  });

  return tokenManager;
});

/// Token refresh callback provider - uses the coordinator for consistent behavior
///
/// This callback can be passed to API clients that need a refresh callback.
/// It delegates to the TokenRefreshCoordinator to ensure consistent handling.
final tokenRefreshCallbackProvider = Provider<TokenRefreshCallback>((ref) {
  final coordinator = ref.watch(tokenRefreshCoordinatorProvider);

  return (String? refreshToken) async {
    final result = await coordinator.refresh(source: 'ApiClient');

    if (!result.success) {
      if (result.result == TokenRefreshResult.permanentError) {
        throw TokenRefreshPermanentException(
          result.error ?? 'Token refresh failed permanently',
        );
      }
      throw Exception(result.error ?? 'Token refresh failed');
    }

    return result.accessToken!;
  };
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

/// Auth headers provider for manual header injection
final authHeadersProvider = FutureProvider<connect.Headers>((ref) async {
  final tokenManager = ref.watch(tokenManagerProvider);
  final headers = connect.Headers();
  final token = tokenManager.accessToken;
  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
});

// ============================================================================
// Service Client Providers
// ============================================================================

/// Chat client provider - uses newChatClient with proper interceptors
final chatClientProvider = FutureProvider<ChatClient>((ref) async {
  final tokenManager = ref.watch(tokenManagerProvider);
  final onTokenRefresh = ref.watch(tokenRefreshCallbackProvider);
  final certificatePinning = ref.watch(certificatePinningProvider);

  // Initialize token manager if not already initialized
  await tokenManager.initialize();

  return newChatClient(
    createTransport: createTransportFactory(certificatePinning),
    endpoint: ApiConfig.chatBaseUrl,
    tokenManager: tokenManager,
    onTokenRefresh: onTokenRefresh,
  );
});

/// Gateway client provider - uses newGatewayClient with proper interceptors
final gatewayClientProvider = FutureProvider<GatewayClient>((ref) async {
  final tokenManager = ref.watch(tokenManagerProvider);
  final onTokenRefresh = ref.watch(tokenRefreshCallbackProvider);
  final certificatePinning = ref.watch(certificatePinningProvider);

  // Initialize token manager if not already initialized
  await tokenManager.initialize();

  return newGatewayClient(
    createTransport: createTransportFactory(certificatePinning),
    endpoint: ApiConfig.gatewayBaseUrl,
    tokenManager: tokenManager,
    onTokenRefresh: onTokenRefresh,
  );
});

/// Device client provider - uses newDeviceClient with proper interceptors
final deviceClientProvider = FutureProvider<DeviceClient>((ref) async {
  final tokenManager = ref.watch(tokenManagerProvider);
  final onTokenRefresh = ref.watch(tokenRefreshCallbackProvider);
  final certificatePinning = ref.watch(certificatePinningProvider);

  // Initialize token manager if not already initialized
  await tokenManager.initialize();

  return newDeviceClient(
    createTransport: createTransportFactory(certificatePinning),
    endpoint: ApiConfig.devicesBaseUrl,
    tokenManager: tokenManager,
    onTokenRefresh: onTokenRefresh,
  );
});

/// Profile client provider - uses newProfileClient with proper interceptors
final profileClientProvider = FutureProvider<ProfileClient>((ref) async {
  final tokenManager = ref.watch(tokenManagerProvider);
  final onTokenRefresh = ref.watch(tokenRefreshCallbackProvider);
  final certificatePinning = ref.watch(certificatePinningProvider);

  // Initialize token manager if not already initialized
  await tokenManager.initialize();

  return newProfileClient(
    createTransport: createTransportFactory(certificatePinning),
    endpoint: ApiConfig.profileBaseUrl,
    tokenManager: tokenManager,
    onTokenRefresh: onTokenRefresh,
  );
});

/// Files client provider - uses newFilesClient with proper interceptors
final filesClientProvider = FutureProvider<FilesClient>((ref) async {
  final tokenManager = ref.watch(tokenManagerProvider);
  final onTokenRefresh = ref.watch(tokenRefreshCallbackProvider);
  final certificatePinning = ref.watch(certificatePinningProvider);

  // Initialize token manager if not already initialized
  await tokenManager.initialize();

  return newFilesClient(
    createTransport: createTransportFactory(certificatePinning),
    endpoint: ApiConfig.filesBaseUrl,
    tokenManager: tokenManager,
    onTokenRefresh: onTokenRefresh,
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

// ============================================================================
// Helper Functions for Authenticated API Calls
// ============================================================================

/// Helper to get current auth headers for API calls
/// Usage: final headers = await ref.read(getAuthHeadersProvider.future);
final getAuthHeadersProvider = FutureProvider.autoDispose<connect.Headers>((
  ref,
) async {
  final tokenManager = ref.watch(tokenManagerProvider);
  final headers = connect.Headers();
  final token = tokenManager.accessToken;
  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
});

/// Reloads TokenManager from secure storage
///
/// IMPORTANT: Call this after login to ensure API clients have the new tokens.
/// After AuthService saves tokens to storage, TokenManager still has its old
/// (empty) in-memory cache. This method reloads from storage.
Future<void> reloadTokenManager(TokenManager tokenManager) async {
  AppLogger.debug('Reloading TokenManager from storage');
  await tokenManager.initialize();
  AppLogger.debug(
    'TokenManager reloaded',
    data: {'hasToken': tokenManager.accessToken != null},
  );
}
