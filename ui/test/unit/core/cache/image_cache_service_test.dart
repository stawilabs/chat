import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/cache/image_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up method channel mock for path_provider
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getApplicationSupportDirectory' ||
                methodCall.method == 'getApplicationCacheDirectory' ||
                methodCall.method == 'getTemporaryDirectory') {
              return '/tmp/test_cache';
            }
            return null;
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
  });
  group('ImageCacheService', () {
    late ImageCacheService service;

    setUp(() {
      service = ImageCacheService();
    });

    group('memory cache operations', () {
      test('putInMemory and getFromMemory work correctly', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        const url = 'https://example.com/image.jpg';

        service.putInMemory(url, data);
        final retrieved = service.getFromMemory(url);

        expect(retrieved, equals(data));
      });

      test('getFromMemory returns null for missing URL', () {
        expect(
          service.getFromMemory('https://example.com/missing.jpg'),
          isNull,
        );
      });

      test('memory cache respects size limit', () {
        // Create a service with a small memory limit
        final smallService = ImageCacheService(memoryLimitBytes: 100);

        // Add items totaling more than 100 bytes
        for (var i = 0; i < 20; i++) {
          smallService.putInMemory(
            'https://example.com/image$i.jpg',
            Uint8List(10), // 10 bytes each
          );
        }

        // Should have evicted some items
        final stats = smallService.getStats();
        expect(stats['memoryUsedBytes'], lessThanOrEqualTo(100));
      });
    });

    group('cache statistics', () {
      test('getStats returns correct initial values', () {
        final stats = service.getStats();

        expect(stats['memoryUsedBytes'], equals(0));
        expect(stats['memoryCacheCount'], equals(0));
      });

      test('getStats updates after adding items', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        service.putInMemory('https://example.com/image1.jpg', data);
        service.putInMemory('https://example.com/image2.jpg', data);

        final stats = service.getStats();

        expect(stats['memoryUsedBytes'], equals(10));
        expect(stats['memoryCacheCount'], equals(2));
      });

      test('getStats includes usage percentage', () {
        final stats = service.getStats();

        expect(stats['memoryUsagePercent'], isNotNull);
        expect(
          stats['memoryMaxBytes'],
          equals(50 * 1024 * 1024),
        ); // 50MB default
      });
    });

    group('static cache managers', () {
      test('profileCacheManager is available', () {
        expect(ImageCacheService.profileCacheManager, isNotNull);
      });

      test('mediaCacheManager is available', () {
        expect(ImageCacheService.mediaCacheManager, isNotNull);
      });
    });
  });

  group('ImageCacheService providers', () {
    test('imageCacheServiceProvider is available', () {
      expect(imageCacheServiceProvider, isNotNull);
    });

    test('profileCacheManagerProvider is available', () {
      expect(profileCacheManagerProvider, isNotNull);
    });

    test('mediaCacheManagerProvider is available', () {
      expect(mediaCacheManagerProvider, isNotNull);
    });
  });

  group('ImageCacheService memory limit', () {
    test('default memory limit is 50MB', () {
      final service = ImageCacheService();
      final stats = service.getStats();

      expect(stats['memoryMaxBytes'], equals(50 * 1024 * 1024));
    });

    test('custom memory limit can be set', () {
      final service = ImageCacheService(memoryLimitBytes: 100 * 1024 * 1024);
      final stats = service.getStats();

      expect(stats['memoryMaxBytes'], equals(100 * 1024 * 1024));
    });

    test('small memory limit causes eviction', () {
      final service = ImageCacheService(memoryLimitBytes: 50);

      // Add 10 items of 10 bytes each (100 bytes total)
      for (var i = 0; i < 10; i++) {
        service.putInMemory('https://example.com/img$i.jpg', Uint8List(10));
      }

      // Should have evicted to stay under 50 bytes
      final stats = service.getStats();
      expect(stats['memoryUsedBytes'], lessThanOrEqualTo(50));
    });
  });

  group('Cache clearing', () {
    test('clearAll clears memory cache', () async {
      final service = ImageCacheService();

      service.putInMemory('https://example.com/img1.jpg', Uint8List(10));
      service.putInMemory('https://example.com/img2.jpg', Uint8List(10));

      await service.clearAll();

      expect(service.getFromMemory('https://example.com/img1.jpg'), isNull);
      expect(service.getFromMemory('https://example.com/img2.jpg'), isNull);

      final stats = service.getStats();
      expect(stats['memoryUsedBytes'], equals(0));
      expect(stats['memoryCacheCount'], equals(0));
    });
  });
}
