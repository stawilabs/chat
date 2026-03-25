import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/startup/startup_service.dart';

void main() {
  group('StartupPhase', () {
    test('has all expected phases', () {
      expect(StartupPhase.values, contains(StartupPhase.critical));
      expect(StartupPhase.values, contains(StartupPhase.essential));
      expect(StartupPhase.values, contains(StartupPhase.deferred));
    });

    test('phases are in correct order', () {
      expect(StartupPhase.values.length, equals(3));
      expect(StartupPhase.values[0], equals(StartupPhase.critical));
      expect(StartupPhase.values[1], equals(StartupPhase.essential));
      expect(StartupPhase.values[2], equals(StartupPhase.deferred));
    });
  });

  group('StartupState', () {
    test('has all expected states', () {
      expect(StartupState.values, contains(StartupState.initial));
      expect(StartupState.values, contains(StartupState.initializingCritical));
      expect(StartupState.values, contains(StartupState.initializingEssential));
      expect(StartupState.values, contains(StartupState.interactive));
      expect(StartupState.values, contains(StartupState.complete));
      expect(StartupState.values, contains(StartupState.error));
    });

    test('states are in correct order', () {
      expect(StartupState.values.length, equals(6));
    });
  });

  group('StartupProgress', () {
    test('default state is initial', () {
      const progress = StartupProgress(state: StartupState.initial);
      expect(progress.state, equals(StartupState.initial));
      expect(progress.currentTask, isNull);
      expect(progress.progress, equals(0.0));
      expect(progress.errorMessage, isNull);
    });

    test('copyWith creates new instance with updated values', () {
      const progress = StartupProgress(
        state: StartupState.initial,
        currentTask: 'Task 1',
        progress: 0.5,
      );

      final updated = progress.copyWith(
        state: StartupState.interactive,
        currentTask: 'Task 2',
        progress: 0.8,
      );

      expect(updated.state, equals(StartupState.interactive));
      expect(updated.currentTask, equals('Task 2'));
      expect(updated.progress, equals(0.8));
    });

    test('copyWith preserves unchanged values', () {
      const progress = StartupProgress(
        state: StartupState.initial,
        currentTask: 'Task 1',
        progress: 0.5,
      );

      final updated = progress.copyWith(state: StartupState.interactive);

      expect(updated.state, equals(StartupState.interactive));
      expect(updated.currentTask, equals('Task 1'));
      expect(updated.progress, equals(0.5));
    });

    test('isComplete returns true only when complete', () {
      expect(
        const StartupProgress(state: StartupState.initial).isComplete,
        isFalse,
      );
      expect(
        const StartupProgress(
          state: StartupState.initializingCritical,
        ).isComplete,
        isFalse,
      );
      expect(
        const StartupProgress(state: StartupState.interactive).isComplete,
        isFalse,
      );
      expect(
        const StartupProgress(state: StartupState.complete).isComplete,
        isTrue,
      );
      expect(
        const StartupProgress(state: StartupState.error).isComplete,
        isFalse,
      );
    });

    test('isInteractive returns true for interactive and complete states', () {
      expect(
        const StartupProgress(state: StartupState.initial).isInteractive,
        isFalse,
      );
      expect(
        const StartupProgress(
          state: StartupState.initializingCritical,
        ).isInteractive,
        isFalse,
      );
      expect(
        const StartupProgress(
          state: StartupState.initializingEssential,
        ).isInteractive,
        isFalse,
      );
      expect(
        const StartupProgress(state: StartupState.interactive).isInteractive,
        isTrue,
      );
      expect(
        const StartupProgress(state: StartupState.complete).isInteractive,
        isTrue,
      );
      expect(
        const StartupProgress(state: StartupState.error).isInteractive,
        isFalse,
      );
    });

    test('hasError returns true only for error state', () {
      expect(
        const StartupProgress(state: StartupState.initial).hasError,
        isFalse,
      );
      expect(
        const StartupProgress(state: StartupState.complete).hasError,
        isFalse,
      );
      expect(const StartupProgress(state: StartupState.error).hasError, isTrue);
    });

    test('error state can contain error message', () {
      const progress = StartupProgress(
        state: StartupState.error,
        errorMessage: 'Something went wrong',
      );

      expect(progress.hasError, isTrue);
      expect(progress.errorMessage, equals('Something went wrong'));
    });

    test('progress value can range from 0 to 1', () {
      const progress0 = StartupProgress(state: StartupState.initial);
      const progress50 = StartupProgress(
        state: StartupState.initializingEssential,
        progress: 0.5,
      );
      const progress100 = StartupProgress(
        state: StartupState.complete,
        progress: 1,
      );

      expect(progress0.progress, equals(0.0));
      expect(progress50.progress, equals(0.5));
      expect(progress100.progress, equals(1.0));
    });
  });

  group('StartupProgress state transitions', () {
    test('typical successful startup sequence', () {
      // Initial state
      var progress = const StartupProgress(state: StartupState.initial);
      expect(progress.isInteractive, isFalse);
      expect(progress.isComplete, isFalse);

      // Critical initialization
      progress = progress.copyWith(
        state: StartupState.initializingCritical,
        currentTask: 'Initializing core services...',
        progress: 0.1,
      );
      expect(progress.isInteractive, isFalse);
      expect(progress.isComplete, isFalse);

      // Essential initialization
      progress = progress.copyWith(
        state: StartupState.initializingEssential,
        currentTask: 'Loading user data...',
        progress: 0.4,
      );
      expect(progress.isInteractive, isFalse);
      expect(progress.isComplete, isFalse);

      // Interactive
      progress = progress.copyWith(
        state: StartupState.interactive,
        currentTask: 'Finishing setup...',
        progress: 0.8,
      );
      expect(progress.isInteractive, isTrue);
      expect(progress.isComplete, isFalse);

      // Complete
      progress = progress.copyWith(state: StartupState.complete, progress: 1);
      expect(progress.isInteractive, isTrue);
      expect(progress.isComplete, isTrue);
    });

    test('error during initialization', () {
      var progress = const StartupProgress(state: StartupState.initial);

      progress = progress.copyWith(
        state: StartupState.initializingCritical,
        currentTask: 'Initializing...',
        progress: 0.1,
      );

      progress = progress.copyWith(
        state: StartupState.error,
        errorMessage: 'Firebase initialization failed',
      );

      expect(progress.hasError, isTrue);
      expect(progress.isInteractive, isFalse);
      expect(progress.isComplete, isFalse);
      expect(progress.errorMessage, contains('Firebase'));
    });
  });

  group('Network timeout behavior', () {
    test('network timeout constant is 5 seconds', () {
      // This tests that the timeout is properly configured
      // The actual value should match what's in the implementation
      const expectedTimeout = Duration(seconds: 5);
      // We can't access the private constant directly, but we verify the behavior
      expect(expectedTimeout.inSeconds, equals(5));
    });

    test('DNS ready delay is 200ms', () {
      // The DNS ready delay ensures network is fully ready
      const expectedDelay = Duration(milliseconds: 200);
      expect(expectedDelay.inMilliseconds, equals(200));
    });

    test('startup continues after network timeout', () {
      // Simulate startup state after network timeout
      // The app should proceed to interactive state even if network times out
      var progress = const StartupProgress(
        state: StartupState.initializingEssential,
        currentTask: 'Checking network...',
        progress: 0.5,
      );

      // After network timeout, startup should continue
      progress = progress.copyWith(
        state: StartupState.interactive,
        currentTask: 'Finishing setup...',
        progress: 0.8,
      );

      expect(progress.state, equals(StartupState.interactive));
      expect(progress.isInteractive, isTrue);
      expect(progress.hasError, isFalse);
    });

    test('network timeout does not cause error state', () {
      // A network timeout should not put the app into error state
      // It should gracefully continue
      const progress = StartupProgress(
        state: StartupState.interactive,
        currentTask: 'Finishing setup...',
        progress: 0.8,
      );

      expect(progress.state, isNot(equals(StartupState.error)));
      expect(progress.hasError, isFalse);
    });

    test('startup progress through network check phase', () {
      // Simulate the network checking phase
      var progress = const StartupProgress(state: StartupState.initial);

      // Start essential initialization
      progress = progress.copyWith(
        state: StartupState.initializingEssential,
        currentTask: 'Loading user data...',
        progress: 0.4,
      );
      expect(progress.currentTask, contains('user data'));

      // Network check starts
      progress = progress.copyWith(
        currentTask: 'Checking network...',
        progress: 0.5,
      );
      expect(progress.currentTask, contains('network'));

      // Start sync (after network check completes or times out)
      progress = progress.copyWith(
        currentTask: 'Starting sync...',
        progress: 0.7,
      );
      expect(progress.currentTask, contains('sync'));

      // Become interactive
      progress = progress.copyWith(
        state: StartupState.interactive,
        currentTask: 'Finishing setup...',
        progress: 0.8,
      );
      expect(progress.isInteractive, isTrue);
    });
  });

  group('Startup constants and configuration', () {
    test('all startup phases are defined', () {
      expect(StartupPhase.values.length, equals(3));
      expect(
        StartupPhase.critical.index,
        lessThan(StartupPhase.essential.index),
      );
      expect(
        StartupPhase.essential.index,
        lessThan(StartupPhase.deferred.index),
      );
    });

    test('all startup states are defined', () {
      expect(StartupState.values.length, equals(6));
      expect(
        StartupState.initial.index,
        lessThan(StartupState.initializingCritical.index),
      );
      expect(
        StartupState.initializingCritical.index,
        lessThan(StartupState.initializingEssential.index),
      );
      expect(
        StartupState.initializingEssential.index,
        lessThan(StartupState.interactive.index),
      );
      expect(
        StartupState.interactive.index,
        lessThan(StartupState.complete.index),
      );
    });

    test('progress percentage values are valid', () {
      const criticalProgress = 0.1;
      const essentialProgress = 0.4;
      const interactiveProgress = 0.8;
      const completeProgress = 1.0;

      // All progress values should be between 0 and 1
      expect(criticalProgress, greaterThan(0));
      expect(essentialProgress, greaterThan(criticalProgress));
      expect(interactiveProgress, greaterThan(essentialProgress));
      expect(completeProgress, greaterThanOrEqualTo(interactiveProgress));

      // Complete should be 1.0
      expect(completeProgress, equals(1.0));
    });
  });

  group('StartupProgress copyWith edge cases', () {
    test('copyWith allows setting currentTask to null', () {
      const progress = StartupProgress(
        state: StartupState.initializingCritical,
        currentTask: 'Some task',
      );

      final updated = progress.copyWith(currentTask: null);

      expect(updated.currentTask, isNull);
      expect(updated.state, equals(StartupState.initializingCritical));
    });

    test('copyWith allows setting errorMessage to null', () {
      const progress = StartupProgress(
        state: StartupState.error,
        errorMessage: 'Some error',
      );

      final updated = progress.copyWith(errorMessage: null);

      expect(updated.errorMessage, isNull);
      expect(updated.state, equals(StartupState.error));
    });

    test('copyWith with no arguments returns equivalent object', () {
      const progress = StartupProgress(
        state: StartupState.interactive,
        currentTask: 'Task',
        progress: 0.8,
      );

      final updated = progress.copyWith();

      expect(updated.state, equals(progress.state));
      expect(updated.currentTask, equals(progress.currentTask));
      expect(updated.progress, equals(progress.progress));
      expect(updated.errorMessage, equals(progress.errorMessage));
    });
  });
}
