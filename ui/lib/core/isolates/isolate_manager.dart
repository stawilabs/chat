import 'dart:async';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import 'isolate_metrics.dart';

/// Message types for isolate communication
enum IsolateMessageType {
  /// Execute a task with a payload
  execute,

  /// Response from task execution
  response,

  /// Error occurred during task execution
  error,

  /// Shutdown the isolate
  shutdown,

  /// Acknowledgment of shutdown
  shutdownAck,
}

/// Message wrapper for isolate communication
class IsolateMessage {
  IsolateMessage({
    required this.type,
    this.taskId,
    this.taskType,
    this.payload,
    this.result,
    this.error,
    this.stackTrace,
    this.sendPort,
  });
  final IsolateMessageType type;
  final String? taskId;
  final String? taskType;
  final dynamic payload;
  final dynamic result;
  final String? error;
  final String? stackTrace;
  final SendPort? sendPort;
}

/// Callback type for isolate entry point
typedef IsolateEntryPoint = void Function(SendPort sendPort);

/// Manages a pool of background isolates for heavy operations
///
/// Provides singleton access to long-running isolates that can be used
/// to offload CPU-intensive tasks from the main thread.
///
/// Example:
/// ```dart
/// final manager = IsolateManager.instance;
/// await manager.initialize();
///
/// final result = await manager.execute(
///   'message_processor',
///   'processMessages',
///   {'messages': messages},
/// );
/// ```
class IsolateManager {
  IsolateManager._();

  static final IsolateManager _instance = IsolateManager._();

  /// Get the singleton instance
  static IsolateManager get instance => _instance;

  /// Map of isolate name to isolate info
  final Map<String, _IsolateInfo> _isolates = {};

  /// Pending responses waiting for completion
  final Map<String, Completer<dynamic>> _pendingResponses = {};

  /// Counter for generating unique task IDs
  int _taskIdCounter = 0;

  /// Whether the manager has been initialized
  bool _initialized = false;

  /// Whether the manager is shutting down
  bool _shuttingDown = false;

  /// Metrics tracker
  final IsolateMetrics metrics = IsolateMetrics();

  /// Check if manager is initialized
  bool get isInitialized => _initialized;

  /// Get list of active isolate names
  List<String> get activeIsolates => _isolates.keys.toList();

  /// Initialize the isolate manager
  ///
  /// This is idempotent and can be called multiple times safely.
  Future<void> initialize() async {
    if (_initialized) return;

    AppLogger.info('Initializing IsolateManager');
    _initialized = true;
    _shuttingDown = false;
  }

  /// Spawn a new isolate with the given entry point
  ///
  /// [name] - Unique name for this isolate
  /// [entryPoint] - Function to run in the isolate
  /// [debugName] - Optional debug name for the isolate
  ///
  /// Returns true if isolate was spawned successfully
  Future<bool> spawnIsolate(
    String name,
    IsolateEntryPoint entryPoint, {
    String? debugName,
  }) async {
    if (_shuttingDown) {
      AppLogger.warning(
        'Cannot spawn isolate while shutting down',
        data: {'isolateName': name},
      );
      return false;
    }

    if (_isolates.containsKey(name)) {
      AppLogger.debug('Isolate already exists', data: {'isolateName': name});
      return true;
    }

    try {
      final receivePort = ReceivePort();

      final isolate = await Isolate.spawn(
        _isolateRunner,
        _IsolateConfig(entryPoint: entryPoint, sendPort: receivePort.sendPort),
        debugName: debugName ?? name,
      );

      // Wait for the isolate to send its SendPort
      final sendPort = await receivePort.first as SendPort;

      // Create a new ReceivePort for ongoing communication
      final communicationPort = ReceivePort();

      // Send our communication port to the isolate
      sendPort.send(communicationPort.sendPort);

      // Listen for responses - subscription is stored in _IsolateInfo and
      // cancelled in shutdownIsolate()
      // ignore: cancel_subscriptions
      final subscription = communicationPort.listen(_handleResponse);

      _isolates[name] = _IsolateInfo(
        isolate: isolate,
        sendPort: sendPort,
        receivePort: communicationPort,
        subscription: subscription,
      );

      AppLogger.info(
        'Isolate spawned successfully',
        data: {'isolateName': name},
      );

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to spawn isolate',
        error: e,
        stackTrace: stackTrace,
        data: {'isolateName': name},
      );
      return false;
    }
  }

  /// Execute a task on the specified isolate
  ///
  /// [isolateName] - Name of the isolate to execute on
  /// [taskType] - Type of task to execute (used by isolate to dispatch)
  /// [payload] - Data to send to the isolate
  /// [timeout] - Optional timeout for the task
  ///
  /// Returns the result from the isolate
  Future<T> execute<T>(
    String isolateName,
    String taskType,
    Object? payload, {
    Duration? timeout,
  }) async {
    if (_shuttingDown) {
      throw StateError('IsolateManager is shutting down');
    }

    final isolateInfo = _isolates[isolateName];
    if (isolateInfo == null) {
      throw StateError('Isolate "$isolateName" not found');
    }

    final taskId = _generateTaskId();
    final completer = Completer<dynamic>();
    _pendingResponses[taskId] = completer;

    final startTime = DateTime.now();

    // Send the task
    isolateInfo.sendPort.send(
      IsolateMessage(
        type: IsolateMessageType.execute,
        taskId: taskId,
        taskType: taskType,
        payload: payload,
      ),
    );

    // Track queue depth
    metrics.incrementQueueDepth(isolateName);

    try {
      final result = timeout != null
          ? await completer.future.timeout(
              timeout,
              onTimeout: () {
                _pendingResponses.remove(taskId);
                metrics.decrementQueueDepth(isolateName);
                throw TimeoutException(
                  'Task $taskType on isolate $isolateName timed out',
                );
              },
            )
          : await completer.future;

      // Record metrics
      final duration = DateTime.now().difference(startTime);
      metrics.recordTaskExecution(isolateName, taskType, duration);
      metrics.decrementQueueDepth(isolateName);

      return result as T;
    } catch (e) {
      metrics.decrementQueueDepth(isolateName);
      rethrow;
    }
  }

  /// Execute a task and return on the main thread via callback
  ///
  /// This is useful for fire-and-forget tasks where you want to process
  /// the result on the main thread without awaiting.
  void executeWithCallback<T>(
    String isolateName,
    String taskType,
    Object? payload, {
    required void Function(T result) onSuccess,
    void Function(Object error, StackTrace? stackTrace)? onError,
    Duration? timeout,
  }) {
    execute<T>(isolateName, taskType, payload, timeout: timeout).then(
      onSuccess,
      onError: (e, st) {
        if (onError != null) {
          onError(e, st);
        } else {
          AppLogger.error(
            'Isolate task failed',
            error: e,
            stackTrace: st,
            data: {'isolateName': isolateName, 'taskType': taskType},
          );
        }
      },
    );
  }

  /// Handle response from an isolate
  void _handleResponse(Object? message) {
    if (message is! IsolateMessage) {
      AppLogger.warning('Received invalid message from isolate');
      return;
    }

    final taskId = message.taskId;
    if (taskId == null) {
      AppLogger.warning('Received message without taskId');
      return;
    }

    final completer = _pendingResponses.remove(taskId);
    if (completer == null) {
      AppLogger.warning(
        'No pending response for taskId',
        data: {'taskId': taskId},
      );
      return;
    }

    switch (message.type) {
      case IsolateMessageType.response:
        completer.complete(message.result);
        break;
      case IsolateMessageType.error:
        completer.completeError(
          IsolateTaskException(
            message.error ?? 'Unknown error',
            stackTrace: message.stackTrace,
          ),
        );
        break;
      default:
        completer.completeError(
          StateError('Unexpected message type: ${message.type}'),
        );
    }
  }

  /// Shutdown a specific isolate
  Future<void> shutdownIsolate(String name) async {
    final isolateInfo = _isolates.remove(name);
    if (isolateInfo == null) {
      AppLogger.debug(
        'Isolate not found for shutdown',
        data: {'isolateName': name},
      );
      return;
    }

    try {
      // Send shutdown message
      isolateInfo.sendPort.send(
        IsolateMessage(type: IsolateMessageType.shutdown),
      );

      // Wait briefly for graceful shutdown
      await Future.delayed(const Duration(milliseconds: 100));

      // Cancel subscription and close port
      await isolateInfo.subscription.cancel();
      isolateInfo.receivePort.close();

      // Kill the isolate
      isolateInfo.isolate.kill(priority: Isolate.immediate);

      AppLogger.info('Isolate shutdown complete', data: {'isolateName': name});
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error during isolate shutdown',
        error: e,
        stackTrace: stackTrace,
        data: {'isolateName': name},
      );
    }
  }

  /// Gracefully shutdown all isolates
  Future<void> shutdown() async {
    if (_shuttingDown) return;
    _shuttingDown = true;

    AppLogger.info('Shutting down IsolateManager');

    // Cancel all pending responses
    for (final entry in _pendingResponses.entries) {
      entry.value.completeError(StateError('IsolateManager is shutting down'));
    }
    _pendingResponses.clear();

    // Shutdown all isolates
    final isolateNames = _isolates.keys.toList();
    for (final name in isolateNames) {
      await shutdownIsolate(name);
    }

    _initialized = false;
    AppLogger.info('IsolateManager shutdown complete');
  }

  /// Generate a unique task ID using isolate hash, microsecond timestamp,
  /// and monotonic counter for cross-isolate uniqueness
  String _generateTaskId() =>
      '${Isolate.current.hashCode}_${DateTime.now().microsecondsSinceEpoch}_${++_taskIdCounter}';
}

/// Configuration passed to isolate on spawn
class _IsolateConfig {
  _IsolateConfig({required this.entryPoint, required this.sendPort});
  final IsolateEntryPoint entryPoint;
  final SendPort sendPort;
}

/// Internal info about a running isolate
class _IsolateInfo {
  _IsolateInfo({
    required this.isolate,
    required this.sendPort,
    required this.receivePort,
    required this.subscription,
  });
  final Isolate isolate;
  final SendPort sendPort;
  final ReceivePort receivePort;
  final StreamSubscription<dynamic> subscription;
}

/// Entry point wrapper that handles communication setup
void _isolateRunner(_IsolateConfig config) {
  final receivePort = ReceivePort();

  // Send our port to the main isolate
  config.sendPort.send(receivePort.sendPort);

  // Wait for the communication port from main isolate
  receivePort.first.then((message) {
    final mainPort = message as SendPort;

    // Now run the actual entry point with the communication port
    // The entry point should listen on its own ReceivePort
    final isolateReceivePort = ReceivePort();
    mainPort.send(isolateReceivePort.sendPort);

    // The entry point handles its own message loop
    config.entryPoint(mainPort);
  });
}

/// Exception thrown when an isolate task fails
class IsolateTaskException implements Exception {
  IsolateTaskException(this.message, {this.stackTrace});
  final String message;
  final String? stackTrace;

  @override
  String toString() {
    var result = 'IsolateTaskException: $message';
    if (stackTrace != null) {
      result += '\nStack trace from isolate:\n$stackTrace';
    }
    return result;
  }
}

// Provider for IsolateManager
final isolateManagerProvider = Provider<IsolateManager>((ref) {
  return IsolateManager.instance;
});

// Provider to ensure isolate manager is initialized
final isolateManagerInitProvider = FutureProvider<bool>((ref) async {
  final manager = ref.watch(isolateManagerProvider);
  await manager.initialize();
  return true;
});
