import 'package:flutter/material.dart';

/// A reusable avatar widget for contacts/profiles
class ContactAvatar extends StatelessWidget {
  const ContactAvatar({
    required this.displayName,
    this.avatarUrl,
    this.radius = 24,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final String displayName;
  final String? avatarUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  String get _initials {
    if (displayName.isEmpty) return '?';

    final words = displayName.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primaryContainer;
    final fgColor = foregroundColor ?? theme.colorScheme.onPrimaryContainer;
    final fontSize = radius * 0.75;

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (exception, stackTrace) {},
        backgroundColor: bgColor,
        child: Text(
          _initials,
          style: TextStyle(
            color: fgColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        _initials,
        style: TextStyle(
          color: fgColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
