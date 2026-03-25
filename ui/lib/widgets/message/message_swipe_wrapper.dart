import 'package:flutter/material.dart';

/// Swipe-to-reply Dismissible gesture wrapper for message bubbles.
class MessageSwipeWrapper extends StatelessWidget {
  const MessageSwipeWrapper({
    required this.messageId,
    required this.child,
    super.key,
    this.onSwipeReply,
  });

  final String messageId;
  final Widget child;
  final VoidCallback? onSwipeReply;

  @override
  Widget build(BuildContext context) {
    if (onSwipeReply == null) return child;

    return Dismissible(
      key: ValueKey('swipe_$messageId'),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.3},
      confirmDismiss: (direction) async {
        onSwipeReply?.call();
        return false; // Never actually dismiss
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.reply, color: Colors.blue),
      ),
      child: child,
    );
  }
}
