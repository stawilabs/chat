// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/db/database.dart';
import 'package:stawi/core/media/media_compression_service.dart';
import 'package:stawi/core/settings/settings_service.dart';

import '../../../test_helpers/test_database.dart';

void main() {
  late AppDatabase testDb;
  late SettingsService settingsService;
  late MediaCompressionService compressionService;

  setUp(() {
    testDb = createTestDatabase();
    settingsService = SettingsService(testDb);
    compressionService = MediaCompressionService(settingsService);
  });

  tearDown(() async {
    compressionService.dispose();
    await testDb.close();
  });

  group('MediaCompressionService', () {
    group('initialization', () {
      test('service is created with settings service', () {
        expect(compressionService, isNotNull);
      });

      test('default image quality is 80', () {
        expect(compressionService.imageQuality, equals(80));
      });

      test('default video quality is medium', () {
        expect(
          compressionService.videoQualityPreset,
          equals(CompressionQualityPreset.medium),
        );
      });

      test('compression is enabled by default', () {
        expect(compressionService.isCompressionEnabled, isTrue);
      });
    });

    group('settings integration', () {
      test('reads image quality from settings', () async {
        await settingsService.setInt(CompressionSettingsKeys.imageQuality, 50);

        expect(compressionService.imageQuality, equals(50));
      });

      test('reads video quality from settings', () async {
        await settingsService.setString(
          CompressionSettingsKeys.videoQuality,
          CompressionQualityPreset.high.name,
        );

        expect(
          compressionService.videoQualityPreset,
          equals(CompressionQualityPreset.high),
        );
      });

      test('reads compression enabled from settings', () async {
        await settingsService.setBool(
          CompressionSettingsKeys.compressionEnabled,
          false,
        );

        expect(compressionService.isCompressionEnabled, isFalse);
      });
    });

    group('size estimation', () {
      // Note: These tests verify the estimation logic, not actual file compression
      // since we don't have actual files in unit tests

      test('estimateImageSize returns smaller size at lower quality', () async {
        // Create a temporary file with known size for testing
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_image_estimate.tmp');
        // Write 1MB of data
        await testFile.writeAsBytes(List.filled(1000000, 0));

        try {
          // Lower quality should give smaller estimate
          final lowQualityEstimate = await compressionService.estimateImageSize(
            testFile,
            quality: 50,
          );
          final highQualityEstimate = await compressionService
              .estimateImageSize(testFile, quality: 90);

          // Higher quality should result in larger estimated size
          expect(highQualityEstimate, greaterThan(lowQualityEstimate));

          // Estimates should be less than original for reasonable quality
          expect(lowQualityEstimate, lessThan(1000000));
        } finally {
          // Clean up
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });

      test('estimateVideoSize varies by quality preset', () async {
        // Create a temporary file with known size for testing
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_video_estimate.tmp');
        // Write 10MB of data
        await testFile.writeAsBytes(List.filled(10000000, 0));

        try {
          // Get estimates for different quality presets
          final lowEstimate = await compressionService.estimateVideoSize(
            testFile,
            qualityPreset: CompressionQualityPreset.low,
          );
          final mediumEstimate = await compressionService.estimateVideoSize(
            testFile,
            qualityPreset: CompressionQualityPreset.medium,
          );
          final highEstimate = await compressionService.estimateVideoSize(
            testFile,
            qualityPreset: CompressionQualityPreset.high,
          );
          final originalEstimate = await compressionService.estimateVideoSize(
            testFile,
            qualityPreset: CompressionQualityPreset.original,
          );

          // Verify estimates follow expected ordering: low < medium < high < original
          expect(lowEstimate, lessThan(mediumEstimate));
          expect(mediumEstimate, lessThan(highEstimate));
          expect(highEstimate, lessThan(originalEstimate));

          // Original should equal actual file size
          expect(originalEstimate, equals(10000000));
        } finally {
          // Clean up
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });
    });
  });

  group('CompressionResult', () {
    test('savingsPercent calculates correctly', () {
      // Create a temp file for testing
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/test_compression_file.txt');

      final result = CompressionResult(
        file: tempFile,
        originalSize: 1000,
        compressedSize: 300,
        wasCompressed: true,
      );

      expect(result.savingsPercent, equals(70.0));
    });

    test('savingsPercent returns 0 for zero original size', () {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/test_compression_file.txt');

      final result = CompressionResult(
        file: tempFile,
        originalSize: 0,
        compressedSize: 0,
        wasCompressed: false,
      );

      expect(result.savingsPercent, equals(0));
    });

    test('sizeReduction formats bytes correctly', () {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/test_compression_file.txt');

      final result = CompressionResult(
        file: tempFile,
        originalSize: 2500000, // 2.5 MB
        compressedSize: 500000, // 500 KB
        wasCompressed: true,
      );

      // Size reduction is 2 MB
      expect(result.sizeReduction, contains('MB'));
    });
  });

  group('CompressionProgress', () {
    test('creates progress with required fields', () {
      const progress = CompressionProgress(
        progress: 0.5,
        stage: 'Compressing...',
      );

      expect(progress.progress, equals(0.5));
      expect(progress.stage, equals('Compressing...'));
      expect(progress.estimatedSize, isNull);
    });

    test('creates progress with optional estimated size', () {
      const progress = CompressionProgress(
        progress: 0.75,
        stage: 'Almost done',
        estimatedSize: 500000,
      );

      expect(progress.estimatedSize, equals(500000));
    });
  });

  group('CompressionQualityPreset', () {
    test('all presets have display names', () {
      for (final preset in CompressionQualityPreset.values) {
        expect(preset.displayName, isNotEmpty);
      }
    });

    test('fromString returns correct preset', () {
      expect(
        CompressionQualityPreset.fromString('low'),
        equals(CompressionQualityPreset.low),
      );
      expect(
        CompressionQualityPreset.fromString('medium'),
        equals(CompressionQualityPreset.medium),
      );
      expect(
        CompressionQualityPreset.fromString('high'),
        equals(CompressionQualityPreset.high),
      );
      expect(
        CompressionQualityPreset.fromString('original'),
        equals(CompressionQualityPreset.original),
      );
    });

    test('fromString returns medium for invalid values', () {
      expect(
        CompressionQualityPreset.fromString('invalid'),
        equals(CompressionQualityPreset.medium),
      );
      expect(
        CompressionQualityPreset.fromString(''),
        equals(CompressionQualityPreset.medium),
      );
    });

    test('display names are user-friendly', () {
      expect(CompressionQualityPreset.low.displayName, equals('Low (480p)'));
      expect(
        CompressionQualityPreset.medium.displayName,
        equals('Medium (540p)'),
      );
      expect(CompressionQualityPreset.high.displayName, equals('High (720p)'));
      expect(
        CompressionQualityPreset.original.displayName,
        equals('Original (1080p)'),
      );
    });
  });

  group('CompressionSettingsKeys', () {
    test('all keys are unique', () {
      final keys = [
        CompressionSettingsKeys.imageQuality,
        CompressionSettingsKeys.videoQuality,
        CompressionSettingsKeys.compressionEnabled,
        CompressionSettingsKeys.showSizeEstimate,
      ];

      final uniqueKeys = keys.toSet();
      expect(uniqueKeys.length, equals(keys.length));
    });

    test('keys have correct string values', () {
      expect(
        CompressionSettingsKeys.imageQuality,
        equals('compression_image_quality'),
      );
      expect(
        CompressionSettingsKeys.videoQuality,
        equals('compression_video_quality'),
      );
      expect(
        CompressionSettingsKeys.compressionEnabled,
        equals('compression_enabled'),
      );
      expect(
        CompressionSettingsKeys.showSizeEstimate,
        equals('compression_show_size_estimate'),
      );
    });
  });

  group('CompressionDefaults', () {
    test('has reasonable default values', () {
      expect(CompressionDefaults.imageQuality, equals(80));
      expect(CompressionDefaults.compressionEnabled, isTrue);
      expect(CompressionDefaults.showSizeEstimate, isTrue);
      expect(CompressionDefaults.maxImageWidth, equals(1920));
      expect(CompressionDefaults.maxImageHeight, equals(1080));
    });
  });

  group('formatBytes helper', () {
    test('formats bytes correctly', () {
      expect(formatBytes(0), equals('0 B'));
      expect(formatBytes(500), equals('500 B'));
      expect(formatBytes(1024), equals('1.0 KB'));
      expect(formatBytes(1536), equals('1.5 KB'));
      expect(formatBytes(1048576), equals('1.0 MB'));
      expect(formatBytes(1572864), equals('1.5 MB'));
      expect(formatBytes(1073741824), equals('1.0 GB'));
    });
  });

  group('Provider', () {
    test('mediaCompressionServiceProvider is available', () {
      expect(mediaCompressionServiceProvider, isNotNull);
    });
  });
}
