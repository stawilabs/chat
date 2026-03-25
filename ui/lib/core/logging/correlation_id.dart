import 'package:uuid/uuid.dart';

/// Manages correlation IDs for request tracing across the application
///
/// Correlation IDs help trace related log entries across different
/// parts of the system, making it easier to debug issues and understand
/// the flow of a request.
class CorrelationId {
  static const _uuid = Uuid();

  /// The current correlation ID for the active request/operation
  static String? _currentId;

  /// Stack of correlation IDs for nested operations
  static final List<String> _idStack = [];

  /// Generate a new unique correlation ID
  static String generate() {
    return _uuid.v4();
  }

  /// Get the current correlation ID, or null if none is set
  static String? get current => _currentId;

  /// Set the current correlation ID
  ///
  /// Typically used at the start of a request or operation
  static void set(String id) {
    _currentId = id;
  }

  /// Clear the current correlation ID
  static void clear() {
    _currentId = null;
  }

  /// Push a new correlation ID onto the stack (for nested operations)
  ///
  /// Returns the new correlation ID
  static String push([String? id]) {
    final newId = id ?? generate();
    if (_currentId != null) {
      _idStack.add(_currentId!);
    }
    _currentId = newId;
    return newId;
  }

  /// Pop the correlation ID stack, restoring the previous ID
  static void pop() {
    if (_idStack.isNotEmpty) {
      _currentId = _idStack.removeLast();
    } else {
      _currentId = null;
    }
  }

  /// Execute a function with a specific correlation ID
  ///
  /// The correlation ID is automatically set before the function runs
  /// and cleared (or restored) after it completes.
  static T withCorrelationId<T>(String id, T Function() fn) {
    final previousId = _currentId;
    _currentId = id;
    try {
      return fn();
    } finally {
      _currentId = previousId;
    }
  }

  /// Execute an async function with a specific correlation ID
  static Future<T> withCorrelationIdAsync<T>(
    String id,
    Future<T> Function() fn,
  ) async {
    final previousId = _currentId;
    _currentId = id;
    try {
      return await fn();
    } finally {
      _currentId = previousId;
    }
  }

  /// Execute a function with a new generated correlation ID
  static T withNewCorrelationId<T>(T Function(String correlationId) fn) {
    final id = generate();
    return withCorrelationId(id, () => fn(id));
  }

  /// Execute an async function with a new generated correlation ID
  static Future<T> withNewCorrelationIdAsync<T>(
    Future<T> Function(String correlationId) fn,
  ) async {
    final id = generate();
    return withCorrelationIdAsync(id, () => fn(id));
  }

  /// Create a child correlation ID that includes the parent ID
  ///
  /// Format: parentId:childSuffix
  /// This helps track parent-child relationships in traces
  static String createChildId([String? parentId]) {
    final parent = parentId ?? _currentId;
    final childSuffix = _uuid.v4().substring(0, 8);
    if (parent != null) {
      return '$parent:$childSuffix';
    }
    return childSuffix;
  }
}
