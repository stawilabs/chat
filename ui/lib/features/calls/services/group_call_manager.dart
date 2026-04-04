import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/networking/api_config.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../messages/domain/room_event.dart';
import '../domain/group_call.dart';
import '../domain/group_call_participant.dart';
import 'group_signaling_service.dart';
import 'turn_credentials_service.dart';

final groupCallManagerProvider = FutureProvider<GroupCallManager>((ref) async {
  final signalingService = await ref.watch(
    groupSignalingServiceProvider.future,
  );
  final authRepo = ref.watch(authRepositoryProvider);
  final turnService = await ref.watch(turnCredentialsServiceProvider.future);
  return GroupCallManager(signalingService, authRepo, turnService);
});

enum GroupCallCameraToggleResult { enabled, disabled, deniedNoStageSlot }

class _PendingGroupCallState {
  const _PendingGroupCallState({
    required this.hostProfileId,
    required this.maxVideoPublishers,
    required this.activeVideoProfileIds,
  });

  final String hostProfileId;
  final int maxVideoPublishers;
  final List<String> activeVideoProfileIds;
}

/// Manager for group video/audio calls
///
/// Handles WebRTC peer connections for multiple participants,
/// media streams, and call state management.
class GroupCallManager {
  GroupCallManager(
    this._signalingService,
    this._authRepository,
    this._turnCredentialsService,
  ) {
    _signalingService.onGroupCallSignal.listen(_handleSignal);
  }

  final GroupSignalingService _signalingService;
  final AuthRepository _authRepository;
  final TurnCredentialsService _turnCredentialsService;

  /// Peer connections mapped by participant profile ID
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, List<RTCIceCandidate>> _pendingIceCandidates = {};
  final Set<String> _remoteDescriptionsReady = <String>{};

  /// Remote streams mapped by participant profile ID
  final Map<String, MediaStream> _remoteStreams = {};

  /// Local media stream
  MediaStream? _localStream;

  /// Current group call
  GroupCall? _currentCall;

  /// Current user's profile ID
  String? _currentProfileId;

  /// Audio/video state
  bool _isAudioMuted = false;
  bool _isVideoOff = false;
  bool _prefersVideoEnabled = true;

  /// Active speaker detection
  Timer? _activeSpeakerTimer;
  String? _currentActiveSpeaker;

  // Stream controllers
  final _callController = StreamController<GroupCall?>.broadcast();
  final _localStreamController = StreamController<MediaStream?>.broadcast();
  final _remoteStreamsController =
      StreamController<Map<String, MediaStream>>.broadcast();
  final _activeSpeakerController = StreamController<String?>.broadcast();

  /// Stream of the current group call state
  Stream<GroupCall?> get callStream => _callController.stream;

  /// Stream of local media
  Stream<MediaStream?> get localStream => _localStreamController.stream;

  /// Stream of remote media streams (profileId -> stream)
  Stream<Map<String, MediaStream>> get remoteStreams =>
      _remoteStreamsController.stream;

  /// Stream of the currently speaking participant
  Stream<String?> get activeSpeaker => _activeSpeakerController.stream;

  /// Current call getter
  GroupCall? get currentCall => _currentCall;

  /// Current user's profile ID getter
  String? get currentProfileId => _currentProfileId;

  /// Media state getters
  bool get isAudioMuted => _isAudioMuted;
  bool get isVideoOff => _isVideoOff;
  bool get canPublishVideo =>
      _currentCall != null &&
      _currentProfileId != null &&
      _currentCall!.canPublishVideo(_currentProfileId!);

  /// Start a new group call as the host
  Future<void> startGroupCall(String roomId) async {
    if (_currentCall != null) {
      AppLogger.warning('Already in a group call');
      return;
    }

    _currentProfileId = await _authRepository.getCurrentProfileId();
    if (_currentProfileId == null) {
      AppLogger.error('Cannot start call: no profile ID');
      return;
    }

    try {
      await _initLocalMedia();

      // Create the call and send notification
      final initialStageProfiles = <String>[_currentProfileId!];
      final callId = await _signalingService.sendGroupCallStart(
        roomId,
        maxVideoPublishers: ApiConfig.groupCallMaxVideoPublishers,
        activeVideoProfileIds: initialStageProfiles,
      );

      final hostParticipant = GroupCallParticipant(
        profileId: _currentProfileId!,
        displayName: 'You', // Will be updated from profile
        hasVideoSlot: true,
        isHost: true,
        joinedAt: DateTime.now(),
        state: ParticipantState.connected,
      );

      _currentCall = GroupCall(
        callId: callId,
        roomId: roomId,
        hostProfileId: _currentProfileId!,
        participants: [hostParticipant],
        activeVideoProfileIds: initialStageProfiles,
        state: GroupCallState.active,
        startedAt: DateTime.now(),
      );

      _applyLocalVideoPolicy(notifyRemote: false);
      _callController.add(_currentCall);
      _startActiveSpeakerDetection();

      AppLogger.info('Started group call', data: {'callId': callId});
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to start group call',
        error: e,
        stackTrace: stackTrace,
      );
      await _cleanup();
      rethrow;
    }
  }

  /// Join an existing group call
  Future<void> joinGroupCall(String roomId, String callId) async {
    if (_currentCall != null) {
      AppLogger.warning('Already in a group call');
      return;
    }

    _currentProfileId = await _authRepository.getCurrentProfileId();
    if (_currentProfileId == null) {
      AppLogger.error('Cannot join call: no profile ID');
      return;
    }

    try {
      await _initLocalMedia();

      // Send join notification
      await _signalingService.sendGroupCallJoin(roomId, callId);

      final pendingCallState = _pendingCallState.remove(callId);
      final activeVideoProfileIds =
          pendingCallState?.activeVideoProfileIds ?? const <String>[];
      final selfParticipant = GroupCallParticipant(
        profileId: _currentProfileId!,
        displayName: 'You',
        hasVideoSlot: activeVideoProfileIds.contains(_currentProfileId),
        joinedAt: DateTime.now(),
        state: ParticipantState.connected,
      );

      // Get host info from pending call starts or leave empty to be updated later
      final hostProfileId = pendingCallState?.hostProfileId ?? '';

      _currentCall = GroupCall(
        callId: callId,
        roomId: roomId,
        hostProfileId: hostProfileId,
        participants: [selfParticipant],
        activeVideoProfileIds: activeVideoProfileIds,
        maxVideoPublishers:
            pendingCallState?.maxVideoPublishers ??
            ApiConfig.groupCallMaxVideoPublishers,
        state: GroupCallState.active,
        startedAt: DateTime.now(),
      );

      _applyLocalVideoPolicy(notifyRemote: false);
      _callController.add(_currentCall);
      _startActiveSpeakerDetection();

      AppLogger.info('Joined group call', data: {'callId': callId});
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to join group call',
        error: e,
        stackTrace: stackTrace,
      );
      await _cleanup();
      rethrow;
    }
  }

  /// Leave the current group call
  Future<void> leaveGroupCall() async {
    if (_currentCall == null) return;

    final roomId = _currentCall!.roomId;
    final callId = _currentCall!.callId;

    await _signalingService.sendGroupCallLeave(roomId, callId);
    await _cleanup();

    AppLogger.info('Left group call', data: {'callId': callId});
  }

  /// End the group call (host only)
  Future<void> endGroupCall() async {
    if (_currentCall == null) return;

    // Only the host can end the call
    if (_currentCall!.hostProfileId != _currentProfileId) {
      AppLogger.warning('Only the host can end the call');
      return;
    }

    final roomId = _currentCall!.roomId;
    final callId = _currentCall!.callId;

    await _signalingService.sendGroupCallEnd(roomId, callId);
    await _cleanup();

    AppLogger.info('Ended group call', data: {'callId': callId});
  }

  Future<void> updateVideoStage(List<String> profileIds) async {
    if (_currentCall == null) {
      throw StateError('Cannot update stage without an active call');
    }

    final normalizedProfileIds = <String>[];
    for (final profileId in profileIds) {
      if (profileId.isEmpty || normalizedProfileIds.contains(profileId)) {
        continue;
      }
      normalizedProfileIds.add(profileId);
      if (normalizedProfileIds.length >= _currentCall!.maxVideoPublishers) {
        break;
      }
    }

    _applyStageState(
      normalizedProfileIds,
      maxVideoPublishers: _currentCall!.maxVideoPublishers,
      notifyRemote: true,
    );
    await _signalingService.sendGroupCallStageUpdate(
      _currentCall!.roomId,
      _currentCall!.callId,
      maxVideoPublishers: _currentCall!.maxVideoPublishers,
      activeVideoProfileIds: normalizedProfileIds,
    );

    AppLogger.info(
      'Updated group call video stage',
      data: {
        'callId': _currentCall!.callId,
        'videoPublisherCount': normalizedProfileIds.length,
      },
    );
  }

  /// Toggle microphone mute
  void toggleMic() {
    _isAudioMuted = !_isAudioMuted;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isAudioMuted;
    });

    // Broadcast mute state to other participants
    if (_currentCall != null) {
      _signalingService.sendMuteUpdate(
        _currentCall!.roomId,
        _currentCall!.callId,
        isAudioMuted: _isAudioMuted,
        isVideoOff: _isVideoOff,
      );
    }

    _updateSelfParticipant();
    AppLogger.debug('Microphone muted: $_isAudioMuted');
  }

  /// Toggle camera on/off
  GroupCallCameraToggleResult toggleCamera() {
    if (_isVideoOff) {
      if (!canPublishVideo) {
        AppLogger.warning(
          'Rejected camera enable without an active video slot',
          data: {
            'callId': _currentCall?.callId,
            'profileId': _currentProfileId,
          },
        );
        return GroupCallCameraToggleResult.deniedNoStageSlot;
      }
      _prefersVideoEnabled = true;
    } else {
      _prefersVideoEnabled = false;
    }

    _applyLocalVideoPolicy(notifyRemote: true);
    AppLogger.debug('Camera off: $_isVideoOff');
    return _isVideoOff
        ? GroupCallCameraToggleResult.disabled
        : GroupCallCameraToggleResult.enabled;
  }

  /// Initialize local media stream
  Future<void> _initLocalMedia() async {
    await [Permission.camera, Permission.microphone].request();

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
      },
    });

    _localStreamController.add(_localStream);
  }

  /// Create a peer connection for a participant
  Future<RTCPeerConnection> _createPeerConnection(String profileId) async {
    final existing = _peerConnections[profileId];
    if (existing != null) {
      return existing;
    }

    // Get ICE server configuration
    final config = await _turnCredentialsService.getIceServers();

    final pc = await createPeerConnection(config);
    _peerConnections[profileId] = pc;
    _pendingIceCandidates.putIfAbsent(profileId, () => <RTCIceCandidate>[]);

    // Add local tracks to the connection
    _localStream?.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });

    // Handle remote stream
    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStreams[profileId] = event.streams.first;
        _remoteStreamsController.add(Map.from(_remoteStreams));
      }
    };

    // Handle ICE candidates
    pc.onIceCandidate = (candidate) {
      if (_currentCall != null) {
        _signalingService.sendGroupCallIceCandidate(
          _currentCall!.roomId,
          _currentCall!.callId,
          profileId,
          {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
      }
    };

    // Handle connection state changes
    pc.onConnectionState = (state) {
      AppLogger.debug('Peer connection state for $profileId: $state');
      _handleConnectionStateChange(profileId, state);
    };

    return pc;
  }

  /// Handle peer connection state changes
  void _handleConnectionStateChange(
    String profileId,
    RTCPeerConnectionState state,
  ) {
    if (_currentCall == null) return;

    ParticipantState participantState;
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        participantState = ParticipantState.connected;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        participantState = ParticipantState.reconnecting;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        participantState = ParticipantState.disconnected;
        _closePeerConnection(profileId);
        break;
      default:
        return;
    }

    _updateParticipantState(profileId, participantState);
  }

  /// Update a participant's state
  void _updateParticipantState(String profileId, ParticipantState state) {
    if (_currentCall == null) return;

    final updatedParticipants = _currentCall!.participants.map((p) {
      if (p.profileId == profileId) {
        return p.copyWith(state: state);
      }
      return p;
    }).toList();

    _currentCall = _currentCall!.copyWith(participants: updatedParticipants);
    _callController.add(_currentCall);
  }

  /// Update self participant mute state
  void _updateSelfParticipant() {
    if (_currentCall == null || _currentProfileId == null) return;

    final updatedParticipants = _currentCall!.participants.map((p) {
      if (p.profileId == _currentProfileId) {
        return p.copyWith(
          isAudioMuted: _isAudioMuted,
          isVideoOff: _isVideoOff,
          hasVideoSlot: _currentCall!.canPublishVideo(_currentProfileId!),
        );
      }
      return p;
    }).toList();

    _currentCall = _currentCall!.copyWith(participants: updatedParticipants);
    _callController.add(_currentCall);
  }

  void _applyLocalVideoPolicy({required bool notifyRemote}) {
    final shouldSendVideo = _prefersVideoEnabled && canPublishVideo;
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = shouldSendVideo;
    });
    _isVideoOff = !shouldSendVideo;
    _updateSelfParticipant();

    if (notifyRemote && _currentCall != null) {
      unawaited(
        _signalingService.sendMuteUpdate(
          _currentCall!.roomId,
          _currentCall!.callId,
          isAudioMuted: _isAudioMuted,
          isVideoOff: _isVideoOff,
        ),
      );
    }
  }

  void _applyStageState(
    List<String> activeVideoProfileIds, {
    required int maxVideoPublishers,
    required bool notifyRemote,
  }) {
    if (_currentCall == null) return;

    final normalizedProfiles = <String>[];
    for (final profileId in activeVideoProfileIds) {
      if (profileId.isEmpty || normalizedProfiles.contains(profileId)) {
        continue;
      }
      normalizedProfiles.add(profileId);
      if (normalizedProfiles.length >= maxVideoPublishers) {
        break;
      }
    }

    final updatedParticipants = _currentCall!.participants.map((participant) {
      final hasVideoSlot = normalizedProfiles.contains(participant.profileId);
      return participant.copyWith(
        hasVideoSlot: hasVideoSlot,
        isVideoOff: !hasVideoSlot || participant.isVideoOff,
      );
    }).toList();

    _currentCall = _currentCall!.copyWith(
      activeVideoProfileIds: normalizedProfiles,
      maxVideoPublishers: maxVideoPublishers,
      participants: updatedParticipants,
    );
    _callController.add(_currentCall);

    if (_currentProfileId != null) {
      _applyLocalVideoPolicy(notifyRemote: notifyRemote);
    }
  }

  List<String> _readStageProfiles(Map<String, dynamic> content) {
    final raw = content['activeVideoProfileIds'];
    if (raw is! List) {
      return const <String>[];
    }
    return raw.whereType<String>().where((value) => value.isNotEmpty).toList();
  }

  int _readMaxVideoPublishers(Map<String, dynamic> content) {
    final raw = content['maxVideoPublishers'];
    if (raw is int) {
      return raw > 0 ? raw : ApiConfig.groupCallMaxVideoPublishers;
    }
    if (raw is double) {
      final parsed = raw.toInt();
      return parsed > 0 ? parsed : ApiConfig.groupCallMaxVideoPublishers;
    }
    return ApiConfig.groupCallMaxVideoPublishers;
  }

  /// Close a peer connection
  void _closePeerConnection(String profileId) {
    _peerConnections[profileId]?.close();
    _peerConnections.remove(profileId);
    _pendingIceCandidates.remove(profileId);
    _remoteDescriptionsReady.remove(profileId);
    _remoteStreams[profileId]?.dispose();
    _remoteStreams.remove(profileId);
    _remoteStreamsController.add(Map.from(_remoteStreams));
  }

  /// Handle incoming signaling events
  Future<void> _handleSignal(RoomEvent event) async {
    final currentProfileId = await _authRepository.getCurrentProfileId();
    final senderProfileId = _eventSenderProfileId(event);
    if (currentProfileId != null && senderProfileId == currentProfileId) return;

    switch (event.type) {
      case RoomEventType.groupCallStart:
        await _handleGroupCallStart(event);
        break;
      case RoomEventType.groupCallJoin:
        await _handleGroupCallJoin(event);
        break;
      case RoomEventType.groupCallLeave:
        await _handleGroupCallLeave(event);
        break;
      case RoomEventType.groupCallEnd:
        await _handleGroupCallEnd(event);
        break;
      case RoomEventType.groupCallOffer:
        await _handleGroupCallOffer(event);
        break;
      case RoomEventType.groupCallAnswer:
        await _handleGroupCallAnswer(event);
        break;
      case RoomEventType.groupCallIce:
        await _handleGroupCallIce(event);
        break;
      case RoomEventType.groupCallMuteUpdate:
        _handleMuteUpdate(event);
        break;
      case RoomEventType.groupCallStageUpdate:
        _handleStageUpdate(event);
        break;
      default:
        break;
    }
  }

  /// Pending call info received from call start events (before joining)
  final Map<String, _PendingGroupCallState> _pendingCallState = {};

  /// Handle group call start notification
  Future<void> _handleGroupCallStart(RoomEvent event) async {
    // This is a notification that someone started a call in a room
    // The UI can show a "call started" notification
    final callId = event.content['callId'] as String?;
    if (callId != null) {
      _pendingCallState[callId] = _PendingGroupCallState(
        hostProfileId: _eventSenderProfileId(event),
        maxVideoPublishers: _readMaxVideoPublishers(event.content),
        activeVideoProfileIds: _readStageProfiles(event.content),
      );
    }

    AppLogger.info(
      'Group call started in room',
      data: {
        'roomId': event.roomId,
        'callId': callId,
        'startedBy': _eventSenderProfileId(event),
      },
    );
  }

  /// Handle participant join
  Future<void> _handleGroupCallJoin(RoomEvent event) async {
    if (_currentCall == null) return;

    final callId = event.content['callId'] as String?;
    if (callId != _currentCall!.callId) return;

    final joinedProfileId = _eventSenderProfileId(event);
    if (_currentCall!.participants.length >=
        ApiConfig.groupCallMeshMaxParticipants) {
      AppLogger.warning(
        'Skipping peer allocation: mesh participant limit reached',
        data: {
          'callId': _currentCall!.callId,
          'limit': ApiConfig.groupCallMeshMaxParticipants,
          'joinedProfileId': joinedProfileId,
        },
      );
      return;
    }

    if (!_currentCall!.participants.any(
      (p) => p.profileId == joinedProfileId,
    )) {
      final newParticipant = GroupCallParticipant(
        profileId: joinedProfileId,
        displayName: joinedProfileId, // Will be updated from profile
        hasVideoSlot: _currentCall!.canPublishVideo(joinedProfileId),
        joinedAt: DateTime.now(),
      );

      final updatedParticipants = [
        ..._currentCall!.participants,
        newParticipant,
      ];
      _currentCall = _currentCall!.copyWith(participants: updatedParticipants);
      _callController.add(_currentCall);
    }

    // Create peer connection and send offer
    final pc = await _createPeerConnection(joinedProfileId);
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    // Include host info in the offer so the joining participant knows who's the host
    final isHost = _currentCall!.hostProfileId == _currentProfileId;
    await _signalingService.sendGroupCallOffer(
      _currentCall!.roomId,
      _currentCall!.callId,
      joinedProfileId,
      {
        'sdp': offer.sdp,
        'type': offer.type,
        'hostProfileId': _currentCall!.hostProfileId,
        'isHost': isHost,
        'maxVideoPublishers': _currentCall!.maxVideoPublishers,
        'activeVideoProfileIds': _currentCall!.activeVideoProfileIds,
      },
    );

    AppLogger.info(
      'Participant joined group call',
      data: {'profileId': joinedProfileId},
    );
  }

  /// Handle participant leave
  Future<void> _handleGroupCallLeave(RoomEvent event) async {
    if (_currentCall == null) return;

    final callId = event.content['callId'] as String?;
    if (callId != _currentCall!.callId) return;

    final leftProfileId = _eventSenderProfileId(event);
    _closePeerConnection(leftProfileId);

    final updatedParticipants = _currentCall!.participants
        .where((p) => p.profileId != leftProfileId)
        .toList();

    final updatedActiveVideoProfileIds = _currentCall!.activeVideoProfileIds
        .where((profileId) => profileId != leftProfileId)
        .toList();
    _currentCall = _currentCall!.copyWith(
      participants: updatedParticipants,
      activeVideoProfileIds: updatedActiveVideoProfileIds,
    );
    _callController.add(_currentCall);

    AppLogger.info(
      'Participant left group call',
      data: {'profileId': leftProfileId},
    );
  }

  /// Handle call end
  Future<void> _handleGroupCallEnd(RoomEvent event) async {
    if (_currentCall == null) return;

    final callId = event.content['callId'] as String?;
    if (callId != _currentCall!.callId) return;

    AppLogger.info('Group call ended by host');
    await _cleanup();
  }

  /// Handle incoming offer
  Future<void> _handleGroupCallOffer(RoomEvent event) async {
    if (_currentCall == null) return;

    final callId = event.content['callId'] as String?;
    if (callId != _currentCall!.callId) return;

    final targetProfileId = event.content['targetProfileId'] as String?;
    if (targetProfileId != _currentProfileId) return;

    final fromProfileId = _eventSenderProfileId(event);

    // Extract host info from offer if present and update call state
    final hostProfileId = event.content['hostProfileId'] as String?;
    if (hostProfileId != null && _currentCall!.hostProfileId.isEmpty) {
      _currentCall = _currentCall!.copyWith(hostProfileId: hostProfileId);
      _callController.add(_currentCall);
    }
    if (event.content.containsKey('activeVideoProfileIds')) {
      _applyStageState(
        _readStageProfiles(event.content),
        maxVideoPublishers: _readMaxVideoPublishers(event.content),
        notifyRemote: false,
      );
    }

    // Add the sender as a participant if not already present
    final isHost = event.content['isHost'] as bool? ?? false;
    if (!_currentCall!.participants.any((p) => p.profileId == fromProfileId)) {
      final newParticipant = GroupCallParticipant(
        profileId: fromProfileId,
        displayName: fromProfileId,
        hasVideoSlot: _currentCall!.canPublishVideo(fromProfileId),
        isHost: isHost,
        joinedAt: DateTime.now(),
      );
      final updatedParticipants = [
        ..._currentCall!.participants,
        newParticipant,
      ];
      _currentCall = _currentCall!.copyWith(participants: updatedParticipants);
      _callController.add(_currentCall);
    }

    // Create peer connection if it doesn't exist
    if (!_peerConnections.containsKey(fromProfileId)) {
      await _createPeerConnection(fromProfileId);
    }

    final pc = _peerConnections[fromProfileId]!;

    final sdp = event.content['sdp'] as String?;
    final type = event.content['type'] as String?;
    if (sdp == null || type == null) return;

    await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
    _remoteDescriptionsReady.add(fromProfileId);
    await _flushPendingCandidates(fromProfileId);

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    await _signalingService.sendGroupCallAnswer(
      _currentCall!.roomId,
      _currentCall!.callId,
      fromProfileId,
      {'sdp': answer.sdp, 'type': answer.type},
    );
  }

  /// Handle incoming answer
  Future<void> _handleGroupCallAnswer(RoomEvent event) async {
    if (_currentCall == null) return;

    final callId = event.content['callId'] as String?;
    if (callId != _currentCall!.callId) return;

    final targetProfileId = event.content['targetProfileId'] as String?;
    if (targetProfileId != _currentProfileId) return;

    final fromProfileId = _eventSenderProfileId(event);
    final pc = _peerConnections[fromProfileId];
    if (pc == null) return;

    final sdp = event.content['sdp'] as String?;
    final type = event.content['type'] as String?;
    if (sdp == null || type == null) return;

    await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
    _remoteDescriptionsReady.add(fromProfileId);
    await _flushPendingCandidates(fromProfileId);
  }

  /// Handle incoming ICE candidate
  Future<void> _handleGroupCallIce(RoomEvent event) async {
    if (_currentCall == null) return;

    final callId = event.content['callId'] as String?;
    if (callId != _currentCall!.callId) return;

    final targetProfileId = event.content['targetProfileId'] as String?;
    if (targetProfileId != _currentProfileId) return;

    final fromProfileId = _eventSenderProfileId(event);
    final pc = _peerConnections[fromProfileId];
    if (pc == null) return;

    final candidateStr = event.content['candidate'] as String?;
    final sdpMid = event.content['sdpMid'] as String?;
    final rawSdpMLineIndex = event.content['sdpMLineIndex'];
    final sdpMLineIndex = rawSdpMLineIndex is int
        ? rawSdpMLineIndex
        : rawSdpMLineIndex is double
        ? rawSdpMLineIndex.toInt()
        : null;

    if (candidateStr != null) {
      final candidate = RTCIceCandidate(candidateStr, sdpMid, sdpMLineIndex);
      if (!_remoteDescriptionsReady.contains(fromProfileId)) {
        _pendingIceCandidates
            .putIfAbsent(fromProfileId, () => <RTCIceCandidate>[])
            .add(candidate);
        return;
      }
      await pc.addCandidate(candidate);
    }
  }

  /// Handle mute state update from participant
  void _handleMuteUpdate(RoomEvent event) {
    if (_currentCall == null) return;

    final callId = event.content['callId'] as String?;
    if (callId != _currentCall!.callId) return;

    final fromProfileId = _eventSenderProfileId(event);
    final isAudioMuted = event.content['isAudioMuted'] as bool? ?? false;
    final isVideoOff = event.content['isVideoOff'] as bool? ?? false;

    final updatedParticipants = _currentCall!.participants.map((p) {
      if (p.profileId == fromProfileId) {
        return p.copyWith(isAudioMuted: isAudioMuted, isVideoOff: isVideoOff);
      }
      return p;
    }).toList();

    _currentCall = _currentCall!.copyWith(participants: updatedParticipants);
    _callController.add(_currentCall);
  }

  void _handleStageUpdate(RoomEvent event) {
    if (_currentCall == null) return;

    final callId = event.content['callId'] as String?;
    if (callId != _currentCall!.callId) return;

    _applyStageState(
      _readStageProfiles(event.content),
      maxVideoPublishers: _readMaxVideoPublishers(event.content),
      notifyRemote: true,
    );
  }

  /// Start active speaker detection
  void _startActiveSpeakerDetection() {
    _activeSpeakerTimer?.cancel();
    _activeSpeakerTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _detectActiveSpeaker(),
    );
  }

  /// Detect active speaker based on audio levels from WebRTC stats
  Future<void> _detectActiveSpeaker() async {
    if (_currentCall == null) return;

    String? loudestSpeaker;
    double maxLevel = 0;

    // Get audio levels from WebRTC stats for each peer connection
    for (final entry in _peerConnections.entries) {
      final profileId = entry.key;
      final pc = entry.value;

      try {
        final stats = await pc.getStats();
        for (final report in stats) {
          // Look for inbound-rtp audio reports which contain audioLevel
          if (report.type == 'inbound-rtp') {
            final values = report.values;
            final kind = values['kind'] as String?;
            if (kind == 'audio') {
              // audioLevel is a value from 0.0 to 1.0
              final audioLevel = values['audioLevel'] as double? ?? 0.0;
              // Also consider voice activity detection if available
              final voiceActivity =
                  values['voiceActivityFlag'] as bool? ?? true;

              if (voiceActivity && audioLevel > maxLevel) {
                maxLevel = audioLevel;
                loudestSpeaker = profileId;
              }
            }
          }
        }
      } catch (e) {
        // Stats may not be available for all connections
        AppLogger.debug(
          'Failed to get stats for peer',
          data: {'profileId': profileId, 'error': e.toString()},
        );
      }
    }

    // Threshold to avoid flickering on background noise
    const speakingThreshold = 0.01;
    if (maxLevel > speakingThreshold) {
      if (loudestSpeaker != _currentActiveSpeaker) {
        _currentActiveSpeaker = loudestSpeaker;
        _activeSpeakerController.add(_currentActiveSpeaker);

        // Update participant speaking state
        if (_currentCall != null) {
          final updatedParticipants = _currentCall!.participants.map((p) {
            return p.copyWith(isSpeaking: p.profileId == loudestSpeaker);
          }).toList();

          _currentCall = _currentCall!.copyWith(
            participants: updatedParticipants,
          );
          _callController.add(_currentCall);
        }
      }
    } else if (_currentActiveSpeaker != null) {
      // No one is speaking above threshold
      _currentActiveSpeaker = null;
      _activeSpeakerController.add(null);

      // Clear all speaking states
      if (_currentCall != null) {
        final updatedParticipants = _currentCall!.participants.map((p) {
          return p.copyWith(isSpeaking: false);
        }).toList();

        _currentCall = _currentCall!.copyWith(
          participants: updatedParticipants,
        );
        _callController.add(_currentCall);
      }
    }
  }

  /// Cleanup all resources
  Future<void> _cleanup() async {
    _activeSpeakerTimer?.cancel();
    _activeSpeakerTimer = null;
    _currentActiveSpeaker = null;

    // Close all peer connections
    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();
    _pendingIceCandidates.clear();
    _remoteDescriptionsReady.clear();

    // Dispose remote streams
    for (final stream in _remoteStreams.values) {
      await stream.dispose();
    }
    _remoteStreams.clear();
    _remoteStreamsController.add({});

    // Dispose local stream
    await _localStream?.dispose();
    _localStream = null;
    _localStreamController.add(null);

    // Reset state - emit ended state first so listeners can react to it
    if (_currentCall != null) {
      _currentCall = _currentCall!.copyWith(
        state: GroupCallState.ended,
        endedAt: DateTime.now(),
      );
      _callController.add(_currentCall);
    }

    // Then clear the call state
    _currentCall = null;
    _callController.add(null);
    _isAudioMuted = false;
    _isVideoOff = false;
    _prefersVideoEnabled = true;
  }

  /// Dispose of resources
  void dispose() {
    _cleanup();
    _callController.close();
    _localStreamController.close();
    _remoteStreamsController.close();
    _activeSpeakerController.close();
  }

  String _eventSenderProfileId(RoomEvent event) {
    final senderProfileId = event.content['senderProfileId'] as String?;
    if (senderProfileId != null && senderProfileId.isNotEmpty) {
      return senderProfileId;
    }
    return event.senderId;
  }

  Future<void> _flushPendingCandidates(String profileId) async {
    final pc = _peerConnections[profileId];
    if (pc == null || !_remoteDescriptionsReady.contains(profileId)) {
      return;
    }

    final pending = _pendingIceCandidates[profileId];
    if (pending == null || pending.isEmpty) {
      return;
    }

    for (final candidate in List<RTCIceCandidate>.from(pending)) {
      await pc.addCandidate(candidate);
    }
    pending.clear();
  }
}
