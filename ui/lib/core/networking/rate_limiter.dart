import 'dart:async';
import 'dart:collection';

import '../logging/app_logger.dart';

/// Client-side rate limiter for API calls
///
/// Implements a token bucket algorithm to limit the rate of API requests:
/// - Prevents overwhelming the server with too many requests
/// - Provides backpressure during high-load scenarios
/// - Helps avoid rate limit errors from the server
///
/// Configuration:
/// - maxRequests: Maximum number of requests allowed per time window
/// - windowDuration: Time window for rate limiting (default: 1 minute)
/// - burstSize: Maximum burst size (default: same as maxRequests)
class RateLimiter {
  RateLimiter({
    required this.maxRequests,
    this.windowDuration = const Duration(minutes: 1),
    int? burstSize,
  }) : burstSize = burstSize ?? maxRequests;
  final int maxRequests;
  final Duration windowDuration;
  final int burstSize;

  final Queue<DateTime> _requestTimestamps = Queue<DateTime>();
  final _requestLock = Completer<void>()..complete();

  /// Wait for permission to make a request
  ///
  /// This method will:
  /// 1. Remove expired timestamps from the window
  /// 2. Check if we're within the rate limit
  /// 3. If over limit, wait until a slot becomes available
  /// 4. Record the new request timestamp
  Future<void> acquire() async {
    // Wait for any previous acquire to complete
    await _requestLock.future;

    final now = DateTime.now();
    final windowStart = now.subtract(windowDuration);

    // Remove timestamps outside the current window
    while (_requestTimestamps.isNotEmpty &&
        _requestTimestamps.first.isBefore(windowStart)) {
      _requestTimestamps.removeFirst();
    }

    // Check if we're at the limit
    if (_requestTimestamps.length >= maxRequests) {
      // Calculate how long to wait
      final oldestInWindow = _requestTimestamps.first;
      final waitTime = oldestInWindow.add(windowDuration).difference(now);

      if (waitTime.inMilliseconds > 0) {
        AppLogger.warning(
          'Rate limit reached, waiting ${waitTime.inMilliseconds}ms',
          data: {
            'maxRequests': maxRequests,
            'windowDuration': windowDuration.inSeconds,
            'currentRequests': _requestTimestamps.length,
          },
        );

        await Future.delayed(waitTime);

        // Recursively try again after waiting
        return acquire();
      }
    }

    // Record this request
    _requestTimestamps.add(now);
  }

  /// Get current request count in the window
  int get currentRequestCount {
    final now = DateTime.now();
    final windowStart = now.subtract(windowDuration);

    // Count requests within the window
    return _requestTimestamps.where((ts) => ts.isAfter(windowStart)).length;
  }

  /// Check if we can make a request without waiting
  bool canMakeRequest() {
    final now = DateTime.now();
    final windowStart = now.subtract(windowDuration);

    // Remove expired timestamps
    while (_requestTimestamps.isNotEmpty &&
        _requestTimestamps.first.isBefore(windowStart)) {
      _requestTimestamps.removeFirst();
    }

    return _requestTimestamps.length < maxRequests;
  }

  /// Reset the rate limiter
  void reset() {
    _requestTimestamps.clear();
  }
}

/// Preconfigured rate limiters for different services
class RateLimiters {
  /// Rate limiter for chat service
  /// 100 requests per minute (aggressive use)
  static final chat = RateLimiter(maxRequests: 100);

  /// Rate limiter for gateway service (streaming)
  /// More lenient since it's used for real-time sync
  static final gateway = RateLimiter(maxRequests: 200);

  /// Rate limiter for profile service
  /// 50 requests per minute (less frequent use)
  static final profile = RateLimiter(maxRequests: 50);

  /// Rate limiter for device service
  /// 30 requests per minute (infrequent use)
  static final device = RateLimiter(maxRequests: 30);

  /// Rate limiter for file uploads
  /// 20 requests per minute (heavy operations)
  static final files = RateLimiter(maxRequests: 20);
}
