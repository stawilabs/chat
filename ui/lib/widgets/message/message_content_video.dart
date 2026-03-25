import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../features/messages/data/upload_progress_provider.dart';
import '../../features/messages/domain/room_event.dart';
import '../../features/messages/domain/upload_progress.dart';
import '../../features/messages/ui/widgets/upload_progress_indicator.dart';
import 'resolved_media_image.dart';

/// Video message content with thumbnail, play button, and upload progress.
class MessageContentVideo extends ConsumerWidget {
  const MessageContentVideo({
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
    final thumbnailUrl = message.content['thumbnailUrl'] as String?;
    final localThumbnailPath = message.content['localThumbnailPath'] as String?;
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
        GestureDetector(
          onTap: url != null && !isUploading && !hasActiveUpload
              ? () => _openUrl(url)
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (localThumbnailPath != null &&
                      (isUploading || hasActiveUpload))
                    Image.file(
                      File(localThumbnailPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _buildMediaPlaceholder(Icons.videocam),
                    )
                  else
                    ResolvedMediaImage(
                      content: message.content,
                      url: thumbnailUrl,
                      placeholderIcon: Icons.videocam,
                      errorIcon: Icons.videocam,
                      useThumbnail: true,
                    ),
                  if (isUploading || hasActiveUpload)
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
                      )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                ],
              ),
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildMediaPlaceholder(IconData icon) => Container(
    width: 150,
    height: 100,
    color: Colors.grey.shade300,
    child: Icon(icon, size: 40, color: Colors.grey.shade600),
  );
}
