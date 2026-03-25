import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/messages/services/voice_recording_service.dart';

void main() {
  group('VoiceRecordingResult', () {
    test('formattedDuration returns correct format for short duration', () {
      const result = VoiceRecordingResult(
        path: '/test/path.m4a',
        duration: Duration(seconds: 45),
        sizeBytes: 1024,
      );

      expect(result.formattedDuration, '00:45');
    });

    test('formattedDuration returns correct format for longer duration', () {
      const result = VoiceRecordingResult(
        path: '/test/path.m4a',
        duration: Duration(minutes: 2, seconds: 30),
        sizeBytes: 5000,
      );

      expect(result.formattedDuration, '02:30');
    });

    test('formattedDuration returns correct format for max duration', () {
      const result = VoiceRecordingResult(
        path: '/test/path.m4a',
        duration: Duration(minutes: 5),
        sizeBytes: 10000,
      );

      expect(result.formattedDuration, '05:00');
    });

    test('fileName extracts correct file name from path', () {
      const result = VoiceRecordingResult(
        path: '/data/user/0/com.example/cache/voice_abc123.m4a',
        duration: Duration(seconds: 10),
        sizeBytes: 1024,
      );

      expect(result.fileName, 'voice_abc123.m4a');
    });

    test('mimeType returns correct audio MIME type', () {
      const result = VoiceRecordingResult(
        path: '/test/path.m4a',
        duration: Duration(seconds: 10),
        sizeBytes: 1024,
      );

      expect(result.mimeType, 'audio/mp4');
    });
  });

  group('VoiceRecordingService', () {
    test('maxDuration is 5 minutes', () {
      expect(VoiceRecordingService.maxDuration, const Duration(minutes: 5));
    });

    // Note: Full service tests would require mocking the record package
    // and file system, which is complex. The service behavior is better
    // tested through integration tests or manual testing.
  });
}
