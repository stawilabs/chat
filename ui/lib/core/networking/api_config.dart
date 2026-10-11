/// API endpoint configuration — the single source of endpoint truth.
///
/// Every service URL the app calls is defined here and nowhere else. Builds
/// set them per environment with `--dart-define-from-file=env/<env>.json`
/// (see `ui/env/`), and any single value can still be overridden with
/// `--dart-define`, e.g.:
/// ```
/// flutter build apk --dart-define-from-file=env/production.json
/// flutter run --dart-define=CHAT_URL=http://localhost:8080
/// ```
///
/// Hosts (must match the platform's public exposure):
///   * `api.stawi.org/<path>` — Cloud Run product APIs behind the Cloudflare
///     path gateway (profile, devices, files, ...).
///   * `chat.stawi.org`, `gateway.stawi.org` — the chat drone and the
///     streaming gateway on the Kubernetes cluster (Gateway API routes).
///
/// `env/staging.json` points at the production backends: there is no
/// separate staging backend for chat. Secrets (`SENTRY_DSN`,
/// `OAUTH2_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID`) are never put in the env
/// files; CI passes them with `--dart-define`.
class ApiConfig {
  const ApiConfig._();

  /// Build environment label (`staging` or `production`), set by the env
  /// file. Empty for local runs. Used for telemetry tagging only.
  static const String environment = String.fromEnvironment('APP_ENVIRONMENT');

  /// Unified product API origin (Cloudflare path gateway).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.stawi.org',
  );

  // Service endpoints (configurable via --dart-define)
  static const String chatBaseUrl = String.fromEnvironment(
    'CHAT_URL',
    defaultValue: 'https://chat.stawi.org',
  );
  static const String gatewayBaseUrl = String.fromEnvironment(
    'GATEWAY_URL',
    defaultValue: 'https://gateway.stawi.org',
  );
  static const String devicesBaseUrl = String.fromEnvironment(
    'DEVICES_URL',
    defaultValue: 'https://api.stawi.org/devices',
  );
  static const String filesBaseUrl = String.fromEnvironment(
    'FILES_URL',
    defaultValue: 'https://api.stawi.org/files',
  );
  static const String profileBaseUrl = String.fromEnvironment(
    'PROFILE_URL',
    defaultValue: 'https://api.stawi.org/profile',
  );

  // OAuth2 configuration (configurable via --dart-define)
  static const String oauth2IssuerUrl = String.fromEnvironment(
    'OAUTH2_ISSUER_URL',
    defaultValue: 'https://oauth2.stawi.org',
  );
  static const String oauth2ClientId = String.fromEnvironment(
    'OAUTH2_CLIENT_ID',
    defaultValue: 'd6qbqdkpf2t52mcunf40',
  );
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '265397001887-hjrrjml6ekekmrjlg4ku4bsgtobgid85.apps.googleusercontent.com',
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

  // Calling configuration
  static const bool allowPublicTurnFallback = bool.fromEnvironment(
    'ALLOW_PUBLIC_TURN_FALLBACK',
  );
  static const int groupCallMeshMaxParticipants = int.fromEnvironment(
    'GROUP_CALL_MESH_MAX_PARTICIPANTS',
    defaultValue: 6,
  );
  static const int groupCallMaxVideoPublishers = int.fromEnvironment(
    'GROUP_CALL_MAX_VIDEO_PUBLISHERS',
    defaultValue: 5,
  );
}
