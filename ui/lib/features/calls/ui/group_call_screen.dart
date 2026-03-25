import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../domain/group_call.dart';
import '../domain/group_call_participant.dart';
import '../services/group_call_manager.dart';
import 'widgets/participant_tile.dart';

/// Screen for group video/audio calls
///
/// Displays a grid of participant video tiles with controls
/// for muting audio/video and leaving/ending the call.
class GroupCallScreen extends ConsumerStatefulWidget {
  const GroupCallScreen({
    required this.roomId,
    required this.roomName,
    this.callId,
    super.key,
  });

  /// Room ID where the call is taking place
  final String roomId;

  /// Display name of the room
  final String roomName;

  /// Call ID to join (null if starting a new call)
  final String? callId;

  @override
  ConsumerState<GroupCallScreen> createState() => _GroupCallScreenState();
}

class _GroupCallScreenState extends ConsumerState<GroupCallScreen> {
  GroupCall? _currentCall;
  MediaStream? _localStream;
  Map<String, MediaStream> _remoteStreams = {};
  String? _activeSpeaker;
  String? _currentProfileId;
  bool _isAudioMuted = false;
  bool _isVideoOff = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  StreamSubscription<GroupCall?>? _callSubscription;
  StreamSubscription<MediaStream?>? _localStreamSubscription;
  StreamSubscription<Map<String, MediaStream>>? _remoteStreamsSubscription;
  StreamSubscription<String?>? _activeSpeakerSubscription;

  @override
  void initState() {
    super.initState();
    _initCall();
    _startHideControlsTimer();
  }

  Future<void> _initCall() async {
    final manager = await ref.read(groupCallManagerProvider.future);

    // Subscribe to streams
    _callSubscription = manager.callStream.listen((call) {
      if (mounted) {
        setState(() {
          _currentCall = call;
          // Update current profile ID from manager
          _currentProfileId = manager.currentProfileId;
        });
      }
    });

    _localStreamSubscription = manager.localStream.listen((stream) {
      if (mounted) {
        setState(() {
          _localStream = stream;
        });
      }
    });

    _remoteStreamsSubscription = manager.remoteStreams.listen((streams) {
      if (mounted) {
        setState(() {
          _remoteStreams = streams;
        });
      }
    });

    _activeSpeakerSubscription = manager.activeSpeaker.listen((speaker) {
      if (mounted) {
        setState(() {
          _activeSpeaker = speaker;
        });
      }
    });

    // Start or join the call
    if (widget.callId != null) {
      await manager.joinGroupCall(widget.roomId, widget.callId!);
    } else {
      await manager.startGroupCall(widget.roomId);
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _onScreenTap() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _callSubscription?.cancel();
    _localStreamSubscription?.cancel();
    _remoteStreamsSubscription?.cancel();
    _activeSpeakerSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    final manager = await ref.read(groupCallManagerProvider.future);
    manager.toggleMic();
    setState(() {
      _isAudioMuted = manager.isAudioMuted;
    });
  }

  Future<void> _toggleCamera() async {
    final manager = await ref.read(groupCallManagerProvider.future);
    manager.toggleCamera();
    setState(() {
      _isVideoOff = manager.isVideoOff;
    });
  }

  Future<void> _leaveCall() async {
    final manager = await ref.read(groupCallManagerProvider.future);
    await manager.leaveGroupCall();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _endCall() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Call'),
        content: const Text(
          'This will end the call for all participants. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Call'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final manager = await ref.read(groupCallManagerProvider.future);
      await manager.endGroupCall();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final managerAsync = ref.watch(groupCallManagerProvider);

    return managerAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
      data: (manager) => _buildCallScreen(context, manager),
    );
  }

  Widget _buildCallScreen(BuildContext context, GroupCallManager manager) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onScreenTap,
        child: Stack(
          children: [
            // Participant grid
            _buildParticipantGrid(),

            // Top bar with room info
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),

            // Bottom controls
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _showControls ? 0 : -120,
              left: 0,
              right: 0,
              child: _buildControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final participantCount = _currentCall?.connectedParticipantCount ?? 0;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.roomName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$participantCount participant${participantCount == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          // Call duration
          if (_currentCall != null)
            _CallDurationTimer(startedAt: _currentCall!.startedAt),
        ],
      ),
    );
  }

  Widget _buildParticipantGrid() {
    final participants = _currentCall?.participants ?? [];
    final activeParticipants = participants
        .where((p) => p.isActive || p.state == ParticipantState.joining)
        .toList();

    if (activeParticipants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Waiting for participants...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    // Determine grid layout based on participant count
    final columns = _getColumnCount(activeParticipants.length);
    final rows = (activeParticipants.length / columns).ceil();

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60,
        bottom: 100,
        left: 8,
        right: 8,
      ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: _getAspectRatio(activeParticipants.length, rows),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: activeParticipants.length,
        itemBuilder: (context, index) {
          final participant = activeParticipants[index];
          // Check if participant is the current user by comparing profile IDs
          final isLocal = participant.profileId == _currentProfileId;

          return ParticipantTile(
            participant: participant,
            stream: isLocal
                ? _localStream
                : _remoteStreams[participant.profileId],
            isLocal: isLocal,
            isSpeaking: _activeSpeaker == participant.profileId,
          );
        },
      ),
    );
  }

  int _getColumnCount(int participantCount) {
    if (participantCount <= 1) return 1;
    if (participantCount <= 4) return 2;
    if (participantCount <= 9) return 3;
    return 4;
  }

  double _getAspectRatio(int participantCount, int rows) {
    // Adjust aspect ratio based on number of participants
    if (participantCount == 1) return 3 / 4;
    if (participantCount == 2) return 9 / 16;
    return 4 / 3;
  }

  Widget _buildControls() {
    // Check if current user is the host by comparing profile IDs
    final isHost =
        _currentCall?.hostProfileId == _currentProfileId &&
        _currentProfileId != null;

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute audio button
          _ControlButton(
            icon: _isAudioMuted ? Icons.mic_off : Icons.mic,
            label: _isAudioMuted ? 'Unmute' : 'Mute',
            isActive: _isAudioMuted,
            onPressed: _toggleMic,
          ),

          // Toggle video button
          _ControlButton(
            icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
            label: _isVideoOff ? 'Start Video' : 'Stop Video',
            isActive: _isVideoOff,
            onPressed: _toggleCamera,
          ),

          // Leave/End call button
          _ControlButton(
            icon: Icons.call_end,
            label: isHost ? 'End' : 'Leave',
            isDestructive: true,
            onPressed: isHost ? _endCall : _leaveCall,
          ),
        ],
      ),
    );
  }
}

/// Button widget for call controls
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDestructive
        ? Colors.red
        : isActive
        ? Colors.white
        : Colors.white24;

    final foregroundColor = isDestructive
        ? Colors.white
        : isActive
        ? Colors.black
        : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: const EdgeInsets.all(16),
          ),
          icon: Icon(icon),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

/// Widget to display call duration
class _CallDurationTimer extends StatefulWidget {
  const _CallDurationTimer({required this.startedAt});

  final DateTime startedAt;

  @override
  State<_CallDurationTimer> createState() => _CallDurationTimerState();
}

class _CallDurationTimerState extends State<_CallDurationTimer> {
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateDuration();
    });
  }

  void _updateDuration() {
    if (mounted) {
      setState(() {
        _duration = DateTime.now().difference(widget.startedAt);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _duration.inHours;
    final minutes = _duration.inMinutes.remainder(60);
    final seconds = _duration.inSeconds.remainder(60);

    final timeString = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
          const SizedBox(width: 6),
          Text(
            timeString,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
