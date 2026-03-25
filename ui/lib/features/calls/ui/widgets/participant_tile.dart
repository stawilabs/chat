import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../domain/group_call_participant.dart';

/// Widget displaying a single participant's video tile in a group call grid
///
/// Shows the participant's video stream, name overlay, and mute indicators.
/// Falls back to avatar display when video is off.
class ParticipantTile extends StatefulWidget {
  const ParticipantTile({
    required this.participant,
    this.stream,
    this.isLocal = false,
    this.isSpeaking = false,
    super.key,
  });

  /// The participant data
  final GroupCallParticipant participant;

  /// Media stream for this participant (null if not available)
  final MediaStream? stream;

  /// Whether this tile represents the local user
  final bool isLocal;

  /// Whether this participant is currently the active speaker
  final bool isSpeaking;

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  final _renderer = RTCVideoRenderer();
  bool _rendererInitialized = false;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    await _renderer.initialize();
    _rendererInitialized = true;
    if (widget.stream != null) {
      _renderer.srcObject = widget.stream;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(ParticipantTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stream != oldWidget.stream && _rendererInitialized) {
      _renderer.srcObject = widget.stream;
    }
  }

  @override
  void dispose() {
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasVideo = widget.stream != null && !widget.participant.isVideoOff;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isSpeaking
              ? theme.colorScheme.primary
              : Colors.transparent,
          width: widget.isSpeaking ? 3 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video or Avatar
            if (hasVideo && _rendererInitialized)
              RTCVideoView(
                _renderer,
                mirror: widget.isLocal,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            else
              _buildAvatarPlaceholder(),

            // Gradient overlay for text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),

            // Name and status indicators
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  // Name
                  Expanded(
                    child: Text(
                      widget.isLocal ? 'You' : widget.participant.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(blurRadius: 4)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Host indicator
                  if (widget.participant.isHost) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Host',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Mute indicators
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Audio mute indicator
                  if (widget.participant.isAudioMuted)
                    _buildIndicator(Icons.mic_off, Colors.red),

                  // Video off indicator
                  if (widget.participant.isVideoOff) ...[
                    const SizedBox(width: 4),
                    _buildIndicator(Icons.videocam_off, Colors.red),
                  ],
                ],
              ),
            ),

            // Connection state overlay
            if (!widget.participant.isActive)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.participant.state ==
                          ParticipantState.reconnecting)
                        const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      else if (widget.participant.state ==
                          ParticipantState.disconnected)
                        const Icon(
                          Icons.signal_wifi_off,
                          color: Colors.white54,
                          size: 32,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        _getStateText(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: widget.participant.avatarUrl != null
            ? CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(widget.participant.avatarUrl!),
              )
            : CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[600],
                child: Text(
                  _getInitials(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildIndicator(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }

  String _getInitials() {
    final name = widget.participant.displayName;
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _getStateText() {
    switch (widget.participant.state) {
      case ParticipantState.invited:
        return 'Invited';
      case ParticipantState.joining:
        return 'Joining...';
      case ParticipantState.reconnecting:
        return 'Reconnecting...';
      case ParticipantState.left:
        return 'Left';
      case ParticipantState.disconnected:
        return 'Disconnected';
      case ParticipantState.connected:
        return '';
    }
  }
}
