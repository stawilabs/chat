import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// A widget that displays a waveform visualization for audio recording
///
/// The waveform is rendered as vertical bars that animate based on the
/// amplitude values provided. Used during voice recording to show audio levels.
class WaveformVisualizer extends StatelessWidget {
  const WaveformVisualizer({
    required this.amplitudes,
    super.key,
    this.width = 120,
    this.height = 32,
    this.barWidth = 3,
    this.barSpacing = 2,
    this.activeColor,
    this.inactiveColor,
    this.minBarHeight = 4,
    this.borderRadius = 1.5,
  });

  /// List of amplitude values (0.0 - 1.0) to visualize
  final List<double> amplitudes;

  /// Total width of the waveform
  final double width;

  /// Maximum height of the waveform bars
  final double height;

  /// Width of each individual bar
  final double barWidth;

  /// Spacing between bars
  final double barSpacing;

  /// Color for bars (defaults to theme accent)
  final Color? activeColor;

  /// Color for inactive/silent bars
  final Color? inactiveColor;

  /// Minimum height for bars when amplitude is 0
  final double minBarHeight;

  /// Border radius for bar corners
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final barCount = ((width + barSpacing) / (barWidth + barSpacing)).floor();
    final color = activeColor ?? AppTheme.primaryGreen;
    final silentColor = inactiveColor ?? color.withValues(alpha: 0.3);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _WaveformPainter(
          amplitudes: amplitudes,
          barCount: barCount,
          barWidth: barWidth,
          barSpacing: barSpacing,
          maxHeight: height,
          minHeight: minBarHeight,
          activeColor: color,
          inactiveColor: silentColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.amplitudes,
    required this.barCount,
    required this.barWidth,
    required this.barSpacing,
    required this.maxHeight,
    required this.minHeight,
    required this.activeColor,
    required this.inactiveColor,
    required this.borderRadius,
  });

  final List<double> amplitudes;
  final int barCount;
  final double barWidth;
  final double barSpacing;
  final double maxHeight;
  final double minHeight;
  final Color activeColor;
  final Color inactiveColor;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < barCount; i++) {
      // Get amplitude for this bar (or use 0 if not enough data)
      final amplitudeIndex = amplitudes.isEmpty
          ? 0
          : (i * amplitudes.length / barCount).floor().clamp(
              0,
              amplitudes.length - 1,
            );
      final amplitude = amplitudes.isEmpty ? 0.0 : amplitudes[amplitudeIndex];

      // Calculate bar height based on amplitude
      final barHeight = minHeight + (maxHeight - minHeight) * amplitude;

      // Position the bar
      final x = i * (barWidth + barSpacing);
      final y = (size.height - barHeight) / 2;

      // Set color based on amplitude
      paint.color = amplitude > 0.1 ? activeColor : inactiveColor;

      // Draw rounded rectangle for bar
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(borderRadius),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      amplitudes != oldDelegate.amplitudes ||
      barCount != oldDelegate.barCount ||
      activeColor != oldDelegate.activeColor;
}

/// An animated waveform that updates based on a stream of amplitude values
///
/// This widget maintains its own state and animation for smooth visualization.
/// It buffers amplitude values and scrolls them from right to left.
class AnimatedWaveformVisualizer extends StatefulWidget {
  const AnimatedWaveformVisualizer({
    required this.amplitudeStream,
    super.key,
    this.width = 120,
    this.height = 32,
    this.barWidth = 3,
    this.barSpacing = 2,
    this.activeColor,
    this.sampleRate = const Duration(milliseconds: 100),
  });

  /// Stream of amplitude values (0.0 - 1.0)
  final Stream<double> amplitudeStream;

  /// Total width of the waveform
  final double width;

  /// Maximum height of the waveform bars
  final double height;

  /// Width of each individual bar
  final double barWidth;

  /// Spacing between bars
  final double barSpacing;

  /// Color for bars (defaults to theme accent)
  final Color? activeColor;

  /// How often to sample from the stream
  final Duration sampleRate;

  @override
  State<AnimatedWaveformVisualizer> createState() =>
      _AnimatedWaveformVisualizerState();
}

class _AnimatedWaveformVisualizerState
    extends State<AnimatedWaveformVisualizer> {
  late List<double> _amplitudes;
  late int _maxBars;
  StreamSubscription<double>? _subscription;

  @override
  void initState() {
    super.initState();
    _maxBars =
        ((widget.width + widget.barSpacing) /
                (widget.barWidth + widget.barSpacing))
            .floor();
    _amplitudes = List.filled(_maxBars, 0);
    _subscription = widget.amplitudeStream.listen(_onAmplitude);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onAmplitude(double amplitude) {
    if (!mounted) return;
    setState(() {
      // Shift amplitudes left and add new value at the end
      _amplitudes = [..._amplitudes.skip(1), amplitude.clamp(0.0, 1.0)];
    });
  }

  @override
  Widget build(BuildContext context) => WaveformVisualizer(
    amplitudes: _amplitudes,
    width: widget.width,
    height: widget.height,
    barWidth: widget.barWidth,
    barSpacing: widget.barSpacing,
    activeColor: widget.activeColor,
  );
}

/// A waveform visualizer for playback that shows the entire audio wave
///
/// This variant displays a static waveform with a progress indicator
/// showing the current playback position.
class PlaybackWaveformVisualizer extends StatelessWidget {
  const PlaybackWaveformVisualizer({
    required this.amplitudes,
    super.key,
    this.progress = 0.0,
    this.width = 200,
    this.height = 32,
    this.barWidth = 2,
    this.barSpacing = 1,
    this.playedColor,
    this.unplayedColor,
    this.onSeek,
  });

  /// Pre-computed amplitude values for the entire audio
  final List<double> amplitudes;

  /// Current playback progress (0.0 - 1.0)
  final double progress;

  /// Total width of the waveform
  final double width;

  /// Maximum height of the waveform bars
  final double height;

  /// Width of each individual bar
  final double barWidth;

  /// Spacing between bars
  final double barSpacing;

  /// Color for played portion
  final Color? playedColor;

  /// Color for unplayed portion
  final Color? unplayedColor;

  /// Callback when user taps to seek
  final void Function(double position)? onSeek;

  @override
  Widget build(BuildContext context) {
    final played = playedColor ?? AppTheme.primaryGreen;
    final unplayed = unplayedColor ?? played.withValues(alpha: 0.4);

    return GestureDetector(
      onTapDown: onSeek != null
          ? (details) => onSeek!(details.localPosition.dx / width)
          : null,
      onPanUpdate: onSeek != null
          ? (details) => onSeek!((details.localPosition.dx / width).clamp(0, 1))
          : null,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _PlaybackWaveformPainter(
            amplitudes: amplitudes,
            progress: progress,
            barWidth: barWidth,
            barSpacing: barSpacing,
            playedColor: played,
            unplayedColor: unplayed,
          ),
        ),
      ),
    );
  }
}

class _PlaybackWaveformPainter extends CustomPainter {
  _PlaybackWaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.barWidth,
    required this.barSpacing,
    required this.playedColor,
    required this.unplayedColor,
  });

  final List<double> amplitudes;
  final double progress;
  final double barWidth;
  final double barSpacing;
  final Color playedColor;
  final Color unplayedColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final barCount = ((size.width + barSpacing) / (barWidth + barSpacing))
        .floor();
    const minHeight = 4.0;
    final progressBarIndex = (barCount * progress).floor();

    for (var i = 0; i < barCount; i++) {
      // Get amplitude for this bar
      final amplitudeIndex = (i * amplitudes.length / barCount).floor().clamp(
        0,
        amplitudes.length - 1,
      );
      final amplitude = amplitudes[amplitudeIndex];

      // Calculate bar height
      final barHeight =
          minHeight + (size.height - minHeight) * amplitude.clamp(0.0, 1.0);

      // Position the bar
      final x = i * (barWidth + barSpacing);
      final y = (size.height - barHeight) / 2;

      // Set color based on progress
      paint.color = i <= progressBarIndex ? playedColor : unplayedColor;

      // Draw bar
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(1),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_PlaybackWaveformPainter oldDelegate) =>
      amplitudes != oldDelegate.amplitudes ||
      progress != oldDelegate.progress ||
      playedColor != oldDelegate.playedColor;
}

/// Generate fake waveform data for visualization when real data isn't available
List<double> generateFakeWaveform(int count, {int seed = 42}) {
  final random = math.Random(seed);
  return List.generate(count, (i) {
    // Create a wave-like pattern with some randomness
    final base = 0.3 + 0.3 * math.sin(i * 0.3);
    final variation = random.nextDouble() * 0.3;
    return (base + variation).clamp(0.1, 1.0);
  });
}
