// @deprecated Use [roster_repository.dart] instead.
// This file provides backward compatibility for existing code.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'roster_repository.dart';

export 'roster_repository.dart'
    show
        RosterRepository,
        RosterEntry,
        RosterContactType,
        ProfileData,
        ProfileWithContacts,
        SyncProgress,
        SyncProgressCallback,
        SyncState,
        rosterRepositoryProvider,
        rosterEntriesProvider,
        rosterSyncTriggerProvider,
        rosterReconcileProvider,
        rosterSyncNeededProvider,
        blockedRosterEntriesProvider,
        profilesWithContactsProvider,
        profilesWithContactsStreamProvider,
        rosterLocalSyncProvider,
        rosterServerSyncProvider;

/// @deprecated Use [RosterContactType] instead.
typedef ContactSyncType = RosterContactType;

/// @deprecated Use [RosterEntry] instead.
class SyncedContact {
  SyncedContact({
    required this.id,
    required this.profileId,
    required this.displayName,
    required this.contactType,
    this.isVerified = false,
  });

  factory SyncedContact.fromRosterEntry(RosterEntry entry) => SyncedContact(
    id: entry.id,
    profileId: entry.profileId ?? '', // Handle nullable profileId
    displayName: entry.displayName ?? entry.contactDetail,
    contactType: entry.contactType,
    isVerified: entry.isVerified,
  );
  final String id;
  final String profileId;
  final String displayName;
  final RosterContactType contactType;
  final bool isVerified;
}

/// @deprecated Use [rosterRepositoryProvider] instead.
final contactSyncRepositoryProvider = FutureProvider<RosterRepository>(
  (ref) async => await ref.watch(rosterRepositoryProvider.future),
);

/// @deprecated Use [rosterEntriesProvider] instead.
final syncedContactsProvider = FutureProvider<List<SyncedContact>>((ref) async {
  final entries = await ref.watch(rosterEntriesProvider.future);
  return entries.map(SyncedContact.fromRosterEntry).toList();
});

/// @deprecated Use [rosterSyncTriggerProvider] instead.
final contactSyncTriggerProvider = FutureProvider<List<SyncedContact>>((
  ref,
) async {
  final entries = await ref.watch(rosterSyncTriggerProvider.future);
  return entries.map(SyncedContact.fromRosterEntry).toList();
});

/// @deprecated Use [rosterReconcileProvider] instead.
final contactReconcileProvider = FutureProvider<void>((ref) async {
  await ref.watch(rosterReconcileProvider.future);
});

/// @deprecated Use [rosterSyncNeededProvider] instead.
final contactSyncNeededProvider = FutureProvider<bool>(
  (ref) async => await ref.watch(rosterSyncNeededProvider.future),
);

/// @deprecated Use [blockedRosterEntriesProvider] instead.
final blockedContactsProvider = FutureProvider<List<SyncedContact>>((
  ref,
) async {
  final entries = await ref.watch(blockedRosterEntriesProvider.future);
  return entries.map(SyncedContact.fromRosterEntry).toList();
});
