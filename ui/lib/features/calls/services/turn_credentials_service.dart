import 'package:antinvestor_api_device/antinvestor_api_device.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/networking/client.dart';
import '../../../core/storage/key_manager.dart';

/// Provider for TURN credentials service
final turnCredentialsServiceProvider = FutureProvider<TurnCredentialsService>((
  ref,
) async {
  final deviceClient = await ref.watch(deviceServiceClientProvider.future);
  final keyManager = ref.watch(keyManagerProvider);
  return TurnCredentialsService(deviceClient, keyManager);
});

/// Cached TURN server credentials
class TurnCredentials {
  TurnCredentials({
    required this.url,
    required this.expiresAt,
    this.username,
    this.credential,
  });
  final String url;
  final String? username;
  final String? credential;
  final DateTime expiresAt;

  /// Check if credentials are expired or about to expire (within 5 minutes)
  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));

  /// Convert to WebRTC ICE server configuration
  Map<String, dynamic> toIceServer() {
    if (username != null && credential != null) {
      return {'urls': url, 'username': username, 'credential': credential};
    }
    return {'urls': url};
  }
}

/// Service for managing TURN server credentials
///
/// Handles:
/// - Fetching TURN credentials from backend
/// - Caching credentials with TTL
/// - Credential refresh before expiry
/// - Fallback to STUN if TURN unavailable
class TurnCredentialsService {
  TurnCredentialsService(this._deviceClient, this._keyManager);

  final DeviceServiceClient _deviceClient;
  final KeyManager _keyManager;

  /// Cached TURN credentials
  List<TurnCredentials>? _cachedCredentials;

  /// Default STUN servers for fallback
  static const List<Map<String, dynamic>> _defaultStunServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
    {'urls': 'stun:stun3.l.google.com:19302'},
    {'urls': 'stun:stun4.l.google.com:19302'},
  ];

  /// Public TURN servers for testing/development
  /// These provide relay functionality when direct connections fail
  static const List<Map<String, dynamic>> _publicTurnServers = [
    // OpenRelay public TURN server (metered.ca)
    {
      'urls': 'turn:openrelay.metered.ca:80',
      'username': 'openrelayproject',
      'credential': 'openrelayproject',
    },
    {
      'urls': 'turn:openrelay.metered.ca:443',
      'username': 'openrelayproject',
      'credential': 'openrelayproject',
    },
    {
      'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
      'username': 'openrelayproject',
      'credential': 'openrelayproject',
    },
  ];

  /// Get ICE server configuration for WebRTC
  ///
  /// Returns a configuration map with:
  /// - STUN servers (always included for fallback)
  /// - TURN servers with dynamic credentials (if available)
  ///
  /// Example:
  /// ```dart
  /// final config = await turnService.getIceServers();
  /// _peerConnection = await createPeerConnection(config);
  /// ```
  Future<Map<String, dynamic>> getIceServers() async {
    final iceServers = <Map<String, dynamic>>[];

    // Always include STUN servers for fallback
    iceServers.addAll(_defaultStunServers);

    try {
      // Get TURN credentials
      final turnCredentials = await _getTurnCredentials();

      if (turnCredentials.isNotEmpty) {
        // Add TURN servers with API credentials
        for (final cred in turnCredentials) {
          iceServers.add(cred.toIceServer());
        }

        AppLogger.info(
          'ICE servers configured with TURN',
          data: {'turnServerCount': turnCredentials.length},
        );
      } else {
        // Use public TURN servers as fallback
        iceServers.addAll(_publicTurnServers);
        AppLogger.info(
          'Using public TURN servers',
          data: {'turnServerCount': _publicTurnServers.length},
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get TURN credentials',
        error: e,
        stackTrace: stackTrace,
      );
      // Continue with STUN-only configuration
    }

    return {'iceServers': iceServers};
  }

  /// Get TURN credentials, using cache if valid
  Future<List<TurnCredentials>> _getTurnCredentials() async {
    // Check if cached credentials are still valid
    if (_cachedCredentials != null && _cachedCredentials!.isNotEmpty) {
      final allValid = _cachedCredentials!.every((c) => !c.isExpired);
      if (allValid) {
        AppLogger.debug('Using cached TURN credentials');
        return _cachedCredentials!;
      }
    }

    // Fetch fresh credentials
    _cachedCredentials = await _fetchTurnCredentials();
    return _cachedCredentials!;
  }

  /// Fetch TURN credentials from the backend
  ///
  /// Calls the Device API to get temporary TURN credentials.
  /// The backend generates short-lived HMAC-based credentials (RFC 5766).
  Future<List<TurnCredentials>> _fetchTurnCredentials() async {
    try {
      final deviceId = await _keyManager.getDeviceId();
      final request = GetTurnCredentialsRequest(deviceId: deviceId);
      final response = await _deviceClient.getTurnCredentials(request);

      final credentials = response.servers.map((server) {
        final expiresAtSeconds = server.expiresAt.toInt();
        return TurnCredentials(
          url: server.url,
          username: server.username.isNotEmpty ? server.username : null,
          credential: server.credential.isNotEmpty ? server.credential : null,
          expiresAt: DateTime.fromMillisecondsSinceEpoch(
            expiresAtSeconds * 1000,
          ),
        );
      }).toList();

      AppLogger.info(
        'Fetched TURN credentials from API',
        data: {
          'serverCount': credentials.length,
          'ttlSeconds': response.ttlSeconds,
        },
      );

      return credentials;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching TURN credentials from API',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Force refresh of cached credentials
  ///
  /// Call this when experiencing connection issues that might
  /// be caused by expired credentials
  Future<void> refreshCredentials() async {
    _cachedCredentials = null;
    await _getTurnCredentials();
  }

  /// Clear cached credentials (call on logout)
  void clearCache() {
    _cachedCredentials = null;
    AppLogger.debug('TURN credentials cache cleared');
  }
}
