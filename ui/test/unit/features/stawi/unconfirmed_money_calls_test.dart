import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/db/database.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/unconfirmed_money_calls.dart';

import '../../../test_helpers/test_database.dart';

SignedMoneyCall signed(String callId, int byte) => SignedMoneyCall(
  callId: callId,
  authorization: Uint8List.fromList(List.filled(65, byte)),
  title: 'Pay 500.00 USDC into Chama',
);

void main() {
  late AppDatabase db;

  setUp(() => db = createTestDatabase());
  tearDown(() => db.close());

  test('a held call is read back exactly, per profile', () async {
    await DriftUnconfirmedMoneyCallStore(db).hold('p1', signed('call-1', 7));

    // A new store over the same database: what a restarted app reads.
    final again = await DriftUnconfirmedMoneyCallStore(db).read('p1');
    expect(again?.callId, 'call-1');
    expect(again?.authorization, List.filled(65, 7));
    expect(again?.title, 'Pay 500.00 USDC into Chama');
    expect(await DriftUnconfirmedMoneyCallStore(db).read('p2'), isNull);
  });

  test('only the call held is cleared', () async {
    final store = DriftUnconfirmedMoneyCallStore(db);
    await store.hold('p1', signed('call-1', 7));
    await store.clear('p1', 'call-other');
    expect((await store.read('p1'))?.callId, 'call-1');
    await store.clear('p1', 'call-1');
    expect(await store.read('p1'), isNull);
  });

  for (final (name, make) in [
    ('the database', () => DriftUnconfirmedMoneyCallStore(db)),
    ('memory', MemoryUnconfirmedMoneyCallStore.new),
  ]) {
    test('$name never replaces a held call with another', () async {
      final store = make();
      await store.hold('p1', signed('call-1', 7));
      await store.hold('p1', signed('call-1', 7));
      await expectLater(
        store.hold('p1', signed('call-2', 8)),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            anotherCallHeldMessage,
          ),
        ),
      );
      expect((await store.read('p1'))?.callId, 'call-1');
      expect((await store.read('p1'))?.authorization, List.filled(65, 7));
    });
  }

  test('the in-memory store behaves the same', () async {
    final store = MemoryUnconfirmedMoneyCallStore();
    await store.hold('p1', signed('call-1', 7));
    await store.clear('p1', 'call-other');
    expect((await store.read('p1'))?.callId, 'call-1');
    await store.clear('p1', 'call-1');
    expect(await store.read('p1'), isNull);
  });

  test('upgrading a version 2 database adds the table', () async {
    final upgraded = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) => raw.execute('PRAGMA user_version = 2'),
      ),
    );
    addTearDown(upgraded.close);
    final store = DriftUnconfirmedMoneyCallStore(upgraded);
    await store.hold('p1', signed('call-1', 7));
    expect((await store.read('p1'))?.callId, 'call-1');
  });
}
