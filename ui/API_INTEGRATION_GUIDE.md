# API Integration Quick Reference Guide

This guide maps each PRD feature to the specific Antinvestor API calls required.

---

## Table of Contents

1. [Authentication Setup](#1-authentication-setup)
2. [Chat Service Integration](#2-chat-service-integration)
3. [Gateway Service Integration](#3-gateway-service-integration)
4. [Profile Service Integration](#4-profile-service-integration)
5. [Files Service Integration](#5-files-service-integration)
6. [Device Service Integration](#6-device-service-integration)
7. [Notification Service Integration](#7-notification-service-integration)
8. [Common Patterns](#8-common-patterns)

---

## 1. Authentication Setup

### Client Initialization Pattern

All API clients follow this pattern:

```dart
// lib/core/networking/client.dart

import 'package:antinvestor_api_common/antinvestor_api_common.dart';
import 'package:antinvestor_api_chat/antinvestor_api_chat.dart';

// TokenManager handles JWT lifecycle
final tokenManagerProvider = Provider<TokenManager>((ref) {
  return TokenManager(
    persistTokens: (accessToken, refreshToken) async {
      final storage = ref.read(secureStorageProvider);
      await storage.write(key: 'access_token', value: accessToken);
      if (refreshToken != null) {
        await storage.write(key: 'refresh_token', value: refreshToken);
      }
    },
    loadTokens: () async {
      final storage = ref.read(secureStorageProvider);
      final access = await storage.read(key: 'access_token');
      final refresh = await storage.read(key: 'refresh_token');
      if (access != null) {
        return TokenPair(accessToken: access, refreshToken: refresh);
      }
      return null;
    },
    onRefreshToken: (refreshToken) async {
      // Call OAuth refresh endpoint
      final result = await authService.refreshToken(refreshToken);
      return TokenPair(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
    },
    onLogout: () async {
      // Clear tokens and navigate to login
      final storage = ref.read(secureStorageProvider);
      await storage.deleteAll();
    },
  );
});

// Create authenticated client
final chatServiceClientProvider = FutureProvider<ChatServiceClient>((ref) async {
  final tokenManager = ref.watch(tokenManagerProvider);

  final client = await newChatClient(
    tokenManager: tokenManager,
    endpoint: ApiConfig.chatServiceUrl,
  );

  return client.stub;
});
```

### JWT Token Extraction

```dart
// Extract profile ID from JWT
String? extractProfileId(String accessToken) {
  final claims = JwtUtils.decodePayload(accessToken);
  return claims['sub'] as String?;
}

// Extract contact ID from JWT
String? extractContactId(String accessToken) {
  final claims = JwtUtils.decodePayload(accessToken);
  return claims['contact_id'] as String?;
}
```

---

## 2. Chat Service Integration

### Feature: Send Message (MSG-EDIT-001, MSG-DEL-001)

```dart
// Send new message
Future<AckEvent> sendTextMessage(String roomId, String text) async {
  final chatClient = await ref.read(chatServiceClientProvider.future);

  final event = pb.RoomEvent(
    id: Xid().toString(),  // Generate unique ID
    roomId: roomId,
    type: pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE,
    sentAt: Timestamp.fromDateTime(DateTime.now()),
    payload: pb.Payload(
      text: pb.TextContent(body: text),
    ),
  );

  final request = pb.SendEventRequest(event: [event]);
  final response = await chatClient.sendEvent(request);

  return response.ack.first;
}

// Edit message
Future<AckEvent> editMessage(String eventId, String roomId, String newText) async {
  final chatClient = await ref.read(chatServiceClientProvider.future);

  final event = pb.RoomEvent(
    id: eventId,  // Same ID as original
    roomId: roomId,
    type: pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE,
    edited: true,  // Mark as edit
    sentAt: Timestamp.fromDateTime(DateTime.now()),
    payload: pb.Payload(
      text: pb.TextContent(body: newText),
    ),
  );

  final request = pb.SendEventRequest(event: [event]);
  final response = await chatClient.sendEvent(request);

  return response.ack.first;
}

// Delete message (redact)
Future<AckEvent> deleteMessage(String eventId, String roomId) async {
  final chatClient = await ref.read(chatServiceClientProvider.future);

  final event = pb.RoomEvent(
    id: eventId,
    roomId: roomId,
    type: pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE,
    redacted: true,  // Mark as deleted
    sentAt: Timestamp.fromDateTime(DateTime.now()),
  );

  final request = pb.SendEventRequest(event: [event]);
  final response = await chatClient.sendEvent(request);

  return response.ack.first;
}
```

### Feature: Message Reactions (MSG-REACT-001)

```dart
Future<AckEvent> sendReaction(String roomId, String targetEventId, String emoji) async {
  final chatClient = await ref.read(chatServiceClientProvider.future);

  final event = pb.RoomEvent(
    id: Xid().toString(),
    roomId: roomId,
    type: pb.RoomEventType.ROOM_EVENT_TYPE_REACTION,
    parentId: targetEventId,  // Reference to target message
    sentAt: Timestamp.fromDateTime(DateTime.now()),
    payload: pb.Payload(
      // Reaction content
      text: pb.TextContent(body: emoji),
    ),
  );

  final request = pb.SendEventRequest(event: [event]);
  final response = await chatClient.sendEvent(request);

  return response.ack.first;
}
```

### Feature: Get Message History (SEARCH-MSG-001)

```dart
Future<List<pb.RoomEvent>> getHistory(
  String roomId, {
  String? cursor,
  int limit = 50,
  bool forward = false,
}) async {
  final chatClient = await ref.read(chatServiceClientProvider.future);

  final request = pb.GetHistoryRequest(
    roomId: roomId,
    cursor: PageCursor(
      limit: limit,
      page: cursor,
    ),
    forward: forward,
  );

  final response = await chatClient.getHistory(request);
  return response.events;
}
```

### Feature: Create Room (GROUP-INVITE-001)

```dart
Future<pb.Room> createRoom({
  required String name,
  String? description,
  bool isPrivate = false,
  List<String> memberProfileIds = const [],
}) async {
  final chatClient = await ref.read(chatServiceClientProvider.future);

  final members = memberProfileIds
      .map((id) => ContactLink(profileId: id))
      .toList();

  final request = pb.CreateRoomRequest(
    id: Xid().toString(),
    name: name,
    description: description ?? '',
    isPrivate: isPrivate,
    members: members,
  );

  final response = await chatClient.createRoom(request);

  if (response.hasError()) {
    throw Exception(response.error.message);
  }

  return response.room;
}
```

### Feature: Update Room (GROUP-DESC-001)

```dart
Future<void> updateRoom({
  required String roomId,
  String? name,
  String? topic,
  Map<String, dynamic>? metadata,
}) async {
  final chatClient = await ref.read(chatServiceClientProvider.future);

  final request = pb.UpdateRoomRequest(
    roomId: roomId,
    name: name ?? '',
    topic: topic ?? '',
  );

  if (metadata != null) {
    request.metadata = _mapToStruct(metadata);
  }

  await chatClient.updateRoom(request);
}
```

### Feature: Manage Members (GROUP-ADMIN-001)

```dart
// Add members
Future<void> addMembers(String roomId, List<String> profileIds) async {
  final chatClient = await ref.read(chatServiceClientProvider.future);

  final members = profileIds.map((profileId) => pb.RoomSubscription(
    roomId: roomId,
    member: ContactLink(profileId: profileId),
  )).toList();

  final request = pb.AddRoomSubscriptionsRequest(
    roomId: roomId,
    members: members,
  );

  await chatClient.addRoomSubscriptions(request);
}

// Remove members
Future<void> removeMembers(String roomId, List<String> subscriptionIds) async {
  final chatClient = await ref.read(chatServiceClientProvider.future);

  final request = pb.RemoveRoomSubscriptionsRequest(
    roomId: roomId,
    subscriptionId: subscriptionIds,
  );

  await chatClient.removeRoomSubscriptions(request);
}

// Update member role
Future<void> updateMemberRole(String roomId, String subscriptionId, String role) async {
  final chatClient = await ref.read(chatServiceClientProvider.future);

  final request = pb.UpdateSubscriptionRoleRequest(
    roomId: roomId,
    subscriptionId: subscriptionId,
    role: role,  // 'admin', 'moderator', 'member'
  );

  await chatClient.updateSubscriptionRole(request);
}
```

### Feature: Search Rooms (SEARCH-CHAT-001)

```dart
Stream<pb.Room> searchRooms(String query, {int limit = 20}) async* {
  final chatClient = await ref.read(chatServiceClientProvider.future);

  final request = pb.SearchRoomsRequest(
    query: query,
    cursor: PageCursor(limit: limit),
  );

  await for (final response in chatClient.searchRooms(request)) {
    for (final room in response.rooms) {
      yield room;
    }
  }
}
```

---

## 3. Gateway Service Integration

### Feature: Real-Time Messaging (Core)

```dart
// lib/core/sync/sync_engine.dart

class SyncEngine {
  final pb.GatewayServiceClient _gatewayClient;
  StreamSubscription? _streamSubscription;

  final _messageController = StreamController<RoomEvent>.broadcast();
  final _typingController = StreamController<pb.TypingEvent>.broadcast();
  final _presenceController = StreamController<pb.PresenceEvent>.broadcast();
  final _receiptController = StreamController<pb.ReceiptEvent>.broadcast();

  Stream<RoomEvent> get messages => _messageController.stream;
  Stream<pb.TypingEvent> get typingEvents => _typingController.stream;
  Stream<pb.PresenceEvent> get presenceEvents => _presenceController.stream;
  Stream<pb.ReceiptEvent> get receiptEvents => _receiptController.stream;

  Future<void> connect() async {
    // Initial hello message with capabilities
    final hello = pb.StreamHello(
      capabilities: {
        'version': '1.0.0',
        'platform': 'flutter',
        'e2ee': 'vodozemac-0.4',
        'calls': 'webrtc',
      },
      clientTime: Timestamp.fromDateTime(DateTime.now()),
    );

    final initialRequest = pb.StreamRequest(hello: hello);

    // Start bidirectional stream
    final responseStream = _gatewayClient.stream(
      Stream.value(initialRequest),
    );

    _streamSubscription = responseStream.listen(
      _handleResponse,
      onError: _handleError,
      onDone: _handleDone,
    );
  }

  void _handleResponse(pb.StreamResponse response) {
    if (response.hasMessage()) {
      final event = _mapToRoomEvent(response.message);
      _messageController.add(event);
    } else if (response.hasTypingEvent()) {
      _typingController.add(response.typingEvent);
    } else if (response.hasPresenceEvent()) {
      _presenceController.add(response.presenceEvent);
    } else if (response.hasReceiptEvent()) {
      _receiptController.add(response.receiptEvent);
    } else if (response.hasReadEvent()) {
      // Handle read markers
    }
  }
}
```

### Feature: Typing Indicators (MSG-TYPE-001)

```dart
Future<void> sendTyping(String roomId, bool isTyping) async {
  final subscriptionId = await _getCurrentSubscriptionId(roomId);

  final typingEvent = pb.TypingEvent(
    subscriptionId: subscriptionId,
    roomId: roomId,
    typing: isTyping,
    since: Timestamp.fromDateTime(DateTime.now()),
  );

  final command = pb.ClientCommand(typing: typingEvent);
  final request = pb.StreamRequest(command: command);

  // Send via existing stream
  _gatewayClient.stream(Stream.value(request));
}
```

### Feature: Read Receipts (MSG-READ-001)

```dart
Future<void> sendReadReceipt(String roomId, String upToEventId) async {
  final subscriptionId = await _getCurrentSubscriptionId(roomId);

  final readMarker = pb.ReadMarker(
    subscriptionId: subscriptionId,
    roomId: roomId,
    upToEventId: upToEventId,
  );

  final command = pb.ClientCommand(readMarker: readMarker);
  final request = pb.StreamRequest(command: command);

  _gatewayClient.stream(Stream.value(request));
}
```

---

## 4. Profile Service Integration

### Feature: Get User Profile (CONTACT-PROFILE-001)

```dart
Future<Profile> getProfile(String profileId) async {
  final profileClient = await ref.read(profileServiceClientProvider.future);

  final request = pb.GetByIdRequest(id: profileId);
  final response = await profileClient.getById(request);

  return Profile(
    id: response.profile.id,
    name: response.profile.name,
    avatarUrl: response.profile.avatarUrl,
  );
}

// Get profile by contact (phone/email)
Future<Profile?> getProfileByContact(String contact, ContactType type) async {
  final profileClient = await ref.read(profileServiceClientProvider.future);

  final request = pb.GetByContactRequest(
    contact: contact,
    type: type,
  );

  final response = await profileClient.getByContact(request);

  if (response.hasProfile()) {
    return Profile.fromProto(response.profile);
  }
  return null;
}
```

### Feature: Update Profile (CONTACT-PROFILE-001)

```dart
Future<void> updateProfile({
  required String profileId,
  String? name,
  String? bio,
  String? avatarUrl,
}) async {
  final profileClient = await ref.read(profileServiceClientProvider.future);

  final properties = <String, Value>{};
  if (name != null) properties['name'] = Value(stringValue: name);
  if (bio != null) properties['bio'] = Value(stringValue: bio);
  if (avatarUrl != null) properties['avatar_url'] = Value(stringValue: avatarUrl);

  final request = pb.UpdateRequest(
    profileId: profileId,
    properties: Struct(fields: properties),
  );

  await profileClient.update(request);
}
```

### Feature: Contact Sync (CONTACT-SYNC-001)

```dart
// Add contacts to roster
Future<void> syncContacts(List<LocalContact> contacts) async {
  final profileClient = await ref.read(profileServiceClientProvider.future);
  final currentProfileId = await _getCurrentProfileId();

  // Convert to roster entries
  final rosterEntries = contacts.map((contact) {
    return pb.RosterEntry(
      contactType: contact.type,  // phone or email
      contactDetail: contact.normalizedValue,
      displayName: contact.displayName,
    );
  }).toList();

  final request = pb.AddRosterRequest(
    profileId: currentProfileId,
    entries: rosterEntries,
  );

  await profileClient.addRoster(request);
}

// Search roster
Stream<pb.RosterEntry> searchRoster(String query) async* {
  final profileClient = await ref.read(profileServiceClientProvider.future);
  final currentProfileId = await _getCurrentProfileId();

  final request = pb.SearchRosterRequest(
    profileId: currentProfileId,
    query: query,
    cursor: PageCursor(limit: 50),
  );

  await for (final response in profileClient.searchRoster(request)) {
    for (final entry in response.entries) {
      yield entry;
    }
  }
}
```

### Feature: Contact Verification (CONTACT-VERIFY-001)

```dart
// Start verification
Future<String> startVerification(String contactId) async {
  final profileClient = await ref.read(profileServiceClientProvider.future);

  final request = pb.CreateContactVerificationRequest(
    contactId: contactId,
  );

  final response = await profileClient.createContactVerification(request);
  return response.verificationId;
}

// Check verification code
Future<bool> checkVerification(String contactId, String code) async {
  final profileClient = await ref.read(profileServiceClientProvider.future);

  final request = pb.CheckVerificationRequest(
    contactId: contactId,
    code: code,
  );

  final response = await profileClient.checkVerification(request);
  return response.verified;
}
```

---

## 5. Files Service Integration

### Feature: Upload Media (MEDIA-UPLOAD-001)

```dart
Future<UploadResult> uploadFile(
  File file, {
  void Function(double)? onProgress,
}) async {
  final filesClient = await ref.read(filesServiceClientProvider.future);

  final fileName = file.path.split('/').last;
  final mimeType = _detectMimeType(fileName);
  final fileSize = await file.length();

  // Create upload stream
  Stream<pb.UploadContentRequest> uploadStream() async* {
    // First: metadata
    yield pb.UploadContentRequest(
      metadata: pb.UploadMetadata(
        filename: fileName,
        contentType: mimeType,
        fileSizeBytes: Int64(fileSize),
      ),
    );

    // Then: chunks
    int bytesUploaded = 0;
    const chunkSize = 256 * 1024;  // 256KB chunks

    await for (final chunk in file.openRead()) {
      yield pb.UploadContentRequest(
        chunk: pb.UploadChunk(chunk: chunk),
      );

      bytesUploaded += chunk.length;
      onProgress?.call(bytesUploaded / fileSize);
    }
  }

  final response = await filesClient.uploadContent(uploadStream());

  return UploadResult(
    fileId: response.mediaId,
    fileUrl: 'mxc://${response.serverName}/${response.mediaId}',
    mimeType: mimeType,
    thumbnailUrl: response.hasThumbnailMediaId()
        ? 'mxc://${response.serverName}/${response.thumbnailMediaId}'
        : null,
  );
}
```

### Feature: Download Media (MEDIA-CACHE-001)

```dart
Future<Uint8List> downloadFile(String serverName, String mediaId) async {
  final filesClient = await ref.read(filesServiceClientProvider.future);

  final request = pb.GetContentRequest(
    serverName: serverName,
    mediaId: mediaId,
  );

  final response = await filesClient.getContent(request);
  return response.content;
}
```

### Feature: Thumbnail Generation (MEDIA-THUMB-001)

```dart
Future<Uint8List> getThumbnail(
  String serverName,
  String mediaId, {
  int width = 300,
  int height = 300,
}) async {
  final filesClient = await ref.read(filesServiceClientProvider.future);

  final request = pb.GetContentThumbnailRequest(
    serverName: serverName,
    mediaId: mediaId,
    width: width,
    height: height,
    method: 'crop',  // or 'scale'
    animated: false,
  );

  final response = await filesClient.getContentThumbnail(request);
  return response.content;
}
```

### Feature: Link Preview (MEDIA-LINK-001)

```dart
Future<LinkPreview?> getUrlPreview(String url) async {
  final filesClient = await ref.read(filesServiceClientProvider.future);

  final request = pb.GetUrlPreviewRequest(url: url);

  try {
    final response = await filesClient.getUrlPreview(request);
    return LinkPreview(
      title: response.title,
      description: response.description,
      imageUrl: response.imageUrl,
      siteName: response.siteName,
    );
  } catch (e) {
    return null;  // URL preview not available
  }
}
```

### Feature: Upload Config (MEDIA-COMP-001)

```dart
Future<UploadConfig> getUploadConfig() async {
  final filesClient = await ref.read(filesServiceClientProvider.future);

  final request = pb.GetConfigRequest();
  final response = await filesClient.getConfig(request);

  return UploadConfig(
    maxUploadSizeBytes: response.maxUploadSizeBytes.toInt(),
  );
}
```

---

## 6. Device Service Integration

### Feature: Device Registration (NOTIF-PUSH-001)

```dart
Future<String> registerDevice() async {
  final deviceClient = await ref.read(deviceServiceClientProvider.future);

  final request = pb.CreateRequest(
    // Device properties from platform
    properties: Struct(fields: {
      'platform': Value(stringValue: Platform.operatingSystem),
      'model': Value(stringValue: await _getDeviceModel()),
      'app_version': Value(stringValue: packageInfo.version),
    }),
  );

  final response = await deviceClient.create(request);
  return response.deviceId;
}

// Link device to user
Future<void> linkDevice(String deviceId, String profileId) async {
  final deviceClient = await ref.read(deviceServiceClientProvider.future);

  final request = pb.LinkRequest(
    deviceId: deviceId,
    userId: profileId,
  );

  await deviceClient.link(request);
}
```

### Feature: FCM Token Registration (NOTIF-PUSH-001)

```dart
Future<void> registerFcmToken(String deviceId, String fcmToken) async {
  final deviceClient = await ref.read(deviceServiceClientProvider.future);

  final request = pb.RegisterKeyRequest(
    deviceId: deviceId,
    keyType: pb.KeyType.FCM_TOKEN,
    keyMaterial: fcmToken,
  );

  await deviceClient.registerKey(request);
}

// Unregister FCM token
Future<void> unregisterFcmToken(String deviceId) async {
  final deviceClient = await ref.read(deviceServiceClientProvider.future);

  // First search for existing key
  final searchRequest = pb.SearchKeyRequest(
    deviceId: deviceId,
    keyType: pb.KeyType.FCM_TOKEN,
  );

  final searchResponse = await deviceClient.searchKey(searchRequest);

  if (searchResponse.keys.isNotEmpty) {
    final keyId = searchResponse.keys.first.id;
    final request = pb.DeRegisterKeyRequest(keyId: keyId);
    await deviceClient.deRegisterKey(request);
  }
}
```

### Feature: E2EE Key Storage (SEC-E2E-001)

```dart
// Store encryption key
Future<void> storeEncryptionKey(
  String deviceId,
  String publicKey,
  KeyType keyType,
) async {
  final deviceClient = await ref.read(deviceServiceClientProvider.future);

  final request = pb.AddKeyRequest(
    deviceId: deviceId,
    keyType: keyType,  // CURVE25519_KEY, ED25519_KEY, etc.
    keyMaterial: publicKey,
  );

  await deviceClient.addKey(request);
}

// Get recipient's keys
Future<List<pb.Key>> getEncryptionKeys(String profileId) async {
  final deviceClient = await ref.read(deviceServiceClientProvider.future);

  final request = pb.SearchKeyRequest(
    profileId: profileId,
    keyType: pb.KeyType.CURVE25519_KEY,
  );

  final response = await deviceClient.searchKey(request);
  return response.keys;
}
```

### Feature: Presence Status (CONTACT-STATUS-001)

```dart
Future<void> updatePresence(String deviceId, PresenceStatus status) async {
  final deviceClient = await ref.read(deviceServiceClientProvider.future);

  final request = pb.UpdatePresenceRequest(
    deviceId: deviceId,
    status: status,  // ONLINE, OFFLINE, AWAY, BUSY
  );

  await deviceClient.updatePresence(request);
}
```

---

## 7. Notification Service Integration

### Feature: Send Notification (NOTIF-PUSH-001)

```dart
// Server-side typically, but client can trigger
Future<void> sendNotification(NotificationPayload payload) async {
  final notificationClient = await ref.read(notificationServiceClientProvider.future);

  final request = pb.SendRequest(
    notification: [
      pb.Notification(
        // Notification details
        recipientId: payload.recipientId,
        title: payload.title,
        body: payload.body,
        data: _mapToStruct(payload.data),
      ),
    ],
    autoRelease: true,
  );

  await for (final response in notificationClient.send(request)) {
    // Handle response
  }
}
```

### Feature: Notification Status (NOTIF-RICH-001)

```dart
Future<NotificationStatus> getNotificationStatus(String notificationId) async {
  final notificationClient = await ref.read(notificationServiceClientProvider.future);

  final request = pb.StatusRequest(id: notificationId);
  final response = await notificationClient.status(request);

  return NotificationStatus(
    id: response.id,
    state: response.state,
    status: response.status,
  );
}
```

---

## 8. Common Patterns

### Error Handling

```dart
Future<T> safeApiCall<T>(Future<T> Function() apiCall) async {
  try {
    return await apiCall();
  } on ConnectException catch (e) {
    if (e.code == Code.unauthenticated) {
      // Token expired, refresh and retry
      await _refreshToken();
      return await apiCall();
    } else if (e.code == Code.unavailable) {
      // Service unavailable, retry with backoff
      await Future.delayed(Duration(seconds: 2));
      return await apiCall();
    }
    rethrow;
  } catch (e) {
    AppLogger.error('API call failed', error: e);
    rethrow;
  }
}
```

### Pagination

```dart
class PaginatedResult<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  PaginatedResult({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });
}

Future<PaginatedResult<RoomEvent>> fetchMessagesPage(
  String roomId, {
  String? cursor,
  int limit = 50,
}) async {
  final response = await getHistory(roomId, cursor: cursor, limit: limit);

  return PaginatedResult(
    items: response.events.map(_mapToRoomEvent).toList(),
    nextCursor: response.hasNextCursor() ? response.nextCursor : null,
    hasMore: response.events.length == limit,
  );
}
```

### Caching

```dart
class CachedApiClient {
  final Map<String, CacheEntry> _cache = {};
  final Duration _ttl = Duration(minutes: 5);

  Future<T> getCached<T>(
    String key,
    Future<T> Function() fetcher,
  ) async {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      return entry.data as T;
    }

    final data = await fetcher();
    _cache[key] = CacheEntry(data: data, expiresAt: DateTime.now().add(_ttl));
    return data;
  }
}
```

### Retry with Backoff

```dart
Future<T> retryWithBackoff<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  int attempt = 0;
  Duration delay = initialDelay;

  while (true) {
    try {
      return await action();
    } catch (e) {
      attempt++;
      if (attempt >= maxAttempts) {
        rethrow;
      }

      await Future.delayed(delay);
      delay *= 2;  // Exponential backoff
    }
  }
}
```

### Struct Conversion

```dart
Struct _mapToStruct(Map<String, dynamic> map) {
  final struct = Struct();
  for (final entry in map.entries) {
    struct.fields[entry.key] = _objectToValue(entry.value);
  }
  return struct;
}

Value _objectToValue(dynamic obj) {
  final value = Value();
  if (obj == null) {
    value.nullValue = NullValue.NULL_VALUE;
  } else if (obj is String) {
    value.stringValue = obj;
  } else if (obj is num) {
    value.numberValue = obj.toDouble();
  } else if (obj is bool) {
    value.boolValue = obj;
  } else if (obj is List) {
    final listValue = ListValue();
    listValue.values.addAll(obj.map(_objectToValue));
    value.listValue = listValue;
  } else if (obj is Map) {
    value.structValue = _mapToStruct(obj.cast<String, dynamic>());
  }
  return value;
}

Map<String, dynamic> _structToMap(Struct struct) {
  final result = <String, dynamic>{};
  for (final entry in struct.fields.entries) {
    result[entry.key] = _valueToObject(entry.value);
  }
  return result;
}

dynamic _valueToObject(Value value) {
  if (value.hasStringValue()) return value.stringValue;
  if (value.hasNumberValue()) return value.numberValue;
  if (value.hasBoolValue()) return value.boolValue;
  if (value.hasNullValue()) return null;
  if (value.hasListValue()) {
    return value.listValue.values.map(_valueToObject).toList();
  }
  if (value.hasStructValue()) {
    return _structToMap(value.structValue);
  }
  return null;
}
```

---

## Quick Reference: Feature → API Mapping

| Feature ID | Primary API | Key Methods |
|------------|-------------|-------------|
| MSG-EDIT-001 | Chat | `sendEvent` (edited=true) |
| MSG-DEL-001 | Chat | `sendEvent` (redacted=true) |
| MSG-FWD-001 | Chat | `sendEvent` |
| MSG-STAR-001 | Local DB | N/A |
| MSG-READ-001 | Gateway | `ClientCommand.readMarker` |
| MSG-TYPE-001 | Gateway | `ClientCommand.typing` |
| NOTIF-PUSH-001 | Device | `registerKey` (FCM_TOKEN) |
| NOTIF-RICH-001 | Notification | `send`, `status` |
| MEDIA-UPLOAD-001 | Files | `uploadContent` |
| MEDIA-THUMB-001 | Files | `getContentThumbnail` |
| MEDIA-LINK-001 | Files | `getUrlPreview` |
| GROUP-ADMIN-001 | Chat | `updateSubscriptionRole` |
| GROUP-INVITE-001 | Chat | `updateRoom` (metadata) |
| CONTACT-SYNC-001 | Profile | `addRoster`, `searchRoster` |
| CONTACT-VERIFY-001 | Profile | `createContactVerification`, `checkVerification` |
| SEARCH-MSG-001 | Chat | `getHistory` + local FTS |
| SEARCH-CHAT-001 | Chat | `searchRooms` |
| SEC-E2E-001 | Device | `addKey`, `searchKey` |
| CALL-* | Gateway | `sendEvent` (CALL type) |

---

*API Integration Guide v1.0*
*Last Updated: January 2026*
