import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xid/xid.dart';

import '../../../core/sync/sync_engine.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../messages/domain/room_event.dart' as domain;

final groupSignalingServiceProvider = FutureProvider<GroupSignalingService>((
  ref,
) async {
  final syncEngine = await ref.watch(syncEngineProvider.future);
  final authRepo = ref.watch(authRepositoryProvider);
  return GroupSignalingService(syncEngine, authRepo);
});

/// Service for handling group call signaling
///
/// Manages WebRTC signaling for group calls, including:
/// - Starting/ending group calls
/// - Joining/leaving calls
/// - Exchanging SDP offers/answers between participants
/// - Exchanging ICE candidates
/// - Broadcasting mute state updates
class GroupSignalingService {
  GroupSignalingService(this._syncEngine, this._authRepository);

  final SyncEngine _syncEngine;
  final AuthRepository _authRepository;

  /// Stream of group call signaling events from the sync engine
  Stream<domain.RoomEvent> get onGroupCallSignal => _syncEngine.signalingEvents
      .where((event) => _isGroupCallEvent(event.type));

  /// Check if an event type is a group call event
  bool _isGroupCallEvent(domain.RoomEventType type) {
    return type == domain.RoomEventType.groupCallStart ||
        type == domain.RoomEventType.groupCallJoin ||
        type == domain.RoomEventType.groupCallLeave ||
        type == domain.RoomEventType.groupCallEnd ||
        type == domain.RoomEventType.groupCallOffer ||
        type == domain.RoomEventType.groupCallAnswer ||
        type == domain.RoomEventType.groupCallIce ||
        type == domain.RoomEventType.groupCallMuteUpdate;
  }

  /// Start a new group call in a room
  ///
  /// Sends a groupCallStart event to notify room members
  /// that a group call is being initiated.
  Future<String> sendGroupCallStart(String roomId) async {
    final callId = Xid().toString();
    await _sendSignal(roomId, domain.RoomEventType.groupCallStart, {
      'callId': callId,
      'startedAt': DateTime.now().millisecondsSinceEpoch,
    });
    return callId;
  }

  /// Send a join request to an existing group call
  ///
  /// Notifies other participants that this user is joining.
  Future<void> sendGroupCallJoin(String roomId, String callId) async {
    await _sendSignal(roomId, domain.RoomEventType.groupCallJoin, {
      'callId': callId,
      'joinedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Send a leave notification for a group call
  ///
  /// Notifies other participants that this user is leaving.
  Future<void> sendGroupCallLeave(String roomId, String callId) async {
    await _sendSignal(roomId, domain.RoomEventType.groupCallLeave, {
      'callId': callId,
      'leftAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// End the entire group call (host only)
  ///
  /// Terminates the call for all participants.
  Future<void> sendGroupCallEnd(String roomId, String callId) async {
    await _sendSignal(roomId, domain.RoomEventType.groupCallEnd, {
      'callId': callId,
      'endedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Send an SDP offer to a specific participant
  ///
  /// [targetProfileId] is the profile ID of the participant to connect to.
  Future<void> sendGroupCallOffer(
    String roomId,
    String callId,
    String targetProfileId,
    Map<String, dynamic> offer,
  ) async {
    await _sendSignal(roomId, domain.RoomEventType.groupCallOffer, {
      'callId': callId,
      'targetProfileId': targetProfileId,
      'sdp': offer['sdp'],
      'type': offer['type'],
    });
  }

  /// Send an SDP answer to a specific participant
  ///
  /// [targetProfileId] is the profile ID of the participant who sent the offer.
  Future<void> sendGroupCallAnswer(
    String roomId,
    String callId,
    String targetProfileId,
    Map<String, dynamic> answer,
  ) async {
    await _sendSignal(roomId, domain.RoomEventType.groupCallAnswer, {
      'callId': callId,
      'targetProfileId': targetProfileId,
      'sdp': answer['sdp'],
      'type': answer['type'],
    });
  }

  /// Send an ICE candidate to a specific participant
  ///
  /// [targetProfileId] is the profile ID of the participant to send to.
  Future<void> sendGroupCallIceCandidate(
    String roomId,
    String callId,
    String targetProfileId,
    Map<String, dynamic> candidate,
  ) async {
    await _sendSignal(roomId, domain.RoomEventType.groupCallIce, {
      'callId': callId,
      'targetProfileId': targetProfileId,
      'candidate': candidate['candidate'],
      'sdpMid': candidate['sdpMid'],
      'sdpMLineIndex': candidate['sdpMLineIndex'],
    });
  }

  /// Broadcast mute state update to all participants
  ///
  /// Notifies participants about audio/video mute state changes.
  Future<void> sendMuteUpdate(
    String roomId,
    String callId, {
    required bool isAudioMuted,
    required bool isVideoOff,
  }) async {
    await _sendSignal(roomId, domain.RoomEventType.groupCallMuteUpdate, {
      'callId': callId,
      'isAudioMuted': isAudioMuted,
      'isVideoOff': isVideoOff,
    });
  }

  /// Internal method to send a signaling event
  Future<void> _sendSignal(
    String roomId,
    domain.RoomEventType type,
    Map<String, dynamic> content,
  ) async {
    final currentProfileId = await _authRepository.getCurrentProfileId();

    final message = domain.RoomEvent(
      id: Xid().toString(),
      roomId: roomId,
      senderId: currentProfileId ?? 'unknown',
      type: type,
      content: content,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      localId: Xid().toString(),
    );

    await _syncEngine.sendSignal(message);
  }
}
