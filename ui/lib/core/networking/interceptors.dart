import 'package:connectrpc/connect.dart' as connect;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../logging/app_logger.dart';
import 'network_optimizer.dart';

/// Auth interceptor for Connect RPC
/// Provides JWT authorization headers for all API calls
class AuthInterceptor {
  AuthInterceptor(this._storage);
  final FlutterSecureStorage _storage;
  String? _cachedToken;
  DateTime? _cacheTime;
  static const _cacheValidDuration = Duration(seconds: 30);

  /// Get auth headers with token caching for performance
  /// Caches token for 30 seconds to reduce secure storage reads
  /// Includes optimization headers for compression and keep-alive
  Future<connect.Headers> getAuthHeaders() async {
    final headers = connect.Headers();

    // Add optimization headers from centralized constant
    NetworkOptimizer.optimizedHeaders.forEach((key, value) {
      headers[key] = value;
    });

    // Check if cached token is still valid
    final now = DateTime.now();
    if (_cachedToken != null &&
        _cacheTime != null &&
        now.difference(_cacheTime!) < _cacheValidDuration) {
      headers['Authorization'] = 'Bearer $_cachedToken';
      return headers;
    }

    // Read fresh token
    final token = await _storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      _cachedToken = token;
      _cacheTime = now;
      headers['Authorization'] = 'Bearer $token';
      AppLogger.debug('Auth headers refreshed');
    }
    return headers;
  }

  /// Invalidate the cached token (call after logout or token refresh)
  void invalidateCache() {
    _cachedToken = null;
    _cacheTime = null;
  }
}

/// Helper class for tracking bandwidth usage
/// Can be used to manually track request/response sizes
class BandwidthTrackingHelper {
  BandwidthTrackingHelper(this._tracker);
  final BandwidthTracker _tracker;

  /// Track bytes sent in a request
  void trackRequest(int requestSize) {
    _tracker.recordSent(requestSize);
  }

  /// Track bytes received in a response
  void trackResponse(int responseSize) {
    _tracker.recordReceived(responseSize);
  }

  /// Estimate size from a protobuf message
  ///
  /// For protobuf messages, uses writeToBuffer() to get accurate byte size.
  /// Falls back to UTF-8 encoded length for strings and raw length for bytes.
  static int estimateMessageSize(Object? message) {
    if (message == null) return 0;
    if (message is List<int>) return message.length;
    if (message is String) return message.codeUnits.length;

    // For protobuf GeneratedMessage, serialize to get actual byte size
    // Using dynamic to avoid hard dependency on protobuf package
    try {
      // ignore: avoid_dynamic_calls
      final buffer = (message as dynamic).writeToBuffer() as List<int>?;
      if (buffer != null) return buffer.length;
    } catch (_) {
      // Not a protobuf message or serialization failed
    }

    // Fallback: estimate using JSON-like string representation
    // This is less accurate but provides a reasonable approximation
    return message.toString().codeUnits.length;
  }
}

/// Helper for request deduplication
/// Use with NetworkOptimizer.deduplicator for deduplicated API calls
class DeduplicationHelper {
  /// Generate a unique key for a request based on method and parameters
  ///
  /// Uses protobuf serialization for reliable deduplication of identical requests.
  /// Falls back to string representation for non-protobuf objects.
  static String generateRequestKey(String method, Object? message) {
    if (message == null) return method;

    // For protobuf messages, use serialized bytes for reliable deduplication
    // Using dynamic to avoid hard dependency on protobuf package
    try {
      // ignore: avoid_dynamic_calls
      final buffer = (message as dynamic).writeToBuffer() as List<int>?;
      if (buffer != null) {
        // Use first 32 bytes for key to keep it reasonably sized
        final truncated = buffer.length > 32 ? buffer.sublist(0, 32) : buffer;
        return '$method:${truncated.join(',')}';
      }
    } catch (_) {
      // Not a protobuf message
    }

    // Fallback: use string representation (better than hashCode)
    final stringRep = message.toString();
    // Truncate long strings to prevent overly long keys
    final truncated = stringRep.length > 100
        ? stringRep.substring(0, 100)
        : stringRep;
    return '$method:$truncated';
  }
}
