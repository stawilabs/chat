import 'package:stawi/features/contacts/data/roster_repository.dart';
import 'package:stawi/features/contacts/services/contact_sync_service.dart';

/// Mock implementation of ContactSyncRepository for testing
class MockRosterRepository implements ContactSyncRepository {
  bool _needsSync = true;
  bool _shouldThrow = false;
  List<RosterEntry> _syncResult = [];
  bool syncContactsCalled = false;
  Duration _delay = Duration.zero;

  void setNeedsSync(bool value) {
    _needsSync = value;
  }

  void setShouldThrow(bool value) {
    _shouldThrow = value;
  }

  void setSyncResult(List<RosterEntry> entries) {
    _syncResult = entries;
  }

  void setDelay(Duration delay) {
    _delay = delay;
  }

  void reset() {
    _needsSync = true;
    _shouldThrow = false;
    _syncResult = [];
    syncContactsCalled = false;
    _delay = Duration.zero;
  }

  /// Create mock roster entries for testing
  List<RosterEntry> createMockEntries(int count) {
    return List.generate(
      count,
      (i) => RosterEntry(
        id: 'entry_$i',
        contactType: i.isEven
            ? RosterContactType.msisdn
            : RosterContactType.email,
        contactDetail: i.isEven ? '+1234567890$i' : 'user$i@example.com',
        displayName: 'Contact $i',
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<bool> needsSync() async {
    if (_delay > Duration.zero) {
      await Future.delayed(_delay);
    }
    return _needsSync;
  }

  @override
  Future<List<RosterEntry>> syncContacts({
    SyncProgressCallback? progressCallback,
  }) async {
    syncContactsCalled = true;

    if (_delay > Duration.zero) {
      await Future.delayed(_delay);
    }

    if (_shouldThrow) {
      throw Exception('Mock sync error');
    }

    return _syncResult;
  }

  Future<List<RosterEntry>> syncIfNeeded({bool force = false}) async {
    if (force || _needsSync) {
      return syncContacts();
    }
    return [];
  }
}

/// Extension to add copyWith to RosterEntry for testing
extension RosterEntryTestExtension on RosterEntry {
  RosterEntry copyWith({
    String? id,
    String? rosterId,
    String? profileId,
    String? contactId,
    RosterContactType? contactType,
    String? contactDetail,
    bool? isVerified,
    String? displayName,
    bool? isBlocked,
    DateTime? syncedAt,
    DateTime? createdAt,
  }) {
    return RosterEntry(
      id: id ?? this.id,
      rosterId: rosterId ?? this.rosterId,
      profileId: profileId ?? this.profileId,
      contactId: contactId ?? this.contactId,
      contactType: contactType ?? this.contactType,
      contactDetail: contactDetail ?? this.contactDetail,
      isVerified: isVerified ?? this.isVerified,
      displayName: displayName ?? this.displayName,
      isBlocked: isBlocked ?? this.isBlocked,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
