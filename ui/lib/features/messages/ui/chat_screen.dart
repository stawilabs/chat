import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../calls/services/call_manager.dart';
import '../../calls/ui/call_screen.dart';
import '../../notifications/notification_service.dart';
import '../../notifications/ui/notification_permission_dialog.dart';
import '../../rooms/data/room_providers.dart';
import '../../rooms/data/room_subscription_service.dart';
import '../../settings/data/settings_providers.dart';
import '../data/message_providers.dart';
import '../data/message_sending_service.dart';
import '../data/typing_provider.dart';
import '../domain/room_event.dart';
import '../services/voice_recording_service.dart';
import 'edit_message_sheet.dart';
import 'forward_sheet.dart';
import 'input_bar.dart';
import 'virtualized_message_list.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.roomId, required this.roomName, super.key});
  final String roomId;
  final String roomName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _readReceiptDebounce;
  bool _isEncryptionEnabled = false;
  String? _replyingToMessageId;
  String? _replyingToText;
  bool _showScrollToBottom = false;
  int _newMessageCount = 0;
  int _previousMessageCount = 0;

  // Pagination state for virtualized list
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    // Add scroll listener for scroll-to-bottom FAB
    _scrollController.addListener(_onScroll);
    // Preload chat background patterns for better performance
    // Note: _black pattern is dark (for light theme), regular is light (for dark theme)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/chat_pattern.webp'), context);
      precacheImage(
        const AssetImage('assets/chat_pattern_black.webp'),
        context,
      );
      // Check if we need to prompt for notification permission
      _checkNotificationPermission();
    });
  }

  /// Check if notification permission dialog should be shown
  ///
  /// Shows the dialog only if:
  /// 1. Notification permission is not already granted
  /// 2. We haven't prompted the user before (to avoid annoying them)
  Future<void> _checkNotificationPermission() async {
    // Check if notification permission is already granted
    final status = await Permission.notification.status;
    if (status.isGranted) return;

    // Check if we've already prompted the user
    if (!mounted) return;
    final hasPrompted = await ref
        .read(settingsProvider.notifier)
        .hasNotificationPermissionBeenPrompted();
    if (hasPrompted) return;

    // Show the permission dialog
    if (!mounted) return;
    final result = await NotificationPermissionDialog.show(context);

    // Mark as prompted so we don't ask again
    // Re-read notifier fresh since the provider may have been disposed/rebuilt
    // during the dialog
    if (!mounted) return;
    try {
      await ref
          .read(settingsProvider.notifier)
          .markNotificationPermissionPrompted();
    } catch (e) {
      AppLogger.warning('Could not save notification prompt state', error: e);
    }

    // Handle the result
    if (!mounted) return;
    if (result == NotificationPermissionResult.granted) {
      // User granted permission - complete notification service initialization
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initializeAfterPermissionGranted();
    } else if (result == NotificationPermissionResult.openSettings) {
      await openAppSettings();
    }
  }

  void _onScroll() {
    // Show scroll-to-bottom FAB when scrolled up more than 200 pixels
    final showButton = _scrollController.offset > 200;
    if (showButton != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = showButton;
        // Reset new message count when scrolling to bottom
        if (!showButton) {
          _newMessageCount = 0;
        }
      });
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    setState(() {
      _newMessageCount = 0;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _readReceiptDebounce?.cancel();
    super.dispose();
  }

  void _sendReadReceipts(List<RoomEvent> messages) {
    // Cancel previous debounce
    _readReceiptDebounce?.cancel();

    _readReceiptDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        // Get current user's subscription ID for this room
        final currentSubscriptionIdAsync = ref.read(
          currentUserSubscriptionIdProvider(widget.roomId),
        );
        final currentSubscriptionId = currentSubscriptionIdAsync.value ?? '';
        if (currentSubscriptionId.isEmpty) return;

        final unreadIds = messages
            .where(
              (m) =>
                  m.senderId != currentSubscriptionId &&
                  m.status != EventStatus.read,
            )
            .map((m) => m.id)
            .toList();

        if (unreadIds.isNotEmpty) {
          final syncEngine = await ref.read(syncEngineProvider.future);
          await syncEngine.sendReadReceipts(widget.roomId, unreadIds);
        }
      } catch (e) {
        // Silently fail for read receipts - they're not critical
        AppLogger.error('Failed to send read receipts', error: e);
      }
    });
  }

  Future<void> _sendMessage(String text, {String? replyToMessageId}) async {
    if (text.trim().isEmpty) return;

    final messagingService = ref.read(messageSendingServiceProvider);

    // Clear reply state immediately for better UX
    if (replyToMessageId != null) {
      setState(() {
        _replyingToMessageId = null;
        _replyingToText = null;
      });
    }

    try {
      // Send message - the service handles optimistic updates internally
      // by inserting into the local DB which triggers the stream update
      await messagingService.sendTextMessage(
        roomId: widget.roomId,
        text: text.trim(),
        encrypt: _isEncryptionEnabled,
        replyToId: replyToMessageId,
      );

      // Scroll to bottom to see the new message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      AppLogger.error('Failed to send message', error: e);
      if (mounted) {
        final errorMessage = e.toString().contains('SubscriptionNotFound')
            ? 'Message will be sent when online'
            : 'Failed to send message: ${e.toString()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () =>
                  _sendMessage(text, replyToMessageId: replyToMessageId),
            ),
          ),
        );
      }
    }
  }

  void _onReplyToMessage(String messageId, String messageText) {
    setState(() {
      _replyingToMessageId = messageId;
      _replyingToText = messageText;
    });
  }

  void _onEditMessage(String messageId, String currentText) {
    showEditMessageSheet(
      context: context,
      messageId: messageId,
      currentText: currentText,
      onSave: (id, newText) async {
        final messagingService = ref.read(messageSendingServiceProvider);
        return messagingService.editTextMessage(
          messageId: id,
          newText: newText,
        );
      },
    );
  }

  Future<void> _retryMessage(RoomEvent message) async {
    try {
      final messagingService = ref.read(messageSendingServiceProvider);
      await messagingService.retryMessage(message.localId ?? message.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retrying message...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to retry: $e')));
      }
    }
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessageId = null;
      _replyingToText = null;
    });
  }

  Future<void> _pickAndSendImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      await _sendMediaFile(File(image.path), RoomEventType.image);
    }
  }

  Future<void> _takeAndSendPhoto() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null) {
      await _sendMediaFile(File(photo.path), RoomEventType.image);
    }
  }

  Future<void> _pickAndSendVideo() async {
    final video = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (video != null) {
      await _sendMediaFile(File(video.path), RoomEventType.video);
    }
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      await _sendMediaFile(File(result.files.single.path!), RoomEventType.file);
    }
  }

  Future<void> _sendMediaFile(File file, RoomEventType type) async {
    try {
      final messagingService = ref.read(messageSendingServiceProvider);

      switch (type) {
        case RoomEventType.image:
          await messagingService.sendImageMessage(
            roomId: widget.roomId,
            imageFile: file,
            encrypt: _isEncryptionEnabled,
          );
          break;
        case RoomEventType.video:
          await messagingService.sendVideoMessage(
            roomId: widget.roomId,
            videoFile: file,
            encrypt: _isEncryptionEnabled,
          );
          break;
        case RoomEventType.file:
          await messagingService.sendFileMessage(
            roomId: widget.roomId,
            file: file,
            encrypt: _isEncryptionEnabled,
          );
          break;
        default:
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File sent successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send file: $e')));
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takeAndSendPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('File'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sync room members on room entry to ensure subscription is available
    // This runs once per room entry and uses caching to avoid redundant syncs
    ref.watch(syncRoomMembersOnEntryProvider(widget.roomId));

    final messagesAsync = ref.watch(
      paginatedMessagesStreamProvider((
        roomId: widget.roomId,
        limit: _pageSize,
      )),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.chatBackgroundDark
                      : AppTheme.chatBackgroundLight,
                  image: _isEncryptionEnabled
                      ? null
                      : DecorationImage(
                          image: AssetImage(
                            // Use light pattern on dark theme, dark pattern on light theme
                            Theme.of(context).brightness == Brightness.dark
                                ? 'assets/chat_pattern.webp' // Light pattern for dark background
                                : 'assets/chat_pattern_black.webp', // Dark pattern for light background
                          ),
                          repeat: ImageRepeat.repeat,
                          fit: BoxFit.none,
                          opacity:
                              Theme.of(context).brightness == Brightness.dark
                              ? 0.08 // 8% for dark theme (6-10% range)
                              : 0.05, // 5% for light theme
                        ),
                ),
                child: Stack(
                  children: [
                    messagesAsync.when(
                      data: _buildMessageList,
                      loading: _buildLoadingState,
                      error: _buildErrorState,
                    ),
                    // Enhanced typing indicator overlay
                    Consumer(
                      builder: (context, ref, child) {
                        final typingUsers = ref.watch(
                          typingProvider(widget.roomId),
                        );
                        final isAnyoneTyping = typingUsers.isNotEmpty;

                        return isAnyoneTyping
                            ? Positioned(
                                bottom: 80,
                                left: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color?>(
                                                AppTheme.primaryGreen,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Someone is typing...',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                    // Scroll-to-bottom FAB with new message count
                    if (_showScrollToBottom)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: _buildScrollToBottomButton(),
                      ),
                  ],
                ),
              ),
            ),
            InputBar(
              roomId: widget.roomId,
              onSendMessage: _sendMessage,
              onAttachment: _showAttachmentOptions,
              onCamera: _takeAndSendPhoto,
              onVoiceRecordingComplete: _onVoiceRecordingComplete,
              isEncryptionEnabled: _isEncryptionEnabled,
              replyingToMessageId: _replyingToMessageId,
              replyingToText: _replyingToText,
              onCancelReply: _cancelReply,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
    title: GestureDetector(
      onTap: _openContactInfo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryGreen,
                child: Text(
                  widget.roomName.isNotEmpty
                      ? widget.roomName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.roomName,
                      style: AppTheme.bodyText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).appBarTheme.foregroundColor,
                      ),
                    ),
                    Text(
                      'Last seen recently',
                      style: AppTheme.metadataText.copyWith(
                        color: Theme.of(
                          context,
                        ).appBarTheme.foregroundColor?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    backgroundColor: Theme.of(context).colorScheme.surface,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => context.go('/'),
    ),
    actions: [
      IconButton(
        icon: Icon(
          _isEncryptionEnabled ? Icons.lock : Icons.lock_open,
          color: _isEncryptionEnabled ? Colors.green : null,
          size: 20,
        ),
        onPressed: _toggleEncryption,
      ),
      IconButton(
        icon: const Icon(Icons.videocam_outlined),
        onPressed: _startCall,
      ),
      IconButton(icon: const Icon(Icons.phone_outlined), onPressed: _startCall),
    ],
  );

  Widget _buildMessageList(List<RoomEvent> messages) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    // Track new messages arriving while scrolled up
    if (messages.length > _previousMessageCount && _showScrollToBottom) {
      final newCount = messages.length - _previousMessageCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _newMessageCount += newCount);
      });
    }
    _previousMessageCount = messages.length;

    // Send read receipts for messages being viewed
    _sendReadReceipts(messages);

    // Get current user's subscription ID at the list level (not per-message)
    // This ensures consistent "isMine" detection and avoids async race conditions
    final currentSubscriptionIdAsync = ref.watch(
      currentUserSubscriptionIdProvider(widget.roomId),
    );

    // Determine if this is a group chat for sender names/avatars
    final roomAsync = ref.watch(roomByIdProvider(widget.roomId));
    final isGroupChat = roomAsync.when(
      data: (room) => room?.type == 'group',
      loading: () => false,
      error: (_, _) => false,
    );

    // Use the optimized VirtualizedMessageList for better performance
    // with large message lists (10,000+ messages)
    return VirtualizedMessageList(
      roomId: widget.roomId,
      messages: messages,
      currentUserSubscriptionId: currentSubscriptionIdAsync.value,
      isGroupChat: isGroupChat,
      scrollController: _scrollController,
      isLoadingMore: _isLoadingMore,
      hasMoreMessages: _hasMoreMessages,
      onLoadMore: _loadMoreMessages,
      onReplyToMessage: _onReplyToMessage,
      onEditMessage: _onEditMessage,
      onRetryMessage: _retryMessage,
      onDeleteMessage: _onDeleteMessage,
      onForwardMessage: _onForwardMessage,
    );
  }

  /// Load older messages when user scrolls near the top
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;

    setState(() => _isLoadingMore = true);

    try {
      final hasMore = await ref
          .read(messageListProvider(widget.roomId).notifier)
          .loadOlderMessages(widget.roomId);

      if (mounted) {
        setState(() {
          _hasMoreMessages = hasMore;
          if (hasMore) {
            _pageSize += 30;
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load more messages', error: e);
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Widget _buildEmptyState() => Center(
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
          'Start the conversation',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Send a message to begin chatting with ${widget.roomName}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            'Say Hello!',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildLoadingState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Loading messages...',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please wait while we fetch your conversation',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildErrorState(Object error, StackTrace stack) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline, size: 64, color: Colors.red),
        ),
        const SizedBox(height: 24),
        Text(
          'Something went wrong',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unable to load messages. Please try again.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () =>
              ref.invalidate(messagesStreamProvider(widget.roomId)),
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ],
    ),
  );

  void _toggleEncryption() {
    setState(() => _isEncryptionEnabled = !_isEncryptionEnabled);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEncryptionEnabled
              ? 'End-to-end encryption enabled'
              : 'End-to-end encryption disabled',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _startCall() async {
    final callManager = await ref.read(callManagerProvider.future);
    await callManager.startCall(widget.roomId);
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              CallScreen(roomId: widget.roomId, roomName: widget.roomName),
        ),
      );
    }
  }

  void _openContactInfo() {
    // Navigate to room details screen with fluid animation
    context.navigateToRoomDetails(
      roomId: widget.roomId,
      roomName: widget.roomName,
    );
  }

  void _onVoiceRecordingComplete(VoiceRecordingResult result) {
    // Voice recording completed, send as audio message
    _sendAudioMessage(result);
  }

  Future<void> _sendAudioMessage(VoiceRecordingResult recording) async {
    try {
      final messagingService = ref.read(messageSendingServiceProvider);
      await messagingService.sendAudioMessage(
        roomId: widget.roomId,
        audioFile: File(recording.path),
        durationMs: recording.duration.inMilliseconds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Voice message sent (${recording.formattedDuration})',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send voice message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onForwardMessage(RoomEvent message) async {
    final result = await showForwardSheet(
      context: context,
      message: message,
      currentRoomId: widget.roomId,
    );

    if (result != null && result.isNotEmpty && mounted) {
      AppLogger.info(
        'Message forwarded',
        data: {'messageId': message.id, 'forwardedTo': result.length},
      );
    }
  }

  Future<void> _onDeleteMessage(
    String messageId, {
    required bool forEveryone,
  }) async {
    final messagingService = ref.read(messageSendingServiceProvider);

    try {
      if (forEveryone) {
        // Delete for everyone (marks as redacted on server)
        final success = await messagingService.deleteMessage(
          messageId: messageId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Message deleted for everyone'
                    : 'Cannot delete this message',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Delete for me only (local deletion)
        await messagingService.deleteMessageForMe(messageId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message deleted for you'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildScrollToBottomButton() => GestureDetector(
    onTap: _scrollToBottom,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.onSurface,
            size: 28,
          ),
          if (_newMessageCount > 0)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  _newMessageCount > 99 ? '99+' : '$_newMessageCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
