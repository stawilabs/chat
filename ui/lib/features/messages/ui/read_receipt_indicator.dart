import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/room_event.dart';
import 'read_receipt_sheet.dart';

/// WhatsApp-style read receipt indicator for messages
///
/// Shows check marks based on message status:
/// - Clock icon: Pending (waiting to send)
/// - Retry indicator: Pending with retry count > 0
/// - Single grey check: Sent
/// - Double grey check: Delivered
/// - Double blue check: Read (at least one person)
/// - Error icon: Failed (max retries exceeded)
///
/// In group chats, tapping the indicator shows who has read the message.
class ReadReceiptIndicator extends ConsumerWidget {
  const ReadReceiptIndicator({
    required this.event,
    required this.isGroupChat,
    super.key,
    this.size = 16.0,
    this.sentColor,
    this.readColor,
    this.showRetryCount = false,
  });

  final RoomEvent event;
  final bool isGroupChat;
  final double size;
  final Color? sentColor;
  final Color? readColor;
  final bool showRetryCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveSentColor =
        sentColor ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    final effectiveReadColor =
        readColor ?? Theme.of(context).colorScheme.primary;

    Widget indicator;
    switch (event.status) {
      case EventStatus.pending:
        // Show retry count if message has been retried
        if (event.retryCount > 0) {
          indicator = _RetryIndicator(
            size: size,
            retryCount: event.retryCount,
            maxRetries: maxAutoRetries,
          );
        } else {
          // First attempt - show spinner
          indicator = SizedBox(
            width: size,
            height: size,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: effectiveSentColor,
              ),
            ),
          );
        }
      case EventStatus.sent:
        // Single check for sent
        indicator = Icon(Icons.check, size: size, color: effectiveSentColor);
      case EventStatus.delivered:
        // Double check for delivered (grey)
        indicator = _DoubleCheck(size: size, color: effectiveSentColor);
      case EventStatus.read:
        // Double check for read (blue)
        indicator = _DoubleCheck(size: size, color: effectiveReadColor);
      case EventStatus.failed:
        // Error icon for failed
        indicator = Icon(Icons.error_outline, size: size, color: Colors.red);
    }

    // In group chats, make the indicator tappable to show readers
    if (isGroupChat && event.status == EventStatus.read) {
      return GestureDetector(
        onTap: () => _showReadersSheet(context, ref),
        child: indicator,
      );
    }

    return indicator;
  }

  void _showReadersSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) =>
          ReadReceiptSheet(eventId: event.id, roomId: event.roomId),
    );
  }
}

/// Double check mark icon (like WhatsApp's delivered/read indicator)
class _DoubleCheck extends StatelessWidget {
  const _DoubleCheck({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.4,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Icon(Icons.check, size: size, color: color),
          ),
          Positioned(
            left: size * 0.4,
            child: Icon(Icons.check, size: size, color: color),
          ),
        ],
      ),
    );
  }
}

/// Retry indicator showing progress during auto-retry attempts
class _RetryIndicator extends StatelessWidget {
  const _RetryIndicator({
    required this.size,
    required this.retryCount,
    required this.maxRetries,
  });

  final double size;
  final int retryCount;
  final int maxRetries;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Retrying ($retryCount/$maxRetries)',
      child: SizedBox(
        width: size + 4,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress showing retry progress
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: retryCount / maxRetries,
                strokeWidth: 1.5,
                backgroundColor: Colors.orange.shade200,
                color: Colors.orange.shade600,
              ),
            ),
            // Retry icon in center
            Icon(
              Icons.refresh,
              size: size * 0.6,
              color: Colors.orange.shade600,
            ),
          ],
        ),
      ),
    );
  }
}
