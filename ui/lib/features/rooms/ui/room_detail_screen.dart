import 'package:flutter/material.dart';

import '../../../core/navigation/navigation_helper.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../messages/ui/chat_screen.dart';
import 'room_detail_panel.dart';

/// Room detail screen showing full room information
/// Accessed when clicking on room avatar
class RoomDetailScreen extends StatelessWidget {
  const RoomDetailScreen({
    required this.roomId,
    required this.roomName,
    super.key,
  });
  final String roomId;
  final String roomName;

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
    mobileLayout: _buildMobileLayout(context),
    tabletLayout: _buildTabletLayout(context),
    desktopLayout: _buildDesktopLayout(context),
  );

  /// Mobile layout: Full screen room details
  Widget _buildMobileLayout(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(roomName),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Navigate back using navigation helper
          context.navigateBack();
        },
        tooltip: 'Back',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.chat),
          onPressed: () {
            // Navigate to chat screen using navigation helper
            context.navigateToChat(roomId: roomId, roomName: roomName);
          },
          tooltip: 'Open chat',
        ),
      ],
    ),
    body: RoomDetailPanel(roomId: roomId, roomName: roomName),
  );

  /// Tablet layout: Chat alongside room details
  Widget _buildTabletLayout(BuildContext context) => Scaffold(
    body: Row(
      children: [
        // Chat panel
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: ChatScreen(roomId: roomId, roomName: roomName),
          ),
        ),
        // Room detail panel
        Expanded(
          child: RoomDetailPanel(roomId: roomId, roomName: roomName),
        ),
      ],
    ),
  );

  /// Desktop layout: Chat alongside room details (wider detail panel)
  Widget _buildDesktopLayout(BuildContext context) => Scaffold(
    body: Row(
      children: [
        // Chat panel
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: ChatScreen(roomId: roomId, roomName: roomName),
          ),
        ),
        // Room detail panel
        Expanded(
          flex: 3,
          child: RoomDetailPanel(roomId: roomId, roomName: roomName),
        ),
      ],
    ),
  );
}
