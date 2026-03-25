import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../features/messages/data/upload_progress_provider.dart';
import '../../features/messages/domain/room_event.dart';
import '../../features/messages/domain/upload_progress.dart';
import '../../features/messages/ui/widgets/upload_progress_indicator.dart';
import 'resolved_media_image.dart';

/// Image message content with upload progress and resolved media.
class MessageContentImage extends ConsumerWidget {
  const MessageContentImage({
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
    final url = message.content['url'] as String?;
    final localPath = message.content['localPath'] as String?;
    final caption = message.content['caption'] as String?;
    final isUploading = message.content['uploading'] == true;
    final localId = message.localId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final uploadProgress = localId != null
        ? ref.watch(singleUploadProgressProvider(localId))
        : null;
    final hasActiveUpload =
        uploadProgress != null &&
        (uploadProgress.isInProgress ||
            uploadProgress.state == UploadState.pending);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
            child: (isUploading || hasActiveUpload) && localPath != null
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.file(
                        File(localPath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _buildMediaPlaceholder(Icons.image),
                      ),
                      if (localId != null && uploadProgress != null)
                        UploadProgressIndicator(
                          localId: localId,
                          size: 56,
                          onCancel: onCancelUpload != null
                              ? () => onCancelUpload!(localId)
                              : null,
                          onRetry: onRetryUpload != null
                              ? () => onRetryUpload!(localId)
                              : null,
                        )
                      else
                        Container(
                          color: Colors.black45,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                    ],
                  )
                : ResolvedMediaImage(
                    content: message.content,
                    url: url,
                    localPath: localPath,
                    placeholderIcon: Icons.image,
                    errorIcon: Icons.broken_image,
                  ),
          ),
        ),
        if (localId != null && hasActiveUpload) ...[
          const SizedBox(height: 4),
          UploadProgressBar(
            localId: localId,
            height: 3,
            onCancel: onCancelUpload != null
                ? () => onCancelUpload!(localId)
                : null,
            onRetry: onRetryUpload != null
                ? () => onRetryUpload!(localId)
                : null,
          ),
        ],
        if (caption != null && caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            caption,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getBubbleTextColor(isMe, isDark),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaPlaceholder(IconData icon) => Container(
    width: 150,
    height: 100,
    color: Colors.grey.shade300,
    child: Icon(icon, size: 40, color: Colors.grey.shade600),
  );
}
