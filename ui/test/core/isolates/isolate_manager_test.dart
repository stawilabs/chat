import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/isolates/isolate_manager.dart';

void main() {
  group('IsolateManager', () {
    late IsolateManager manager;

    setUp(() async {
      manager = IsolateManager.instance;
      await manager.initialize();
    });

    tearDown(() async {
      await manager.shutdown();
    });

    test('should initialize successfully', () {
      expect(manager.isInitialized, isTrue);
    });

    test('should return empty active isolates initially', () {
      expect(manager.activeIsolates, isEmpty);
    });

    test('should not be shutting down after initialization', () {
      expect(manager.isInitialized, isTrue);
    });

    test('should throw when executing on non-existent isolate', () {
      expect(
        () => manager.execute('non_existent', 'testTask', {}),
        throwsA(isA<StateError>()),
      );
    });

    test('should shutdown gracefully', () async {
      await manager.shutdown();
      expect(manager.isInitialized, isFalse);
    });

    test('should re-initialize after shutdown', () async {
      await manager.shutdown();
      expect(manager.isInitialized, isFalse);

      await manager.initialize();
      expect(manager.isInitialized, isTrue);
    });

    test('metrics should be accessible', () {
      expect(manager.metrics, isNotNull);
      expect(manager.metrics.getTaskCount('any'), equals(0));
    });
  });

  group('IsolateTaskException', () {
    test('should format message correctly', () {
      final exception = IsolateTaskException(
        'Test error',
        stackTrace: 'at test (test.dart:1)',
      );

      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), contains('at test'));
    });

    test('should handle missing stack trace', () {
      final exception = IsolateTaskException('Test error');

      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), isNot(contains('Stack trace')));
    });

    test('should preserve message', () {
      final exception = IsolateTaskException('Custom error message');
      expect(exception.message, equals('Custom error message'));
    });

    test('should preserve stack trace', () {
      final exception = IsolateTaskException(
        'Error',
        stackTrace: 'stack trace content',
      );
      expect(exception.stackTrace, equals('stack trace content'));
    });
  });

  group('IsolateMessage', () {
    test('should create execute message', () {
      final message = IsolateMessage(
        type: IsolateMessageType.execute,
        taskId: 'task-123',
        taskType: 'processMessages',
        payload: {'data': 'test'},
      );

      expect(message.type, equals(IsolateMessageType.execute));
      expect(message.taskId, equals('task-123'));
      expect(message.taskType, equals('processMessages'));
      expect(message.payload, isA<Map<String, dynamic>>());
    });

    test('should create response message', () {
      final message = IsolateMessage(
        type: IsolateMessageType.response,
        taskId: 'task-123',
        result: {'success': true},
      );

      expect(message.type, equals(IsolateMessageType.response));
      expect(message.taskId, equals('task-123'));
      expect(message.result, isA<Map<String, dynamic>>());
    });

    test('should create error message', () {
      final message = IsolateMessage(
        type: IsolateMessageType.error,
        taskId: 'task-123',
        error: 'Something went wrong',
        stackTrace: 'at function (file.dart:1)',
      );

      expect(message.type, equals(IsolateMessageType.error));
      expect(message.error, equals('Something went wrong'));
      expect(message.stackTrace, contains('at function'));
    });

    test('should create shutdown message', () {
      final message = IsolateMessage(type: IsolateMessageType.shutdown);

      expect(message.type, equals(IsolateMessageType.shutdown));
    });
  });

  group('IsolateMessageType', () {
    test('should have all required types', () {
      expect(IsolateMessageType.values, contains(IsolateMessageType.execute));
      expect(IsolateMessageType.values, contains(IsolateMessageType.response));
      expect(IsolateMessageType.values, contains(IsolateMessageType.error));
      expect(IsolateMessageType.values, contains(IsolateMessageType.shutdown));
      expect(
        IsolateMessageType.values,
        contains(IsolateMessageType.shutdownAck),
      );
    });
  });
}
