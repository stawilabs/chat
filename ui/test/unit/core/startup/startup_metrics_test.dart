import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/startup/startup_metrics.dart';

void main() {
  group('StartupMetrics', () {
    late StartupMetrics metrics;

    setUp(() {
      metrics = StartupMetrics.instance;
      metrics.reset();
    });

    test('is a singleton', () {
      final instance1 = StartupMetrics.instance;
      final instance2 = StartupMetrics.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('timeSinceStart returns positive duration', () {
      expect(metrics.timeSinceStart.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('startPhase and endPhase track duration', () async {
      metrics.startPhase('test_phase');
      await Future.delayed(const Duration(milliseconds: 50));
      metrics.endPhase('test_phase');

      final duration = metrics.getPhaseDuration('test_phase');
      expect(duration, isNotNull);
      expect(duration!.inMilliseconds, greaterThanOrEqualTo(50));
    });

    test('getPhaseDuration returns null for unknown phase', () {
      expect(metrics.getPhaseDuration('unknown'), isNull);
    });

    test('allPhaseDurations returns unmodifiable map', () {
      metrics.startPhase('phase1');
      metrics.endPhase('phase1');

      final durations = metrics.allPhaseDurations;
      expect(durations, isNotEmpty);
      expect(() => (durations as Map).clear(), throwsUnsupportedError);
    });

    test('markFirstFrame records time to first frame', () {
      expect(metrics.timeToFirstFrame, isNull);

      metrics.markFirstFrame();

      expect(metrics.timeToFirstFrame, isNotNull);
      expect(metrics.timeToFirstFrame!.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('markInteractive records time to interactive', () {
      expect(metrics.timeToInteractive, isNull);

      metrics.markInteractive();

      expect(metrics.timeToInteractive, isNotNull);
      expect(
        metrics.timeToInteractive!.inMilliseconds,
        greaterThanOrEqualTo(0),
      );
    });

    test('markFullyLoaded records time to fully loaded', () {
      expect(metrics.timeToFullyLoaded, isNull);

      metrics.markFullyLoaded();

      expect(metrics.timeToFullyLoaded, isNotNull);
      expect(
        metrics.timeToFullyLoaded!.inMilliseconds,
        greaterThanOrEqualTo(0),
      );
    });

    test('coldStartTargetMet returns false when not interactive', () {
      expect(metrics.coldStartTargetMet, isFalse);
    });

    test('coldStartTargetMet returns true for fast startup', () {
      // Since we just started, time to interactive should be < 2s
      metrics.markInteractive();
      expect(metrics.coldStartTargetMet, isTrue);
    });

    test('warmStartTargetMet returns true for fast resume', () {
      expect(
        metrics.warmStartTargetMet(const Duration(milliseconds: 400)),
        isTrue,
      );
    });

    test('warmStartTargetMet returns false for slow resume', () {
      expect(
        metrics.warmStartTargetMet(const Duration(milliseconds: 600)),
        isFalse,
      );
    });

    test('reset clears all metrics', () {
      metrics.startPhase('test');
      metrics.endPhase('test');
      metrics.markFirstFrame();
      metrics.markInteractive();
      metrics.markFullyLoaded();

      metrics.reset();

      expect(metrics.allPhaseDurations, isEmpty);
      expect(metrics.timeToFirstFrame, isNull);
      expect(metrics.timeToInteractive, isNull);
      expect(metrics.timeToFullyLoaded, isNull);
    });

    test('multiple phases can be tracked', () {
      metrics.startPhase('phase1');
      metrics.endPhase('phase1');

      metrics.startPhase('phase2');
      metrics.endPhase('phase2');

      metrics.startPhase('phase3');
      metrics.endPhase('phase3');

      expect(metrics.allPhaseDurations.length, equals(3));
      expect(metrics.getPhaseDuration('phase1'), isNotNull);
      expect(metrics.getPhaseDuration('phase2'), isNotNull);
      expect(metrics.getPhaseDuration('phase3'), isNotNull);
    });
  });
}
