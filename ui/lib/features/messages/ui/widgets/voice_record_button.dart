import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../services/voice_recording_service.dart';
import 'waveform_visualizer.dart';

/// Callback for when a voice recording is completed
typedef VoiceRecordingCallback = void Function(VoiceRecordingResult result);

/// State of the voice recording button
enum VoiceRecordingState {
  /// Initial state - ready to record
  idle,

  /// User is holding the button - recording in progress
  recording,

  /// User has locked recording for hands-free mode
  locked,

  /// Recording completed - preview available
  preview,
}

/// A WhatsApp-style voice recording button with hold-to-record,
/// slide-to-cancel, and lock for hands-free recording.
///
/// Features:
/// - Hold mic button to record
/// - Slide left to cancel
/// - Slide up to lock for hands-free recording
/// - Waveform visualization while recording
/// - Max duration: 5 minutes (auto-stop)
/// - Preview before send option
class VoiceRecordButton extends ConsumerStatefulWidget {
  const VoiceRecordButton({
    required this.onRecordingComplete,
    super.key,
    this.onRecordingStart,
    this.onRecordingCancel,
    this.maxDuration = const Duration(minutes: 5),
    this.iconSize = 24,
    this.slideToCancelThreshold = 100,
    this.slideToLockThreshold = 80,
  });

  /// Called when recording is completed with the result
  final VoiceRecordingCallback onRecordingComplete;

  /// Called when recording starts
  final VoidCallback? onRecordingStart;

  /// Called when recording is cancelled
  final VoidCallback? onRecordingCancel;

  /// Maximum recording duration before auto-stop
  final Duration maxDuration;

  /// Size of the microphone icon
  final double iconSize;

  /// Distance to slide left before cancelling (in pixels)
  final double slideToCancelThreshold;

  /// Distance to slide up before locking (in pixels)
  final double slideToLockThreshold;

  @override
  ConsumerState<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends ConsumerState<VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  VoiceRecordingState _state = VoiceRecordingState.idle;
  Duration _duration = Duration.zero;
  List<double> _amplitudes = [];
  Offset _dragOffset = Offset.zero;
  VoiceRecordingResult? _recordingResult;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  StreamSubscription<Duration>? _durationSubscription;
  Timer? _amplitudeTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _amplitudeTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isRecording =>
      _state == VoiceRecordingState.recording ||
      _state == VoiceRecordingState.locked;

  bool get _showCancelIndicator =>
      _isRecording && _dragOffset.dx < -widget.slideToCancelThreshold / 2;

  bool get _shouldCancel => _dragOffset.dx < -widget.slideToCancelThreshold;

  bool get _shouldLock => _dragOffset.dy < -widget.slideToLockThreshold;

  Future<void> _startRecording() async {
    final service = ref.read(voiceRecordingServiceProvider);

    // Request permission and start recording
    final path = await service.startRecording();
    if (path == null) {
      // Permission denied or error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission required'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Haptic feedback
    await HapticFeedback.mediumImpact();

    setState(() {
      _state = VoiceRecordingState.recording;
      _duration = Duration.zero;
      _amplitudes = [];
      _dragOffset = Offset.zero;
    });

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    // Subscribe to duration updates
    _durationSubscription = service.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);

        // Auto-stop at max duration
        if (duration >= widget.maxDuration) {
          _stopRecording();
        }
      }
    });

    // Start amplitude sampling for waveform
    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _sampleAmplitude(),
    );

    widget.onRecordingStart?.call();
  }

  Future<void> _sampleAmplitude() async {
    if (!_isRecording) return;

    final service = ref.read(voiceRecordingServiceProvider);
    final amplitude = await service.getAmplitude();

    if (mounted && _isRecording) {
      setState(() {
        _amplitudes = [..._amplitudes.take(50), amplitude];
      });
    }
  }

  Future<void> _stopRecording() async {
    _durationSubscription?.cancel();
    _amplitudeTimer?.cancel();
    _pulseController.stop();

    final service = ref.read(voiceRecordingServiceProvider);
    final result = await service.stopRecording();

    if (result != null && mounted) {
      setState(() {
        _state = VoiceRecordingState.preview;
        _recordingResult = result;
      });
    } else {
      _reset();
    }
  }

  Future<void> _cancelRecording() async {
    await HapticFeedback.lightImpact();

    _durationSubscription?.cancel();
    _amplitudeTimer?.cancel();
    _pulseController.stop();

    final service = ref.read(voiceRecordingServiceProvider);
    await service.cancelRecording();

    widget.onRecordingCancel?.call();
    _reset();
  }

  void _lockRecording() {
    HapticFeedback.heavyImpact();
    setState(() {
      _state = VoiceRecordingState.locked;
      _dragOffset = Offset.zero;
    });
  }

  void _reset() {
    setState(() {
      _state = VoiceRecordingState.idle;
      _duration = Duration.zero;
      _amplitudes = [];
      _dragOffset = Offset.zero;
      _recordingResult = null;
    });
  }

  void _sendRecording() {
    if (_recordingResult != null) {
      widget.onRecordingComplete(_recordingResult!);
    }
    _reset();
  }

  void _discardRecording() {
    if (_recordingResult != null) {
      // Delete the recorded file
      // ignore: discarded_futures
      ref.read(voiceRecordingServiceProvider).cancelRecording();
    }
    widget.onRecordingCancel?.call();
    _reset();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case VoiceRecordingState.idle:
        return _buildIdleState();
      case VoiceRecordingState.recording:
        return _buildRecordingState();
      case VoiceRecordingState.locked:
        return _buildLockedState();
      case VoiceRecordingState.preview:
        return _buildPreviewState();
    }
  }

  Widget _buildIdleState() => Tooltip(
    message: 'Voice Message',
    child: GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onTap: _startRecording,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.getSubtleColor(context, AppTheme.primaryGreen),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mic,
          size: widget.iconSize,
          color: AppTheme.primaryGreen,
        ),
      ),
    ),
  );

  Widget _buildRecordingState() => GestureDetector(
    onLongPressMoveUpdate: (details) {
      setState(() {
        _dragOffset = details.offsetFromOrigin;
      });

      if (_shouldCancel) {
        _cancelRecording();
      } else if (_shouldLock) {
        _lockRecording();
      }
    },
    onLongPressEnd: (_) {
      if (_state == VoiceRecordingState.recording) {
        _stopRecording();
      }
    },
    onLongPressCancel: () {
      if (_state == VoiceRecordingState.recording) {
        _cancelRecording();
      }
    },
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slide to cancel indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: _showCancelIndicator ? 80 : 0,
          child: _showCancelIndicator
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_left,
                      color: Colors.red.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.red.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : null,
        ),

        // Recording UI
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.getSubtleColor(context, Colors.red),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recording indicator
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),

              // Duration
              Text(
                _formatDuration(_duration),
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),

              // Waveform
              WaveformVisualizer(
                amplitudes: _amplitudes,
                width: 60,
                height: 24,
                activeColor: Colors.red,
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Mic button with pulse
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) => Transform.scale(
            scale: _pulseAnimation.value,
            child: Transform.translate(
              offset: _dragOffset,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mic,
                  size: widget.iconSize,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // Lock indicator (appears when dragging up)
        if (_dragOffset.dy < -20)
          Positioned(
            top: -60,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: (_dragOffset.dy.abs() / widget.slideToLockThreshold)
                  .clamp(0.0, 1.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, size: 20, color: Colors.white),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _buildLockedState() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cancel button
        GestureDetector(
          onTap: _cancelRecording,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete, color: Colors.red, size: 20),
          ),
        ),

        const SizedBox(width: 12),

        // Recording indicator
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),

        // Duration
        Text(
          _formatDuration(_duration),
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),

        // Waveform
        WaveformVisualizer(
          amplitudes: _amplitudes,
          width: 80,
          height: 24,
          activeColor: Colors.red,
        ),

        const SizedBox(width: 12),

        // Send button
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 22),
          ),
        ),
      ],
    ),
  );

  Widget _buildPreviewState() {
    final result = _recordingResult;
    if (result == null) return _buildIdleState();

    return VoiceMessagePreview(
      result: result,
      onSend: _sendRecording,
      onDiscard: _discardRecording,
    );
  }
}

/// Preview widget for a recorded voice message before sending
class VoiceMessagePreview extends StatelessWidget {
  const VoiceMessagePreview({
    required this.result,
    required this.onSend,
    required this.onDiscard,
    super.key,
  });

  final VoiceRecordingResult result;
  final VoidCallback onSend;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Delete button
        GestureDetector(
          onTap: onDiscard,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete, color: Colors.red, size: 20),
          ),
        ),

        const SizedBox(width: 12),

        // Voice preview player
        Expanded(
          child: VoicePreviewPlayer(
            filePath: result.path,
            duration: result.duration,
          ),
        ),

        const SizedBox(width: 12),

        // Send button
        GestureDetector(
          onTap: onSend,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 22),
          ),
        ),
      ],
    ),
  );
}

/// Simple voice preview player for before sending
class VoicePreviewPlayer extends StatefulWidget {
  const VoicePreviewPlayer({
    required this.filePath,
    required this.duration,
    super.key,
  });

  final String filePath;
  final Duration duration;

  @override
  State<VoicePreviewPlayer> createState() => _VoicePreviewPlayerState();
}

class _VoicePreviewPlayerState extends State<VoicePreviewPlayer> {
  bool _isPlaying = false;
  double _progress = 0;
  Timer? _progressTimer;

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        // Start progress animation (simplified - real impl would use audio player)
        _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
          setState(() {
            _progress += 100 / widget.duration.inMilliseconds;
            if (_progress >= 1.0) {
              _progress = 0.0;
              _isPlaying = false;
              _progressTimer?.cancel();
            }
          });
        });
      } else {
        _progressTimer?.cancel();
      }
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Generate fake waveform for preview (real impl would analyze audio)
    final waveform = generateFakeWaveform(50);

    return Row(
      children: [
        // Play/Pause button
        GestureDetector(
          onTap: _togglePlayback,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Waveform with progress
        Expanded(
          child: PlaybackWaveformVisualizer(
            amplitudes: waveform,
            progress: _progress,
            height: 28,
            playedColor: AppTheme.primaryGreen,
          ),
        ),

        const SizedBox(width: 8),

        // Duration
        Text(
          _formatDuration(widget.duration),
          style: AppTheme.metadataText.copyWith(
            color: AppTheme.getTextColor(context),
          ),
        ),
      ],
    );
  }
}
