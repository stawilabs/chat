# Roster Foreign Key Constraint Fix - Summary

## Problem
The original error `fk_rosters_contact` foreign key constraint violation occurred because:
- Roster table had non-nullable `profileId` field referencing profiles table
- Contact sync inserted empty string `profileId` values for unlinked contacts
- Empty strings don't exist in profiles table, causing FK violations

## Solution
Made `profileId` nullable and corrected the business logic for contact tracking:

### Database Schema Changes
- **profileId**: Now nullable (null if contact hasn't logged in yet)
- **contactId**: Contact's unique ID from server (available after successful sync)
- **contactDetail**: Email/phone number for local display and reference

### Business Logic Clarification
Based on requirements, the roster table now correctly handles:

1. **contactId**: Primary identifier from server (always available after successful sync)
2. **profileId**: Optional profile link (null if user hasn't logged in yet)
3. **contactDetail**: Local email/phone for display and user recognition

### Key Changes Made

#### 1. Database Schema (`lib/core/db/database.dart`)
```dart
class Roster extends Table {
  TextColumn get id => text()(); // Roster entry unique ID
  TextColumn get profileId => text().nullable()(); // Null if user hasn't logged in
  TextColumn get contactId => text().nullable()(); // Contact's unique ID from server
  TextColumn get contactDetail => text()(); // Email/phone for local display
  // ... other fields
}
```

#### 2. Roster Entry Model (`lib/features/contacts/data/roster_repository.dart`)
```dart
class RosterEntry {
  final String id; // Roster entry unique ID
  final String? profileId; // Profile ID (null if user hasn't logged in)
  final String? contactId; // Contact's unique ID from server
  final String contactDetail; // Email/phone for local display
  // ... other fields
}
```

#### 3. Correct Proto Mapping
```dart
factory RosterEntry.fromProto(pb.RosterObject roster, {String? localDisplayName}) {
  final contact = roster.hasContact() ? roster.contact : null;
  return RosterEntry(
    id: roster.id, // Roster entry ID
    profileId: roster.hasProfileId() ? roster.profileId : null, // Null if not logged in
    contactId: contact?.id, // Contact's unique ID from server
    contactDetail: contact?.detail ?? '', // Email/phone for display
    // ... other fields
  );
}
```

#### 4. Server Sync Update Logic
```dart
dbBatch.update(
  _database.roster,
  RosterCompanion(
    contactId: Value(roster.hasContact() ? roster.contact.id : null), // Contact ID
    profileId: Value(roster.hasProfileId() ? roster.profileId : null), // Profile ID
    // ... other fields
  ),
  where: (t) => t.id.equals(localRow.id),
);
```

### Contact Sync Flow
1. **Local Sync**: Contacts stored with `null` profileId and `null` contactId initially
2. **Server Sync**: When found on platform:
   - `contactId` gets populated with server's contact unique ID
   - `profileId` gets populated only if user has logged in (has profile)
3. **Display**: Uses `contactDetail` (email/phone) for user recognition

### Benefits
✅ **No FK violations**: Null profileIds don't violate constraints
✅ **Correct tracking**: contactId always available after sync, profileId optional
✅ **Better UX**: Contacts display with email/phone even without profiles
✅ **Scalable**: Handles both registered and unregistered contacts properly

### Migration
- Schema version updated from 5 to 6
- Existing empty string profileIds converted to null
- Backward compatible with existing data

The roster table now effectively tracks contacts locally and remotely as requested, with proper distinction between contact identifiers and profile links.
