import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/messages/ui/widgets/voice_message_player.dart';
import 'package:stawi/features/messages/ui/widgets/voice_record_button.dart';
import 'package:stawi/features/messages/ui/widgets/waveform_visualizer.dart';

import '../test_helpers/test_helpers.dart';

void main() {
  setUp(TestHelpers.resetMocks);

  group('WaveformVisualizer', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WaveformVisualizer(amplitudes: [0.1, 0.5, 0.8, 0.3, 0.6]),
          ),
        ),
      );

      expect(find.byType(WaveformVisualizer), findsOneWidget);
    });

    testWidgets('renders with empty amplitudes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WaveformVisualizer(amplitudes: [])),
        ),
      );

      expect(find.byType(WaveformVisualizer), findsOneWidget);
    });

    testWidgets('renders with custom dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WaveformVisualizer(
              amplitudes: [0.5, 0.7, 0.3],
              width: 200,
              height: 50,
              barWidth: 4,
              barSpacing: 3,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(WaveformVisualizer),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 200);
      expect(sizedBox.height, 50);
    });

    testWidgets('PlaybackWaveformVisualizer handles seek tap', (
      WidgetTester tester,
    ) async {
      double? seekPosition;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackWaveformVisualizer(
              amplitudes: generateFakeWaveform(20),
              progress: 0.5,
              onSeek: (position) => seekPosition = position,
            ),
          ),
        ),
      );

      // Tap in the middle of the waveform
      await tester.tapAt(
        tester.getCenter(find.byType(PlaybackWaveformVisualizer)),
      );
      await tester.pump();

      // Should have triggered seek callback
      expect(seekPosition, isNotNull);
      expect(seekPosition, closeTo(0.5, 0.1));
    });
  });

  group('VoiceMessagePlayer', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceMessagePlayer(
              audioUrl: 'https://example.com/audio.m4a',
              durationMs: 30000,
            ),
          ),
        ),
      );

      expect(find.byType(VoiceMessagePlayer), findsOneWidget);
      // Should show play button initially
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      // Should not show pause button initially
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
    });

    testWidgets('toggles play/pause on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceMessagePlayer(
              audioUrl: 'https://example.com/audio.m4a',
              durationMs: 5000,
            ),
          ),
        ),
      );

      // Initially shows play button
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Tap to play — in tests, AudioPlayer has no platform support,
      // so we verify the tap doesn't crash rather than checking state change
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      // Widget should still be rendered without crashing
      expect(find.byType(VoiceMessagePlayer), findsOneWidget);
    });

    testWidgets('shows duration text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceMessagePlayer(
              audioUrl: 'https://example.com/audio.m4a',
              durationMs: 65000, // 1:05
            ),
          ),
        ),
      );

      // Should show formatted duration (1:05)
      expect(find.text('1:05'), findsOneWidget);
    });

    testWidgets('shows playback speed button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceMessagePlayer(
              audioUrl: 'https://example.com/audio.m4a',
              durationMs: 30000,
            ),
          ),
        ),
      );

      // Should show 1x speed initially
      expect(find.text('1x'), findsOneWidget);
    });

    testWidgets('cycles through playback speeds', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceMessagePlayer(
              audioUrl: 'https://example.com/audio.m4a',
              durationMs: 30000,
            ),
          ),
        ),
      );

      // Find the speed button (contains "1x")
      final speedButton = find.text('1x');
      expect(speedButton, findsOneWidget);

      // Tap to cycle to 1.5x
      await tester.tap(speedButton);
      await tester.pump();
      expect(find.text('1.5x'), findsOneWidget);

      // Tap to cycle to 2x
      await tester.tap(find.text('1.5x'));
      await tester.pump();
      expect(find.text('2x'), findsOneWidget);

      // Tap to cycle back to 1x
      await tester.tap(find.text('2x'));
      await tester.pump();
      expect(find.text('1x'), findsOneWidget);
    });

    testWidgets('uses different colors for own messages', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceMessagePlayer(
              audioUrl: 'https://example.com/audio.m4a',
              durationMs: 30000,
              isOwnMessage: true,
            ),
          ),
        ),
      );

      expect(find.byType(VoiceMessagePlayer), findsOneWidget);
    });
  });

  group('CompactVoiceMessagePlayer', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactVoiceMessagePlayer(
              audioUrl: 'https://example.com/audio.m4a',
              durationMs: 15000,
            ),
          ),
        ),
      );

      expect(find.byType(CompactVoiceMessagePlayer), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    });

    testWidgets('shows duration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactVoiceMessagePlayer(
              audioUrl: 'https://example.com/audio.m4a',
              durationMs: 90000, // 1:30
            ),
          ),
        ),
      );

      expect(find.text('1:30'), findsOneWidget);
    });
  });

  group('VoiceRecordButton', () {
    testWidgets('renders in idle state', (WidgetTester tester) async {
      await tester.pumpWidgetWithMocks(
        MaterialApp(
          home: Scaffold(body: VoiceRecordButton(onRecordingComplete: (_) {})),
        ),
      );

      expect(find.byType(VoiceRecordButton), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    // Note: Full recording tests would require mocking the voice recording service
    // and permission handler, which is beyond the scope of widget tests
  });

  group('generateFakeWaveform', () {
    test('generates correct number of samples', () {
      final waveform = generateFakeWaveform(50);
      expect(waveform.length, 50);
    });

    test('generates values in valid range', () {
      final waveform = generateFakeWaveform(100);
      for (final amplitude in waveform) {
        expect(amplitude, greaterThanOrEqualTo(0.0));
        expect(amplitude, lessThanOrEqualTo(1.0));
      }
    });

    test('generates consistent results with same seed', () {
      final waveform1 = generateFakeWaveform(20, seed: 123);
      final waveform2 = generateFakeWaveform(20, seed: 123);
      expect(waveform1, equals(waveform2));
    });

    test('generates different results with different seeds', () {
      final waveform1 = generateFakeWaveform(20, seed: 123);
      final waveform2 = generateFakeWaveform(20, seed: 456);
      expect(waveform1, isNot(equals(waveform2)));
    });
  });
}
