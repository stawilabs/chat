import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_stats.freezed.dart';
part 'call_stats.g.dart';

/// Connection quality levels
enum ConnectionQuality {
  /// Excellent connection (< 50ms latency, < 1% packet loss)
  excellent,

  /// Good connection (50-150ms latency, 1-3% packet loss)
  good,

  /// Fair connection (150-300ms latency, 3-5% packet loss)
  fair,

  /// Poor connection (> 300ms latency or > 5% packet loss)
  poor,

  /// Very poor or disconnected
  veryPoor,

  /// Unknown (insufficient data)
  unknown,
}

/// Represents WebRTC call statistics
@freezed
abstract class CallStats with _$CallStats {
  const factory CallStats({
    /// Round-trip time in milliseconds
    @Default(0) double roundTripTimeMs,

    /// Jitter in milliseconds
    @Default(0) double jitterMs,

    /// Packet loss percentage (0-100)
    @Default(0) double packetLossPercent,

    /// Available outgoing bandwidth in bits per second
    @Default(0) int availableBandwidthBps,

    /// Current video bitrate in bits per second
    @Default(0) int videoBitrateBps,

    /// Current audio bitrate in bits per second
    @Default(0) int audioBitrateBps,

    /// Frames per second being sent
    @Default(0) double framesSentPerSecond,

    /// Frames per second being received
    @Default(0) double framesReceivedPerSecond,

    /// Video resolution width being sent
    @Default(0) int videoWidthSent,

    /// Video resolution height being sent
    @Default(0) int videoHeightSent,

    /// Video resolution width being received
    @Default(0) int videoWidthReceived,

    /// Video resolution height being received
    @Default(0) int videoHeightReceived,

    /// Total bytes sent
    @Default(0) int bytesSent,

    /// Total bytes received
    @Default(0) int bytesReceived,

    /// Number of packets sent
    @Default(0) int packetsSent,

    /// Number of packets received
    @Default(0) int packetsReceived,

    /// Number of packets lost
    @Default(0) int packetsLost,

    /// Timestamp when stats were collected
    DateTime? timestamp,

    /// Connection quality derived from stats
    @Default(ConnectionQuality.unknown) ConnectionQuality quality,

    /// Whether video is currently disabled due to poor connection
    @Default(false) bool isVideoDisabledDueToPoorConnection,

    /// Whether reconnection is in progress
    @Default(false) bool isReconnecting,

    /// Reconnection attempt count
    @Default(0) int reconnectionAttempts,
  }) = _CallStats;
  const CallStats._();

  factory CallStats.fromJson(Map<String, dynamic> json) =>
      _$CallStatsFromJson(json);

  /// Check if connection quality is acceptable for video
  bool get isVideoQualityAcceptable =>
      quality == ConnectionQuality.excellent ||
      quality == ConnectionQuality.good ||
      quality == ConnectionQuality.fair;

  /// Check if connection quality requires warning
  bool get shouldShowWarning =>
      quality == ConnectionQuality.poor ||
      quality == ConnectionQuality.veryPoor ||
      isReconnecting;

  /// Human-readable quality description
  String get qualityDescription {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 'Excellent';
      case ConnectionQuality.good:
        return 'Good';
      case ConnectionQuality.fair:
        return 'Fair';
      case ConnectionQuality.poor:
        return 'Poor';
      case ConnectionQuality.veryPoor:
        return 'Very Poor';
      case ConnectionQuality.unknown:
        return 'Checking...';
    }
  }

  /// Human-readable latency description
  String get latencyDescription {
    if (roundTripTimeMs < 50) return '< 50ms';
    if (roundTripTimeMs < 150) return '${roundTripTimeMs.round()}ms';
    if (roundTripTimeMs < 300) return '${roundTripTimeMs.round()}ms (high)';
    return '${roundTripTimeMs.round()}ms (very high)';
  }

  /// Human-readable packet loss description
  String get packetLossDescription {
    if (packetLossPercent < 1) return '< 1%';
    if (packetLossPercent < 3) {
      return '${packetLossPercent.toStringAsFixed(1)}%';
    }
    if (packetLossPercent < 5) {
      return '${packetLossPercent.toStringAsFixed(1)}% (high)';
    }
    return '${packetLossPercent.toStringAsFixed(1)}% (very high)';
  }
}

/// Extension for calculating quality from stats
extension CallStatsQuality on CallStats {
  /// Calculate connection quality based on latency, packet loss, and jitter
  static ConnectionQuality calculateQuality({
    required double roundTripTimeMs,
    required double packetLossPercent,
    required double jitterMs,
  }) {
    // Very poor: disconnected-level metrics (include jitter for stability check)
    if (packetLossPercent > 15 || roundTripTimeMs > 500 || jitterMs > 200) {
      return ConnectionQuality.veryPoor;
    }

    // Poor: noticeably degraded experience
    if (packetLossPercent > 5 || roundTripTimeMs > 300 || jitterMs > 100) {
      return ConnectionQuality.poor;
    }

    // Fair: some degradation but usable
    if (packetLossPercent > 3 || roundTripTimeMs > 150 || jitterMs > 50) {
      return ConnectionQuality.fair;
    }

    // Good: minor issues that don't affect experience
    if (packetLossPercent > 1 || roundTripTimeMs > 50 || jitterMs > 20) {
      return ConnectionQuality.good;
    }

    // Excellent: optimal conditions
    return ConnectionQuality.excellent;
  }
}

/// Bitrate limits for adaptive streaming
class BitrateConfig {
  /// Minimum video bitrate in bps
  static const int minVideoBitrate = 100000; // 100 Kbps

  /// Maximum video bitrate in bps
  static const int maxVideoBitrate = 2500000; // 2.5 Mbps

  /// Target audio bitrate in bps
  static const int audioBitrate = 64000; // 64 Kbps

  /// Bitrate reduction factor when quality is poor
  static const double poorQualityReductionFactor = 0.5;

  /// Bitrate reduction factor when quality is very poor
  static const double veryPoorQualityReductionFactor = 0.25;

  /// Get recommended video bitrate based on quality
  ///
  /// Returns a bitrate clamped between [minVideoBitrate] and [maxVideoBitrate]
  /// to ensure video remains usable even in degraded conditions.
  static int getRecommendedVideoBitrate(ConnectionQuality quality) {
    final bitrate = switch (quality) {
      ConnectionQuality.excellent => maxVideoBitrate,
      ConnectionQuality.good => (maxVideoBitrate * 0.8).round(),
      ConnectionQuality.fair => (maxVideoBitrate * 0.5).round(),
      ConnectionQuality.poor =>
        (maxVideoBitrate * poorQualityReductionFactor).round(),
      ConnectionQuality.veryPoor =>
        (maxVideoBitrate * veryPoorQualityReductionFactor).round(),
      ConnectionQuality.unknown => (maxVideoBitrate * 0.5).round(),
    };
    // Clamp to ensure we never go below minimum bitrate
    return bitrate.clamp(minVideoBitrate, maxVideoBitrate);
  }

  /// Get recommended frame rate based on quality
  static int getRecommendedFrameRate(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 30;
      case ConnectionQuality.good:
        return 24;
      case ConnectionQuality.fair:
        return 15;
      case ConnectionQuality.poor:
      case ConnectionQuality.veryPoor:
        return 10;
      case ConnectionQuality.unknown:
        return 15;
    }
  }
}
