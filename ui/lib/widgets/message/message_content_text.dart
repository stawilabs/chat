import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/messages/data/link_preview_service.dart';
import '../../features/messages/ui/widgets/link_preview_card.dart';

/// Text message content with link detection and inline link preview.
class MessageContentText extends StatelessWidget {
  const MessageContentText({required this.text, required this.isMe, super.key});

  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getBubbleTextColor(isMe, isDark);
    final urls = LinkPreviewService.extractUrls(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: textColor,
            fontWeight: FontWeight.w400,
          ),
        ),
        if (urls.isNotEmpty)
          InlineMessageLinkPreview(url: urls.first, isOwnMessage: isMe),
      ],
    );
  }
}
