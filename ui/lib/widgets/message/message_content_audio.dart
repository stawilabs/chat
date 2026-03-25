import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/messages/data/upload_progress_provider.dart';
import '../../features/messages/domain/room_event.dart';
import '../../features/messages/domain/upload_progress.dart';
import '../../features/messages/ui/widgets/upload_progress_indicator.dart';
import '../../features/messages/ui/widgets/voice_message_player.dart';

/// Audio/voice message content that delegates to VoiceMessagePlayer.
class MessageContentAudio extends ConsumerWidget {
  const MessageContentAudio({
    required this.message,
    required this.isMe,
    super.key,
    this.onCancelUpload,
    this.onRetryUpload,
  });

  final RoomEvent message;
  final bool isMe;
  final Function(String localId)? onCancelUpload;
  final Function(String localId)? onRetryUpload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = message.content['url'] as String? ?? '';
    final localPath = message.content['localPath'] as String?;
    final duration = message.content['duration'] as int? ?? 0;
    final isUploading = message.content['uploading'] == true;
    final localId = message.localId;

    final uploadProgress = localId != null
        ? ref.watch(singleUploadProgressProvider(localId))
        : null;
    final hasActiveUpload =
        uploadProgress != null &&
        (uploadProgress.isInProgress ||
            uploadProgress.state == UploadState.pending);

    if (isUploading || hasActiveUpload) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (localId != null && uploadProgress != null)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: UploadProgressIndicator(
                    localId: localId,
                    size: 40,
                    showPercentage: false,
                    onCancel: onCancelUpload != null
                        ? () => onCancelUpload!(localId)
                        : null,
                    onRetry: onRetryUpload != null
                        ? () => onRetryUpload!(localId)
                        : null,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uploadProgress?.progressText ??
                          'Sending voice message...',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (localId != null && hasActiveUpload) ...[
            const SizedBox(height: 8),
            UploadProgressBar(localId: localId, height: 3, showText: false),
          ],
        ],
      );
    }

    return VoiceMessagePlayer(
      audioUrl: url,
      localPath: localPath,
      durationMs: duration,
      isOwnMessage: isMe,
    );
  }

  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).round();
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
