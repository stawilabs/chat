import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/call_stats.dart';

/// Service for monitoring and managing call quality
class CallQualityService {
  CallQualityService({
    required RTCPeerConnection peerConnection,
    required this.onStatsUpdate,
    required this.onVideoStateChange,
    required this.onReconnectNeeded,
    required this.onWarning,
  }) : _peerConnection = peerConnection;
  static const Duration _statsInterval = Duration(seconds: 2);
  static const Duration _reconnectTimeout = Duration(seconds: 30);
  static const int _maxReconnectAttempts = 5;

  final RTCPeerConnection _peerConnection;
  final void Function(CallStats) onStatsUpdate;
  final void Function(bool videoEnabled) onVideoStateChange;
  final void Function() onReconnectNeeded;
  final void Function(String message) onWarning;

  Timer? _statsTimer;
  CallStats _currentStats = const CallStats();
  ConnectionQuality _previousQuality = ConnectionQuality.unknown;
  bool _isVideoEnabled = true;
  bool _isAutoVideoDisabled = false;
  int _reconnectAttempts = 0;
  DateTime? _reconnectStartTime;

  // Stats tracking for delta calculations
  int _lastBytesSent = 0;
  int _lastBytesReceived = 0;
  // ignore: unused_field - reserved for future packet rate calculations
  int _lastPacketsSent = 0;
  // ignore: unused_field - reserved for future packet rate calculations
  int _lastPacketsReceived = 0;
  // ignore: unused_field - reserved for future packet loss rate tracking
  int _lastPacketsLost = 0;
  DateTime? _lastStatsTime;

  /// Current call statistics
  CallStats get currentStats => _currentStats;

  /// Whether video is currently enabled
  bool get isVideoEnabled => _isVideoEnabled && !_isAutoVideoDisabled;

  /// Start monitoring call quality
  void start() {
    AppLogger.info('CallQualityService started');
    _statsTimer = Timer.periodic(_statsInterval, (_) => _collectStats());
    // Collect initial stats immediately
    _collectStats();
  }

  /// Stop monitoring
  void stop() {
    AppLogger.info('CallQualityService stopped');
    _statsTimer?.cancel();
    _statsTimer = null;
    _reconnectAttempts = 0;
    _reconnectStartTime = null;
  }

  /// Force collect stats immediately
  Future<void> refreshStats() async {
    await _collectStats();
  }

  /// Manually enable/disable video
  void setVideoEnabled(bool enabled) {
    _isVideoEnabled = enabled;
    if (enabled && _isAutoVideoDisabled) {
      // User wants video, but it was auto-disabled
      // Check if quality allows it
      if (_currentStats.isVideoQualityAcceptable) {
        _isAutoVideoDisabled = false;
        onVideoStateChange(true);
      } else {
        onWarning('Video disabled due to poor connection');
      }
    } else if (!enabled) {
      onVideoStateChange(false);
    }
  }

  /// Notify that reconnection started
  void notifyReconnectStarted() {
    if (_reconnectStartTime == null) {
      _reconnectStartTime = DateTime.now();
      _reconnectAttempts++;
      _currentStats = _currentStats.copyWith(
        isReconnecting: true,
        reconnectionAttempts: _reconnectAttempts,
      );
      onStatsUpdate(_currentStats);
      AppLogger.info('Reconnection attempt $_reconnectAttempts started');
    }
  }

  /// Notify that reconnection completed
  void notifyReconnectCompleted(bool success) {
    if (success) {
      _reconnectAttempts = 0;
      _reconnectStartTime = null;
      _currentStats = _currentStats.copyWith(
        isReconnecting: false,
        reconnectionAttempts: 0,
      );
      onStatsUpdate(_currentStats);
      AppLogger.info('Reconnection successful');
    } else {
      final elapsed = _reconnectStartTime != null
          ? DateTime.now().difference(_reconnectStartTime!)
          : Duration.zero;

      if (elapsed > _reconnectTimeout ||
          _reconnectAttempts >= _maxReconnectAttempts) {
        AppLogger.warning(
          'Reconnection failed after $_reconnectAttempts attempts',
        );
        _currentStats = _currentStats.copyWith(
          isReconnecting: false,
          quality: ConnectionQuality.veryPoor,
        );
        onStatsUpdate(_currentStats);
      }
    }
  }

  Future<void> _collectStats() async {
    try {
      final stats = await _peerConnection.getStats();
      if (stats.isEmpty) return;

      double roundTripTime = 0;
      double jitter = 0;
      var packetsLost = 0;
      var packetsSent = 0;
      var packetsReceived = 0;
      var bytesSent = 0;
      var bytesReceived = 0;
      var videoWidthSent = 0;
      var videoHeightSent = 0;
      var videoWidthReceived = 0;
      var videoHeightReceived = 0;
      double framesPerSecondSent = 0;
      double framesPerSecondReceived = 0;

      for (final report in stats) {
        final type = report.type;
        final values = report.values;

        switch (type) {
          case 'candidate-pair':
            if (values['state'] == 'succeeded') {
              roundTripTime =
                  (values['currentRoundTripTime'] as num? ?? 0).toDouble() *
                  1000;
            }
            break;

          case 'inbound-rtp':
            if (values['mediaType'] == 'video' || values['kind'] == 'video') {
              packetsReceived += (values['packetsReceived'] as num? ?? 0)
                  .toInt();
              packetsLost += (values['packetsLost'] as num? ?? 0).toInt();
              bytesReceived += (values['bytesReceived'] as num? ?? 0).toInt();
              jitter = (values['jitter'] as num? ?? 0).toDouble() * 1000;
              if (values['frameWidth'] != null) {
                videoWidthReceived = (values['frameWidth'] as num).toInt();
                videoHeightReceived = (values['frameHeight'] as num? ?? 0)
                    .toInt();
              }
              framesPerSecondReceived = (values['framesPerSecond'] as num? ?? 0)
                  .toDouble();
            } else if (values['mediaType'] == 'audio' ||
                values['kind'] == 'audio') {
              packetsReceived += (values['packetsReceived'] as num? ?? 0)
                  .toInt();
              packetsLost += (values['packetsLost'] as num? ?? 0).toInt();
              bytesReceived += (values['bytesReceived'] as num? ?? 0).toInt();
              if (jitter == 0) {
                jitter = (values['jitter'] as num? ?? 0).toDouble() * 1000;
              }
            }
            break;

          case 'outbound-rtp':
            if (values['mediaType'] == 'video' || values['kind'] == 'video') {
              packetsSent += (values['packetsSent'] as num? ?? 0).toInt();
              bytesSent += (values['bytesSent'] as num? ?? 0).toInt();
              if (values['frameWidth'] != null) {
                videoWidthSent = (values['frameWidth'] as num).toInt();
                videoHeightSent = (values['frameHeight'] as num? ?? 0).toInt();
              }
              framesPerSecondSent = (values['framesPerSecond'] as num? ?? 0)
                  .toDouble();
            } else if (values['mediaType'] == 'audio' ||
                values['kind'] == 'audio') {
              packetsSent += (values['packetsSent'] as num? ?? 0).toInt();
              bytesSent += (values['bytesSent'] as num? ?? 0).toInt();
            }
            break;
        }
      }

      // Calculate packet loss percentage
      final totalPackets = packetsSent + packetsReceived;
      final packetLossPercent = totalPackets > 0
          ? (packetsLost / totalPackets) * 100
          : 0.0;

      // Calculate bitrate from deltas
      var videoBitrate = 0;
      var audioBitrate = 0;
      final now = DateTime.now();
      if (_lastStatsTime != null) {
        final elapsed = now.difference(_lastStatsTime!).inSeconds;
        if (elapsed > 0) {
          final bytesDelta =
              (bytesSent - _lastBytesSent) +
              (bytesReceived - _lastBytesReceived);
          final bitrate = (bytesDelta * 8) ~/ elapsed;
          // Rough split between video and audio
          videoBitrate = (bitrate * 0.9).round();
          audioBitrate = (bitrate * 0.1).round();
        }
      }

      // Update tracking values
      _lastBytesSent = bytesSent;
      _lastBytesReceived = bytesReceived;
      _lastPacketsSent = packetsSent;
      _lastPacketsReceived = packetsReceived;
      _lastPacketsLost = packetsLost;
      _lastStatsTime = now;

      // Calculate quality
      final quality = CallStatsQuality.calculateQuality(
        roundTripTimeMs: roundTripTime,
        packetLossPercent: packetLossPercent,
        jitterMs: jitter,
      );

      // Update stats
      _currentStats = CallStats(
        roundTripTimeMs: roundTripTime,
        jitterMs: jitter,
        packetLossPercent: packetLossPercent,
        videoBitrateBps: videoBitrate,
        audioBitrateBps: audioBitrate,
        framesSentPerSecond: framesPerSecondSent,
        framesReceivedPerSecond: framesPerSecondReceived,
        videoWidthSent: videoWidthSent,
        videoHeightSent: videoHeightSent,
        videoWidthReceived: videoWidthReceived,
        videoHeightReceived: videoHeightReceived,
        bytesSent: bytesSent,
        bytesReceived: bytesReceived,
        packetsSent: packetsSent,
        packetsReceived: packetsReceived,
        packetsLost: packetsLost,
        timestamp: now,
        quality: quality,
        isVideoDisabledDueToPoorConnection: _isAutoVideoDisabled,
        isReconnecting: _currentStats.isReconnecting,
        reconnectionAttempts: _reconnectAttempts,
      );

      // Handle quality changes
      _handleQualityChange(quality);

      onStatsUpdate(_currentStats);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to collect call stats',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleQualityChange(ConnectionQuality quality) {
    // Only trigger actions on quality transitions
    if (quality == _previousQuality) return;

    AppLogger.info(
      'Call quality changed',
      data: {'from': _previousQuality.name, 'to': quality.name},
    );

    // Handle degradation
    if (_shouldDowngrade(quality)) {
      _handleQualityDegradation(quality);
    }

    // Handle improvement
    if (_shouldUpgrade(quality)) {
      _handleQualityImprovement(quality);
    }

    _previousQuality = quality;
  }

  bool _shouldDowngrade(ConnectionQuality quality) {
    final previousIndex = _previousQuality.index;
    final currentIndex = quality.index;
    // Higher index = worse quality
    return currentIndex > previousIndex;
  }

  bool _shouldUpgrade(ConnectionQuality quality) {
    final previousIndex = _previousQuality.index;
    final currentIndex = quality.index;
    return currentIndex < previousIndex;
  }

  void _handleQualityDegradation(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.poor:
        onWarning('Connection quality is poor');
        _considerDisablingVideo();
        break;

      case ConnectionQuality.veryPoor:
        onWarning('Connection quality is very poor');
        _disableVideoForPoorConnection();
        break;

      default:
        break;
    }
  }

  void _handleQualityImprovement(ConnectionQuality quality) {
    // Consider re-enabling video if quality improves
    if (_isAutoVideoDisabled &&
        _isVideoEnabled &&
        (quality == ConnectionQuality.good ||
            quality == ConnectionQuality.excellent)) {
      _enableVideoAfterImprovement();
    }
  }

  void _considerDisablingVideo() {
    // Only auto-disable if enabled and quality stays poor
    if (_isVideoEnabled && !_isAutoVideoDisabled) {
      // We'll disable on the next poor reading if it persists
      AppLogger.debug('Considering disabling video due to poor quality');
    }
  }

  void _disableVideoForPoorConnection() {
    if (_isVideoEnabled && !_isAutoVideoDisabled) {
      _isAutoVideoDisabled = true;
      onVideoStateChange(false);
      onWarning('Video disabled due to poor connection. Audio only.');
      AppLogger.info('Video auto-disabled due to poor connection');
    }
  }

  void _enableVideoAfterImprovement() {
    _isAutoVideoDisabled = false;
    onVideoStateChange(true);
    AppLogger.info('Video re-enabled after connection improvement');
  }

  /// Get recommended bitrate based on current quality
  int getRecommendedVideoBitrate() {
    return BitrateConfig.getRecommendedVideoBitrate(_currentStats.quality);
  }

  /// Get recommended frame rate based on current quality
  int getRecommendedFrameRate() {
    return BitrateConfig.getRecommendedFrameRate(_currentStats.quality);
  }

  /// Dispose resources
  void dispose() {
    stop();
  }
}
