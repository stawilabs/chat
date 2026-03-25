import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/files/content_resolver.dart';
import '../../features/messages/data/upload_progress_provider.dart';
import '../../features/messages/domain/room_event.dart';
import '../../features/messages/domain/upload_progress.dart';
import '../../features/messages/ui/widgets/upload_progress_indicator.dart';

/// File message content with icon, name, size, and download/upload handling.
class MessageContentFile extends ConsumerWidget {
  const MessageContentFile({
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
    final fileName = message.content['fileName'] as String? ?? 'File';
    final fileSize = message.content['fileSize'] as int?;
    final url = message.content['url'] as String?;
    final localPath = message.content['localPath'] as String?;
    final isUploading = message.content['uploading'] == true;
    final localId = message.localId;

    final uploadProgress = localId != null
        ? ref.watch(singleUploadProgressProvider(localId))
        : null;
    final hasActiveUpload =
        uploadProgress != null &&
        (uploadProgress.isInProgress ||
            uploadProgress.state == UploadState.pending);

    final canOpen =
        !isUploading && !hasActiveUpload && (url != null || localPath != null);

    return GestureDetector(
      onTap: canOpen
          ? () => _downloadAndOpenFile(context, ref, message.content, fileName)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((isUploading || hasActiveUpload) &&
                  localId != null &&
                  uploadProgress != null)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: UploadProgressIndicator(
                    localId: localId,
                    size: 44,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.insert_drive_file,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (fileSize != null)
                      Builder(
                        builder: (context) {
                          final uploadedBytes =
                              uploadProgress?.uploadedBytes ?? 0;
                          return Text(
                            hasActiveUpload
                                ? '${_formatFileSize(uploadedBytes)} / ${_formatFileSize(fileSize)}'
                                : _formatFileSize(fileSize),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (localId != null && hasActiveUpload) ...[
            const SizedBox(height: 8),
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
        ],
      ),
    );
  }

  Future<void> _downloadAndOpenFile(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> content,
    String fileName,
  ) async {
    final localPath = content['localPath'] as String?;
    if (localPath != null) {
      final localFile = File(localPath);
      if (localFile.existsSync()) {
        final uri = Uri.file(localPath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return;
      }
    }

    final tempDir = await getTemporaryDirectory();
    final downloadDir = Directory('${tempDir.path}/chat_downloads');
    if (!downloadDir.existsSync()) {
      await downloadDir.create(recursive: true);
    }
    final destPath = '${downloadDir.path}/$fileName';

    final resolver = ref.read(contentResolverProvider);
    final file = await resolver.resolveFileDownload(content, destPath);
    if (file != null) {
      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final url = content['url'] as String?;
    if (url != null && url.startsWith('http')) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
