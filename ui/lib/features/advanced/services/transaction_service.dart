import 'package:antinvestor_auth_runtime/antinvestor_auth_runtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xid/xid.dart';

import '../../../core/sync/sync_engine.dart';
import '../../messages/domain/room_event.dart';

final transactionServiceProvider = FutureProvider<TransactionService>((
  ref,
) async {
  final syncEngine = await ref.watch(syncEngineProvider.future);
  final runtime = ref.watch(authRuntimeProvider);
  return TransactionService(syncEngine, runtime);
});

class TransactionService {
  TransactionService(this._syncEngine, this._authRuntime);
  final SyncEngine _syncEngine;
  final AuthRuntime _authRuntime;

  Future<void> sendMoney({
    required String roomId,
    required String recipientId,
    required double amount,
    required String currency,
    String? note,
  }) async {
    final content = {
      'recipientId': recipientId,
      'amount': amount,
      'currency': currency,
      'note': note,
      'status': 'pending', // pending, completed, failed
    };

    final currentProfileId = (await _authRuntime.getUserClaims()).sub;

    final event = RoomEvent(
      id: Xid().toString(),
      roomId: roomId,
      senderId: currentProfileId ?? 'unknown',
      type: RoomEventType.transaction,
      content: content,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      localId: Xid().toString(),
    );

    await _syncEngine.sendSignal(event);
  }
}
