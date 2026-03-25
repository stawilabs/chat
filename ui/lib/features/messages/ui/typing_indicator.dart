import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/typing_provider.dart';

class TypingIndicator extends ConsumerWidget {
  const TypingIndicator({required this.roomId, super.key});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingUsers = ref.watch(typingProvider(roomId));

    if (typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildDots(context),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getTypingText(typingUsers),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Format the typing text based on the number of users
  ///
  /// - 1 user: "John is typing..."
  /// - 2 users: "John and Jane are typing..."
  /// - 3 users: "John, Jane, and Bob are typing..."
  /// - 4+ users: "Several people are typing..."
  String _getTypingText(Set<TypingUser> users) {
    final names = users.map((u) => u.displayName).toList();

    if (names.length == 1) {
      return '${names[0]} is typing...';
    } else if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing...';
    } else if (names.length == 3) {
      return '${names[0]}, ${names[1]}, and ${names[2]} are typing...';
    } else {
      return 'Several people are typing...';
    }
  }

  Widget _buildDots(BuildContext context) =>
      SizedBox(width: 24, height: 12, child: _TypingDotsAnimation());
}

class _TypingDotsAnimation extends StatefulWidget {
  @override
  State<_TypingDotsAnimation> createState() => _TypingDotsAnimationState();
}

class _TypingDotsAnimationState extends State<_TypingDotsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(3, (index) {
        final offset = index * 0.2;
        final value = (_controller.value + offset) % 1.0;
        final opacity = (value < 0.5) ? value * 2 : (1.0 - value) * 2;

        return Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.6 + (opacity * 0.4)),
            shape: BoxShape.circle,
          ),
        );
      }),
    ),
  );
}
