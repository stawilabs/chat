import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/link_preview_service.dart';
import '../../domain/link_preview.dart';

/// Widget to display a link preview card in messages
///
/// Shows OpenGraph metadata including title, description, and image.
/// Tappable to open the URL in an external browser.
class LinkPreviewCard extends ConsumerWidget {
  const LinkPreviewCard({
    required this.url,
    this.isOwnMessage = false,
    super.key,
  });

  final String url;
  final bool isOwnMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(linkPreviewProvider(url));

    return previewAsync.when(
      data: (preview) {
        if (preview == null) {
          return const SizedBox.shrink();
        }
        return _buildPreviewCard(context, preview);
      },
      loading: () => _buildLoadingState(context),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading preview...',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, LinkPreview preview) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _openUrl(preview.url),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview image
            if (preview.imageUrl != null && preview.imageUrl!.isNotEmpty)
              AspectRatio(
                aspectRatio: 1.91, // Standard OG image ratio
                child: Image.network(
                  preview.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    child: Icon(
                      Icons.link,
                      size: 32,
                      color: isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Site name with favicon
                  Row(
                    children: [
                      if (preview.favicon != null &&
                          preview.favicon!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.network(
                            preview.favicon!,
                            width: 14,
                            height: 14,
                            errorBuilder: (context, error, stack) => Icon(
                              Icons.language,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          preview.siteName ?? _getDomain(preview.url),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    preview.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Description
                  if (preview.description != null &&
                      preview.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      preview.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDomain(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return url;
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Inline link preview that shows for a specific URL
///
/// Accepts a pre-extracted URL to avoid duplicate URL parsing.
class InlineMessageLinkPreview extends ConsumerWidget {
  const InlineMessageLinkPreview({
    required this.url,
    this.isOwnMessage = false,
    super.key,
  });

  final String url;
  final bool isOwnMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LinkPreviewCard(url: url, isOwnMessage: isOwnMessage);
  }
}
