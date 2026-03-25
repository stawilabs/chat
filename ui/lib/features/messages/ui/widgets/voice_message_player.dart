import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/app_theme.dart';
import 'waveform_visualizer.dart';

/// A polished voice message player widget for displaying voice messages
/// in chat bubbles.
///
/// Features:
/// - Play/pause button
/// - Waveform visualization with progress
/// - Duration display (elapsed/total)
/// - Seek by tapping on waveform
/// - Playback speed control
class VoiceMessagePlayer extends StatefulWidget {
  const VoiceMessagePlayer({
    required this.audioUrl,
    required this.durationMs,
    super.key,
    this.localPath,
    this.isOwnMessage = false,
    this.waveformData,
    this.onPlaybackStart,
    this.onPlaybackEnd,
  });

  /// URL of the audio file on the server
  final String audioUrl;

  /// Local file path (for offline playback)
  final String? localPath;

  /// Duration in milliseconds
  final int durationMs;

  /// Whether this is the user's own message (affects styling)
  final bool isOwnMessage;

  /// Pre-computed waveform data (if available)
  final List<double>? waveformData;

  /// Called when playback starts
  final VoidCallback? onPlaybackStart;

  /// Called when playback ends
  final VoidCallback? onPlaybackEnd;

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  double _progress = 0;
  double _playbackSpeed = 1;
  Duration _currentPosition = Duration.zero;
  bool _initialized = false;

  late Duration _totalDuration;
  late List<double> _waveformData;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _totalDuration = Duration(milliseconds: widget.durationMs);
    _waveformData = widget.waveformData ?? generateFakeWaveform(50);

    try {
      _audioPlayer = AudioPlayer();
      _positionSub = _audioPlayer!.positionStream.listen((position) {
        if (!mounted) return;
        setState(() {
          _currentPosition = position;
          if (_totalDuration.inMilliseconds > 0) {
            _progress = position.inMilliseconds / _totalDuration.inMilliseconds;
          }
        });
      });

      _stateSub = _audioPlayer!.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
            _progress = 0;
            _currentPosition = Duration.zero;
            _audioPlayer?.seek(Duration.zero);
            _audioPlayer?.pause();
            widget.onPlaybackEnd?.call();
          }
        });
      });
    } catch (e) {
      // AudioPlayer may fail in test environments without platform channels
      debugPrint('AudioPlayer init failed: $e');
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initializeAudio() async {
    if (_initialized || _audioPlayer == null) return;
    setState(() => _isLoading = true);
    try {
      // Prefer local path for offline playback
      if (widget.localPath != null && File(widget.localPath!).existsSync()) {
        await _audioPlayer!.setFilePath(widget.localPath!);
      } else {
        await _audioPlayer!.setUrl(widget.audioUrl);
      }
      final duration = _audioPlayer!.duration;
      if (duration != null) {
        _totalDuration = duration;
      }
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize audio: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_isLoading || _audioPlayer == null) return;

    if (!_initialized) {
      await _initializeAudio();
    }

    if (_isPlaying) {
      await _audioPlayer!.pause();
      widget.onPlaybackEnd?.call();
    } else {
      widget.onPlaybackStart?.call();
      await _audioPlayer!.play();
    }
  }

  Future<void> _seekTo(double position) async {
    if (_audioPlayer == null) return;
    final clampedPosition = position.clamp(0.0, 1.0);
    final seekPosition = Duration(
      milliseconds: (_totalDuration.inMilliseconds * clampedPosition).round(),
    );
    await _audioPlayer!.seek(seekPosition);
    setState(() {
      _progress = clampedPosition;
      _currentPosition = seekPosition;
    });
  }

  Future<void> _cyclePlaybackSpeed() async {
    double newSpeed;
    if (_playbackSpeed == 1.0) {
      newSpeed = 1.5;
    } else if (_playbackSpeed == 1.5) {
      newSpeed = 2.0;
    } else {
      newSpeed = 1.0;
    }
    final player = _audioPlayer;
    if (player != null) {
      unawaited(
        player.setSpeed(newSpeed).catchError((e) {
          // AudioPlayer may not be initialized in test environments.
          debugPrint('Failed to set playback speed: $e');
        }),
      );
    }
    if (!mounted) return;
    setState(() => _playbackSpeed = newSpeed);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Colors based on message ownership
    final primaryColor = widget.isOwnMessage
        ? Colors.white.withValues(alpha: 0.9)
        : AppTheme.primaryGreen;
    final secondaryColor = widget.isOwnMessage
        ? Colors.white.withValues(alpha: 0.4)
        : AppTheme.primaryGreen.withValues(alpha: 0.4);
    final textColor = widget.isOwnMessage
        ? Colors.white.withValues(alpha: 0.7)
        : AppTheme.getTextColor(context).withValues(alpha: 0.7);

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primaryColor.withValues(
                  alpha: widget.isOwnMessage ? 0.2 : 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(primaryColor),
                      ),
                    )
                  : Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: primaryColor,
                      size: 28,
                    ),
            ),
          ),

          const SizedBox(width: 8),

          // Waveform and info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform
                PlaybackWaveformVisualizer(
                  amplitudes: _waveformData,
                  progress: _progress,
                  width: 180,
                  height: 28,
                  playedColor: primaryColor,
                  unplayedColor: secondaryColor,
                  onSeek: _seekTo,
                ),

                const SizedBox(height: 4),

                // Duration and speed indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Current time / Total time
                    Text(
                      _isPlaying || _progress > 0
                          ? _formatDuration(_currentPosition)
                          : _formatDuration(_totalDuration),
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Playback speed button
                    GestureDetector(
                      onTap: _cyclePlaybackSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(
                            alpha: widget.isOwnMessage ? 0.2 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_playbackSpeed.toStringAsFixed(_playbackSpeed == 1.0 || _playbackSpeed == 2.0 ? 0 : 1)}x',
                          style: TextStyle(
                            fontSize: 10,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact voice message player for list views or smaller contexts
class CompactVoiceMessagePlayer extends StatefulWidget {
  const CompactVoiceMessagePlayer({
    required this.audioUrl,
    required this.durationMs,
    super.key,
    this.localPath,
    this.isOwnMessage = false,
  });

  final String audioUrl;
  final String? localPath;
  final int durationMs;
  final bool isOwnMessage;

  @override
  State<CompactVoiceMessagePlayer> createState() =>
      _CompactVoiceMessagePlayerState();
}

class _CompactVoiceMessagePlayerState extends State<CompactVoiceMessagePlayer> {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  double _progress = 0;
  bool _initialized = false;

  late Duration _totalDuration;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _totalDuration = Duration(milliseconds: widget.durationMs);

    try {
      _audioPlayer = AudioPlayer();
      _positionSub = _audioPlayer!.positionStream.listen((position) {
        if (!mounted) return;
        setState(() {
          if (_totalDuration.inMilliseconds > 0) {
            _progress = position.inMilliseconds / _totalDuration.inMilliseconds;
          }
        });
      });

      _stateSub = _audioPlayer!.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
            _progress = 0;
            _audioPlayer?.seek(Duration.zero);
            _audioPlayer?.pause();
          }
        });
      });
    } catch (e) {
      debugPrint('AudioPlayer init failed: $e');
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isLoading || _audioPlayer == null) return;

    if (!_initialized) {
      setState(() => _isLoading = true);
      try {
        if (widget.localPath != null && File(widget.localPath!).existsSync()) {
          await _audioPlayer!.setFilePath(widget.localPath!);
        } else {
          await _audioPlayer!.setUrl(widget.audioUrl);
        }
        final duration = _audioPlayer!.duration;
        if (duration != null) {
          _totalDuration = duration;
        }
        _initialized = true;
      } catch (e) {
        debugPrint('Failed to initialize audio: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

    if (_isPlaying) {
      await _audioPlayer!.pause();
    } else {
      await _audioPlayer!.play();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isOwnMessage
        ? Colors.white.withValues(alpha: 0.9)
        : AppTheme.primaryGreen;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _togglePlayback,
          child: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: primaryColor,
            size: 32,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: _progress.clamp(0.0, 1.0),
                backgroundColor: primaryColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(primaryColor),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDuration(_totalDuration),
                style: TextStyle(
                  fontSize: 10,
                  color: primaryColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
