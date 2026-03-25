import 'dart:async';
import 'dart:collection';

/// Utility class for optimizing performance on low-resource devices
class PerformanceUtils {
  PerformanceUtils._();

  /// Debounce a function call
  static Timer? _debounceTimer;
  static void debounce(Duration duration, void Function() action) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, action);
  }

  /// Throttle a function call (max once per duration)
  static final Map<String, DateTime> _throttleTimestamps = {};
  static bool throttle(String key, Duration duration) {
    final now = DateTime.now();
    final lastCall = _throttleTimestamps[key];
    if (lastCall == null || now.difference(lastCall) >= duration) {
      _throttleTimestamps[key] = now;
      return true;
    }
    return false;
  }

  /// Clean up throttle timestamps to prevent memory leaks
  static void cleanupThrottles() {
    final now = DateTime.now();
    _throttleTimestamps.removeWhere(
      (key, timestamp) =>
          now.difference(timestamp) > const Duration(minutes: 5),
    );
  }
}

/// LRU Cache implementation for caching API responses
/// Helps reduce memory usage on low-resource devices
class LRUCache<K, V> {
  LRUCache({this.maxSize = 100});
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap();

  V? get(K key) {
    if (!_cache.containsKey(key)) return null;
    // Move to end (most recently used)
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    // Remove if already exists
    _cache.remove(key);
    // Add to end
    _cache[key] = value;
    // Evict oldest if over capacity
    while (_cache.length > maxSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  void remove(K key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  int get length => _cache.length;
  bool containsKey(K key) => _cache.containsKey(key);
}

/// Batch processor for reducing API calls
/// Collects items and processes them in batches
class BatchProcessor<T> {
  BatchProcessor({
    required this.processor,
    this.batchSize = 10,
    this.maxWait = const Duration(milliseconds: 500),
  });
  final int batchSize;
  final Duration maxWait;
  final Future<void> Function(List<T> items) processor;

  final List<T> _pending = [];
  Timer? _timer;
  bool _isProcessing = false;

  void add(T item) {
    _pending.add(item);

    if (_pending.length >= batchSize) {
      _processBatch();
    } else {
      _timer ??= Timer(maxWait, _processBatch);
    }
  }

  Future<void> _processBatch() async {
    _timer?.cancel();
    _timer = null;

    if (_pending.isEmpty || _isProcessing) return;

    _isProcessing = true;
    try {
      final batch = List<T>.from(_pending);
      _pending.clear();
      await processor(batch);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> flush() async {
    await _processBatch();
  }

  void dispose() {
    _timer?.cancel();
    _pending.clear();
  }
}

/// Rate limiter to prevent overwhelming the API
class RateLimiter {
  RateLimiter({
    this.maxRequests = 10,
    this.window = const Duration(seconds: 1),
  });
  final int maxRequests;
  final Duration window;
  final Queue<DateTime> _requestTimes = Queue();

  /// Returns true if request is allowed, false if rate limited
  bool allowRequest() {
    final now = DateTime.now();

    // Remove expired timestamps
    while (_requestTimes.isNotEmpty &&
        now.difference(_requestTimes.first) > window) {
      _requestTimes.removeFirst();
    }

    if (_requestTimes.length < maxRequests) {
      _requestTimes.addLast(now);
      return true;
    }

    return false;
  }

  /// Wait until request is allowed
  Future<void> waitForSlot() async {
    while (!allowRequest()) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}

/// Memory-efficient stream transformer that limits buffer size
class BoundedStreamTransformer<T> extends StreamTransformerBase<T, T> {
  BoundedStreamTransformer({this.maxBufferSize = 100});
  final int maxBufferSize;

  @override
  Stream<T> bind(Stream<T> stream) {
    final controller = StreamController<T>();
    final buffer = Queue<T>();

    stream.listen(
      (data) {
        buffer.addLast(data);
        while (buffer.length > maxBufferSize) {
          buffer.removeFirst(); // Drop oldest items
        }
        controller.add(data);
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    return controller.stream;
  }
}
