// ignore_for_file: avoid_dynamic_calls

import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/isolates/isolate_metrics.dart';

void main() {
  group('IsolateMetrics', () {
    late IsolateMetrics metrics;

    setUp(() {
      metrics = IsolateMetrics();
    });

    tearDown(() {
      metrics.clear();
    });

    group('Task Execution Recording', () {
      test('should record task execution', () {
        metrics.recordTaskExecution(
          'test_isolate',
          'processMessages',
          const Duration(milliseconds: 50),
        );

        final taskCount = metrics.getTaskCount('test_isolate');
        expect(taskCount, equals(1));
      });

      test('should record multiple task executions', () {
        for (var i = 0; i < 5; i++) {
          metrics.recordTaskExecution(
            'test_isolate',
            'processMessages',
            Duration(milliseconds: 10 * (i + 1)),
          );
        }

        final taskCount = metrics.getTaskCount('test_isolate');
        expect(taskCount, equals(5));
      });

      test('should record tasks for different isolates', () {
        metrics.recordTaskExecution(
          'isolate_1',
          'task_a',
          const Duration(milliseconds: 10),
        );
        metrics.recordTaskExecution(
          'isolate_2',
          'task_b',
          const Duration(milliseconds: 20),
        );

        expect(metrics.getTaskCount('isolate_1'), equals(1));
        expect(metrics.getTaskCount('isolate_2'), equals(1));
      });

      test('should record tasks for different task types', () {
        metrics.recordTaskExecution(
          'test_isolate',
          'task_a',
          const Duration(milliseconds: 10),
        );
        metrics.recordTaskExecution(
          'test_isolate',
          'task_b',
          const Duration(milliseconds: 20),
        );

        final taskCount = metrics.getTaskCount('test_isolate');
        expect(taskCount, equals(2));
      });
    });

    group('Queue Depth Tracking', () {
      test('should increment queue depth', () {
        metrics.incrementQueueDepth('test_isolate');
        expect(metrics.getQueueDepth('test_isolate'), equals(1));

        metrics.incrementQueueDepth('test_isolate');
        expect(metrics.getQueueDepth('test_isolate'), equals(2));
      });

      test('should decrement queue depth', () {
        metrics.incrementQueueDepth('test_isolate');
        metrics.incrementQueueDepth('test_isolate');
        metrics.decrementQueueDepth('test_isolate');

        expect(metrics.getQueueDepth('test_isolate'), equals(1));
      });

      test('should not go negative', () {
        metrics.decrementQueueDepth('test_isolate');
        expect(metrics.getQueueDepth('test_isolate'), equals(0));
      });

      test('should return 0 for unknown isolate', () {
        expect(metrics.getQueueDepth('unknown'), equals(0));
      });
    });

    group('Error Tracking', () {
      test('should record task errors', () {
        metrics.recordTaskError('test_isolate', 'task', Exception('test'));

        expect(metrics.getErrorCount('test_isolate'), equals(1));
      });

      test('should return 0 for unknown isolate', () {
        expect(metrics.getErrorCount('unknown'), equals(0));
      });
    });

    group('Summary', () {
      test('should return null for unknown task', () {
        final summary = metrics.getSummary('unknown', 'unknown');
        expect(summary, isNull);
      });

      test('should calculate summary statistics', () {
        // Add some task executions with varying durations
        metrics.recordTaskExecution(
          'test_isolate',
          'task',
          const Duration(milliseconds: 10),
        );
        metrics.recordTaskExecution(
          'test_isolate',
          'task',
          const Duration(milliseconds: 20),
        );
        metrics.recordTaskExecution(
          'test_isolate',
          'task',
          const Duration(milliseconds: 30),
        );
        metrics.recordTaskExecution(
          'test_isolate',
          'task',
          const Duration(milliseconds: 40),
        );
        metrics.recordTaskExecution(
          'test_isolate',
          'task',
          const Duration(milliseconds: 50),
        );

        final summary = metrics.getSummary('test_isolate', 'task');

        expect(summary, isNotNull);
        expect(summary!.totalExecutions, equals(5));
        expect(summary.minDuration.inMilliseconds, equals(10));
        expect(summary.maxDuration.inMilliseconds, equals(50));
        expect(summary.averageDuration.inMilliseconds, equals(30));
      });

      test('should calculate percentiles', () {
        // Add 100 executions
        for (var i = 1; i <= 100; i++) {
          metrics.recordTaskExecution(
            'test_isolate',
            'task',
            Duration(milliseconds: i),
          );
        }

        final summary = metrics.getSummary('test_isolate', 'task');

        expect(summary, isNotNull);
        expect(summary!.p50Duration.inMilliseconds, closeTo(50, 5));
        expect(summary.p90Duration.inMilliseconds, closeTo(90, 5));
        expect(summary.p99Duration.inMilliseconds, closeTo(99, 5));
      });

      test('should get all summaries for isolate', () {
        metrics.recordTaskExecution(
          'test_isolate',
          'task_a',
          const Duration(milliseconds: 10),
        );
        metrics.recordTaskExecution(
          'test_isolate',
          'task_b',
          const Duration(milliseconds: 20),
        );

        final summaries = metrics.getAllSummaries('test_isolate');

        expect(summaries.length, equals(2));
      });
    });

    group('Recent Metrics', () {
      test('should return recent metrics', () {
        for (var i = 0; i < 10; i++) {
          metrics.recordTaskExecution(
            'test_isolate',
            'task',
            Duration(milliseconds: i * 10),
          );
        }

        final recent = metrics.getRecentMetrics(
          'test_isolate',
          'task',
          limit: 5,
        );

        expect(recent.length, equals(5));
        // Most recent first
        expect(recent.first.duration.inMilliseconds, equals(90));
      });

      test('should return empty list for unknown task', () {
        final recent = metrics.getRecentMetrics('unknown', 'unknown');
        expect(recent, isEmpty);
      });
    });

    group('Global Summary', () {
      test('should return global summary', () {
        metrics.recordTaskExecution(
          'isolate_1',
          'task_a',
          const Duration(milliseconds: 10),
        );
        metrics.incrementQueueDepth('isolate_1');
        metrics.recordTaskError('isolate_1', 'task_a', Exception('test'));

        final summary = metrics.getGlobalSummary();

        expect(summary.containsKey('isolate_1'), isTrue);
        expect(summary['isolate_1']['totalTasks'], equals(1));
        expect(summary['isolate_1']['queueDepth'], equals(1));
        expect(summary['isolate_1']['errorCount'], equals(1));
      });
    });

    group('Clearing', () {
      test('should clear all metrics', () {
        metrics.recordTaskExecution(
          'test_isolate',
          'task',
          const Duration(milliseconds: 10),
        );
        metrics.incrementQueueDepth('test_isolate');
        metrics.recordTaskError('test_isolate', 'task', Exception('test'));

        metrics.clear();

        expect(metrics.getTaskCount('test_isolate'), equals(0));
        expect(metrics.getQueueDepth('test_isolate'), equals(0));
        expect(metrics.getErrorCount('test_isolate'), equals(0));
      });

      test('should clear specific isolate', () {
        metrics.recordTaskExecution(
          'isolate_1',
          'task',
          const Duration(milliseconds: 10),
        );
        metrics.recordTaskExecution(
          'isolate_2',
          'task',
          const Duration(milliseconds: 20),
        );

        metrics.clearIsolate('isolate_1');

        expect(metrics.getTaskCount('isolate_1'), equals(0));
        expect(metrics.getTaskCount('isolate_2'), equals(1));
      });
    });

    group('JSON Serialization', () {
      test('TaskExecutionMetric should serialize to JSON', () {
        final metric = TaskExecutionMetric(
          isolateName: 'test_isolate',
          taskType: 'task',
          duration: const Duration(milliseconds: 50),
          timestamp: DateTime(2024),
        );

        final json = metric.toJson();

        expect(json['isolateName'], equals('test_isolate'));
        expect(json['taskType'], equals('task'));
        expect(json['durationMs'], equals(50));
      });

      test('TaskMetricsSummary should serialize to JSON', () {
        metrics.recordTaskExecution(
          'test_isolate',
          'task',
          const Duration(milliseconds: 50),
        );

        final summary = metrics.getSummary('test_isolate', 'task');
        final json = summary!.toJson();

        expect(json['isolateName'], equals('test_isolate'));
        expect(json['taskType'], equals('task'));
        expect(json['totalExecutions'], equals(1));
        expect(json.containsKey('averageDurationMs'), isTrue);
      });
    });
  });
}
