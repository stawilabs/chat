import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../calls/services/signaling_service.dart';
import '../messages/data/message_sending_service.dart';
import '../messages/data/read_receipt_repository.dart';
import 'rich_notification_service.dart';

/// Provider for NotificationActionHandler
final notificationActionHandlerProvider = Provider<NotificationActionHandler>(
  NotificationActionHandler.new,
);

/// Service for handling notification actions like reply and mark as read
///
/// This service processes user interactions with notification action buttons
/// and performs the appropriate operations.
class NotificationActionHandler {
  NotificationActionHandler(this._ref);

  final Ref _ref;

  /// Handle a notification action
  ///
  /// [actionId] - The action identifier (reply, mark_as_read, etc.)
  /// [roomId] - The room ID associated with the notification
  /// [payload] - Additional payload data (e.g., reply text)
  Future<void> handleAction({
    required String actionId,
    String? roomId,
    String? payload,
  }) async {
    if (roomId == null) {
      AppLogger.warning(
        'Cannot handle notification action without roomId',
        data: {'actionId': actionId},
      );
      return;
    }

    AppLogger.info(
      'Handling notification action',
      data: {
        'actionId': actionId,
        'roomId': roomId,
        'hasPayload': payload != null,
      },
    );

    try {
      switch (actionId) {
        case NotificationActions.reply:
          await _handleReplyAction(roomId, payload);
        case NotificationActions.markAsRead:
          await _handleMarkAsReadAction(roomId);
        case NotificationActions.answerCall:
          await _handleAnswerCallAction(roomId);
        case NotificationActions.declineCall:
          await _handleDeclineCallAction(roomId);
        default:
          AppLogger.warning(
            'Unknown notification action',
            data: {'actionId': actionId},
          );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to handle notification action',
        error: e,
        stackTrace: stackTrace,
        data: {'actionId': actionId, 'roomId': roomId},
      );
    }
  }

  /// Handle reply action - send a text message to the room
  Future<void> _handleReplyAction(String roomId, String? replyText) async {
    if (replyText == null || replyText.trim().isEmpty) {
      AppLogger.debug('Reply action with empty text, ignoring');
      return;
    }

    final trimmedText = replyText.trim();

    AppLogger.info(
      'Sending reply from notification',
      data: {'roomId': roomId, 'textLength': trimmedText.length},
    );

    try {
      final messageSendingService = _ref.read(messageSendingServiceProvider);
      await messageSendingService.sendTextMessage(
        roomId: roomId,
        text: trimmedText,
      );

      // Cancel the notification after successful reply
      final richNotificationService = _ref.read(
        richNotificationServiceProvider,
      );
      await richNotificationService.cancelNotification(roomId);

      AppLogger.info('Reply sent successfully from notification');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to send reply from notification',
        error: e,
        stackTrace: stackTrace,
      );
      // Re-throw to allow caller to handle the error
      rethrow;
    }
  }

  /// Handle mark as read action - mark all messages in room as read
  Future<void> _handleMarkAsReadAction(String roomId) async {
    AppLogger.info(
      'Marking room as read from notification',
      data: {'roomId': roomId},
    );

    try {
      final readReceiptRepository = _ref.read(readReceiptRepositoryProvider);
      await readReceiptRepository.markRoomAsRead(roomId);

      // Cancel the notification after marking as read
      final richNotificationService = _ref.read(
        richNotificationServiceProvider,
      );
      await richNotificationService.cancelNotification(roomId);

      AppLogger.info('Room marked as read from notification');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to mark room as read from notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle answer call action
  Future<void> _handleAnswerCallAction(String roomId) async {
    AppLogger.info(
      'Answering call from notification',
      data: {'roomId': roomId},
    );

    // Cancel the notification
    final richNotificationService = _ref.read(richNotificationServiceProvider);
    await richNotificationService.cancelNotification(roomId);

    // The actual call answering will be handled by navigation to the call screen
    // This is typically done via a deep link or direct navigation
  }

  /// Handle decline call action
  Future<void> _handleDeclineCallAction(String roomId) async {
    AppLogger.info(
      'Declining call from notification',
      data: {'roomId': roomId},
    );

    // Cancel the notification
    final richNotificationService = _ref.read(richNotificationServiceProvider);
    await richNotificationService.cancelNotification(roomId);

    // Send call decline signal to backend
    try {
      final signalingService = await _ref.read(signalingServiceProvider.future);
      await signalingService.sendHangup(roomId);
      AppLogger.info('Call decline signal sent', data: {'roomId': roomId});
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to send call decline signal',
        error: e,
        stackTrace: stackTrace,
        data: {'roomId': roomId},
      );
    }
  }
}
