import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/cache/image_cache_service.dart';

/// A cached image widget for media content (message images, video thumbnails).
///
/// Uses the media thumbnail cache manager for efficient caching.
/// Provides loading and error states with customizable placeholders.
class CachedMediaImage extends ConsumerWidget {
  const CachedMediaImage({
    required this.imageUrl,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.showProgress = true,
    this.onTap,
    this.onLoaded,
  });

  /// The URL of the image (HTTPS URL)
  final String imageUrl;

  /// Width constraint for the image
  final double? width;

  /// Height constraint for the image
  final double? height;

  /// How the image should fit within its bounds
  final BoxFit fit;

  /// Border radius for the image
  final BorderRadius? borderRadius;

  /// Custom placeholder widget
  final Widget? placeholder;

  /// Custom error widget
  final Widget? errorWidget;

  /// Whether to show a progress indicator while loading
  final bool showProgress;

  /// Called when the image is tapped
  final VoidCallback? onTap;

  /// Called when the image finishes loading
  final VoidCallback? onLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildCachedNetworkImage(context);
  }

  /// Build image from HTTPS URL using CachedNetworkImage.
  Widget _buildCachedNetworkImage(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: ImageCacheService.mediaCacheManager,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          placeholder ?? _buildPlaceholder(context, showProgress),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildErrorWidget(context),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      imageBuilder: (context, imageProvider) {
        // Call onLoaded callback when image is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onLoaded?.call();
        });

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            image: DecorationImage(image: imageProvider, fit: fit),
          ),
        );
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: image);
    }

    return image;
  }

  Widget _buildPlaceholder(BuildContext context, bool showProgress) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: showProgress
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : null,
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Theme.of(context).colorScheme.outline,
          size: 32,
        ),
      ),
    );
  }
}

/// A cached video thumbnail with a play overlay.
class CachedVideoThumbnail extends ConsumerWidget {
  const CachedVideoThumbnail({
    required this.thumbnailUrl,
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.onTap,
    this.duration,
  });

  /// The URL of the thumbnail image
  final String thumbnailUrl;

  /// Width of the thumbnail
  final double? width;

  /// Height of the thumbnail
  final double? height;

  /// Border radius for the thumbnail
  final BorderRadius? borderRadius;

  /// Called when tapped (typically to play video)
  final VoidCallback? onTap;

  /// Duration of the video (optional, shown as overlay)
  final Duration? duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CachedMediaImage(
            imageUrl: thumbnailUrl,
            width: width,
            height: height,
            borderRadius: borderRadius,
          ),
          // Play button overlay
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          // Duration overlay
          if (duration != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(duration!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// A grid of cached media images with lazy loading.
class CachedMediaGrid extends StatelessWidget {
  const CachedMediaGrid({
    required this.imageUrls,
    super.key,
    this.crossAxisCount = 3,
    this.spacing = 2,
    this.childAspectRatio = 1,
    this.onImageTap,
    this.borderRadius,
  });

  /// List of image URLs
  final List<String> imageUrls;

  /// Number of columns in the grid
  final int crossAxisCount;

  /// Spacing between items
  final double spacing;

  /// Aspect ratio of each item
  final double childAspectRatio;

  /// Called when an image is tapped
  final void Function(int index, String url)? onImageTap;

  /// Border radius for images
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return CachedMediaImage(
          imageUrl: imageUrls[index],
          borderRadius: borderRadius,
          onTap: onImageTap != null
              ? () => onImageTap!(index, imageUrls[index])
              : null,
        );
      },
    );
  }
}
