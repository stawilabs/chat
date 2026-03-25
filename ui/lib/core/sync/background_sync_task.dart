import 'dart:io' as io;

import 'package:antinvestor_api_chat/antinvestor_api_chat.dart' as pb;
import 'package:antinvestor_api_chat/antinvestor_api_chat.dart';
import 'package:antinvestor_api_common/antinvestor_api_common.dart' as common;
import 'package:connectrpc/connect.dart' as connect;
import 'package:connectrpc/io.dart' as connect_io;
import 'package:connectrpc/protobuf.dart' as connect_protobuf;
import 'package:connectrpc/protocol/connect.dart' as connect_protocol;
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart' as fixnum;

import '../../features/messages/data/message_repository.dart';
import '../../features/messages/domain/room_event.dart' as domain;
import '../../features/notifications/badge_service.dart';
import '../auth/shared_token_service.dart';
import '../db/database.dart';
import '../files/files_config_service.dart';
import '../logging/app_logger.dart';
import '../networking/api_config.dart';
import '../settings/settings_service.dart';
import 'pending_job.dart' as domain_job;
import 'pending_job_repository.dart';

class BackgroundSyncTask {
  /// Main entry point for background sync
  /// Returns true if sync completed successfully, false otherwise
  static Future<bool> run() async {
    try {
      AppLogger.info('Starting background sync task');

      // Initialize database
      final database = AppDatabase.instance;
      final jobRepo = PendingJobRepository(database);
      final messageRepo = MessageRepository(database);

      // Get auth token using SharedTokenService
      // This validates expiry and will refresh if needed
      final tokenService = SharedTokenService.instance;
      final accessToken = await tokenService.getAccessToken();

      if (accessToken == null) {
        // Log token info for debugging
        final tokenInfo = await tokenService.getTokenInfo();
        AppLogger.debug(
          'No valid access token for background sync',
          data: tokenInfo,
        );
        return true; // Not a failure - foreground will refresh and retry
      }

      // Get profile ID from ID token using SharedTokenService
      final currentProfileId = await tokenService.getProfileId();

      // Create auth headers
      final authHeaders = connect.Headers();
      authHeaders['Authorization'] = 'Bearer $accessToken';

      // Initialize API client with optimized HTTP client
      final httpClient = io.HttpClient();
      httpClient.connectionTimeout = ApiConfig.connectionTimeout;
      httpClient.idleTimeout = ApiConfig.idleTimeout;
      httpClient.maxConnectionsPerHost = 2; // Limit for background tasks

      final transport = connect_protocol.Transport(
        baseUrl: ApiConfig.chatBaseUrl,
        codec: const connect_protobuf.ProtoCodec(),
        httpClient: connect_io.createHttpClient(httpClient),
      );
      final chatClient = ChatServiceClient(transport);

      // Download new messages from subscribed rooms
      await _downloadNewMessages(
        database,
        messageRepo,
        chatClient,
        authHeaders,
      );

      // Process pending jobs (uploads)
      final success = await _processPendingJobs(
        database,
        jobRepo,
        messageRepo,
        chatClient,
        authHeaders,
        currentProfileId,
      );

      // Clean up expired (disappearing) messages
      try {
        final deletedCount = await messageRepo.deleteExpiredMessages();
        if (deletedCount > 0) {
          AppLogger.info(
            'Deleted expired messages in background sync',
            data: {'deletedCount': deletedCount},
          );
        }
      } catch (e, stackTrace) {
        AppLogger.error(
          'Failed to delete expired messages in background sync',
          error: e,
          stackTrace: stackTrace,
        );
        // Don't fail the sync task for cleanup errors
      }

      // Clean up old failed jobs (older than 7 days)
      try {
        final cleanedJobs = await jobRepo.clearOldFailedJobs();
        if (cleanedJobs > 0) {
          AppLogger.info(
            'Cleaned up old failed jobs',
            data: {'cleanedCount': cleanedJobs},
          );
        }

        // Log warning if there are recent failed jobs
        final failedCount = await jobRepo.getFailedJobCount();
        if (failedCount > 0) {
          AppLogger.warning(
            'There are failed messages that could not be sent',
            data: {'failedCount': failedCount},
          );
        }
      } catch (e, stackTrace) {
        AppLogger.error(
          'Failed to clean up old failed jobs',
          error: e,
          stackTrace: stackTrace,
        );
        // Don't fail the sync task for cleanup errors
      }

      // Refresh badge count after sync
      if (BadgeService.isSupported) {
        try {
          final settingsService = SettingsService(database);
          await settingsService.initialize();
          final badgeService = BadgeService(database, settingsService);
          await badgeService.refreshBadge();
          AppLogger.debug('Badge refreshed after background sync');
        } catch (e, stackTrace) {
          AppLogger.error(
            'Failed to refresh badge in background sync',
            error: e,
            stackTrace: stackTrace,
          );
          // Don't fail the sync task for badge errors
        }
      }

      AppLogger.info('Background sync completed', data: {'success': success});
      return success;
    } catch (e, stack) {
      AppLogger.error(
        'Background sync task failed',
        error: e,
        stackTrace: stack,
      );
      return false; // Signal failure so workmanager can retry
    }
  }

  /// Process all pending upload jobs
  static Future<bool> _processPendingJobs(
    AppDatabase database,
    PendingJobRepository jobRepo,
    MessageRepository messageRepo,
    ChatServiceClient chatClient,
    connect.Headers authHeaders,
    String? currentProfileId,
  ) async {
    try {
      final jobs = await jobRepo.getPendingJobs();

      if (jobs.isEmpty) {
        AppLogger.debug('No pending jobs to process in background sync');
        return true;
      }

      AppLogger.info(
        'Processing pending jobs in background',
        data: {'jobCount': jobs.length},
      );

      for (final job in jobs) {
        try {
          await _processJob(
            database,
            job,
            chatClient,
            messageRepo,
            jobRepo,
            authHeaders,
            currentProfileId,
          );
        } catch (e, stackTrace) {
          AppLogger.error(
            'Failed to process background job',
            error: e,
            stackTrace: stackTrace,
            data: {'jobId': job.id, 'jobType': job.type.toString()},
          );
          // Increment retry count so failed jobs eventually reach 'failed' status
          await jobRepo.incrementRetry(job.id, errorMessage: e.toString());
          // Continue with other jobs even if one fails
        }
      }

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error processing pending jobs',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Download new messages from subscribed rooms
  static Future<void> _downloadNewMessages(
    AppDatabase database,
    MessageRepository messageRepo,
    ChatServiceClient chatClient,
    connect.Headers authHeaders,
  ) async {
    try {
      // Get list of rooms the user is subscribed to
      final rooms = await database.select(database.rooms).get();

      if (rooms.isEmpty) {
        AppLogger.debug('No rooms to sync in background');
        return;
      }

      AppLogger.info(
        'Downloading messages for rooms in background',
        data: {'roomCount': rooms.length},
      );

      var totalMessages = 0;

      // Fetch recent messages for each room (limit to prevent long background tasks)
      for (final room in rooms.take(10)) {
        // Limit to 10 rooms per background sync
        try {
          final request = pb.GetHistoryRequest(
            roomId: room.id,
            cursor: common.PageCursor(limit: 20), // Get last 20 messages
            forward: false,
          );

          final response = await chatClient.getHistory(
            request,
            headers: authHeaders,
          );

          for (final event in response.events) {
            if (event.id.isEmpty || event.roomId.isEmpty) continue;

            // Extract content from payload
            var content = <String, dynamic>{};
            var eventType = _mapProtoEventTypeToLocal(event.type);
            if (event.hasPayload()) {
              final payload = event.payload;
              if (payload.hasText()) {
                content = {'text': payload.text.body};
              } else if (payload.hasAttachment()) {
                final contentUrl = FilesConfigService.buildContentUrlFrom(
                  ApiConfig.filesBaseUrl,
                  payload.attachment.attachmentId,
                );
                content = {
                  'attachmentId': payload.attachment.attachmentId,
                  'fileName': payload.attachment.filename,
                  'mimeType': payload.attachment.mimeType,
                  'size': payload.attachment.sizeBytes.toInt(),
                  'mediaId': payload.attachment.attachmentId,
                  'contentUri': contentUrl,
                  'url': contentUrl,
                };
              } else if (payload.hasRoomChange()) {
                final roomChange = payload.roomChange;
                content = {
                  'text': roomChange.body,
                  'body': roomChange.body,
                  'action': roomChange.action.name,
                  'actorSubscriptionId': roomChange.actorSubscriptionId,
                  'targetSubscriptionIds': roomChange.targetSubscriptionIds
                      .toList(),
                  'isRoomChange': true,
                };
                eventType = domain.RoomEventType.roomChange;
              } else if (payload.hasModeration()) {
                final moderation = payload.moderation;
                content = {
                  'text': moderation.body,
                  'body': moderation.body,
                  'actorSubscriptionId': moderation.actorSubscriptionId,
                  'targetSubscriptionIds': moderation.targetSubscriptionIds
                      .toList(),
                  'isModeration': true,
                };
                eventType = domain.RoomEventType.roomChange;
              }
            }

            final roomEvent = domain.RoomEvent(
              id: event.id,
              roomId: event.roomId,
              senderId: event.hasSubscriptionId() ? event.subscriptionId : '',
              type: eventType,
              content: content,
              parentId: event.hasParentId() ? event.parentId : null,
              status: domain.EventStatus.delivered,
              createdAt: event.hasSentAt()
                  ? event.sentAt.seconds.toInt() * 1000 +
                        event.sentAt.nanos ~/ 1000000
                  : DateTime.now().millisecondsSinceEpoch,
              serverTs: event.hasSentAt()
                  ? event.sentAt.seconds.toInt() * 1000 +
                        event.sentAt.nanos ~/ 1000000
                  : null,
            );

            await messageRepo.insertMessage(roomEvent);
            totalMessages++;
          }
        } catch (e) {
          AppLogger.warning(
            'Failed to fetch history for room in background',
            data: {'roomId': room.id, 'error': e.toString()},
          );
          // Continue with other rooms
        }
      }

      AppLogger.info(
        'Background message download completed',
        data: {'totalMessages': totalMessages},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error downloading messages in background',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow - this is a best-effort operation
    }
  }

  /// Map proto event type to local domain type
  static domain.RoomEventType _mapProtoEventTypeToLocal(pb.RoomEventType type) {
    switch (type) {
      case pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE:
        return domain.RoomEventType.text;
      case pb.RoomEventType.ROOM_EVENT_TYPE_REACTION:
        return domain.RoomEventType.reaction;
      case pb.RoomEventType.ROOM_EVENT_TYPE_CALL:
        return domain.RoomEventType.callOffer;
      case pb.RoomEventType.ROOM_EVENT_TYPE_MOTION:
        return domain.RoomEventType.motion;
      default:
        return domain.RoomEventType.text;
    }
  }

  /// Process a single job
  static Future<void> _processJob(
    AppDatabase database,
    domain_job.PendingJob job,
    ChatServiceClient chatClient,
    MessageRepository messageRepo,
    PendingJobRepository jobRepo,
    connect.Headers authHeaders,
    String? currentProfileId,
  ) async {
    switch (job.type) {
      case domain_job.JobType.sendMessage:
      case domain_job.JobType.sendMediaMessage:
        await _processSendMessage(
          job,
          chatClient,
          messageRepo,
          authHeaders,
          currentProfileId,
        );
        break;
      case domain_job.JobType.createRoom:
        await _processCreateRoom(database, job, chatClient, authHeaders);
        break;
      case domain_job.JobType.updateRoom:
        await _processUpdateRoom(job, chatClient, authHeaders);
        break;
      case domain_job.JobType.deleteRoom:
        await _processDeleteRoom(job, chatClient, authHeaders);
        break;
      case domain_job.JobType.addRoomMembers:
        await _processAddRoomMembers(job, chatClient, authHeaders);
        break;
      case domain_job.JobType.removeRoomMembers:
        await _processRemoveRoomMembers(job, chatClient, authHeaders);
        break;
      case domain_job.JobType.deleteMessage:
        await _processDeleteMessage(job, chatClient, authHeaders);
        break;
      default:
        AppLogger.debug(
          'Skipping unsupported job type in background',
          data: {'jobType': job.type.toString()},
        );
        return; // Skip unknown/unsupported jobs
    }

    // Mark job as completed
    await jobRepo.deleteJob(job.id);
    AppLogger.debug(
      'Background job completed',
      data: {'jobId': job.id, 'jobType': job.type.toString()},
    );
  }

  /// Create a room
  static Future<void> _processCreateRoom(
    AppDatabase database,
    domain_job.PendingJob job,
    ChatServiceClient chatClient,
    connect.Headers authHeaders,
  ) async {
    final payload = job.payload;

    // Convert contact IDs to ContactLink objects for server routing
    final contactIds =
        (payload['contactIds'] as List<dynamic>?)?.cast<String>() ?? [];
    final memberLinks = contactIds
        .map((id) => common.ContactLink(contactId: id))
        .toList();

    final request = pb.CreateRoomRequest(
      id: payload['id'] as String,
      name: payload['name'] as String? ?? '',
      description: payload['description'] as String? ?? '',
      isPrivate: payload['isPrivate'] as bool? ?? false,
      members: memberLinks,
    );

    if (payload['metadata'] != null) {
      request.metadata = _mapToStruct(
        payload['metadata'] as Map<String, dynamic>,
      );
    }

    final response = await chatClient.createRoom(request, headers: authHeaders);

    if (response.hasRoom()) {
      final roomId = response.room.id;
      AppLogger.debug(
        'Room created in background',
        data: {'localId': payload['id'], 'serverId': roomId},
      );

      // CRITICAL: Sync room members immediately after room creation
      // This ensures the current user's subscription ID is available
      // for sending messages when the app comes back to foreground
      try {
        await _syncRoomMembers(database, chatClient, authHeaders, roomId);
        AppLogger.debug(
          'Room members synced after background creation',
          data: {'roomId': roomId},
        );
      } catch (e) {
        // Log but don't fail - the sync will retry when app comes to foreground
        AppLogger.warning(
          'Failed to sync room members after background creation',
          data: {'roomId': roomId, 'error': e.toString()},
        );
      }
    } else if (response.hasError()) {
      throw Exception('Room creation failed: ${response.error.message}');
    }
  }

  /// Sync room members from server to local database
  static Future<void> _syncRoomMembers(
    AppDatabase database,
    ChatServiceClient chatClient,
    connect.Headers authHeaders,
    String roomId,
  ) async {
    // Fetch subscriptions from API
    final request = pb.SearchRoomSubscriptionsRequest(roomId: roomId);
    final response = await chatClient.searchRoomSubscriptions(
      request,
      headers: authHeaders,
    );

    var memberCount = 0;

    // Process each subscription from the response
    for (final subscription in response.members) {
      final subscriptionId = subscription.id;

      // Extract profileId and contactId from ContactLink
      final profileId =
          subscription.hasMember() && subscription.member.hasProfileId()
          ? subscription.member.profileId
          : null;
      final contactId =
          subscription.hasMember() && subscription.member.hasContactId()
          ? subscription.member.contactId
          : null;

      // Extract role (use first role if multiple, or null)
      final role = subscription.roles.isNotEmpty
          ? subscription.roles.first
          : null;

      // Insert or update room member
      await database
          .into(database.roomSubscriptions)
          .insertOnConflictUpdate(
            RoomSubscriptionsCompanion.insert(
              id: subscriptionId,
              roomId: subscription.roomId,
              profileId: Value(profileId),
              contactId: Value(contactId),
              role: Value(role),
              joinedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      memberCount++;
    }

    AppLogger.debug(
      'Room members synced in background',
      data: {'roomId': roomId, 'memberCount': memberCount},
    );
  }

  /// Update a room
  static Future<void> _processUpdateRoom(
    domain_job.PendingJob job,
    ChatServiceClient chatClient,
    connect.Headers authHeaders,
  ) async {
    final payload = job.payload;

    final request = pb.UpdateRoomRequest(
      roomId: payload['id'] as String,
      name: payload['name'] as String? ?? '',
      description: payload['description'] as String? ?? '',
    );

    if (payload['metadata'] != null) {
      request.metadata = _mapToStruct(
        payload['metadata'] as Map<String, dynamic>,
      );
    }

    await chatClient.updateRoom(request, headers: authHeaders);
    AppLogger.debug(
      'Room updated in background',
      data: {'roomId': payload['id']},
    );
  }

  /// Delete a room
  static Future<void> _processDeleteRoom(
    domain_job.PendingJob job,
    ChatServiceClient chatClient,
    connect.Headers authHeaders,
  ) async {
    final payload = job.payload;

    final request = pb.DeleteRoomRequest(roomId: payload['id'] as String);

    await chatClient.deleteRoom(request, headers: authHeaders);
    AppLogger.debug(
      'Room deleted in background',
      data: {'roomId': payload['id']},
    );
  }

  /// Add members to a room
  static Future<void> _processAddRoomMembers(
    domain_job.PendingJob job,
    ChatServiceClient chatClient,
    connect.Headers authHeaders,
  ) async {
    final payload = job.payload;
    final roomId = payload['roomId'] as String;
    final profileIds = (payload['profileIds'] as List<dynamic>).cast<String>();

    // Convert profileIds to RoomSubscription objects with ContactLink
    final members = profileIds
        .map(
          (profileId) => pb.RoomSubscription(
            roomId: roomId,
            member: common.ContactLink(profileId: profileId),
          ),
        )
        .toList();

    final request = pb.AddRoomSubscriptionsRequest(
      roomId: roomId,
      members: members,
    );

    await chatClient.addRoomSubscriptions(request, headers: authHeaders);
    AppLogger.debug(
      'Members added in background',
      data: {'roomId': roomId, 'memberCount': profileIds.length},
    );
  }

  /// Remove members from a room
  static Future<void> _processRemoveRoomMembers(
    domain_job.PendingJob job,
    ChatServiceClient chatClient,
    connect.Headers authHeaders,
  ) async {
    final payload = job.payload;

    // Note: The API now expects subscription_id instead of profileIds
    // For now, we'll use profileIds as subscription IDs (they should match)
    final subscriptionIds = (payload['profileIds'] as List<dynamic>)
        .cast<String>();

    final request = pb.RemoveRoomSubscriptionsRequest(
      roomId: payload['roomId'] as String,
      subscriptionId: subscriptionIds,
    );

    await chatClient.removeRoomSubscriptions(request, headers: authHeaders);
    AppLogger.debug(
      'Members removed in background',
      data: {
        'roomId': payload['roomId'],
        'memberCount': (payload['profileIds'] as List).length,
      },
    );
  }

  /// Delete a message (redact)
  static Future<void> _processDeleteMessage(
    domain_job.PendingJob job,
    ChatServiceClient chatClient,
    connect.Headers authHeaders,
  ) async {
    final payload = job.payload;
    final messageId = payload['messageId'] as String;
    final roomId = payload['roomId'] as String;

    // Send a redacted event to mark the message as deleted
    final now = DateTime.now();
    final timestamp = common.Timestamp(
      seconds: fixnum.Int64(now.millisecondsSinceEpoch ~/ 1000),
      nanos: (now.millisecondsSinceEpoch % 1000) * 1000000,
    );

    final event = pb.RoomEvent(
      id: messageId,
      roomId: roomId,
      type: pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE,
      sentAt: timestamp,
      redacted: true,
    );

    final request = pb.SendEventRequest(event: [event]);
    await chatClient.sendEvent(request, headers: authHeaders);

    AppLogger.debug(
      'Message deleted in background',
      data: {'messageId': messageId, 'roomId': roomId},
    );
  }

  /// Send a message
  static Future<void> _processSendMessage(
    domain_job.PendingJob job,
    ChatServiceClient chatClient,
    MessageRepository messageRepo,
    connect.Headers authHeaders,
    String? currentProfileId,
  ) async {
    final payload = job.payload;

    // Create timestamp
    final now = DateTime.now();
    final timestamp = common.Timestamp(
      seconds: fixnum.Int64(now.millisecondsSinceEpoch ~/ 1000),
      nanos: (now.millisecondsSinceEpoch % 1000) * 1000000,
    );

    // currentProfileId is already available as a parameter
    // Source is no longer used in new API

    // Extract content and type
    final content = payload['content'] as Map<String, dynamic>;
    final localType = domain.RoomEventType.values.firstWhere(
      (t) => t.toString() == payload['type'],
      orElse: () => domain.RoomEventType.text,
    );
    final protoType = _mapLocalEventTypeToProto(localType);

    // Build event with payload-based content
    final pbPayload = pb.Payload();
    if (localType == domain.RoomEventType.text) {
      pbPayload.text = pb.TextContent(
        body: content['text'] as String? ?? '',
        format: 'plain',
      );
    } else if (localType == domain.RoomEventType.image ||
        localType == domain.RoomEventType.video ||
        localType == domain.RoomEventType.audio ||
        localType == domain.RoomEventType.file) {
      pbPayload.attachment = pb.AttachmentContent(
        attachmentId: content['attachmentId'] as String? ?? '',
        filename: content['fileName'] as String? ?? '',
        mimeType: content['mimeType'] as String? ?? '',
        sizeBytes: fixnum.Int64(content['size'] as int? ?? 0),
      );
    }

    final event = pb.RoomEvent(
      id: payload['localId'] as String? ?? '',
      roomId: payload['roomId'] as String,
      type: protoType,
      sentAt: timestamp,
      payload: pbPayload,
    );

    final request = pb.SendEventRequest(event: [event]);
    final response = await chatClient.sendEvent(request, headers: authHeaders);

    // Update local message status
    if (payload['localId'] != null && response.ack.isNotEmpty) {
      final ackEventId = response.ack.first.eventId;
      await messageRepo.updateMessageStatus(
        ackEventId.first,
        domain.EventStatus.sent,
      );
      AppLogger.debug(
        'Message sent in background',
        data: {'localId': payload['localId'], 'serverId': ackEventId},
      );
    }
  }

  // Helper methods for Struct conversion (copied from SyncEngine)

  static common.Struct _mapToStruct(Map<String, dynamic> map) {
    final struct = common.Struct();
    for (final entry in map.entries) {
      struct.fields[entry.key] = _objectToValue(entry.value);
    }
    return struct;
  }

  static common.Value _objectToValue(Object? obj) {
    final value = common.Value();

    if (obj == null) {
      value.nullValue = common.NullValue.NULL_VALUE;
    } else if (obj is bool) {
      value.boolValue = obj;
    } else if (obj is num) {
      value.numberValue = obj.toDouble();
    } else if (obj is String) {
      value.stringValue = obj;
    } else if (obj is List) {
      value.listValue = common.ListValue(
        values: obj.map(_objectToValue).toList(),
      );
    } else if (obj is Map<String, dynamic>) {
      value.structValue = _mapToStruct(obj);
    } else {
      value.stringValue = obj.toString();
    }

    return value;
  }

  static pb.RoomEventType _mapLocalEventTypeToProto(domain.RoomEventType type) {
    switch (type) {
      case domain.RoomEventType.text:
        return pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE;
      case domain.RoomEventType.image:
      case domain.RoomEventType.video:
      case domain.RoomEventType.audio:
      case domain.RoomEventType.file:
        // All media types map to MESSAGE with attachment payload
        return pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE;
      case domain.RoomEventType.reaction:
        return pb.RoomEventType.ROOM_EVENT_TYPE_REACTION;
      case domain.RoomEventType.callOffer:
      case domain.RoomEventType.callAnswer:
      case domain.RoomEventType.callIce:
      case domain.RoomEventType.callEnd:
      case domain.RoomEventType.groupCallStart:
      case domain.RoomEventType.groupCallJoin:
      case domain.RoomEventType.groupCallLeave:
      case domain.RoomEventType.groupCallEnd:
      case domain.RoomEventType.groupCallOffer:
      case domain.RoomEventType.groupCallAnswer:
      case domain.RoomEventType.groupCallIce:
      case domain.RoomEventType.groupCallMuteUpdate:
        // All call types (1-on-1 and group) map to a single ROOM_EVENT_TYPE_CALL
        return pb.RoomEventType.ROOM_EVENT_TYPE_CALL;
      case domain.RoomEventType.motion:
        return pb.RoomEventType.ROOM_EVENT_TYPE_MOTION;
      case domain.RoomEventType.vote:
      case domain.RoomEventType.transaction:
      case domain.RoomEventType.groupConfig:
        // These might not be in protobuf yet, map to MESSAGE for now
        return pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE;
      case domain.RoomEventType.roomKey:
        // Room key events are sent as messages for E2EE key exchange
        return pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE;
      case domain.RoomEventType.roomChange:
        // Room change events are system events
        return pb.RoomEventType.ROOM_EVENT_TYPE_EVENT;
    }
  }
}
