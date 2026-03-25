import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/calls/domain/call_stats.dart';
import 'package:stawi/features/calls/services/turn_credentials_service.dart';

void main() {
  group('TurnCredentials', () {
    test('isExpired returns false for future expiry', () {
      final creds = TurnCredentials(
        url: 'turn:test.com:3478',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(creds.isExpired, isFalse);
    });

    test('isExpired returns true for past expiry', () {
      final creds = TurnCredentials(
        url: 'turn:test.com:3478',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(creds.isExpired, isTrue);
    });

    test('isExpired returns true when expiring within 5 minutes', () {
      final creds = TurnCredentials(
        url: 'turn:test.com:3478',
        expiresAt: DateTime.now().add(const Duration(minutes: 3)),
      );

      expect(creds.isExpired, isTrue);
    });

    test('isExpired returns false when more than 5 minutes until expiry', () {
      final creds = TurnCredentials(
        url: 'turn:test.com:3478',
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );

      expect(creds.isExpired, isFalse);
    });

    test('toIceServer returns correct structure with credentials', () {
      final creds = TurnCredentials(
        url: 'turn:example.com:3478',
        username: 'user',
        credential: 'pass',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      final iceServer = creds.toIceServer();

      expect(iceServer['urls'], equals('turn:example.com:3478'));
      expect(iceServer['username'], equals('user'));
      expect(iceServer['credential'], equals('pass'));
    });

    test('toIceServer returns structure without credentials when not set', () {
      final creds = TurnCredentials(
        url: 'stun:example.com:3478',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      final iceServer = creds.toIceServer();

      expect(iceServer['urls'], equals('stun:example.com:3478'));
      expect(iceServer.containsKey('username'), isFalse);
      expect(iceServer.containsKey('credential'), isFalse);
    });

    test('toIceServer returns only urls when username is null', () {
      final creds = TurnCredentials(
        url: 'turn:example.com:3478',
        credential: 'pass',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      final iceServer = creds.toIceServer();

      expect(iceServer['urls'], equals('turn:example.com:3478'));
      expect(iceServer.containsKey('username'), isFalse);
    });

    test('toIceServer returns only urls when credential is null', () {
      final creds = TurnCredentials(
        url: 'turn:example.com:3478',
        username: 'user',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      final iceServer = creds.toIceServer();

      expect(iceServer['urls'], equals('turn:example.com:3478'));
      expect(iceServer.containsKey('credential'), isFalse);
    });
  });

  group('TurnCredentialsService static servers', () {
    test('turnCredentialsServiceProvider is available', () {
      expect(turnCredentialsServiceProvider, isNotNull);
    });
  });

  group('CallQualityService BitrateConfig integration', () {
    test('excellent quality returns max bitrate', () {
      final bitrate = BitrateConfig.getRecommendedVideoBitrate(
        ConnectionQuality.excellent,
      );

      expect(bitrate, equals(BitrateConfig.maxVideoBitrate));
    });

    test('veryPoor quality returns reduced bitrate above minimum', () {
      final bitrate = BitrateConfig.getRecommendedVideoBitrate(
        ConnectionQuality.veryPoor,
      );

      // veryPoor returns 25% of max, which is above minimum
      final expectedBitrate = (BitrateConfig.maxVideoBitrate * 0.25).round();
      expect(bitrate, equals(expectedBitrate));
      expect(bitrate, greaterThanOrEqualTo(BitrateConfig.minVideoBitrate));
    });

    test('bitrate decreases as quality degrades', () {
      final excellent = BitrateConfig.getRecommendedVideoBitrate(
        ConnectionQuality.excellent,
      );
      final good = BitrateConfig.getRecommendedVideoBitrate(
        ConnectionQuality.good,
      );
      final fair = BitrateConfig.getRecommendedVideoBitrate(
        ConnectionQuality.fair,
      );
      final poor = BitrateConfig.getRecommendedVideoBitrate(
        ConnectionQuality.poor,
      );
      final veryPoor = BitrateConfig.getRecommendedVideoBitrate(
        ConnectionQuality.veryPoor,
      );

      expect(excellent, greaterThan(good));
      expect(good, greaterThan(fair));
      expect(fair, greaterThanOrEqualTo(poor));
      expect(poor, greaterThan(veryPoor));
    });

    test('frame rate for excellent quality is 30 fps', () {
      final fps = BitrateConfig.getRecommendedFrameRate(
        ConnectionQuality.excellent,
      );

      expect(fps, equals(30));
    });

    test('frame rate for veryPoor quality is minimum 10 fps', () {
      final fps = BitrateConfig.getRecommendedFrameRate(
        ConnectionQuality.veryPoor,
      );

      expect(fps, greaterThanOrEqualTo(10));
    });

    test('frame rate decreases as quality degrades', () {
      final excellent = BitrateConfig.getRecommendedFrameRate(
        ConnectionQuality.excellent,
      );
      final poor = BitrateConfig.getRecommendedFrameRate(
        ConnectionQuality.poor,
      );

      expect(excellent, greaterThan(poor));
    });
  });

  group('CallQualityService Quality Calculation', () {
    test('excellent quality for low RTT and no packet loss', () {
      final quality = CallStatsQuality.calculateQuality(
        roundTripTimeMs: 30,
        packetLossPercent: 0.5,
        jitterMs: 10,
      );

      expect(quality, equals(ConnectionQuality.excellent));
    });

    test('good quality for moderate RTT', () {
      final quality = CallStatsQuality.calculateQuality(
        roundTripTimeMs: 80,
        packetLossPercent: 1.5,
        jitterMs: 20,
      );

      expect(quality, equals(ConnectionQuality.good));
    });

    test('fair quality for higher RTT', () {
      final quality = CallStatsQuality.calculateQuality(
        roundTripTimeMs: 180,
        packetLossPercent: 3.5,
        jitterMs: 50,
      );

      expect(quality, equals(ConnectionQuality.fair));
    });

    test('poor quality for high RTT and packet loss', () {
      final quality = CallStatsQuality.calculateQuality(
        roundTripTimeMs: 350,
        packetLossPercent: 7,
        jitterMs: 100,
      );

      expect(quality, equals(ConnectionQuality.poor));
    });

    test('veryPoor quality for extreme conditions', () {
      final quality = CallStatsQuality.calculateQuality(
        roundTripTimeMs: 600,
        packetLossPercent: 15,
        jitterMs: 200,
      );

      expect(quality, equals(ConnectionQuality.veryPoor));
    });

    test('high packet loss alone causes veryPoor quality', () {
      final quality = CallStatsQuality.calculateQuality(
        roundTripTimeMs: 50,
        packetLossPercent: 20,
        jitterMs: 10,
      );

      expect(quality, equals(ConnectionQuality.veryPoor));
    });

    test('high RTT alone causes veryPoor quality', () {
      final quality = CallStatsQuality.calculateQuality(
        roundTripTimeMs: 600,
        packetLossPercent: 0.5,
        jitterMs: 10,
      );

      expect(quality, equals(ConnectionQuality.veryPoor));
    });
  });

  group('CallStats video quality assessment', () {
    test('isVideoQualityAcceptable true for excellent', () {
      const stats = CallStats(quality: ConnectionQuality.excellent);
      expect(stats.isVideoQualityAcceptable, isTrue);
    });

    test('isVideoQualityAcceptable true for good', () {
      const stats = CallStats(quality: ConnectionQuality.good);
      expect(stats.isVideoQualityAcceptable, isTrue);
    });

    test('isVideoQualityAcceptable true for fair', () {
      const stats = CallStats(quality: ConnectionQuality.fair);
      expect(stats.isVideoQualityAcceptable, isTrue);
    });

    test('isVideoQualityAcceptable false for poor', () {
      const stats = CallStats(quality: ConnectionQuality.poor);
      expect(stats.isVideoQualityAcceptable, isFalse);
    });

    test('isVideoQualityAcceptable false for veryPoor', () {
      const stats = CallStats(quality: ConnectionQuality.veryPoor);
      expect(stats.isVideoQualityAcceptable, isFalse);
    });
  });

  group('CallStats warning conditions', () {
    test('shouldShowWarning false for excellent quality', () {
      const stats = CallStats(quality: ConnectionQuality.excellent);
      expect(stats.shouldShowWarning, isFalse);
    });

    test('shouldShowWarning false for good quality', () {
      const stats = CallStats(quality: ConnectionQuality.good);
      expect(stats.shouldShowWarning, isFalse);
    });

    test('shouldShowWarning true for poor quality', () {
      const stats = CallStats(quality: ConnectionQuality.poor);
      expect(stats.shouldShowWarning, isTrue);
    });

    test('shouldShowWarning true for veryPoor quality', () {
      const stats = CallStats(quality: ConnectionQuality.veryPoor);
      expect(stats.shouldShowWarning, isTrue);
    });

    test('shouldShowWarning true when reconnecting', () {
      const stats = CallStats(
        quality: ConnectionQuality.good,
        isReconnecting: true,
      );
      expect(stats.shouldShowWarning, isTrue);
    });

    test('shouldShowWarning false when video disabled but quality is fair', () {
      // Note: shouldShowWarning only checks quality and isReconnecting,
      // not isVideoDisabledDueToPoorConnection (that's handled separately in UI)
      const stats = CallStats(
        quality: ConnectionQuality.fair,
        isVideoDisabledDueToPoorConnection: true,
      );
      expect(stats.shouldShowWarning, isFalse);
    });
  });

  group('CallStats description strings', () {
    test('qualityDescription for all levels', () {
      expect(
        const CallStats(
          quality: ConnectionQuality.excellent,
        ).qualityDescription,
        equals('Excellent'),
      );
      expect(
        const CallStats(quality: ConnectionQuality.good).qualityDescription,
        equals('Good'),
      );
      expect(
        const CallStats(quality: ConnectionQuality.fair).qualityDescription,
        equals('Fair'),
      );
      expect(
        const CallStats(quality: ConnectionQuality.poor).qualityDescription,
        equals('Poor'),
      );
      expect(
        const CallStats(quality: ConnectionQuality.veryPoor).qualityDescription,
        equals('Very Poor'),
      );
      expect(const CallStats().qualityDescription, equals('Checking...'));
    });

    test('latencyDescription for various RTT values', () {
      expect(
        const CallStats(roundTripTimeMs: 30).latencyDescription,
        equals('< 50ms'),
      );
      expect(
        const CallStats(roundTripTimeMs: 100).latencyDescription,
        equals('100ms'),
      );
      expect(
        const CallStats(roundTripTimeMs: 200).latencyDescription,
        equals('200ms (high)'),
      );
      expect(
        const CallStats(roundTripTimeMs: 400).latencyDescription,
        equals('400ms (very high)'),
      );
    });

    test('packetLossDescription for various loss values', () {
      expect(
        const CallStats(packetLossPercent: 0.5).packetLossDescription,
        equals('< 1%'),
      );
      expect(
        const CallStats(packetLossPercent: 2).packetLossDescription,
        equals('2.0%'),
      );
      expect(
        const CallStats(packetLossPercent: 4).packetLossDescription,
        equals('4.0% (high)'),
      );
      expect(
        const CallStats(packetLossPercent: 8).packetLossDescription,
        equals('8.0% (very high)'),
      );
    });
  });

  group('CallStats copyWith', () {
    test('copyWith updates specified fields', () {
      const original = CallStats(
        roundTripTimeMs: 50,
        quality: ConnectionQuality.good,
      );

      final updated = original.copyWith(
        roundTripTimeMs: 100,
        quality: ConnectionQuality.fair,
      );

      expect(updated.roundTripTimeMs, equals(100));
      expect(updated.quality, equals(ConnectionQuality.fair));
    });

    test('copyWith preserves unspecified fields', () {
      const original = CallStats(
        roundTripTimeMs: 50,
        jitterMs: 10,
        packetLossPercent: 1,
        quality: ConnectionQuality.good,
      );

      final updated = original.copyWith(quality: ConnectionQuality.fair);

      expect(updated.roundTripTimeMs, equals(50));
      expect(updated.jitterMs, equals(10));
      expect(updated.packetLossPercent, equals(1.0));
      expect(updated.quality, equals(ConnectionQuality.fair));
    });

    test('copyWith can update reconnection state', () {
      const original = CallStats();

      final updated = original.copyWith(
        isReconnecting: true,
        reconnectionAttempts: 2,
      );

      expect(updated.isReconnecting, isTrue);
      expect(updated.reconnectionAttempts, equals(2));
    });
  });

  group('Auto-reconnection behavior', () {
    test('default stats has zero reconnection attempts', () {
      const stats = CallStats();
      expect(stats.reconnectionAttempts, equals(0));
      expect(stats.isReconnecting, isFalse);
    });

    test('reconnection attempts can be incremented', () {
      const stats = CallStats();

      final attempt1 = stats.copyWith(
        isReconnecting: true,
        reconnectionAttempts: 1,
      );
      expect(attempt1.reconnectionAttempts, equals(1));
      expect(attempt1.isReconnecting, isTrue);

      final attempt2 = attempt1.copyWith(reconnectionAttempts: 2);
      expect(attempt2.reconnectionAttempts, equals(2));

      final attempt3 = attempt2.copyWith(reconnectionAttempts: 3);
      expect(attempt3.reconnectionAttempts, equals(3));
    });

    test('reconnection state can be cleared after successful reconnection', () {
      const reconnecting = CallStats(
        isReconnecting: true,
        reconnectionAttempts: 3,
        quality: ConnectionQuality.poor,
      );

      final reconnected = reconnecting.copyWith(
        isReconnecting: false,
        reconnectionAttempts: 0,
        quality: ConnectionQuality.good,
      );

      expect(reconnected.isReconnecting, isFalse);
      expect(reconnected.reconnectionAttempts, equals(0));
      expect(reconnected.quality, equals(ConnectionQuality.good));
    });

    test(
      'shouldShowWarning is true during reconnection regardless of quality',
      () {
        const reconnecting = CallStats(
          quality: ConnectionQuality.excellent,
          isReconnecting: true,
        );

        expect(reconnecting.shouldShowWarning, isTrue);
      },
    );

    test('reconnection tracking survives quality changes', () {
      const stats = CallStats(
        isReconnecting: true,
        reconnectionAttempts: 2,
        quality: ConnectionQuality.poor,
      );

      final updatedQuality = stats.copyWith(quality: ConnectionQuality.fair);

      expect(updatedQuality.isReconnecting, isTrue);
      expect(updatedQuality.reconnectionAttempts, equals(2));
    });

    test('simulated reconnection flow', () {
      // Start with good connection
      var stats = const CallStats(quality: ConnectionQuality.good);
      expect(stats.shouldShowWarning, isFalse);

      // Connection drops - start reconnecting
      stats = stats.copyWith(
        isReconnecting: true,
        reconnectionAttempts: 1,
        quality: ConnectionQuality.veryPoor,
      );
      expect(stats.shouldShowWarning, isTrue);
      expect(stats.isReconnecting, isTrue);

      // Attempt 2
      stats = stats.copyWith(reconnectionAttempts: 2);
      expect(stats.reconnectionAttempts, equals(2));

      // Attempt 3
      stats = stats.copyWith(reconnectionAttempts: 3);
      expect(stats.reconnectionAttempts, equals(3));

      // Successful reconnection
      stats = stats.copyWith(
        isReconnecting: false,
        reconnectionAttempts: 0,
        quality: ConnectionQuality.good,
      );
      expect(stats.shouldShowWarning, isFalse);
      expect(stats.isReconnecting, isFalse);
    });
  });

  group('Video disable behavior', () {
    test('default stats has video not disabled', () {
      const stats = CallStats();
      expect(stats.isVideoDisabledDueToPoorConnection, isFalse);
    });

    test('video disabled flag can be set', () {
      const stats = CallStats();

      final disabled = stats.copyWith(isVideoDisabledDueToPoorConnection: true);

      expect(disabled.isVideoDisabledDueToPoorConnection, isTrue);
    });

    test('video disabled flag can be cleared', () {
      const disabled = CallStats(isVideoDisabledDueToPoorConnection: true);

      final enabled = disabled.copyWith(
        isVideoDisabledDueToPoorConnection: false,
      );

      expect(enabled.isVideoDisabledDueToPoorConnection, isFalse);
    });

    test('video disabled when quality is poor or veryPoor', () {
      // Excellent quality - video should be acceptable
      const excellent = CallStats(quality: ConnectionQuality.excellent);
      expect(excellent.isVideoQualityAcceptable, isTrue);

      // Good quality - video should be acceptable
      const good = CallStats(quality: ConnectionQuality.good);
      expect(good.isVideoQualityAcceptable, isTrue);

      // Fair quality - video should be acceptable
      const fair = CallStats(quality: ConnectionQuality.fair);
      expect(fair.isVideoQualityAcceptable, isTrue);

      // Poor quality - video not acceptable
      const poor = CallStats(quality: ConnectionQuality.poor);
      expect(poor.isVideoQualityAcceptable, isFalse);

      // Very poor quality - video not acceptable
      const veryPoor = CallStats(quality: ConnectionQuality.veryPoor);
      expect(veryPoor.isVideoQualityAcceptable, isFalse);
    });

    test('video disable flow when quality degrades', () {
      // Start with excellent quality and video enabled
      var stats = const CallStats(quality: ConnectionQuality.excellent);
      expect(stats.isVideoQualityAcceptable, isTrue);

      // Quality degrades to good - still acceptable
      stats = stats.copyWith(quality: ConnectionQuality.good);
      expect(stats.isVideoQualityAcceptable, isTrue);

      // Quality degrades to fair - still acceptable
      stats = stats.copyWith(quality: ConnectionQuality.fair);
      expect(stats.isVideoQualityAcceptable, isTrue);

      // Quality degrades to poor - should disable video
      stats = stats.copyWith(
        quality: ConnectionQuality.poor,
        isVideoDisabledDueToPoorConnection: true,
      );
      expect(stats.isVideoQualityAcceptable, isFalse);
      expect(stats.isVideoDisabledDueToPoorConnection, isTrue);
    });

    test('video re-enable flow when quality improves', () {
      // Start with poor quality and video disabled
      var stats = const CallStats(
        quality: ConnectionQuality.poor,
        isVideoDisabledDueToPoorConnection: true,
      );
      expect(stats.isVideoQualityAcceptable, isFalse);
      expect(stats.isVideoDisabledDueToPoorConnection, isTrue);

      // Quality improves to fair - video now acceptable
      stats = stats.copyWith(quality: ConnectionQuality.fair);
      expect(stats.isVideoQualityAcceptable, isTrue);
      // Note: isVideoDisabledDueToPoorConnection may still be true until UI re-enables

      // UI re-enables video
      stats = stats.copyWith(isVideoDisabledDueToPoorConnection: false);
      expect(stats.isVideoQualityAcceptable, isTrue);
      expect(stats.isVideoDisabledDueToPoorConnection, isFalse);
    });

    test('video disable state persists through other stat updates', () {
      const stats = CallStats(
        quality: ConnectionQuality.poor,
        isVideoDisabledDueToPoorConnection: true,
        roundTripTimeMs: 300,
      );

      // Update RTT but preserve video disabled state
      final updated = stats.copyWith(roundTripTimeMs: 350);

      expect(updated.isVideoDisabledDueToPoorConnection, isTrue);
      expect(updated.roundTripTimeMs, equals(350));
    });
  });

  group('Combined reconnection and video disable scenarios', () {
    test('both reconnecting and video disabled during severe conditions', () {
      const stats = CallStats(
        quality: ConnectionQuality.veryPoor,
        isReconnecting: true,
        reconnectionAttempts: 2,
        isVideoDisabledDueToPoorConnection: true,
      );

      expect(stats.isReconnecting, isTrue);
      expect(stats.isVideoDisabledDueToPoorConnection, isTrue);
      expect(stats.shouldShowWarning, isTrue);
      expect(stats.isVideoQualityAcceptable, isFalse);
    });

    test('recovery sequence: reconnection then video re-enable', () {
      // Start with severe conditions
      var stats = const CallStats(
        quality: ConnectionQuality.veryPoor,
        isReconnecting: true,
        reconnectionAttempts: 3,
        isVideoDisabledDueToPoorConnection: true,
      );

      // Phase 1: Reconnection succeeds but quality still poor
      stats = stats.copyWith(
        isReconnecting: false,
        quality: ConnectionQuality.poor,
      );
      expect(stats.isReconnecting, isFalse);
      expect(stats.isVideoDisabledDueToPoorConnection, isTrue);
      expect(stats.shouldShowWarning, isTrue); // Poor quality shows warning

      // Phase 2: Quality improves to fair
      stats = stats.copyWith(quality: ConnectionQuality.fair);
      expect(stats.isVideoQualityAcceptable, isTrue);
      expect(stats.shouldShowWarning, isFalse);

      // Phase 3: Video can be re-enabled and reconnection attempts reset
      stats = stats.copyWith(
        isVideoDisabledDueToPoorConnection: false,
        reconnectionAttempts: 0,
      );
      expect(stats.isVideoDisabledDueToPoorConnection, isFalse);
      expect(stats.reconnectionAttempts, equals(0));
    });

    test('quality fluctuation with video disable hysteresis', () {
      // Excellent -> poor -> fair -> excellent
      var stats = const CallStats(quality: ConnectionQuality.excellent);
      expect(stats.isVideoQualityAcceptable, isTrue);

      // Drop to poor - disable video
      stats = stats.copyWith(
        quality: ConnectionQuality.poor,
        isVideoDisabledDueToPoorConnection: true,
      );
      expect(stats.isVideoQualityAcceptable, isFalse);

      // Improve to fair - video acceptable but still marked disabled
      stats = stats.copyWith(quality: ConnectionQuality.fair);
      expect(stats.isVideoQualityAcceptable, isTrue);
      expect(stats.isVideoDisabledDueToPoorConnection, isTrue);

      // Improve to excellent - can now safely re-enable
      stats = stats.copyWith(
        quality: ConnectionQuality.excellent,
        isVideoDisabledDueToPoorConnection: false,
      );
      expect(stats.isVideoQualityAcceptable, isTrue);
      expect(stats.isVideoDisabledDueToPoorConnection, isFalse);
    });
  });

  group('Edge cases', () {
    test('default quality in stats is unknown', () {
      const stats = CallStats();
      // Default quality is unknown (not null), indicated by 'Checking...'
      expect(stats.quality, equals(ConnectionQuality.unknown));
      expect(stats.qualityDescription, equals('Checking...'));
    });

    test('all stat values can be set to zero', () {
      const stats = CallStats();

      expect(stats.roundTripTimeMs, equals(0));
      expect(stats.jitterMs, equals(0));
      expect(stats.packetLossPercent, equals(0));
      expect(stats.reconnectionAttempts, equals(0));
    });

    test('maximum reconnection attempts value', () {
      const stats = CallStats(reconnectionAttempts: 100);
      expect(stats.reconnectionAttempts, equals(100));
    });

    test('extreme RTT and packet loss values', () {
      const stats = CallStats(
        roundTripTimeMs: 10000,
        packetLossPercent: 100,
        jitterMs: 5000,
      );

      expect(stats.roundTripTimeMs, equals(10000));
      expect(stats.packetLossPercent, equals(100));
      expect(stats.jitterMs, equals(5000));
      expect(stats.latencyDescription, contains('very high'));
      expect(stats.packetLossDescription, contains('very high'));
    });
  });
}
