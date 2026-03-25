import 'package:drift/native.dart';
import 'package:stawi/core/db/database.dart';

/// Creates an in-memory database for testing
///
/// Each call creates a new isolated database instance that can be used
/// for testing database operations without affecting the real database.
///
/// Example:
/// ```dart
/// late AppDatabase testDb;
///
/// setUp(() {
///   testDb = createTestDatabase();
/// });
///
/// tearDown(() async {
///   await testDb.close();
/// });
/// ```
AppDatabase createTestDatabase() =>
    AppDatabase.forTesting(NativeDatabase.memory());
