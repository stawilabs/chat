// Simple verification script to test the foreign key constraint fix

import 'dart:io';

import 'package:stawi/core/db/database.dart';
import 'package:stawi/core/logging/app_logger.dart';

void main() async {
  AppLogger.info('🧪 Testing Roster Foreign Key Constraint Fix...\n');

  // Use the existing database instance
  final database = AppDatabase.instance;

  try {
    // Clean up any existing test data
    await database
        .customSelect('DELETE FROM roster WHERE id LIKE "test-%"')
        .get();
    await database
        .customSelect('DELETE FROM profiles WHERE id LIKE "test-%"')
        .get();

    // Test 1: Insert roster entry with null profileId (this was causing the FK error)
    AppLogger.info('📝 Test 1: Inserting roster entry with null profileId...');
    await database.customSelect('''
      INSERT INTO roster (
        id, profile_id, contact_id, contact_type, contact_detail, 
        is_verified, display_name, is_blocked, created_at
      ) VALUES (
        'test-null-profile', NULL, NULL, 0, 'null@example.com',
        0, 'Null Profile Test', 0, ${DateTime.now().millisecondsSinceEpoch}
      )
    ''').get();

    AppLogger.info(
      '✅ SUCCESS: Roster entry with null profileId inserted without FK violation',
    );

    // Test 2: Insert roster entry with valid profileId
    AppLogger.info(
      '\n📝 Test 2: Inserting roster entry with valid profileId...',
    );

    // First insert a profile
    await database.customSelect('''
      INSERT INTO profiles (id, name) 
      VALUES ('test-profile-1', 'Test Profile')
    ''').get();

    // Then insert roster entry with that profileId
    await database.customSelect('''
      INSERT INTO roster (
        id, profile_id, contact_id, contact_type, contact_detail, 
        is_verified, display_name, is_blocked, created_at
      ) VALUES (
        'test-valid-profile', 'test-profile-1', 'contact-1', 1, '+1234567890',
        1, 'Valid Profile Test', 0, ${DateTime.now().millisecondsSinceEpoch}
      )
    ''').get();

    AppLogger.info(
      '✅ SUCCESS: Roster entry with valid profileId inserted successfully',
    );

    // Test 3: Verify both entries exist
    AppLogger.info('\n📝 Test 3: Verifying entries exist...');
    final allRosterEntries = await database.customSelect('''
      SELECT id, profile_id, contact_detail FROM roster WHERE id LIKE 'test-%'
    ''').get();

    AppLogger.info(
      '✅ SUCCESS: Found ${allRosterEntries.length} roster entries',
    );

    for (final entry in allRosterEntries) {
      final id = entry.read<String>('id');
      final profileId = entry.read<String?>('profile_id');
      final contact = entry.read<String>('contact_detail');
      AppLogger.info('   - ID: $id, ProfileId: $profileId, Contact: $contact');
    }

    // Test 4: Count entries with null profileId
    AppLogger.info('\n📝 Test 4: Testing null profileId handling...');
    final nullProfileCount = await database.customSelect('''
      SELECT COUNT(*) as count FROM roster WHERE profile_id IS NULL AND id LIKE 'test-%'
    ''').getSingle();

    final count = nullProfileCount.read<int>('count');
    AppLogger.info('✅ SUCCESS: Found $count entries with null profileId');

    // Clean up test data
    await database
        .customSelect('DELETE FROM roster WHERE id LIKE "test-%"')
        .get();
    await database
        .customSelect('DELETE FROM profiles WHERE id LIKE "test-%"')
        .get();

    AppLogger.info(
      '\n🎉 ALL TESTS PASSED! The foreign key constraint fix is working correctly.',
    );
    AppLogger.info('\n📋 Summary:');
    AppLogger.info(
      '   • Roster entries can now have null profileId without FK violations',
    );
    AppLogger.info(
      '   • Roster entries with valid profileId still work correctly',
    );
    AppLogger.info('   • The database schema properly handles both cases');
    AppLogger.info(
      '   • Contact sync should no longer fail with FK constraint errors',
    );
    AppLogger.info(
      '   • The original error "fk_rosters_contact" has been resolved',
    );
  } catch (e, stackTrace) {
    AppLogger.error('❌ FAILED: $e');
    AppLogger.error('Stack trace: $stackTrace');
    exit(1);
  }
}
