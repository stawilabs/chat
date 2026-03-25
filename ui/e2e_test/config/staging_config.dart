/// Staging environment configuration for E2E tests.
///
/// All sensitive values are loaded from environment variables to ensure
/// security and flexibility across different CI/CD environments.
library;

/// Configuration for the staging environment.
class StagingConfig {
  /// Private constructor to prevent instantiation.
  StagingConfig._();

  /// Base URL for the gateway service.
  static String get gatewayUrl => const String.fromEnvironment(
    'E2E_GATEWAY_URL',
    defaultValue: 'https://gateway.staging.antinvestor.com',
  );

  /// Base URL for the chat service.
  static String get chatUrl => const String.fromEnvironment(
    'E2E_CHAT_URL',
    defaultValue: 'https://chat.staging.antinvestor.com',
  );

  /// Base URL for the profile service.
  static String get profileUrl => const String.fromEnvironment(
    'E2E_PROFILE_URL',
    defaultValue: 'https://profile.staging.antinvestor.com',
  );

  /// Base URL for the auth service (OAuth2/OIDC issuer).
  static String get authUrl => const String.fromEnvironment(
    'E2E_AUTH_URL',
    defaultValue: 'https://auth.staging.antinvestor.com',
  );

  /// OAuth2 client ID for E2E tests.
  static String get oauthClientId => const String.fromEnvironment(
    'E2E_OAUTH_CLIENT_ID',
    defaultValue: 'e2e-test-client',
  );

  /// Whether to use mock services instead of real staging.
  static bool get useMocks => const bool.fromEnvironment('E2E_USE_MOCKS');
}

/// Timeout constants for E2E test operations.
class TestTimeouts {
  /// Private constructor to prevent instantiation.
  TestTimeouts._();

  /// Timeout for authentication operations (login, token refresh).
  static const Duration authTimeout = Duration(seconds: 30);

  /// Timeout for sync connection establishment.
  static const Duration syncTimeout = Duration(seconds: 60);

  /// Timeout for message delivery (send to receive acknowledgment).
  static const Duration messageDeliveryTimeout = Duration(seconds: 15);

  /// Timeout for sync operations (initial sync, catch-up sync).
  static const Duration syncOperationTimeout = Duration(minutes: 2);

  /// Timeout for media upload operations.
  static const Duration mediaUploadTimeout = Duration(minutes: 3);

  /// Timeout for database operations.
  static const Duration databaseTimeout = Duration(seconds: 10);

  /// Short timeout for UI interactions.
  static const Duration uiInteractionTimeout = Duration(seconds: 5);

  /// Default test timeout for individual test cases.
  static const Duration defaultTestTimeout = Duration(minutes: 5);
}

/// Performance thresholds for E2E performance tests.
class PerformanceThresholds {
  /// Private constructor to prevent instantiation.
  PerformanceThresholds._();

  /// Maximum acceptable cold start time in milliseconds.
  ///
  /// Cold start includes app launch, dependency injection, and initial render.
  static const int maxColdStartMs = 3000;

  /// Maximum acceptable warm start time in milliseconds.
  static const int maxWarmStartMs = 1000;

  /// Maximum acceptable database initialization time in milliseconds.
  static const int maxDatabaseInitMs = 500;

  /// Maximum acceptable startup time in milliseconds (total).
  static const int maxStartupMs = 5000;

  /// Maximum P95 latency for message delivery in milliseconds.
  ///
  /// 95th percentile of message send-to-delivery time.
  static const int maxP95LatencyMs = 2000;

  /// Maximum P99 latency for message delivery in milliseconds.
  static const int maxP99LatencyMs = 5000;

  /// Minimum messages per second throughput for burst tests.
  static const double minMessagesPerSecond = 10;

  /// Maximum memory usage increase during messaging (MB).
  static const int maxMemoryIncreasePerMessageMb = 1;

  /// Maximum acceptable frame drop rate (percentage).
  static const double maxFrameDropRate = 5;

  /// Minimum frame rate during scrolling (FPS).
  static const int minScrollFps = 55;
}
