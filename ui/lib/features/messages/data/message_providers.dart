import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/sync/pending_job.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/room_event.dart' as domain;
import 'message_repository.dart';

part 'message_providers.g.dart';

@riverpod
MessageRepository messageRepository(Ref ref) =>
    MessageRepository(AppDatabase.instance);

/// Fetch a single parent message by event ID (for reply previews).
final parentMessageProvider = FutureProvider.family<domain.RoomEvent?, String>((
  ref,
  eventId,
) {
  final repo = ref.watch(messageRepositoryProvider);
  return repo.getEventById(eventId);
});

/// Reactive stream provider for messages - provides instant UI updates
/// when messages are added, updated, or deleted from the local database
final messagesStreamProvider =
    StreamProvider.family<List<domain.RoomEvent>, String>((ref, roomId) {
      final repo = ref.watch(messageRepositoryProvider);
      return repo.watchMessagesForRoom(roomId);
    });

/// Paginated messages stream provider with configurable limit
/// Use this for views that need to load more messages on scroll
final paginatedMessagesStreamProvider =
    StreamProvider.family<List<domain.RoomEvent>, ({String roomId, int limit})>(
      (ref, params) {
        final repo = ref.watch(messageRepositoryProvider);
        return repo.watchMessagesForRoom(params.roomId, limit: params.limit);
      },
    );

@riverpod
class MessageList extends _$MessageList {
  @override
  Future<List<domain.RoomEvent>> build(String roomId) async {
    final repo = ref.watch(messageRepositoryProvider);
    return repo.getMessagesForRoom(roomId);
  }

  Future<void> sendMessage(domain.RoomEvent event) async {
    final messageRepo = ref.read(messageRepositoryProvider);
    final jobRepo = ref.read(pendingJobRepositoryProvider);

    // 1. Optimistic update: Insert into local DB
    // The stream provider will automatically update the UI
    await messageRepo.insertMessage(event);

    // 2. Always queue through the job system for reliable delivery.
    // This avoids the double-send risk of trying sendMessageDirect first
    // and falling back to a job on failure (the server may have received
    // the direct send even though the client got an error).
    await jobRepo.addJob(JobType.sendMessage, {
      'roomId': event.roomId,
      'type': event.type.toString(),
      'localId': event.localId,
      'content': event.content,
    });
  }

  /// Load older messages with proper pagination
  /// Uses timestamp filtering to fetch messages before the oldest message
  /// Returns true if more messages were loaded, false if no more available
  Future<bool> loadOlderMessages(String roomId) async {
    final repo = ref.read(messageRepositoryProvider);

    // Get the oldest message timestamp as the cursor
    final oldestTimestamp = await repo.getOldestMessageTimestamp(roomId);
    if (oldestTimestamp == null) {
      // No messages yet, try to fetch from server
      try {
        final syncEngine = await ref.read(syncEngineProvider.future);
        final fetchedCount = await syncEngine.getHistory(roomId);
        if (fetchedCount > 0) {
          ref.invalidateSelf();
          return true;
        }
      } catch (e) {
        AppLogger.warning('Failed to fetch history from server', error: e);
      }
      return false;
    }

    // First check if we have more messages locally
    final olderLocalMessages = await repo.getMessagesBeforeTimestamp(
      roomId,
      beforeTimestamp: oldestTimestamp,
    );

    if (olderLocalMessages.isNotEmpty) {
      // We have older messages locally, just refresh the view
      ref.invalidateSelf();
      return true;
    }

    // No local messages, try to fetch from server
    try {
      final syncEngine = await ref.read(syncEngineProvider.future);
      // Convert timestamp to cursor format (server expects timestamp in seconds)
      final cursorTimestamp = (oldestTimestamp ~/ 1000).toString();
      final fetchedCount = await syncEngine.getHistory(
        roomId,
        cursor: cursorTimestamp,
      );

      if (fetchedCount > 0) {
        // Messages were fetched and stored, refresh view
        ref.invalidateSelf();
        return true;
      } else {
        // No more messages available
        AppLogger.debug(
          'No more history available for room',
          data: {'roomId': roomId},
        );
        return false;
      }
    } catch (e) {
      AppLogger.warning('Failed to fetch older messages from server', error: e);
      return false;
    }
  }

  /// Check if there are more messages to load
  Future<bool> hasMoreMessages(String roomId) async {
    final repo = ref.read(messageRepositoryProvider);
    final oldestTimestamp = await repo.getOldestMessageTimestamp(roomId);

    if (oldestTimestamp == null) return false;

    // Check locally first
    final olderMessages = await repo.getMessagesBeforeTimestamp(
      roomId,
      beforeTimestamp: oldestTimestamp,
      limit: 1,
    );

    // If we have local older messages, there are more
    // Otherwise we don't know for sure until we try to fetch
    return olderMessages.isNotEmpty;
  }
}
