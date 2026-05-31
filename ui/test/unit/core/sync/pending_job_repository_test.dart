import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/db/database.dart';
import 'package:stawi/core/sync/pending_job.dart' as domain;
import 'package:stawi/core/sync/pending_job_repository.dart';

import '../../../test_helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late PendingJobRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = PendingJobRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> statusOf(int id) async {
    final row = await (db.select(
      db.pendingJobs,
    )..where((t) => t.id.equals(id))).getSingle();
    return row.status;
  }

  group('claimJob (cross-isolate safety)', () {
    test('only one claimer wins; a second claim fails', () async {
      final id = await repo.addJob(domain.JobType.sendMessage, {
        'localId': 'local-1',
        'roomId': 'room-1',
      });

      expect(await statusOf(id), 'pending');
      expect(await repo.claimJob(id), isTrue, reason: 'first claim wins');
      expect(await statusOf(id), 'processing');
      expect(
        await repo.claimJob(id),
        isFalse,
        reason: 'second claim must fail — job already processing',
      );
    });

    test('a retried job returns to pending and can be re-claimed', () async {
      final id = await repo.addJob(domain.JobType.sendMessage, {
        'localId': 'local-2',
        'roomId': 'room-1',
      });

      expect(await repo.claimJob(id), isTrue);
      // Transient failure -> retry scheduled, status reset to pending.
      expect(await repo.incrementRetry(id, errorMessage: 'boom'), isTrue);
      expect(await statusOf(id), 'pending');
      expect(
        await repo.claimJob(id),
        isTrue,
        reason: 'job is claimable again after retry reset',
      );
    });
  });
}
