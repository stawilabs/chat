import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xid/xid.dart';

import '../../../core/auth/auth_context.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/sync/pending_job.dart';
import '../../../core/sync/pending_job_repository.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/room_event.dart' as domain;
import 'message_providers.dart';
import 'message_repository.dart';

/// Maximum number of destinations a message can be forwarded to at once
const int maxForwardDestinations = 5;

/// Result of a forward operation
class ForwardResult {
  ForwardResult({
    required this.success,
    required this.destinationRoomId,
    this.forwardedEvent,
    this.errorMessage,
  });

  final bool success;
  final String destinationRoomId;
  final domain.RoomEvent? forwardedEvent;
  final String? errorMessage;
}

/// Service for forwarding messages to other rooms
///
/// Supports:
/// - Forwarding to multiple destinations (max 5)
/// - Media forwarding shares same file (no re-upload)
/// - Forward count tracking for viral spread
/// - Restricted message handling
class MessageForwardingService {
  MessageForwardingService(
    this._messageRepo,
    this._jobRepo,
    this._getSubscriptionIdForRoom,
  );

  final MessageRepository _messageRepo;
  final PendingJobRepository _jobRepo;

  /// Callback to get current user's subscription ID for a room
  final Future<String> Function(String roomId) _getSubscriptionIdForRoom;

  /// Forward a message to multiple destinations
  ///
  /// Parameters:
  /// - [originalEvent]: The message to forward
  /// - [destinationRoomIds]: List of room IDs to forward to (max 5)
  ///
  /// Returns a list of [ForwardResult] for each destination
  Future<List<ForwardResult>> forwardMessage({
    required domain.RoomEvent originalEvent,
    required List<String> destinationRoomIds,
  }) async {
    // Validate destinations
    if (destinationRoomIds.isEmpty) {
      AppLogger.warning('No destinations provided for forward');
      return [];
    }

    if (destinationRoomIds.length > maxForwardDestinations) {
      AppLogger.warning(
        'Too many forward destinations',
        data: {
          'requested': destinationRoomIds.length,
          'max': maxForwardDestinations,
        },
      );
      // Take only first maxForwardDestinations
      destinationRoomIds = destinationRoomIds
          .take(maxForwardDestinations)
          .toList();
    }

    // Check if message can be forwarded
    if (!originalEvent.canBeForwarded) {
      AppLogger.warning(
        'Message cannot be forwarded',
        data: {
          'messageId': originalEvent.id,
          'isDeleted': originalEvent.isDeleted,
          'forwardRestricted': originalEvent.forwardRestricted,
        },
      );
      return destinationRoomIds
          .map(
            (roomId) => ForwardResult(
              success: false,
              destinationRoomId: roomId,
              errorMessage: originalEvent.isDeleted
                  ? 'Cannot forward deleted message'
                  : 'This message cannot be forwarded',
            ),
          )
          .toList();
    }

    final results = <ForwardResult>[];
    final now = DateTime.now().millisecondsSinceEpoch;

    // Forward to each destination
    for (final destinationRoomId in destinationRoomIds) {
      try {
        // Get subscription ID for the destination room
        final senderId = await _getSubscriptionIdForRoom(destinationRoomId);
        final result = await _forwardToRoom(
          originalEvent: originalEvent,
          destinationRoomId: destinationRoomId,
          senderId: senderId,
          timestamp: now,
        );
        results.add(result);
      } catch (e, stackTrace) {
        AppLogger.error(
          'Failed to forward message',
          error: e,
          stackTrace: stackTrace,
          data: {
            'messageId': originalEvent.id,
            'destinationRoomId': destinationRoomId,
          },
        );
        results.add(
          ForwardResult(
            success: false,
            destinationRoomId: destinationRoomId,
            errorMessage: 'Failed to forward: ${e.toString()}',
          ),
        );
      }
    }

    // Increment forward count on original message
    if (results.any((r) => r.success)) {
      await _messageRepo.incrementForwardCount(originalEvent.id);
      AppLogger.info(
        'Message forwarded',
        data: {
          'messageId': originalEvent.id,
          'successCount': results.where((r) => r.success).length,
          'totalDestinations': destinationRoomIds.length,
        },
      );
    }

    return results;
  }

  /// Forward a single message to a single room
  Future<ForwardResult> _forwardToRoom({
    required domain.RoomEvent originalEvent,
    required String destinationRoomId,
    required String senderId,
    required int timestamp,
  }) async {
    final localId = Xid().toString();

    // Determine the original event ID for tracking
    // If the message is already forwarded, use its original source
    final originalEventId =
        originalEvent.forwardedFromEvent ?? originalEvent.id;
    final originalRoomId =
        originalEvent.forwardedFromRoom ?? originalEvent.roomId;

    // Create forwarded event with same content but new metadata
    // For media, we reuse the same URLs (no re-upload)
    final forwardedEvent = domain.RoomEvent(
      id: localId,
      roomId: destinationRoomId,
      senderId: senderId,
      type: originalEvent.type,
      content: originalEvent.content, // Same content including media URLs
      createdAt: timestamp,
      localId: localId,
      forwardedFromRoom: originalRoomId,
      forwardedFromEvent: originalEventId,
      forwardRestricted: originalEvent.forwardRestricted,
    );

    // Save locally first (optimistic update)
    await _messageRepo.insertMessage(forwardedEvent);

    // Queue for upload to server
    await _jobRepo.addJob(JobType.forwardMessage, {
      'roomId': destinationRoomId,
      'type': forwardedEvent.type.toString(),
      'content': forwardedEvent.content,
      'localId': localId,
      'forwardedFromRoom': originalRoomId,
      'forwardedFromEvent': originalEventId,
    });

    AppLogger.debug(
      'Forward queued',
      data: {
        'localId': localId,
        'destinationRoomId': destinationRoomId,
        'originalEventId': originalEventId,
      },
    );

    return ForwardResult(
      success: true,
      destinationRoomId: destinationRoomId,
      forwardedEvent: forwardedEvent,
    );
  }

  /// Check if a message can be forwarded
  ///
  /// A message can be forwarded if:
  /// - It is not deleted
  /// - It is not restricted
  /// - It is not a pending/failed message
  static bool canForwardMessage(domain.RoomEvent event) {
    // Cannot forward deleted messages
    if (event.isDeleted) return false;

    // Cannot forward restricted messages
    if (event.forwardRestricted) return false;

    // Cannot forward pending or failed messages
    if (event.status == domain.EventStatus.pending ||
        event.status == domain.EventStatus.failed) {
      return false;
    }

    // Cannot forward certain event types
    if (event.type == domain.RoomEventType.reaction ||
        event.type == domain.RoomEventType.callOffer ||
        event.type == domain.RoomEventType.callAnswer ||
        event.type == domain.RoomEventType.callIce ||
        event.type == domain.RoomEventType.callEnd ||
        event.type == domain.RoomEventType.roomKey) {
      return false;
    }

    return true;
  }
}

// Provider
final messageForwardingServiceProvider = Provider<MessageForwardingService>((
  ref,
) {
  final messageRepo = ref.watch(messageRepositoryProvider);
  final jobRepo = ref.watch(pendingJobRepositoryProvider);
  final authContextService = ref.watch(authContextServiceProvider);

  return MessageForwardingService(messageRepo, jobRepo, (String roomId) async {
    // Use AuthContextService for atomic auth state and automatic sync
    return authContextService.requireSubscriptionIdForRoom(roomId);
  });
});
