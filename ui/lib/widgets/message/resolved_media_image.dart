import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/files/content_resolver.dart';

/// Shared HTTP image resolver widget.
///
/// Resolves images from direct URLs, attachment IDs, or local file paths,
/// with placeholder and error fallbacks.
class ResolvedMediaImage extends ConsumerWidget {
  const ResolvedMediaImage({
    required this.content,
    required this.placeholderIcon,
    required this.errorIcon,
    super.key,
    this.url,
    this.localPath,
    this.useThumbnail = false,
    this.width,
    this.height,
  });

  final Map<String, dynamic> content;
  final String? url;
  final String? localPath;
  final IconData placeholderIcon;
  final IconData errorIcon;
  final bool useThumbnail;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolver = ref.watch(contentResolverProvider);
    final resolvedUrl = url ?? resolver.resolveLegacyUrl(content);

    if (resolvedUrl != null) {
      return Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildPlaceholder(placeholderIcon);
        },
        errorBuilder: (_, _, _) => _buildPlaceholder(errorIcon),
      );
    }

    if (localPath != null) {
      return Image.file(
        File(localPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(placeholderIcon),
      );
    }

    final future = useThumbnail
        ? resolver.resolveVideoThumbnail(content)
        : resolver.resolveImageUrl(
            content,
            width: (width ?? 250).toInt(),
            height: (height ?? 200).toInt(),
          );

    return FutureBuilder<dynamic>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder(placeholderIcon);
        }
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildPlaceholder(errorIcon),
          );
        }
        return _buildPlaceholder(errorIcon);
      },
    );
  }

  Widget _buildPlaceholder(IconData icon) => Container(
    width: width ?? 150,
    height: height ?? 100,
    color: Colors.grey.shade300,
    child: Icon(icon, size: 40, color: Colors.grey.shade600),
  );
}
