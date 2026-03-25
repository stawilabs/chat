import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xid/xid.dart';

import '../../../core/sync/sync_engine.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../messages/domain/room_event.dart' as domain;

final signalingServiceProvider = FutureProvider<SignalingService>((ref) async {
  final syncEngine = await ref.watch(syncEngineProvider.future);
  final authRepo = ref.watch(authRepositoryProvider);
  return SignalingService(syncEngine, authRepo);
});

class SignalingService {
  SignalingService(this._syncEngine, this._authRepository);
  final SyncEngine _syncEngine;
  final AuthRepository _authRepository;

  Stream<domain.RoomEvent> get onSignal => _syncEngine.signalingEvents;

  Future<void> sendOffer(String roomId, Map<String, dynamic> offer) async {
    await _sendSignal(roomId, domain.RoomEventType.callOffer, offer);
  }

  Future<void> sendAnswer(String roomId, Map<String, dynamic> answer) async {
    await _sendSignal(roomId, domain.RoomEventType.callAnswer, answer);
  }

  Future<void> sendCandidate(
    String roomId,
    Map<String, dynamic> candidate,
  ) async {
    await _sendSignal(roomId, domain.RoomEventType.callIce, candidate);
  }

  Future<void> sendHangup(String roomId) async {
    await _sendSignal(roomId, domain.RoomEventType.callEnd, {});
  }

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

    // Use the existing sendMessage flow in SyncEngine (via MessageRepository/PendingJobs)
    // But since we want to bypass the repository for immediate sending if possible,
    // we might want to use a direct method. However, SyncEngine's sendMessage is via PendingJobs.
    // For now, we'll use the standard flow which ensures reliability.
    // Ideally, we should have a "sendImmediate" for signaling if latency is an issue with the queue.
    // Given the current architecture, we'll create a pending job.

    // We need to access the message repository or pending job repository to send.
    // Since SignalingService doesn't have access to those directly, we can use a provider or
    // add a method to SyncEngine.
    //
    // Actually, the UI uses `messageListProvider(roomId).notifier.sendMessage(message)`.
    // We should probably do something similar or expose a method in SyncEngine.
    //
    // Let's check how `sendMessage` is implemented in `MessageNotifier`.
    // It calls `_repo.insertMessage` and `_jobRepo.addJob`.
    //
    // To keep it simple and consistent, we'll add a `sendSignal` method to `SyncEngine`
    // or just use the repositories if we can access them.
    //
    // But `SignalingService` only has `SyncEngine`.
    // Let's add `sendSignal` to `SyncEngine` which handles the job creation.
    //
    // Wait, `SyncEngine` has `_jobRepo` but it's private.
    // Let's modify `SyncEngine` to expose a `sendMessage` or `sendSignal` method.
    //
    // Alternatively, we can just use the `messageListProvider` logic if we were in the UI layer.
    // But we are in the service layer.
    //
    // Let's add `sendSignal` to `SyncEngine` for now.
    await _syncEngine.sendSignal(message);
  }
}
