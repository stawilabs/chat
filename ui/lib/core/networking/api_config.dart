/// API endpoint configuration for AntInvestor services
///
/// Each service has its own dedicated endpoint for optimal routing
/// and load balancing. Endpoints can be overridden at build time via
/// `--dart-define`, e.g.:
/// ```
/// flutter build web --dart-define=CHAT_URL=https://chat.stawi.im
/// ```
class ApiConfig {
  const ApiConfig._();

  // Service endpoints (configurable via --dart-define)
  static const String chatBaseUrl = String.fromEnvironment(
    'CHAT_URL',
    defaultValue: 'https://chat.stawi.im',
  );
  static const String gatewayBaseUrl = String.fromEnvironment(
    'GATEWAY_URL',
    defaultValue: 'https://gateway.stawi.im',
  );
  static const String devicesBaseUrl = String.fromEnvironment(
    'DEVICES_URL',
    defaultValue: 'https://api.stawi.im/devices',
  );
  static const String filesBaseUrl = String.fromEnvironment(
    'FILES_URL',
    defaultValue: 'https://api.stawi.im/files',
  );
  static const String profileBaseUrl = String.fromEnvironment(
    'PROFILE_URL',
    defaultValue: 'https://profile.stawi.org',
  );

  // OAuth2 configuration (configurable via --dart-define)
  static const String oauth2IssuerUrl = String.fromEnvironment(
    'OAUTH2_ISSUER_URL',
    defaultValue: 'https://oauth2.stawi.org',
  );
  static const String oauth2ClientId = String.fromEnvironment(
    'OAUTH2_CLIENT_ID',
    defaultValue: '9bsv0s0hijjg02qk7l1g',
  );

  // Connection settings optimized for low-resource devices
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration idleTimeout = Duration(seconds: 120);

  // Retry configuration
  static const int maxRetryAttempts = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);
  static const Duration maxRetryDelay = Duration(seconds: 30);

  // Batch sizes for low-resource optimization
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Cache configuration
  static const Duration cacheMaxAge = Duration(hours: 1);
  static const int maxCacheEntries = 100;
}
