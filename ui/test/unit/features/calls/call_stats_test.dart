import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/calls/domain/call_stats.dart';

void main() {
  group('ConnectionQuality', () {
    test('has all expected quality levels', () {
      expect(ConnectionQuality.values, contains(ConnectionQuality.excellent));
      expect(ConnectionQuality.values, contains(ConnectionQuality.good));
      expect(ConnectionQuality.values, contains(ConnectionQuality.fair));
      expect(ConnectionQuality.values, contains(ConnectionQuality.poor));
      expect(ConnectionQuality.values, contains(ConnectionQuality.veryPoor));
      expect(ConnectionQuality.values, contains(ConnectionQuality.unknown));
    });

    test('quality levels are ordered from best to worst', () {
      expect(
        ConnectionQuality.excellent.index,
        lessThan(ConnectionQuality.good.index),
      );
      expect(
        ConnectionQuality.good.index,
        lessThan(ConnectionQuality.fair.index),
      );
      expect(
        ConnectionQuality.fair.index,
        lessThan(ConnectionQuality.poor.index),
      );
      expect(
        ConnectionQuality.poor.index,
        lessThan(ConnectionQuality.veryPoor.index),
      );
    });
  });

  group('CallStats', () {
    test('default values are correct', () {
      const stats = CallStats();

      expect(stats.roundTripTimeMs, equals(0));
      expect(stats.jitterMs, equals(0));
      expect(stats.packetLossPercent, equals(0));
      expect(stats.quality, equals(ConnectionQuality.unknown));
      expect(stats.isVideoDisabledDueToPoorConnection, isFalse);
      expect(stats.isReconnecting, isFalse);
      expect(stats.reconnectionAttempts, equals(0));
    });

    test('copyWith creates updated instance', () {
      const stats = CallStats(
        roundTripTimeMs: 50,
        quality: ConnectionQuality.good,
      );

      final updated = stats.copyWith(
        roundTripTimeMs: 100,
        quality: ConnectionQuality.fair,
      );

      expect(updated.roundTripTimeMs, equals(100));
      expect(updated.quality, equals(ConnectionQuality.fair));
    });

    test('isVideoQualityAcceptable returns true for good qualities', () {
      expect(
        const CallStats(
          quality: ConnectionQuality.excellent,
        ).isVideoQualityAcceptable,
        isTrue,
      );
      expect(
        const CallStats(
          quality: ConnectionQuality.good,
        ).isVideoQualityAcceptable,
        isTrue,
      );
      expect(
        const CallStats(
          quality: ConnectionQuality.fair,
        ).isVideoQualityAcceptable,
        isTrue,
      );
    });

    test('isVideoQualityAcceptable returns false for poor qualities', () {
      expect(
        const CallStats(
          quality: ConnectionQuality.poor,
        ).isVideoQualityAcceptable,
        isFalse,
      );
      expect(
        const CallStats(
          quality: ConnectionQuality.veryPoor,
        ).isVideoQualityAcceptable,
        isFalse,
      );
    });

    test('shouldShowWarning returns true for poor quality', () {
      expect(
        const CallStats(quality: ConnectionQuality.poor).shouldShowWarning,
        isTrue,
      );
      expect(
        const CallStats(quality: ConnectionQuality.veryPoor).shouldShowWarning,
        isTrue,
      );
    });

    test('shouldShowWarning returns true when reconnecting', () {
      expect(
        const CallStats(
          quality: ConnectionQuality.good,
          isReconnecting: true,
        ).shouldShowWarning,
        isTrue,
      );
    });

    test(
      'shouldShowWarning returns false for good quality and not reconnecting',
      () {
        expect(
          const CallStats(
            quality: ConnectionQuality.excellent,
          ).shouldShowWarning,
          isFalse,
        );
        expect(
          const CallStats(quality: ConnectionQuality.good).shouldShowWarning,
          isFalse,
        );
      },
    );

    test('qualityDescription returns correct strings', () {
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

    test('latencyDescription formats correctly', () {
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

    test('packetLossDescription formats correctly', () {
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

  group('CallStatsQuality.calculateQuality', () {
    test('returns excellent for low latency and no packet loss', () {
      final quality = CallStatsQuality.calculateQuality(
        roundTripTimeMs: 30,
        packetLossPercent: 0.5,
        jitterMs: 10,
      );
      expect(quality, equals(ConnectionQuality.excellent));
    });

    test('returns good for moderate metrics', () {
      final quality = CallStatsQuality.calculateQuality(
        roundTripTimeMs: 80,
        packetLossPercent: 1.5,
        jitterMs: 25,
      );
      expect(quality, equals(ConnectionQuality.good));
    });

    test('returns fair for elevated metrics', () {
      final quality = CallStatsQuality.calculateQuality(
        roundTripTimeMs: 200,
        packetLossPercent: 4,
        jitterMs: 60,
      );
      expect(quality, equals(ConnectionQuality.fair));
    });

    test('returns poor for high metrics', () {
      final quality = CallStatsQuality.calculateQuality(
        roundTripTimeMs: 350,
        packetLossPercent: 7,
        jitterMs: 120,
      );
      expect(quality, equals(ConnectionQuality.poor));
    });

    test('returns veryPoor for very high packet loss', () {
      final quality = CallStatsQuality.calculateQuality(
        roundTripTimeMs: 100,
        packetLossPercent: 20,
        jitterMs: 30,
      );
      expect(quality, equals(ConnectionQuality.veryPoor));
    });

    test('returns veryPoor for very high latency', () {
      final quality = CallStatsQuality.calculateQuality(
        roundTripTimeMs: 600,
        packetLossPercent: 2,
        jitterMs: 30,
      );
      expect(quality, equals(ConnectionQuality.veryPoor));
    });
  });

  group('BitrateConfig', () {
    test('minVideoBitrate is reasonable', () {
      expect(BitrateConfig.minVideoBitrate, greaterThan(0));
      expect(
        BitrateConfig.minVideoBitrate,
        lessThan(BitrateConfig.maxVideoBitrate),
      );
    });

    test('maxVideoBitrate allows HD video', () {
      // HD video typically needs 1.5-4 Mbps
      expect(BitrateConfig.maxVideoBitrate, greaterThanOrEqualTo(1500000));
    });

    test('audioBitrate is reasonable for voice', () {
      // Good voice quality is 32-128 Kbps
      expect(BitrateConfig.audioBitrate, greaterThanOrEqualTo(32000));
      expect(BitrateConfig.audioBitrate, lessThanOrEqualTo(128000));
    });

    test('getRecommendedVideoBitrate returns max for excellent', () {
      expect(
        BitrateConfig.getRecommendedVideoBitrate(ConnectionQuality.excellent),
        equals(BitrateConfig.maxVideoBitrate),
      );
    });

    test('getRecommendedVideoBitrate decreases with worse quality', () {
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

    test('getRecommendedVideoBitrate never returns below minimum', () {
      for (final quality in ConnectionQuality.values) {
        final bitrate = BitrateConfig.getRecommendedVideoBitrate(quality);
        expect(bitrate, greaterThanOrEqualTo(BitrateConfig.minVideoBitrate));
      }
    });

    test('getRecommendedFrameRate returns 30 for excellent', () {
      expect(
        BitrateConfig.getRecommendedFrameRate(ConnectionQuality.excellent),
        equals(30),
      );
    });

    test('getRecommendedFrameRate decreases with worse quality', () {
      final excellent = BitrateConfig.getRecommendedFrameRate(
        ConnectionQuality.excellent,
      );
      final poor = BitrateConfig.getRecommendedFrameRate(
        ConnectionQuality.poor,
      );

      expect(excellent, greaterThan(poor));
    });

    test('getRecommendedFrameRate is at least 10 fps', () {
      for (final quality in ConnectionQuality.values) {
        final fps = BitrateConfig.getRecommendedFrameRate(quality);
        expect(fps, greaterThanOrEqualTo(10));
      }
    });
  });
}
