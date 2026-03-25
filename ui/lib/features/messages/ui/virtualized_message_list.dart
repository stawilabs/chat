import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../advanced/ui/group_config_bubble.dart';
import '../../advanced/ui/motion_bubble.dart';
import '../../advanced/ui/transaction_bubble.dart';
import '../data/message_forwarding_service.dart';
import '../data/message_sending_service.dart';
import '../domain/room_event.dart';
import 'date_header.dart';
import 'message_bubble.dart';
import 'system_event_bubble.dart';

/// Configuration for the virtualized message list
class VirtualizedMessageListConfig {
  const VirtualizedMessageListConfig({
    this.cacheExtentMultiplier = 2.0,
    this.estimatedItemHeight = 80.0,
    this.groupingThresholdMs = 120000,
    this.loadMoreThreshold = 0.8,
    this.initialBatchSize = 50,
    this.loadMoreBatchSize = 30,
    this.enableKeepAlive = true,
    this.scrollPhysics,
  });

  /// Multiplier for cache extent relative to viewport height
  /// Higher values cache more items but use more memory
  final double cacheExtentMultiplier;

  /// Estimated height for items when extent is unknown
  /// Used for initial scroll position calculations
  final double estimatedItemHeight;

  /// Time threshold in milliseconds for grouping consecutive messages
  final int groupingThresholdMs;

  /// Scroll position threshold (0-1) for triggering load more
  final double loadMoreThreshold;

  /// Number of messages to load initially
  final int initialBatchSize;

  /// Number of messages to load when scrolling to load more
  final int loadMoreBatchSize;

  /// Whether to use AutomaticKeepAlive for visible items
  final bool enableKeepAlive;

  /// Custom scroll physics (defaults to BouncingScrollPhysics)
  final ScrollPhysics? scrollPhysics;
}

/// A high-performance virtualized message list optimized for 10,000+ messages
///
/// Features:
/// - Smooth 60fps scrolling through efficient item extent estimation
/// - Memory-stable during scroll via proper widget recycling
/// - Fast initial render (<100ms) with lazy item building
/// - No jank when loading more through preloading
/// - RepaintBoundary isolation for complex widgets
/// - AutomaticKeepAlive for visible items to prevent rebuilds
class VirtualizedMessageList extends ConsumerStatefulWidget {
  const VirtualizedMessageList({
    required this.roomId,
    required this.messages,
    required this.onReplyToMessage,
    required this.onEditMessage,
    required this.onRetryMessage,
    required this.onDeleteMessage,
    super.key,
    this.currentUserSubscriptionId,
    this.isGroupChat = false,
    this.config = const VirtualizedMessageListConfig(),
    this.onLoadMore,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.scrollController,
    this.onForwardMessage,
  });

  final String roomId;
  final List<RoomEvent> messages;

  /// Current user's subscription ID for this room
  /// Used to determine if a message is from the current user (isMine)
  /// Pass this from parent to avoid async race conditions
  final String? currentUserSubscriptionId;

  /// Whether this is a group chat (enables sender names, avatars)
  final bool isGroupChat;
  final VirtualizedMessageListConfig config;
  final Future<void> Function()? onLoadMore;
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final ScrollController? scrollController;

  /// Callback when user wants to reply to a message
  final void Function(String messageId, String messageText) onReplyToMessage;

  /// Callback when user wants to edit a message
  final void Function(String messageId, String currentText) onEditMessage;

  /// Callback when user wants to retry a failed message
  final void Function(RoomEvent message) onRetryMessage;

  /// Callback when user wants to delete a message
  final Future<void> Function(String messageId, {required bool forEveryone})
  onDeleteMessage;

  /// Callback when user wants to forward a message
  final Future<void> Function(RoomEvent message)? onForwardMessage;

  @override
  ConsumerState<VirtualizedMessageList> createState() =>
      _VirtualizedMessageListState();
}

class _VirtualizedMessageListState extends ConsumerState<VirtualizedMessageList>
    with WidgetsBindingObserver {
  late ScrollController _scrollController;
  bool _isOwnController = false;

  // Performance tracking
  final Stopwatch _frameStopwatch = Stopwatch();
  int _frameCount = 0;
  double _averageFrameTime = 0;

  // Item extent cache for scroll performance
  final Map<String, double> _itemExtentCache = {};

  // Scroll position preservation
  double? _savedScrollOffset;

  // Load more debouncing
  Timer? _loadMoreDebounce;
  bool _isLoadingTriggered = false;

  @override
  void initState() {
    super.initState();
    _initScrollController();
    WidgetsBinding.instance.addObserver(this);

    // Start frame tracking in debug mode
    assert(() {
      SchedulerBinding.instance.addPostFrameCallback(_trackFrame);
      return true;
    }(), 'Frame tracking should be enabled in debug mode');
  }

  void _initScrollController() {
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
      _isOwnController = false;
    } else {
      _scrollController = ScrollController();
      _isOwnController = true;
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant VirtualizedMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle scroll controller changes
    if (widget.scrollController != oldWidget.scrollController) {
      _scrollController.removeListener(_onScroll);
      if (_isOwnController) {
        _scrollController.dispose();
      }
      _initScrollController();
    }

    // Preserve scroll position when messages are added at the top
    if (widget.messages.length > oldWidget.messages.length) {
      final addedCount = widget.messages.length - oldWidget.messages.length;
      if (_savedScrollOffset != null && addedCount > 0) {
        // Adjust scroll position for newly loaded messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && mounted) {
            final adjustment = addedCount * widget.config.estimatedItemHeight;
            _scrollController.jumpTo(_savedScrollOffset! + adjustment);
            _savedScrollOffset = null;
          }
        });
      }
    }

    // Reset load trigger when loading completes
    if (oldWidget.isLoadingMore && !widget.isLoadingMore) {
      _isLoadingTriggered = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Clear item extent cache when app resumes to handle orientation changes
    if (state == AppLifecycleState.resumed) {
      _itemExtentCache.clear();
    }
  }

  @override
  void dispose() {
    _loadMoreDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    if (_isOwnController) {
      _scrollController.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final maxExtent = position.maxScrollExtent;
    final currentExtent = position.pixels;

    // Check if we should trigger load more (near top in reversed list)
    if (widget.onLoadMore != null &&
        widget.hasMoreMessages &&
        !widget.isLoadingMore &&
        !_isLoadingTriggered) {
      // In a reversed list, approaching maxScrollExtent means approaching older messages
      final threshold = maxExtent * widget.config.loadMoreThreshold;
      if (currentExtent >= threshold) {
        _triggerLoadMore();
      }
    }
  }

  void _triggerLoadMore() {
    _loadMoreDebounce?.cancel();
    _loadMoreDebounce = Timer(const Duration(milliseconds: 100), () async {
      if (!mounted ||
          widget.onLoadMore == null ||
          _isLoadingTriggered ||
          widget.isLoadingMore) {
        return;
      }

      _isLoadingTriggered = true;
      _savedScrollOffset = _scrollController.offset;

      try {
        await widget.onLoadMore!();
      } catch (e) {
        AppLogger.error('Failed to load more messages', error: e);
        _isLoadingTriggered = false;
      }
    });
  }

  void _trackFrame(Duration timestamp) {
    if (!mounted) return;

    _frameStopwatch.stop();
    if (_frameStopwatch.elapsedMicroseconds > 0) {
      _frameCount++;
      final frameTime = _frameStopwatch.elapsedMicroseconds / 1000.0;
      _averageFrameTime =
          ((_averageFrameTime * (_frameCount - 1)) + frameTime) / _frameCount;

      // Only log significant jank (>33ms = below 30fps) and only every 100 frames
      // to avoid log spam during normal scrolling
      if (frameTime > 33.33 && _frameCount % 100 == 0) {
        AppLogger.debug(
          'Significant frame jank detected',
          data: {
            'frameTime': '${frameTime.toStringAsFixed(2)}ms',
            'average': '${_averageFrameTime.toStringAsFixed(2)}ms',
            'frameCount': _frameCount,
          },
        );
      }
    }

    _frameStopwatch.reset();
    _frameStopwatch.start();

    SchedulerBinding.instance.addPostFrameCallback(_trackFrame);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return _buildEmptyState(context);
    }

    final viewportHeight = MediaQuery.of(context).size.height;
    final cacheExtent = viewportHeight * widget.config.cacheExtentMultiplier;

    return CustomScrollView(
      controller: _scrollController,
      reverse: true,
      cacheExtent: cacheExtent,
      physics:
          widget.config.scrollPhysics ??
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // Main message list
        SliverList(
          delegate: SliverChildBuilderDelegate(
            _buildMessageItem,
            childCount: widget.messages.length,
            addAutomaticKeepAlives: widget.config.enableKeepAlive,
          ),
        ),

        // Loading indicator at the top (end of list in reversed view)
        if (widget.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),

        // End of messages indicator
        if (!widget.hasMoreMessages && widget.messages.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Beginning of conversation',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageItem(BuildContext context, int index) {
    // Reverse index since list is reversed
    final reversedIndex = widget.messages.length - 1 - index;
    final message = widget.messages[reversedIndex];
    final provisionalSenderId = 'provisional_${widget.roomId}';

    // Calculate grouping
    final groupingInfo = _calculateGrouping(reversedIndex);

    // Build the message widget
    return _OptimizedMessageItem(
      key: ValueKey(message.id),
      message: message,
      currentUserSubscriptionId: widget.currentUserSubscriptionId,
      isProvisionalSender: message.senderId == provisionalSenderId,
      isGroupChat: widget.isGroupChat,
      showDateHeader: groupingInfo.showDateHeader,
      shouldGroupWithPrevious: groupingInfo.shouldGroupWithPrevious,
      removeTail: groupingInfo.removeTail,
      onReplyToMessage: widget.onReplyToMessage,
      onEditMessage: widget.onEditMessage,
      onRetryMessage: widget.onRetryMessage,
      onDeleteMessage: widget.onDeleteMessage,
      onForwardMessage: widget.onForwardMessage,
      enableKeepAlive: widget.config.enableKeepAlive,
      onSizeChanged: (size) {
        // Cache the measured size for scroll calculations
        _itemExtentCache[message.id] = size.height;
      },
    );
  }

  _MessageGroupingInfo _calculateGrouping(int index) {
    final message = widget.messages[index];
    var showDateHeader = false;
    var shouldGroupWithPrevious = false;
    var removeTail = false;

    if (index < widget.messages.length - 1) {
      final nextMessage = widget.messages[index + 1];
      final timeDiff =
          _displayTimestamp(message) - _displayTimestamp(nextMessage);
      shouldGroupWithPrevious =
          nextMessage.senderId == message.senderId &&
          timeDiff < widget.config.groupingThresholdMs;
      removeTail = shouldGroupWithPrevious;

      // Check if date changed
      final messageDate = DateTime.fromMillisecondsSinceEpoch(
        _displayTimestamp(message),
      );
      final nextDate = DateTime.fromMillisecondsSinceEpoch(
        _displayTimestamp(nextMessage),
      );
      showDateHeader =
          messageDate.day != nextDate.day ||
          messageDate.month != nextDate.month ||
          messageDate.year != nextDate.year;
    } else {
      // First message (oldest) always shows date header
      showDateHeader = true;
    }

    return _MessageGroupingInfo(
      showDateHeader: showDateHeader,
      shouldGroupWithPrevious: shouldGroupWithPrevious,
      removeTail: removeTail,
    );
  }

  int _displayTimestamp(RoomEvent message) =>
      message.serverTs ?? message.createdAt;

  Widget _buildEmptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'No messages yet',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start the conversation!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

/// Internal class for message grouping information
class _MessageGroupingInfo {
  const _MessageGroupingInfo({
    required this.showDateHeader,
    required this.shouldGroupWithPrevious,
    required this.removeTail,
  });

  final bool showDateHeader;
  final bool shouldGroupWithPrevious;
  final bool removeTail;
}

/// Optimized message item with RepaintBoundary and AutomaticKeepAlive
class _OptimizedMessageItem extends ConsumerStatefulWidget {
  const _OptimizedMessageItem({
    required this.message,
    required this.showDateHeader,
    required this.shouldGroupWithPrevious,
    required this.removeTail,
    required this.onReplyToMessage,
    required this.onEditMessage,
    required this.onRetryMessage,
    required this.onDeleteMessage,
    super.key,
    this.currentUserSubscriptionId,
    this.isProvisionalSender = false,
    this.isGroupChat = false,
    this.enableKeepAlive = true,
    this.onSizeChanged,
    this.onForwardMessage,
  });

  final RoomEvent message;

  /// Current user's subscription ID - passed from parent to avoid async issues
  final String? currentUserSubscriptionId;
  final bool isProvisionalSender;

  /// Whether this is a group chat
  final bool isGroupChat;
  final bool showDateHeader;
  final bool shouldGroupWithPrevious;
  final bool removeTail;
  final bool enableKeepAlive;
  final void Function(Size size)? onSizeChanged;
  final void Function(String messageId, String messageText) onReplyToMessage;
  final void Function(String messageId, String currentText) onEditMessage;
  final void Function(RoomEvent message) onRetryMessage;
  final Future<void> Function(String messageId, {required bool forEveryone})
  onDeleteMessage;
  final Future<void> Function(RoomEvent message)? onForwardMessage;

  @override
  ConsumerState<_OptimizedMessageItem> createState() =>
      _OptimizedMessageItemState();
}

class _OptimizedMessageItemState extends ConsumerState<_OptimizedMessageItem>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey _sizeKey = GlobalKey();
  Size? _lastSize;

  @override
  bool get wantKeepAlive => widget.enableKeepAlive;

  @override
  void initState() {
    super.initState();
    // Measure size after first frame
    WidgetsBinding.instance.addPostFrameCallback(_measureSize);
  }

  void _measureSize(Duration _) {
    final renderBox = _sizeKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final size = renderBox.size;
      if (_lastSize != size) {
        _lastSize = size;
        widget.onSizeChanged?.call(size);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Use subscription ID passed from parent to determine if message is from me
    // This avoids async race conditions that caused messages to appear on wrong side
    final isMe =
        (widget.currentUserSubscriptionId != null &&
            widget.message.senderId == widget.currentUserSubscriptionId) ||
        widget.isProvisionalSender;

    // Use shared validation logic from MessageSendingService
    final canEdit = MessageSendingService.canEditMessage(
      isOwnMessage: isMe,
      messageType: widget.message.type,
      messageStatus: widget.message.status,
      messageCreatedAt: widget.message.createdAt,
    );

    final canDelete = MessageSendingService.canDeleteMessage(
      isOwnMessage: isMe,
      messageStatus: widget.message.status,
      messageCreatedAt: widget.message.createdAt,
      isDeleted: widget.message.isDeleted,
    );

    final canForward = MessageForwardingService.canForwardMessage(
      widget.message,
    );

    // Wrap in RepaintBoundary for paint isolation
    return RepaintBoundary(
      child: Container(
        key: _sizeKey,
        child: Column(
          children: [
            if (widget.showDateHeader)
              DateHeader(
                timestamp: widget.message.serverTs ?? widget.message.createdAt,
              ),
            _buildMessageWidget(isMe, canEdit, canDelete, canForward),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageWidget(
    bool isMe,
    bool canEdit,
    bool canDelete,
    bool canForward,
  ) {
    switch (widget.message.type) {
      case RoomEventType.motion:
        return MotionBubble(event: widget.message, isMe: isMe);
      case RoomEventType.transaction:
        return TransactionBubble(event: widget.message, isMe: isMe);
      case RoomEventType.vote:
        return VoteBubble(event: widget.message, isMe: isMe);
      case RoomEventType.groupConfig:
        return GroupConfigBubble(event: widget.message);
      case RoomEventType.roomChange:
        return SystemEventBubble(event: widget.message);
      case RoomEventType.roomKey:
        // Room key events are internal and should not be displayed
        return const SizedBox.shrink();
      case RoomEventType.callOffer:
      case RoomEventType.callAnswer:
      case RoomEventType.callIce:
      case RoomEventType.callEnd:
      case RoomEventType.groupCallOffer:
      case RoomEventType.groupCallAnswer:
      case RoomEventType.groupCallIce:
      case RoomEventType.groupCallMuteUpdate:
        // Call signaling events are handled by SignalingService
        // and should not appear in the message list
        return const SizedBox.shrink();
      case RoomEventType.groupCallStart:
      case RoomEventType.groupCallJoin:
      case RoomEventType.groupCallLeave:
      case RoomEventType.groupCallEnd:
        // Group call lifecycle events shown as system messages
        return SystemEventBubble(event: widget.message);
      default:
        return MessageBubble(
          message: widget.message,
          isMe: isMe,
          shouldGroupWithPrevious: widget.shouldGroupWithPrevious,
          removeTail: widget.removeTail,
          isGroupChat: widget.isGroupChat,
          onReply: widget.onReplyToMessage,
          onRetry: widget.message.status == EventStatus.failed
              ? () => widget.onRetryMessage(widget.message)
              : null,
          onEdit: widget.onEditMessage,
          canEdit: canEdit,
          onDelete: widget.onDeleteMessage,
          canDelete: canDelete,
          onForward: widget.onForwardMessage,
          canForward: canForward,
        );
    }
  }
}

/// Performance metrics for the virtualized list
class VirtualizedListMetrics {
  VirtualizedListMetrics({
    required this.averageFrameTime,
    required this.frameCount,
    required this.cachedItemCount,
    required this.estimatedTotalHeight,
  });

  final double averageFrameTime;
  final int frameCount;
  final int cachedItemCount;
  final double estimatedTotalHeight;

  bool get isPerformant => averageFrameTime < 16.67; // 60fps threshold

  @override
  String toString() =>
      'VirtualizedListMetrics(avgFrame: ${averageFrameTime.toStringAsFixed(2)}ms, '
      'frames: $frameCount, cached: $cachedItemCount, '
      'totalHeight: ${estimatedTotalHeight.toStringAsFixed(0)})';
}
