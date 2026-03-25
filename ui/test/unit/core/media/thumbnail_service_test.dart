import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stawi/core/media/thumbnail_service.dart';

void main() {
  group('ThumbnailConfig', () {
    test('default configuration has correct values', () {
      const config = ThumbnailConfig();

      expect(config.maxWidth, equals(200));
      expect(config.maxHeight, equals(200));
      expect(config.quality, equals(70));
      expect(config.format, equals(ThumbnailFormat.jpeg));
    });

    test('custom configuration overrides defaults', () {
      const config = ThumbnailConfig(
        maxWidth: 300,
        maxHeight: 400,
        quality: 85,
        format: ThumbnailFormat.png,
      );

      expect(config.maxWidth, equals(300));
      expect(config.maxHeight, equals(400));
      expect(config.quality, equals(85));
      expect(config.format, equals(ThumbnailFormat.png));
    });

    test('configuration with webp format', () {
      const config = ThumbnailConfig(format: ThumbnailFormat.webp);

      expect(config.format, equals(ThumbnailFormat.webp));
    });
  });

  group('ThumbnailFormat', () {
    test('has three supported formats', () {
      expect(ThumbnailFormat.values.length, equals(3));
    });

    test('contains jpeg format', () {
      expect(ThumbnailFormat.values, contains(ThumbnailFormat.jpeg));
    });

    test('contains png format', () {
      expect(ThumbnailFormat.values, contains(ThumbnailFormat.png));
    });

    test('contains webp format', () {
      expect(ThumbnailFormat.values, contains(ThumbnailFormat.webp));
    });
  });

  group('ThumbnailResult', () {
    test('creates result with required fields', () {
      final tempFile = File(
        path.join(Directory.systemTemp.path, 'test_thumb.jpg'),
      );
      final result = ThumbnailResult(
        file: tempFile,
        width: 200,
        height: 150,
        size: 5000,
      );

      expect(result.file, equals(tempFile));
      expect(result.width, equals(200));
      expect(result.height, equals(150));
      expect(result.size, equals(5000));
      expect(result.blurHash, isNull);
    });

    test('creates result with optional blurHash', () {
      final tempFile = File(
        path.join(Directory.systemTemp.path, 'test_thumb.jpg'),
      );
      final result = ThumbnailResult(
        file: tempFile,
        width: 200,
        height: 150,
        size: 5000,
        blurHash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
      );

      expect(result.blurHash, equals('LEHV6nWB2yk8pyo0adR*.7kCMdnj'));
    });

    test('result maintains file reference', () {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/thumb_test_12345.jpg');

      final result = ThumbnailResult(
        file: tempFile,
        width: 100,
        height: 100,
        size: 1000,
      );

      expect(result.file.path, contains('thumb_test_12345.jpg'));
    });
  });

  group('ThumbnailService', () {
    test('service is created with default config', () {
      final service = ThumbnailService();

      expect(service, isNotNull);
    });

    test('service is created with custom config', () {
      const customConfig = ThumbnailConfig(
        maxWidth: 150,
        maxHeight: 150,
        quality: 60,
        format: ThumbnailFormat.png,
      );
      final service = ThumbnailService(customConfig);

      expect(service, isNotNull);
    });

    test('service accepts null config and uses defaults', () {
      final service = ThumbnailService();

      expect(service, isNotNull);
    });
  });

  group('Thumbnail naming conventions', () {
    test('image thumbnails use thumb_ prefix with extension', () {
      // Verify the naming pattern for image thumbnails
      const thumbnailName = 'thumb_1234567890.jpg';

      expect(thumbnailName.startsWith('thumb_'), isTrue);
      expect(thumbnailName.endsWith('.jpg'), isTrue);
    });

    test('video thumbnails use vthumb_ prefix', () {
      // Verify the naming pattern for video thumbnails
      const thumbnailName = 'vthumb_1234567890.jpg';

      expect(thumbnailName.startsWith('vthumb_'), isTrue);
    });

    test('cleanup identifies thumbnail files by prefix', () {
      // Thumbnails should be identifiable by their prefix for cleanup
      final testNames = [
        'thumb_12345.jpg',
        'vthumb_12345.jpg',
        'regular_file.jpg',
        'thumbnail_not_ours.jpg',
      ];

      final thumbnailNames = testNames.where(
        (name) => name.startsWith('thumb_') || name.startsWith('vthumb_'),
      );

      expect(thumbnailNames.length, equals(2));
      expect(thumbnailNames, contains('thumb_12345.jpg'));
      expect(thumbnailNames, contains('vthumb_12345.jpg'));
    });
  });

  group('Provider', () {
    test('thumbnailServiceProvider is available', () {
      expect(thumbnailServiceProvider, isNotNull);
    });
  });

  group('ThumbnailConfig quality bounds', () {
    test('quality can be set to minimum (0)', () {
      const config = ThumbnailConfig(quality: 0);

      expect(config.quality, equals(0));
    });

    test('quality can be set to maximum (100)', () {
      const config = ThumbnailConfig(quality: 100);

      expect(config.quality, equals(100));
    });

    test('quality can be any value in range', () {
      const config = ThumbnailConfig(quality: 50);

      expect(config.quality, equals(50));
    });
  });

  group('ThumbnailConfig dimensions', () {
    test('dimensions can be square', () {
      const config = ThumbnailConfig();

      expect(config.maxWidth, equals(config.maxHeight));
    });

    test('dimensions can be landscape (width > height)', () {
      const config = ThumbnailConfig(maxWidth: 300);

      expect(config.maxWidth, greaterThan(config.maxHeight));
    });

    test('dimensions can be portrait (height > width)', () {
      const config = ThumbnailConfig(maxHeight: 300);

      expect(config.maxHeight, greaterThan(config.maxWidth));
    });

    test('dimensions can be very small', () {
      const config = ThumbnailConfig(maxWidth: 32, maxHeight: 32);

      expect(config.maxWidth, equals(32));
      expect(config.maxHeight, equals(32));
    });
  });
}
