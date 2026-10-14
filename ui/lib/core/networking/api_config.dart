import 'package:flutter/foundation.dart' show kDebugMode;

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
///   * `settlement.stawi.org`, `finance.stawi.org` — Stawi settlement (the
///     one chain writer: account and room calls) and finance (the read
///     model: rooms, members, statements).
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

  /// Whether the app offers the testnet faucet: staging builds, and local
  /// debug runs. Never production (settlement refuses it there anyway).
  static bool get testFundsEnabled =>
      environment == 'staging' || (environment.isEmpty && kDebugMode);

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

  /// Stawi settlement: builds every digest a device signs and relays the
  /// signed account and room calls to the chain.
  static const String settlementBaseUrl = String.fromEnvironment(
    'SETTLEMENT_URL',
    defaultValue: 'https://settlement.stawi.org',
  );

  /// The authentication service's Connect API (genesis session proofs). It
  /// is served on the accounts host, the same service as the sign-in pages.
  static const String authenticationBaseUrl = String.fromEnvironment(
    'AUTHENTICATION_URL',
    defaultValue: 'https://accounts.stawi.org',
  );

  /// Stawi finance: the read model (rooms, members, templates, statements).
  static const String financeBaseUrl = String.fromEnvironment(
    'FINANCE_URL',
    defaultValue: 'https://finance.stawi.org',
  );

  /// The chain the Stawi deployment is on (Sonic testnet by default). A key
  /// change the device signs is checked against it, never against the chain
  /// a prepared intent names.
  static const int stawiChainId = int.fromEnvironment(
    'STAWI_CHAIN_ID',
    defaultValue: 14601,
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

  /// Resource audiences the access token is requested for, comma-separated
  /// (e.g. the settlement and finance audiences). Empty requests none, which
  /// is what the app has always done; set it only once the OAuth2 client is
  /// allowed every audience listed, or sign-in is refused.
  static const String oauth2Audiences = String.fromEnvironment(
    'OAUTH2_AUDIENCES',
  );

  /// [oauth2Audiences] split into its entries.
  static List<String> get oauth2AudienceList => [
    for (final audience in oauth2Audiences.split(','))
      if (audience.trim().isNotEmpty) audience.trim(),
  ];

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
