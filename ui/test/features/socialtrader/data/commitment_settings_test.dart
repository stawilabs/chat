import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/db/database.dart';
import 'package:stawi/features/socialtrader/data/commitment_settings.dart';

void main() {
  late AppDatabase db;
  late DriftCommitmentSettings settings;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settings = DriftCommitmentSettings(db);
  });

  tearDown(() => db.close());

  test('commitmentSettings_persistsAndReturnsDefault', () async {
    expect(await settings.defaultFor('p1'), isNull, reason: 'nothing saved');

    await settings.save('p1', '250');
    expect(await settings.defaultFor('p1'), '250');

    await settings.save('p1', '400');
    expect(await settings.defaultFor('p1'), '400', reason: 'saving replaces');

    expect(await settings.defaultFor('p2'), isNull, reason: 'per profile');
  });

  test('commitmentSettings_forgetClearsTheDefault', () async {
    await settings.save('p1', '250');
    await settings.forget('p1');
    expect(await settings.defaultFor('p1'), isNull);
  });

  test('commitmentSettings_rejectsANonPositiveAmount', () async {
    expect(() => settings.save('p1', '0'), throwsArgumentError);
    expect(() => settings.save('p1', '-1'), throwsArgumentError);
    expect(() => settings.save('p1', 'abc'), throwsArgumentError);
    expect(await settings.defaultFor('p1'), isNull);
  });

  test('upgrading a version 4 database adds the table', () async {
    final upgraded = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) => raw.execute('PRAGMA user_version = 4'),
      ),
    );
    addTearDown(upgraded.close);
    final store = DriftCommitmentSettings(upgraded);
    await store.save('p1', '10');
    expect(await store.defaultFor('p1'), '10');
  });

  test('the in-memory store behaves the same', () async {
    final memory = MemoryCommitmentSettings();
    await memory.save('p1', '250');
    expect(await memory.defaultFor('p1'), '250');
    await memory.forget('p1');
    expect(await memory.defaultFor('p1'), isNull);
  });
}
