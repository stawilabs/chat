import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/cache/image_cache_service.dart';

/// A cached circular avatar for profile images.
///
/// Uses the profile image cache manager for efficient caching.
/// Shows initials as fallback when image is not available.
class CachedProfileAvatar extends ConsumerWidget {
  const CachedProfileAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
    this.showLoading = false,
  });

  /// The URL of the profile image
  final String? imageUrl;

  /// The display name used to generate initials
  final String? name;

  /// The radius of the avatar
  final double radius;

  /// Background color when showing initials
  final Color? backgroundColor;

  /// Text color for initials
  final Color? foregroundColor;

  /// Called when the avatar is tapped
  final VoidCallback? onTap;

  /// Whether to show a loading indicator while loading
  final bool showLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primaryContainer;
    final fgColor = foregroundColor ?? theme.colorScheme.onPrimaryContainer;

    Widget avatar;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = CachedNetworkImage(
        imageUrl: imageUrl!,
        cacheManager: ImageCacheService.profileCacheManager,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
          backgroundColor: bgColor,
        ),
        placeholder: showLoading
            ? (context, url) => CircleAvatar(
                radius: radius,
                backgroundColor: bgColor,
                child: SizedBox(
                  width: radius,
                  height: radius,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fgColor,
                  ),
                ),
              )
            : (context, url) => _buildInitialsAvatar(bgColor, fgColor),
        errorWidget: (context, url, error) =>
            _buildInitialsAvatar(bgColor, fgColor),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
      );
    } else {
      avatar = _buildInitialsAvatar(bgColor, fgColor);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildInitialsAvatar(Color bgColor, Color fgColor) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: fgColor,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getInitials() {
    if (name == null || name!.isEmpty) {
      return '?';
    }

    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }
}

/// A row of stacked profile avatars for group displays.
class CachedProfileAvatarGroup extends StatelessWidget {
  const CachedProfileAvatarGroup({
    required this.imageUrls,
    super.key,
    this.names = const [],
    this.maxAvatars = 3,
    this.radius = 16,
    this.overlap = 8,
  });

  /// List of image URLs (null entries show initials)
  final List<String?> imageUrls;

  /// List of names for initials fallback
  final List<String?> names;

  /// Maximum number of avatars to show
  final int maxAvatars;

  /// Radius of each avatar
  final double radius;

  /// Overlap amount between avatars
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final displayCount = imageUrls.length.clamp(0, maxAvatars);
    final extraCount = imageUrls.length - displayCount;

    return SizedBox(
      width:
          (radius * 2 * displayCount) -
          (overlap * (displayCount - 1)) +
          (extraCount > 0 ? radius * 2 - overlap : 0),
      height: radius * 2,
      child: Stack(
        children: [
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: i * (radius * 2 - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: CachedProfileAvatar(
                  imageUrl: imageUrls[i],
                  name: i < names.length ? names[i] : null,
                  radius: radius - 2,
                ),
              ),
            ),
          if (extraCount > 0)
            Positioned(
              left: displayCount * (radius * 2 - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: radius - 2,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  child: Text(
                    '+$extraCount',
                    style: TextStyle(
                      fontSize: radius * 0.6,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
