import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/files/content_resolver.dart';

/// Shared HTTP image resolver widget.
///
/// Resolves images from direct URLs, attachment IDs, or local file paths,
/// with placeholder and error fallbacks.
class ResolvedMediaImage extends ConsumerStatefulWidget {
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
  ConsumerState<ResolvedMediaImage> createState() => _ResolvedMediaImageState();
}

class _ResolvedMediaImageState extends ConsumerState<ResolvedMediaImage> {
  Future<dynamic>? _resolvedFuture;

  @override
  void initState() {
    super.initState();
    _resolvedFuture = _buildFuture();
  }

  @override
  void didUpdateWidget(ResolvedMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.url != widget.url ||
        oldWidget.localPath != widget.localPath ||
        oldWidget.useThumbnail != widget.useThumbnail ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height) {
      _resolvedFuture = _buildFuture();
    }
  }

  Future<dynamic>? _buildFuture() {
    // Only create a future if we actually need one (no url or localPath)
    if (widget.url != null || widget.localPath != null) return null;
    final resolver = ref.read(contentResolverProvider);
    return widget.useThumbnail
        ? resolver.resolveVideoThumbnail(widget.content)
        : resolver.resolveImageUrl(
            widget.content,
            width: (widget.width ?? 250).toInt(),
            height: (widget.height ?? 200).toInt(),
          );
  }

  @override
  Widget build(BuildContext context) {
    final resolver = ref.watch(contentResolverProvider);
    final resolvedUrl = widget.url ?? resolver.resolveLegacyUrl(widget.content);

    if (resolvedUrl != null) {
      return Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildPlaceholder(widget.placeholderIcon);
        },
        errorBuilder: (_, _, _) => _buildPlaceholder(widget.errorIcon),
      );
    }

    if (widget.localPath != null) {
      return Image.file(
        File(widget.localPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(widget.placeholderIcon),
      );
    }

    return FutureBuilder<dynamic>(
      future: _resolvedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder(widget.placeholderIcon);
        }
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildPlaceholder(widget.errorIcon),
          );
        }
        return _buildPlaceholder(widget.errorIcon);
      },
    );
  }

  Widget _buildPlaceholder(IconData icon) => Container(
    width: widget.width ?? 150,
    height: widget.height ?? 100,
    color: Colors.grey.shade300,
    child: Icon(icon, size: 40, color: Colors.grey.shade600),
  );
}
