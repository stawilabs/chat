import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:xid/xid.dart';

import '../../../core/logging/app_logger.dart';

/// Service for handling voice recording functionality
class VoiceRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  Timer? _durationTimer;
  final _durationController = StreamController<Duration>.broadcast();

  Stream<Duration> get durationStream => _durationController.stream;

  /// Maximum recording duration (5 minutes)
  static const maxDuration = Duration(minutes: 5);

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async => _recorder.hasPermission();

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Start recording voice
  /// Returns the path where the recording will be saved, or null if failed
  Future<String?> startRecording() async {
    try {
      // Check permission
      if (!await hasPermission()) {
        final granted = await requestPermission();
        if (!granted) {
          AppLogger.warning('Microphone permission denied');
          return null;
        }
      }

      // Stop any existing recording
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      // Generate unique file path
      final directory = await getTemporaryDirectory();
      final fileName = 'voice_${Xid().toString()}.m4a';
      _currentRecordingPath = '${directory.path}/$fileName';

      // Configure and start recording
      const config = RecordConfig(numChannels: 1);

      await _recorder.start(config, path: _currentRecordingPath!);
      _recordingStartTime = DateTime.now();

      // Start duration timer
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        if (_recordingStartTime != null) {
          final duration = DateTime.now().difference(_recordingStartTime!);
          _durationController.add(duration);

          // Auto-stop at max duration
          if (duration >= maxDuration) {
            stopRecording();
          }
        }
      });

      AppLogger.info(
        'Voice recording started',
        data: {'path': _currentRecordingPath},
      );
      return _currentRecordingPath;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to start voice recording',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Stop recording and return the recorded file path
  /// Returns null if no recording was in progress
  Future<VoiceRecordingResult?> stopRecording() async {
    try {
      _durationTimer?.cancel();
      _durationTimer = null;

      if (!await _recorder.isRecording()) {
        return null;
      }

      final path = await _recorder.stop();
      final duration = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!)
          : Duration.zero;

      _recordingStartTime = null;

      if (path == null || path.isEmpty) {
        return null;
      }

      // Verify the file exists and has content
      final file = File(path);
      // ignore: avoid_slow_async_io
      if (!await file.exists()) {
        AppLogger.warning(
          'Recording file does not exist',
          data: {'path': path},
        );
        return null;
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        AppLogger.warning('Recording file is empty', data: {'path': path});
        await file.delete();
        return null;
      }

      // Require minimum duration (500ms) to prevent accidental taps
      if (duration.inMilliseconds < 500) {
        AppLogger.debug(
          'Recording too short, discarding',
          data: {'duration': duration.inMilliseconds},
        );
        await file.delete();
        return null;
      }

      AppLogger.info(
        'Voice recording stopped',
        data: {'path': path, 'duration': duration.inSeconds, 'size': fileSize},
      );

      return VoiceRecordingResult(
        path: path,
        duration: duration,
        sizeBytes: fileSize,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to stop voice recording',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Cancel recording and delete any recorded file
  Future<void> cancelRecording() async {
    try {
      _durationTimer?.cancel();
      _durationTimer = null;
      _recordingStartTime = null;

      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        // ignore: avoid_slow_async_io
        if (await file.exists()) {
          await file.delete();
        }
        _currentRecordingPath = null;
      }

      AppLogger.debug('Voice recording cancelled');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to cancel voice recording',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if currently recording
  Future<bool> isRecording() async => _recorder.isRecording();

  /// Get the current recording amplitude (for waveform visualization)
  Future<double> getAmplitude() async {
    try {
      final amplitude = await _recorder.getAmplitude();
      // Normalize to 0-1 range (typical range is -60 to 0 dB)
      final normalized = (amplitude.current + 60) / 60;
      return normalized.clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  /// Dispose of resources
  void dispose() {
    _durationTimer?.cancel();
    _durationController.close();
    _recorder.dispose();
  }
}

/// Result of a voice recording
class VoiceRecordingResult {
  const VoiceRecordingResult({
    required this.path,
    required this.duration,
    required this.sizeBytes,
  });
  final String path;
  final Duration duration;
  final int sizeBytes;

  /// Get formatted duration string (MM:SS)
  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get file name from path
  String get fileName => path.split('/').last;

  /// Get MIME type for the recording
  String get mimeType => 'audio/mp4';
}

/// Provider for voice recording service
final voiceRecordingServiceProvider = Provider<VoiceRecordingService>((ref) {
  final service = VoiceRecordingService();
  ref.onDispose(service.dispose);
  return service;
});
