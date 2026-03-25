import 'package:flutter/material.dart';

/// Loading skeleton for list items
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.height = 20,
    this.width = double.infinity,
    this.borderRadius,
  });
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
          gradient: LinearGradient(
            begin: Alignment(_animation.value - 1, 0),
            end: Alignment(_animation.value, 0),
            colors: [
              theme.colorScheme.surfaceContainerHighest,
              theme.colorScheme.surfaceContainerHigh,
              theme.colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for room list item
class RoomListSkeleton extends StatelessWidget {
  const RoomListSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        // Avatar skeleton
        const SkeletonLoader(
          width: 48,
          height: 48,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        const SizedBox(width: 12),
        // Content skeleton
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(
                width: MediaQuery.of(context).size.width * 0.4,
                height: 16,
              ),
              const SizedBox(height: 8),
              SkeletonLoader(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 14,
              ),
            ],
          ),
        ),
        // Timestamp skeleton
        const SkeletonLoader(width: 40, height: 12),
      ],
    ),
  );
}

/// Skeleton for message bubble
class MessageSkeleton extends StatelessWidget {
  const MessageSkeleton({super.key, this.isMe = false});
  final bool isMe;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe) ...[
          const SkeletonLoader(
            width: 32,
            height: 32,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          const SizedBox(width: 8),
        ],
        SkeletonLoader(
          width: MediaQuery.of(context).size.width * 0.6,
          height: 60,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
      ],
    ),
  );
}
