import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/cache/lru_cache.dart';

void main() {
  group('LRUCache', () {
    group('basic operations', () {
      test('put and get returns correct value', () {
        final cache = LRUCache<String, int>(maxSize: 3);

        cache.put('a', 1);
        cache.put('b', 2);
        cache.put('c', 3);

        expect(cache.get('a'), equals(1));
        expect(cache.get('b'), equals(2));
        expect(cache.get('c'), equals(3));
      });

      test('get returns null for missing key', () {
        final cache = LRUCache<String, int>(maxSize: 3);

        expect(cache.get('missing'), isNull);
      });

      test('put updates existing key', () {
        final cache = LRUCache<String, int>(maxSize: 3);

        cache.put('a', 1);
        cache.put('a', 10);

        expect(cache.get('a'), equals(10));
        expect(cache.length, equals(1));
      });

      test('remove removes item from cache', () {
        final cache = LRUCache<String, int>(maxSize: 3);

        cache.put('a', 1);
        final removed = cache.remove('a');

        expect(removed, equals(1));
        expect(cache.get('a'), isNull);
        expect(cache.length, equals(0));
      });

      test('remove returns null for missing key', () {
        final cache = LRUCache<String, int>(maxSize: 3);

        expect(cache.remove('missing'), isNull);
      });

      test('containsKey returns correct value', () {
        final cache = LRUCache<String, int>(maxSize: 3);

        cache.put('a', 1);

        expect(cache.containsKey('a'), isTrue);
        expect(cache.containsKey('b'), isFalse);
      });

      test('clear removes all items', () {
        final cache = LRUCache<String, int>(maxSize: 3);

        cache.put('a', 1);
        cache.put('b', 2);
        cache.clear();

        expect(cache.isEmpty, isTrue);
        expect(cache.length, equals(0));
      });
    });

    group('eviction', () {
      test('evicts oldest item when maxSize exceeded', () {
        final cache = LRUCache<String, int>(maxSize: 3);

        cache.put('a', 1);
        cache.put('b', 2);
        cache.put('c', 3);
        cache.put('d', 4); // Should evict 'a'

        expect(cache.get('a'), isNull);
        expect(cache.get('b'), equals(2));
        expect(cache.get('c'), equals(3));
        expect(cache.get('d'), equals(4));
        expect(cache.length, equals(3));
      });

      test('accessing item makes it most recently used', () {
        final cache = LRUCache<String, int>(maxSize: 3);

        cache.put('a', 1);
        cache.put('b', 2);
        cache.put('c', 3);

        cache.get('a'); // Access 'a', making it most recent

        cache.put('d', 4); // Should evict 'b' (now oldest)

        expect(cache.get('a'), equals(1)); // 'a' should still exist
        expect(cache.get('b'), isNull); // 'b' should be evicted
        expect(cache.get('c'), equals(3));
        expect(cache.get('d'), equals(4));
      });

      test('onEvict callback is called when item is evicted', () {
        final evictedItems = <String>[];
        final cache = LRUCache<String, int>(
          maxSize: 2,
          onEvict: (key, value) => evictedItems.add(key),
        );

        cache.put('a', 1);
        cache.put('b', 2);
        cache.put('c', 3); // Evicts 'a'

        expect(evictedItems, contains('a'));
        expect(evictedItems.length, equals(1));
      });

      test('onEvict is called for all items on clear', () {
        final evictedItems = <String>[];
        final cache = LRUCache<String, int>(
          maxSize: 3,
          onEvict: (key, value) => evictedItems.add(key),
        );

        cache.put('a', 1);
        cache.put('b', 2);
        cache.put('c', 3);
        cache.clear();

        expect(evictedItems.length, equals(3));
        expect(evictedItems, containsAll(['a', 'b', 'c']));
      });
    });

    group('properties', () {
      test('length returns correct count', () {
        final cache = LRUCache<String, int>(maxSize: 5);

        expect(cache.length, equals(0));

        cache.put('a', 1);
        expect(cache.length, equals(1));

        cache.put('b', 2);
        expect(cache.length, equals(2));
      });

      test('isEmpty and isNotEmpty work correctly', () {
        final cache = LRUCache<String, int>(maxSize: 3);

        expect(cache.isEmpty, isTrue);
        expect(cache.isNotEmpty, isFalse);

        cache.put('a', 1);

        expect(cache.isEmpty, isFalse);
        expect(cache.isNotEmpty, isTrue);
      });

      test('keys returns all keys in order', () {
        final cache = LRUCache<String, int>(maxSize: 3);

        cache.put('a', 1);
        cache.put('b', 2);
        cache.put('c', 3);

        expect(cache.keys.toList(), equals(['a', 'b', 'c']));
      });

      test('values returns all values in order', () {
        final cache = LRUCache<String, int>(maxSize: 3);

        cache.put('a', 1);
        cache.put('b', 2);
        cache.put('c', 3);

        expect(cache.values.toList(), equals([1, 2, 3]));
      });
    });
  });

  group('SizedLRUCache', () {
    group('basic operations', () {
      test('put and get returns correct value', () {
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 100,
          sizeCalculator: (bytes) => bytes.length,
        );

        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        cache.put('a', data);

        expect(cache.get('a'), equals(data));
      });

      test('get returns null for missing key', () {
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 100,
          sizeCalculator: (bytes) => bytes.length,
        );

        expect(cache.get('missing'), isNull);
      });

      test('put updates existing key', () {
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 100,
          sizeCalculator: (bytes) => bytes.length,
        );

        final data1 = Uint8List.fromList([1, 2, 3]);
        final data2 = Uint8List.fromList([4, 5, 6, 7, 8]);

        cache.put('a', data1);
        expect(cache.currentSizeBytes, equals(3));

        cache.put('a', data2);
        expect(cache.currentSizeBytes, equals(5));
        expect(cache.get('a'), equals(data2));
      });

      test('remove removes item and updates size', () {
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 100,
          sizeCalculator: (bytes) => bytes.length,
        );

        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        cache.put('a', data);

        expect(cache.currentSizeBytes, equals(5));

        cache.remove('a');

        expect(cache.currentSizeBytes, equals(0));
        expect(cache.get('a'), isNull);
      });

      test('clear resets size to zero', () {
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 100,
          sizeCalculator: (bytes) => bytes.length,
        );

        cache.put('a', Uint8List.fromList([1, 2, 3]));
        cache.put('b', Uint8List.fromList([4, 5, 6, 7]));

        expect(cache.currentSizeBytes, equals(7));

        cache.clear();

        expect(cache.currentSizeBytes, equals(0));
        expect(cache.length, equals(0));
      });
    });

    group('size-based eviction', () {
      test('evicts oldest items when size exceeded', () {
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 10,
          sizeCalculator: (bytes) => bytes.length,
        );

        cache.put('a', Uint8List.fromList([1, 2, 3])); // 3 bytes
        cache.put('b', Uint8List.fromList([4, 5, 6])); // 3 bytes
        cache.put(
          'c',
          Uint8List.fromList([7, 8, 9, 10, 11]),
        ); // 5 bytes, evicts 'a'

        expect(cache.get('a'), isNull);
        expect(cache.get('b'), isNotNull);
        expect(cache.get('c'), isNotNull);
        expect(cache.currentSizeBytes, equals(8));
      });

      test('accessing item makes it most recently used', () {
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 10,
          sizeCalculator: (bytes) => bytes.length,
        );

        cache.put('a', Uint8List.fromList([1, 2, 3])); // 3 bytes
        cache.put('b', Uint8List.fromList([4, 5, 6])); // 3 bytes

        cache.get('a'); // Access 'a', making it most recent

        cache.put(
          'c',
          Uint8List.fromList([7, 8, 9, 10, 11]),
        ); // 5 bytes, evicts 'b'

        expect(cache.get('a'), isNotNull);
        expect(cache.get('b'), isNull);
        expect(cache.get('c'), isNotNull);
      });

      test('rejects item larger than maxSize', () {
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 5,
          sizeCalculator: (bytes) => bytes.length,
        );

        cache.put('large', Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));

        expect(cache.get('large'), isNull);
        expect(cache.currentSizeBytes, equals(0));
      });

      test('onEvict callback is called when item is evicted', () {
        final evictedItems = <String>[];
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 5,
          sizeCalculator: (bytes) => bytes.length,
          onEvict: (key, value) => evictedItems.add(key),
        );

        cache.put('a', Uint8List.fromList([1, 2, 3]));
        cache.put('b', Uint8List.fromList([4, 5, 6])); // Evicts 'a'

        expect(evictedItems, contains('a'));
      });
    });

    group('properties', () {
      test('currentSizeBytes tracks total size', () {
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 100,
          sizeCalculator: (bytes) => bytes.length,
        );

        expect(cache.currentSizeBytes, equals(0));

        cache.put('a', Uint8List.fromList([1, 2, 3]));
        expect(cache.currentSizeBytes, equals(3));

        cache.put('b', Uint8List.fromList([4, 5, 6, 7]));
        expect(cache.currentSizeBytes, equals(7));
      });

      test('usageRatio calculates correctly', () {
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 100,
          sizeCalculator: (bytes) => bytes.length,
        );

        expect(cache.usageRatio, equals(0.0));

        cache.put('a', Uint8List.fromList(List.filled(50, 0)));
        expect(cache.usageRatio, equals(0.5));

        cache.put('b', Uint8List.fromList(List.filled(25, 0)));
        expect(cache.usageRatio, equals(0.75));
      });

      test('maxSize returns maxSizeBytes', () {
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 100,
          sizeCalculator: (bytes) => bytes.length,
        );

        expect(cache.maxSize, equals(100));
      });
    });

    group('memory limit compliance', () {
      test('respects 50MB memory limit', () {
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 50 * 1024 * 1024, // 50MB
          sizeCalculator: (bytes) => bytes.length,
        );

        // Add items totaling 60MB
        for (var i = 0; i < 6; i++) {
          cache.put('item$i', Uint8List(10 * 1024 * 1024)); // 10MB each
        }

        // Should have evicted some items to stay under 50MB
        expect(cache.currentSizeBytes, lessThanOrEqualTo(50 * 1024 * 1024));
      });
    });
  });

  group('Cache eviction integration tests', () {
    group('LRU eviction order', () {
      test('evicts items in correct LRU order', () {
        final evictionOrder = <String>[];
        final cache = LRUCache<String, int>(
          maxSize: 5,
          onEvict: (key, value) => evictionOrder.add(key),
        );

        // Add items a-e
        for (var i = 0; i < 5; i++) {
          cache.put(String.fromCharCode(97 + i), i);
        }

        // Access b, d (making them recently used)
        cache.get('b');
        cache.get('d');

        // Add 3 more items to trigger evictions
        cache.put('f', 5);
        cache.put('g', 6);
        cache.put('h', 7);

        // Eviction order should be: a, c, e (least recently used)
        expect(evictionOrder, equals(['a', 'c', 'e']));
      });

      test('multiple accesses affect eviction order', () {
        final evictionOrder = <String>[];
        final cache = LRUCache<String, int>(
          maxSize: 3,
          onEvict: (key, value) => evictionOrder.add(key),
        );

        cache.put('a', 1);
        cache.put('b', 2);
        cache.put('c', 3);

        // Access pattern: a, c, a, b, c
        cache.get('a');
        cache.get('c');
        cache.get('a');
        cache.get('b');
        cache.get('c');

        // Now order is: a(oldest), b, c(newest)
        cache.put('d', 4); // Evicts 'a'

        expect(evictionOrder, equals(['a']));
      });
    });

    group('size-based eviction cascades', () {
      test('single large item evicts multiple small items', () {
        final evicted = <String>[];
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 100,
          sizeCalculator: (bytes) => bytes.length,
          onEvict: (key, value) => evicted.add(key),
        );

        // Add 10 small items (10 bytes each = 100 total)
        for (var i = 0; i < 10; i++) {
          cache.put('small$i', Uint8List(10));
        }

        expect(cache.currentSizeBytes, equals(100));

        // Add one large item (50 bytes) - should evict at least 5 small items
        cache.put('large', Uint8List(50));

        expect(evicted.length, greaterThanOrEqualTo(5));
        expect(cache.currentSizeBytes, lessThanOrEqualTo(100));
        expect(cache.get('large'), isNotNull);
      });

      test('evicts minimum necessary to fit new item', () {
        final evicted = <String>[];
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 100,
          sizeCalculator: (bytes) => bytes.length,
          onEvict: (key, value) => evicted.add(key),
        );

        cache.put('a', Uint8List(30)); // 30 bytes
        cache.put('b', Uint8List(30)); // 60 bytes
        cache.put('c', Uint8List(30)); // 90 bytes

        // Add 20-byte item - needs only 10 bytes freed
        cache.put('d', Uint8List(20));

        // Should evict only 'a' (oldest, 30 bytes)
        expect(evicted, equals(['a']));
        expect(cache.currentSizeBytes, equals(80)); // 30 + 30 + 20
      });
    });

    group('concurrent-like access patterns', () {
      test('rapid put/get interleaving maintains consistency', () {
        final cache = LRUCache<String, int>(maxSize: 10);

        // Simulate rapid access pattern
        for (var round = 0; round < 100; round++) {
          final key = 'key${round % 15}'; // More keys than cache size
          cache.put(key, round);

          // Access some random existing keys
          for (var i = 0; i < 3; i++) {
            cache.get('key${(round + i) % 15}');
          }
        }

        expect(cache.length, equals(10));
        expect(cache.isNotEmpty, isTrue);
      });

      test('batch insertions with eviction callback', () {
        var evictCount = 0;
        final cache = LRUCache<String, int>(
          maxSize: 5,
          onEvict: (key, value) => evictCount++,
        );

        // Insert 100 items
        for (var i = 0; i < 100; i++) {
          cache.put('key$i', i);
        }

        // Should have evicted 95 items (100 - 5)
        expect(evictCount, equals(95));
        expect(cache.length, equals(5));
      });
    });

    group('eviction callback behavior', () {
      test('eviction callback receives correct key-value pairs', () {
        final evicted = <MapEntry<String, int>>[];
        final cache = LRUCache<String, int>(
          maxSize: 2,
          onEvict: (key, value) => evicted.add(MapEntry(key, value)),
        );

        cache.put('a', 100);
        cache.put('b', 200);
        cache.put('c', 300); // Evicts 'a'
        cache.put('d', 400); // Evicts 'b'

        expect(evicted.length, equals(2));
        expect(evicted[0].key, equals('a'));
        expect(evicted[0].value, equals(100));
        expect(evicted[1].key, equals('b'));
        expect(evicted[1].value, equals(200));
      });

      test('eviction callback for sized cache receives actual data', () {
        final evicted = <MapEntry<String, int>>[];
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 20,
          sizeCalculator: (bytes) => bytes.length,
          onEvict: (key, value) => evicted.add(MapEntry(key, value.length)),
        );

        cache.put('a', Uint8List(10));
        cache.put('b', Uint8List(15)); // Evicts 'a'

        expect(evicted.length, equals(1));
        expect(evicted[0].key, equals('a'));
        expect(evicted[0].value, equals(10)); // Size of evicted data
      });
    });

    group('edge cases', () {
      test('cache size of 1 works correctly', () {
        final evicted = <String>[];
        final cache = LRUCache<String, int>(
          maxSize: 1,
          onEvict: (key, _) => evicted.add(key),
        );

        cache.put('a', 1);
        cache.put('b', 2);
        cache.put('c', 3);

        expect(evicted, equals(['a', 'b']));
        expect(cache.get('c'), equals(3));
        expect(cache.length, equals(1));
      });

      test('updating same key does not trigger eviction', () {
        var evictCount = 0;
        final cache = LRUCache<String, int>(
          maxSize: 2,
          onEvict: (key, value) => evictCount++,
        );

        cache.put('a', 1);
        cache.put('a', 2);
        cache.put('a', 3);

        expect(evictCount, equals(0));
        expect(cache.length, equals(1));
      });

      test('sized cache handles zero-size items', () {
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 10,
          sizeCalculator: (bytes) => bytes.length,
        );

        cache.put('empty', Uint8List(0));
        expect(cache.get('empty'), isNotNull);
        expect(cache.currentSizeBytes, equals(0));
      });

      test('sized cache handles exact-fit items', () {
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 10,
          sizeCalculator: (bytes) => bytes.length,
        );

        cache.put('exact', Uint8List(10));
        expect(cache.get('exact'), isNotNull);
        expect(cache.currentSizeBytes, equals(10));
      });
    });

    group('real-world image cache scenarios', () {
      test('thumbnail gallery simulation', () {
        // Simulate a thumbnail gallery with 100 thumbnails, cache for 20
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 20 * 50 * 1024, // 20 * 50KB thumbnails
          sizeCalculator: (bytes) => bytes.length,
        );

        // Load thumbnails
        for (var i = 0; i < 100; i++) {
          final thumbnail = Uint8List(50 * 1024); // 50KB each
          cache.put('thumb_$i', thumbnail);
        }

        // Verify cache stays within limits
        expect(cache.currentSizeBytes, lessThanOrEqualTo(20 * 50 * 1024));
        expect(cache.length, lessThanOrEqualTo(20));
      });

      test('profile picture cache with varying sizes', () {
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 5 * 1024 * 1024, // 5MB
          sizeCalculator: (bytes) => bytes.length,
        );

        // Add profile pictures of varying sizes (10KB - 500KB)
        for (var i = 0; i < 50; i++) {
          final size = (10 + (i % 50) * 10) * 1024; // 10KB to 500KB
          cache.put('profile_$i', Uint8List(size));
        }

        // Cache should respect limit
        expect(cache.currentSizeBytes, lessThanOrEqualTo(5 * 1024 * 1024));
      });

      test('chat image scroll simulation', () {
        // Simulate scrolling through chat images
        final cache = SizedLRUCache<String, Uint8List>(
          maxSizeBytes: 10 * 1024 * 1024, // 10MB
          sizeCalculator: (bytes) => bytes.length,
        );

        // First pass: load images 0-29
        for (var i = 0; i < 30; i++) {
          cache.put('image_$i', Uint8List(500 * 1024)); // 500KB each
        }

        // Scroll back: access images 10-20 (making them recent)
        for (var i = 10; i <= 20; i++) {
          cache.get('image_$i');
        }

        // Load more images 30-39
        for (var i = 30; i < 40; i++) {
          cache.put('image_$i', Uint8List(500 * 1024));
        }

        // Images 10-20 should still be in cache (recently accessed)
        var recentHits = 0;
        for (var i = 10; i <= 20; i++) {
          if (cache.get('image_$i') != null) recentHits++;
        }

        // Most of the recently accessed images should still be cached
        expect(recentHits, greaterThanOrEqualTo(8));
      });
    });
  });
}
