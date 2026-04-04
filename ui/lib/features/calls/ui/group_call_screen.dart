import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../rooms/data/room_subscription_service.dart';
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
  bool _canManageStage = false;
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
        final nextProfileId = manager.currentProfileId;
        setState(() {
          _currentCall = call;
          _currentProfileId = nextProfileId;
          _isAudioMuted = manager.isAudioMuted;
          _isVideoOff = manager.isVideoOff;
        });
        unawaited(_refreshStagePermissions(nextProfileId, call));
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
    final result = manager.toggleCamera();
    setState(() {
      _isVideoOff = manager.isVideoOff;
    });
    if (!mounted) return;
    if (result == GroupCallCameraToggleResult.deniedNoStageSlot) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Only people on the current video stage can turn on their camera.',
          ),
        ),
      );
    }
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

  Future<void> _refreshStagePermissions(
    String? profileId,
    GroupCall? call,
  ) async {
    if (profileId == null || call == null) {
      if (mounted && _canManageStage) {
        setState(() {
          _canManageStage = false;
        });
      }
      return;
    }

    final repo = ref.read(roomSubscriptionRepositoryProvider);
    final isAdmin = await repo.isRoomAdmin(widget.roomId, profileId);
    final canManage = isAdmin || call.hostProfileId == profileId;
    if (!mounted || _canManageStage == canManage) {
      return;
    }
    setState(() {
      _canManageStage = canManage;
    });
  }

  Future<void> _manageVideoStage() async {
    final call = _currentCall;
    if (call == null) return;

    final selectableParticipants =
        call.participants.where((participant) => participant.isActive).toList()
          ..sort((a, b) {
            if (a.hasVideoSlot != b.hasVideoSlot) {
              return a.hasVideoSlot ? -1 : 1;
            }
            if (a.isHost != b.isHost) {
              return a.isHost ? -1 : 1;
            }
            return a.displayName.compareTo(b.displayName);
          });

    final selectedProfiles = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      builder: (context) {
        final selected = call.activeVideoProfileIds.toSet();
        return StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Video Stage',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select up to ${call.maxVideoPublishers} people who can publish video right now.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: selectableParticipants.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final participant = selectableParticipants[index];
                        final selectedNow = selected.contains(
                          participant.profileId,
                        );
                        final atCapacity =
                            !selectedNow &&
                            selected.length >= call.maxVideoPublishers;
                        return CheckboxListTile(
                          value: selectedNow,
                          activeColor: Theme.of(context).colorScheme.primary,
                          checkColor: Colors.white,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            participant.profileId == _currentProfileId
                                ? 'You'
                                : participant.displayName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            participant.isHost
                                ? 'Host'
                                : participant.isAudioMuted
                                ? 'Muted'
                                : 'Audience',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          secondary: participant.hasVideoSlot
                              ? const Icon(
                                  Icons.videocam,
                                  color: Colors.greenAccent,
                                )
                              : const Icon(
                                  Icons.visibility,
                                  color: Colors.white54,
                                ),
                          onChanged: atCapacity
                              ? null
                              : (value) {
                                  setModalState(() {
                                    if (value ?? false) {
                                      selected.add(participant.profileId);
                                    } else {
                                      selected.remove(participant.profileId);
                                    }
                                  });
                                },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '${selected.length}/${call.maxVideoPublishers} on video',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(selected.toList()),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selectedProfiles == null) return;

    try {
      final manager = await ref.read(groupCallManagerProvider.future);
      await manager.updateVideoStage(selectedProfiles);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated video stage to ${selectedProfiles.length} participant${selectedProfiles.length == 1 ? '' : 's'}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update video stage: $error')),
      );
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
    final stageCount = _currentCall?.stageParticipants.length ?? 0;
    final maxStageCount = _currentCall?.maxVideoPublishers ?? 0;

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
                const SizedBox(height: 2),
                Text(
                  '$stageCount/$maxStageCount on video',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_canManageStage)
            IconButton(
              tooltip: 'Manage video stage',
              onPressed: _manageVideoStage,
              icon: const Icon(Icons.video_settings, color: Colors.white),
            ),
          // Call duration
          if (_currentCall != null)
            _CallDurationTimer(startedAt: _currentCall!.startedAt),
        ],
      ),
    );
  }

  Widget _buildParticipantGrid() {
    final call = _currentCall;
    final stageParticipants =
        call?.participants
            .where(
              (participant) =>
                  (participant.isActive ||
                      participant.state == ParticipantState.joining) &&
                  participant.hasVideoSlot,
            )
            .toList() ??
        const <GroupCallParticipant>[];
    final audienceParticipants =
        call?.participants
            .where(
              (participant) =>
                  (participant.isActive ||
                      participant.state == ParticipantState.joining) &&
                  !participant.hasVideoSlot,
            )
            .toList() ??
        const <GroupCallParticipant>[];

    if (stageParticipants.isEmpty && audienceParticipants.isEmpty) {
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

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60,
        bottom: 100,
        left: 8,
        right: 8,
      ),
      child: Column(
        children: [
          Expanded(
            child: stageParticipants.isEmpty
                ? _buildEmptyStage()
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getColumnCount(stageParticipants.length),
                      childAspectRatio: _getAspectRatio(
                        stageParticipants.length,
                      ),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: stageParticipants.length,
                    itemBuilder: (context, index) {
                      final participant = stageParticipants[index];
                      final isLocal =
                          participant.profileId == _currentProfileId;
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
          ),
          if (audienceParticipants.isNotEmpty) ...[
            const SizedBox(height: 12),
            _AudienceStrip(
              participants: audienceParticipants,
              currentProfileId: _currentProfileId,
            ),
          ],
        ],
      ),
    );
  }

  int _getColumnCount(int participantCount) {
    if (participantCount <= 1) return 1;
    if (participantCount <= 4) return 2;
    return 3;
  }

  double _getAspectRatio(int participantCount) {
    if (participantCount == 1) return 3 / 4;
    if (participantCount == 2) return 9 / 16;
    return 4 / 3;
  }

  Widget _buildEmptyStage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.live_tv, color: Colors.white54, size: 40),
            SizedBox(height: 12),
            Text(
              'No one is on the video stage right now.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
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
          if (_canManageStage)
            _ControlButton(
              icon: Icons.video_settings,
              label: 'Stage',
              onPressed: _manageVideoStage,
            ),
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
            label: _isVideoOff
                ? (_currentCall?.canPublishVideo(_currentProfileId ?? '') ??
                          false
                      ? 'Start Video'
                      : 'Stage Only')
                : 'Stop Video',
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

class _AudienceStrip extends StatelessWidget {
  const _AudienceStrip({
    required this.participants,
    required this.currentProfileId,
  });

  final List<GroupCallParticipant> participants;
  final String? currentProfileId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audience',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: participants.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final participant = participants[index];
                final isLocal = participant.profileId == currentProfileId;
                final label = isLocal ? 'You' : participant.displayName;
                return Container(
                  width: 96,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white12,
                        backgroundImage: participant.avatarUrl != null
                            ? NetworkImage(participant.avatarUrl!)
                            : null,
                        child: participant.avatarUrl == null
                            ? Text(
                                label.isNotEmpty ? label[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            participant.isAudioMuted
                                ? Icons.mic_off
                                : Icons.mic,
                            size: 14,
                            color: participant.isAudioMuted
                                ? Colors.redAccent
                                : Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.visibility,
                            size: 14,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
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
