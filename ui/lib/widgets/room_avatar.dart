import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A circular avatar for room list items.
///
/// Displays the first letter of the room name in a colored circle.
/// Supports optional tap handler and multi-select checkbox overlay.
class RoomAvatar extends StatelessWidget {
  const RoomAvatar({
    required this.name,
    super.key,
    this.size = 50,
    this.onTap,
    this.isSelectable = false,
    this.isSelected = false,
  });

  /// Room name — first letter is displayed as the avatar initial.
  final String name;

  /// Diameter of the avatar circle.
  final double size;

  /// Called when the avatar is tapped. Wraps in GestureDetector when non-null.
  final VoidCallback? onTap;

  /// When true, shows a selection checkbox overlay.
  final bool isSelectable;

  /// Whether the item is currently selected (only used when [isSelectable] is true).
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final avatar = Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTheme.headerText.copyWith(
                fontSize: size * 0.36,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (isSelectable)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGreen : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}
