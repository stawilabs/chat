import 'dart:collection';

/// A generic LRU (Least Recently Used) cache implementation.
///
/// Items are evicted from the cache when the maximum size is exceeded,
/// with the least recently accessed items being removed first.
class LRUCache<K, V> {
  LRUCache({required this.maxSize, this.onEvict})
    : assert(maxSize > 0, 'maxSize must be greater than 0');

  /// Maximum number of items in the cache
  final int maxSize;

  /// Internal linked hash map that maintains insertion order
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  /// Callback invoked when an item is evicted from the cache
  final void Function(K key, V value)? onEvict;

  /// Gets an item from the cache.
  ///
  /// If found, the item is moved to the end (most recently used).
  /// Returns null if the key is not found.
  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value; // Move to end (most recently used)
    }
    return value;
  }

  /// Puts an item in the cache.
  ///
  /// If the key already exists, the value is updated and moved to the end.
  /// If adding this item exceeds maxSize, the least recently used item is evicted.
  ///
  /// Note: When replacing an existing entry, onEvict is NOT called. The onEvict
  /// callback is only invoked when items are evicted due to capacity limits.
  void put(K key, V value) {
    // Remove existing entry to update position (don't trigger onEvict for replacements)
    _cache.remove(key);
    _cache[key] = value;

    // Evict oldest entries if over capacity
    while (_cache.length > maxSize) {
      final oldestKey = _cache.keys.first;
      final oldestValue = _cache.remove(oldestKey);
      if (oldestValue != null) {
        onEvict?.call(oldestKey, oldestValue);
      }
    }
  }

  /// Removes an item from the cache.
  ///
  /// Returns the removed value, or null if the key was not found.
  V? remove(K key) {
    return _cache.remove(key);
  }

  /// Checks if the cache contains a key.
  bool containsKey(K key) => _cache.containsKey(key);

  /// Clears all items from the cache.
  void clear() {
    if (onEvict != null) {
      for (final entry in _cache.entries) {
        onEvict!(entry.key, entry.value);
      }
    }
    _cache.clear();
  }

  /// Current number of items in the cache.
  int get length => _cache.length;

  /// Whether the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Whether the cache is not empty.
  bool get isNotEmpty => _cache.isNotEmpty;

  /// All keys in the cache (oldest first).
  Iterable<K> get keys => _cache.keys;

  /// All values in the cache (oldest first).
  Iterable<V> get values => _cache.values;

  /// All entries in the cache (oldest first).
  Iterable<MapEntry<K, V>> get entries => _cache.entries;
}

/// A size-aware LRU cache that evicts based on total memory size.
///
/// Each item has an associated size, and items are evicted when
/// the total size exceeds the maximum allowed size.
class SizedLRUCache<K, V> {
  SizedLRUCache({
    required this.maxSizeBytes,
    required this.sizeCalculator,
    this.onEvict,
  }) : assert(maxSizeBytes > 0, 'maxSizeBytes must be greater than 0');

  /// Maximum total size of all items in bytes
  final int maxSizeBytes;

  /// Function to calculate the size of a value in bytes
  final int Function(V value) sizeCalculator;

  /// Internal linked hash map
  final LinkedHashMap<K, _SizedEntry<V>> _cache =
      LinkedHashMap<K, _SizedEntry<V>>();

  /// Callback invoked when an item is evicted
  final void Function(K key, V value)? onEvict;

  /// Current total size in bytes
  int _currentSizeBytes = 0;

  /// Gets an item from the cache.
  V? get(K key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _cache[key] = entry; // Move to end
      return entry.value;
    }
    return null;
  }

  /// Puts an item in the cache.
  void put(K key, V value) {
    final size = sizeCalculator(value);

    // Remove existing entry if present
    final existing = _cache.remove(key);
    if (existing != null) {
      _currentSizeBytes -= existing.size;
    }

    // Evict entries until we have enough space
    while (_cache.isNotEmpty && _currentSizeBytes + size > maxSizeBytes) {
      final oldestKey = _cache.keys.first;
      final oldestEntry = _cache.remove(oldestKey);
      if (oldestEntry != null) {
        _currentSizeBytes -= oldestEntry.size;
        onEvict?.call(oldestKey, oldestEntry.value);
      }
    }

    // Only add if the item fits in the cache
    if (size <= maxSizeBytes) {
      _cache[key] = _SizedEntry(value, size);
      _currentSizeBytes += size;
    }
  }

  /// Removes an item from the cache.
  V? remove(K key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _currentSizeBytes -= entry.size;
      return entry.value;
    }
    return null;
  }

  /// Checks if the cache contains a key.
  bool containsKey(K key) => _cache.containsKey(key);

  /// Clears all items from the cache.
  void clear() {
    if (onEvict != null) {
      for (final entry in _cache.entries) {
        onEvict!(entry.key, entry.value.value);
      }
    }
    _cache.clear();
    _currentSizeBytes = 0;
  }

  /// Current number of items in the cache.
  int get length => _cache.length;

  /// Current total size in bytes.
  int get currentSizeBytes => _currentSizeBytes;

  /// Maximum size in bytes.
  int get maxSize => maxSizeBytes;

  /// Percentage of cache used (0.0 to 1.0).
  double get usageRatio =>
      maxSizeBytes > 0 ? _currentSizeBytes / maxSizeBytes : 0.0;

  /// Whether the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// All keys in the cache (oldest first).
  Iterable<K> get keys => _cache.keys;
}

class _SizedEntry<V> {
  _SizedEntry(this.value, this.size);
  final V value;
  final int size;
}
