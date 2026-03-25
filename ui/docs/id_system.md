# ID System Documentation

## 📋 ID Types and Their Purposes

### 1. **Profile ID** (Primary Identity)
- **Source**: JWT `sub` claim from authentication
- **Represents**: The entity (person/organization) identity
- **Scope**: Global across the entire system
- **Usage**: 
  - User authentication and authorization
  - Message sender identification (`RoomEvent.senderId`)
  - Current user context (`currentUserIdProvider`)
- **Can be null**: Yes, initially for anonymous subscriptions
- **Updatable**: Yes, can be assigned later when user authenticates
- **Example**: `profile_abc123def456`

### 2. **Contact ID** (Connection Method)
- **Source**: ContactLink from address book/contacts
- **Represents**: Different ways to connect to the same profile
- **Scope**: Contact-specific (phone, email, etc.)
- **Usage**:
  - Multiple contact methods for the same person
  - Room member contact information (`RoomMembers.contactId`)
- **Example**: `phone_+1234567890`, `email_user@example.com`

### 3. **Subscription ID** (Room-Specific Presence)
- **Source**: Chat API room subscription
- **Represents**: A profile's specific presence in a room
- **Scope**: Room-specific (unique per room per profile)
- **Usage**:
  - Real-time event routing (`TypingEvent.subscriptionId`)
  - Room membership tracking (`RoomMembers.subscriptionId`)
  - Message sending permissions
- **Example**: `sub_xyz789uvw456`

## 🔄 ID Relationships

```
Profile ID (Global Identity) - Can be null initially
    ↓ (has multiple)
Contact ID (Connection Methods)
    ↓ (joins room via)
Subscription ID (Room-Specific Presence) - Always exists
```

## 👤 Anonymous Subscriptions

### **What are Anonymous Subscriptions?**
Room subscriptions can be created without an associated profile ID initially. This allows:
- Users to join rooms before authenticating
- Provisional access while identity is being established
- Gradual profile assignment process

### **Lifecycle:**
1. **Create Subscription**: `subscriptionId` + `roomId` (no `profileId`)
2. **User Authenticates**: Profile ID becomes available
3. **Update Subscription**: Assign `profileId` to existing `subscriptionId`
4. **Full Functionality**: All features work with assigned profile

### **Key Methods:**
```dart
// Create anonymous subscription
await subscriptionService.createSubscription(
  subscriptionId: 'sub_xyz789',
  roomId: 'room_123',
  profileId: null, // Anonymous initially
);

// Update with profile ID later
await syncEngine.updateSubscriptionProfile(
  subscriptionId: 'sub_xyz789',
  profileId: 'profile_abc123',
  contactId: 'phone_+1234567890',
);

// Find anonymous subscriptions
final anonymous = await syncEngine.getAnonymousSubscriptions(roomId: 'room_123');
```

## 📊 Database Schema Mapping

### RoomMembers Table
| Column | ID Type | Purpose |
|--------|---------|---------|
| `subscriptionId` | Subscription ID | Primary key, room-specific presence |
| `profileId` | Profile ID | Global identity of the member |
| `contactId` | Contact ID | How this member was contacted |

### RoomEvents Table  
| Column | ID Type | Purpose |
|--------|---------|---------|
| `senderId` | Profile ID | Global identity of message sender |
| `senderContactId` | Contact ID | Contact method used by sender |

## 🔍 Key Functions

### Getting Current User's Profile ID
```dart
// This returns the PROFILE ID from JWT
final currentProfileId = ref.watch(currentUserIdProvider);
```

### Mapping Subscription → Profile in a Room
```dart
// Find which profile owns a subscription in a room
final member = await db.select(db.roomMembers)
  ..where((t) => t.subscriptionId.equals(subscriptionId) & 
              t.roomId.equals(roomId))
  ..getSingleOrNull();
final profileId = member?.profileId;
```

### Getting Current User's Subscription in a Room
```dart
// Find current user's subscription ID for a specific room
final subscriptionId = await syncEngine.getCurrentUserSubscriptionId(roomId);
```

## 🚫 Common Mistakes to Avoid

1. **❌ Using profile ID for room-specific operations**
   - Wrong: Checking if `profileId` is in room
   - Right: Checking if `subscriptionId` exists for profile in room

2. **❌ Using subscription ID for global identity**
   - Wrong: Using `subscriptionId` as user identifier across rooms
   - Right: Using `profileId` for global identity

3. **❌ Confusing contact ID with profile ID**
   - Wrong: Assuming `contactId` == `profileId`
   - Right: `contactId` is just one way to reach a `profileId`

4. **❌ Mixing ID types in comparisons**
   - Wrong: `subscriptionId == profileId`
   - Right: Always compare same ID types

## ✅ Correct Usage Patterns

### Message Positioning
```dart
// CORRECT: Compare profile IDs for message positioning
final currentProfileId = ref.watch(currentUserIdProvider);
final isMe = message.senderId == currentProfileId;
```

### Typing Events
```dart
// CORRECT: Use subscription ID for typing events
final typingEvent = pb.TypingEvent(
  subscriptionId: currentSubscriptionId,  // Room-specific
  roomId: roomId,
  typing: isTyping,
);
```

### Room Membership
```dart
// CORRECT: Store all three ID types with clear relationships
await db.into(db.roomMembers).insertOnConflictUpdate(
  RoomMembersCompanion.insert(
    subscriptionId: subscriptionId,  // Primary key
    roomId: roomId,
    profileId: profileId,          // Global identity
    contactId: contactId,          // Contact method
  ),
);
```

## 🔧 Migration Guide

When working with IDs, always ask:

1. **What is the scope?** (Global vs Room-specific vs Contact-specific)
2. **What does this ID represent?** (Identity vs Connection vs Presence)
3. **Where does this ID come from?** (JWT vs API vs Contacts)

This ensures proper ID usage and prevents mixing concerns.
