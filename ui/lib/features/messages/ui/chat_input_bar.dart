import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/media/compression_options_widget.dart';
import '../../../core/media/media_compression_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../messages/domain/room_event.dart' as domain;
import '../data/chat_input_providers.dart';
import '../data/draft_repository.dart';
import '../data/message_providers.dart';
import '../data/message_sending_service.dart';
import '../services/voice_recording_service.dart';
import 'widgets/voice_record_button.dart';

/// WhatsApp-style chat input bar with proper Riverpod/state separation
class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({required this.roomId, required this.roomName, super.key});
  final String roomId;
  final String roomName;

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  // Local UI state only
  bool _hasText = false;

  // Voice recording state
  VoiceRecordingState _voiceRecordingState = VoiceRecordingState.idle;

  // Draft persistence
  Timer? _draftSaveTimer;
  bool _draftLoaded = false;
  static const _draftSaveDebounce = Duration(milliseconds: 500);

  // Store draft repository reference for use in dispose()
  DraftRepository? _draftRepository;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    // Local listener only - no Riverpod calls
    _controller.addListener(_onTextChanged);

    // Load existing draft
    _loadDraft();
  }

  @override
  void dispose() {
    // Cancel all timers first to prevent any pending callbacks
    _draftSaveTimer?.cancel();
    // Remove listener before disposing controller to prevent callbacks
    _controller.removeListener(_onTextChanged);
    // Save any pending draft content synchronously
    _draftRepository?.saveDraft(
      roomId: widget.roomId,
      content: _controller.text,
    );
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Load any existing draft for this room
  Future<void> _loadDraft() async {
    _draftRepository = ref.read(draftRepositoryProvider);
    final draft = await _draftRepository!.getDraft(widget.roomId);
    if (draft != null && mounted) {
      _controller.text = draft.content;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: draft.content.length),
      );
      setState(() {
        _hasText = draft.content.trim().isNotEmpty;
        _draftLoaded = true;
      });
    } else {
      setState(() => _draftLoaded = true);
    }
  }

  /// Save draft with debouncing to avoid excessive writes
  void _scheduleDraftSave() {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(_draftSaveDebounce, _saveDraftImmediately);
  }

  /// Save draft immediately without debouncing
  void _saveDraftImmediately() {
    _draftSaveTimer?.cancel();
    // Use stored reference to avoid calling ref.read() in dispose()
    _draftRepository?.saveDraft(
      roomId: widget.roomId,
      content: _controller.text,
    );
  }

  /// Clear draft when message is sent
  Future<void> _clearDraft() async {
    _draftSaveTimer?.cancel();
    // Use stored reference for consistency
    await _draftRepository?.deleteDraft(widget.roomId);
  }

  // Local state change only
  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText && mounted) {
      setState(() => _hasText = hasText);
    }

    // Schedule draft save when text changes (only after initial load and if still mounted)
    if (_draftLoaded && mounted) {
      _scheduleDraftSave();
    }
  }

  // Riverpod-driven emoji toggle
  void _toggleEmoji() {
    final isOpen = ref.read(emojiPanelVisibilityProvider);

    if (isOpen) {
      ref.read(emojiPanelVisibilityProvider.notifier).hide();
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      ref.read(emojiPanelVisibilityProvider.notifier).show();
    }
  }

  // Riverpod-driven send with proper UI ordering
  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Clear UI instantly for perceived speed
    _controller.clear();
    setState(() => _hasText = false);

    // Clear draft on send
    await _clearDraft();

    // Network happens async via Riverpod
    await _sendMessage(ref, text, 'text', '');
  }

  // Voice recording callbacks
  void _onVoiceRecordingStart() {
    setState(() => _voiceRecordingState = VoiceRecordingState.recording);
    ref.read(typingProvider.notifier).onTyping();
  }

  void _onVoiceRecordingCancel() {
    setState(() => _voiceRecordingState = VoiceRecordingState.idle);
  }

  Future<void> _onVoiceRecordingComplete(VoiceRecordingResult result) async {
    setState(() => _voiceRecordingState = VoiceRecordingState.idle);

    // Send the voice message
    try {
      final sendingService = ref.read(messageSendingServiceProvider);
      await sendingService.sendAudioMessage(
        roomId: widget.roomId,
        audioFile: File(result.path),
        durationMs: result.duration.inMilliseconds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice message sent (${result.formattedDuration})'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send voice message: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Check if we are currently in voice recording mode
  bool get _isVoiceRecordingActive =>
      _voiceRecordingState != VoiceRecordingState.idle;

  // Helper method to send messages through provider
  Future<void> _sendMessage(
    WidgetRef ref,
    String filePath,
    String messageType,
    String fileName,
  ) async {
    final message = domain.RoomEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: widget.roomId,
      senderId: '', // Will be set by provider
      type: messageType == 'image'
          ? domain.RoomEventType.image
          : domain.RoomEventType.file,
      content: {'path': filePath, 'fileName': fileName},
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    // Send via existing message infrastructure
    final messageRepo = ref.read(messageRepositoryProvider);

    // Optimistic update
    await messageRepo.insertMessage(message);

    // Network send (simplified for example)
    try {
      // Actual network send logic here
      await messageRepo.updateMessageStatus(
        message.id,
        domain.EventStatus.sent,
      );
    } catch (e) {
      await messageRepo.updateMessageStatus(
        message.id,
        domain.EventStatus.failed,
      );
    }
  }

  // Camera functionality
  Future<void> _captureFromCamera() async {
    final picker = ImagePicker();
    // Pick without compression - we'll handle compression ourselves
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image != null && mounted) {
      final file = File(image.path);
      await _showCompressionOptionsAndSend(file: file, isVideo: false);
    }
  }

  // Gallery functionality
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    // Pick without compression - we'll handle compression ourselves
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && mounted) {
      final file = File(image.path);
      await _showCompressionOptionsAndSend(file: file, isVideo: false);
    }
  }

  // Video from gallery
  Future<void> _pickVideoFromGallery() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null && mounted) {
      final file = File(video.path);
      await _showCompressionOptionsAndSend(file: file, isVideo: true);
    }
  }

  // Show compression options and send media
  Future<void> _showCompressionOptionsAndSend({
    required File file,
    required bool isVideo,
  }) async {
    await showCompressionOptionsSheet(
      context: context,
      file: file,
      isVideo: isVideo,
      onConfirm:
          ({
            required bool keepOriginal,
            int? imageQuality,
            CompressionQualityPreset? videoQuality,
          }) async {
            // Show a progress indicator
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        keepOriginal
                            ? 'Sending ${isVideo ? "video" : "image"}...'
                            : 'Compressing and sending...',
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 30),
                ),
              );
            }

            try {
              final sendingService = ref.read(messageSendingServiceProvider);

              if (isVideo) {
                await sendingService.sendVideoMessage(
                  roomId: widget.roomId,
                  videoFile: file,
                  keepOriginal: keepOriginal,
                  videoQuality: videoQuality,
                  onCompressionProgress: (progress) {
                    if (mounted && !keepOriginal) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: progress.progress,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(progress.stage)),
                            ],
                          ),
                          duration: const Duration(seconds: 30),
                        ),
                      );
                    }
                  },
                );
              } else {
                await sendingService.sendImageMessage(
                  roomId: widget.roomId,
                  imageFile: file,
                  keepOriginal: keepOriginal,
                  imageQuality: imageQuality,
                  onCompressionProgress: (progress) {
                    if (mounted && !keepOriginal) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: progress.progress,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(progress.stage)),
                            ],
                          ),
                          duration: const Duration(seconds: 30),
                        ),
                      );
                    }
                  },
                );
              }

              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${isVideo ? "Video" : "Image"} sent!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to send: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          },
    );
  }

  // Document functionality
  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      // Process and send selected document
      await _sendMessage(ref, file.path!, 'file', file.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document sent: ${file.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.standardMargin),
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () async {
                      Navigator.pop(context);
                      await _captureFromCamera();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickFromGallery();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.videocam,
                    label: 'Video',
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickVideoFromGallery();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.description,
                    label: 'Document',
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickDocument();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.standardMargin),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.getSubtleColor(context, AppTheme.primaryGreen),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.metadataText.copyWith(
              color: AppTheme.getTextColor(context),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // If voice recording is active, show the voice recording UI
    if (_isVoiceRecordingActive) {
      return _buildVoiceRecordingBar();
    }

    return _buildNormalInputBar();
  }

  /// Build the normal text input bar
  Widget _buildNormalInputBar() => ProviderScope(
    child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Emoji button (Riverpod-driven)
              IconButton(
                icon: Icon(
                  ref.watch(emojiPanelVisibilityProvider)
                      ? Icons.keyboard
                      : Icons.emoji_emotions_outlined,
                ),
                onPressed: _toggleEmoji,
                tooltip: 'Emoji',
                style: IconButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                ),
              ),

              const SizedBox(width: AppTheme.elementGap),

              // Attachment button
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _showAttachmentOptions,
                tooltip: 'Attachment',
                style: IconButton.styleFrom(
                  foregroundColor: AppTheme.getTextColor(context),
                ),
              ),

              const SizedBox(width: AppTheme.elementGap),

              // Text field (local state only)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.getChatBackground(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _focusNode.hasFocus
                          ? AppTheme.primaryGreen.withValues(alpha: 0.5)
                          : Colors.transparent,
                      width: _focusNode.hasFocus ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.getTextColor(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Message',
                      hintStyle: AppTheme.bodyText.copyWith(
                        color: AppTheme.getTextColor(
                          context,
                        ).withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    // No onChanged that touches providers
                  ),
                ),
              ),

              const SizedBox(width: AppTheme.elementGap),

              // Camera button (only show when no text)
              if (!_hasText)
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _captureFromCamera,
                  tooltip: 'Camera',
                  style: IconButton.styleFrom(
                    foregroundColor: AppTheme.getTextColor(context),
                  ),
                ),

              // Send button when text is present, VoiceRecordButton otherwise
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _hasText
                    ? IconButton(
                        key: const ValueKey('send'),
                        icon: const Icon(Icons.send),
                        onPressed: _send,
                        tooltip: 'Send',
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                      )
                    : VoiceRecordButton(
                        key: const ValueKey('voice'),
                        onRecordingComplete: _onVoiceRecordingComplete,
                        onRecordingStart: _onVoiceRecordingStart,
                        onRecordingCancel: _onVoiceRecordingCancel,
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  /// Build the voice recording bar (full width for recording UI)
  Widget _buildVoiceRecordingBar() => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.standardMargin,
            vertical: AppTheme.elementGap,
          ),
          child: VoiceRecordButton(
            onRecordingComplete: _onVoiceRecordingComplete,
            onRecordingStart: _onVoiceRecordingStart,
            onRecordingCancel: _onVoiceRecordingCancel,
          ),
        ),
      ),
    ),
  );
}
