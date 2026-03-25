import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// A three-panel layout widget for desktop and tablet views
///
/// Layout structure:
/// - Left panel: Fixed width (e.g., room list)
/// - Center panel: Flexible width (e.g., chat messages)
/// - Right panel: Fixed width (e.g., room details) - optional
///
/// On tablet (2-panel mode), only left and center panels are shown.
/// On desktop (3-panel mode), all three panels are shown.
class ThreePanelLayout extends StatelessWidget {
  const ThreePanelLayout({
    required this.leftPanel,
    required this.centerPanel,
    super.key,
    this.rightPanel,
  });
  final Widget leftPanel;
  final Widget centerPanel;
  final Widget? rightPanel;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      // Left panel (room list)
      SizedBox(width: AppBreakpoints.roomListWidth, child: leftPanel),

      // Vertical divider
      const VerticalDivider(width: 1),

      // Center panel (chat)
      Expanded(child: centerPanel),

      // Right panel (details) - only shown if provided
      if (rightPanel != null) ...[
        const VerticalDivider(width: 1),
        SizedBox(width: AppBreakpoints.detailPanelWidth, child: rightPanel),
      ],
    ],
  );
}
