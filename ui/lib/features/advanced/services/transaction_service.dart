import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xid/xid.dart';

import '../../../core/sync/sync_engine.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../messages/domain/room_event.dart';

final transactionServiceProvider = FutureProvider<TransactionService>((
  ref,
) async {
  final syncEngine = await ref.watch(syncEngineProvider.future);
  final authRepo = ref.watch(authRepositoryProvider);
  return TransactionService(syncEngine, authRepo);
});

class TransactionService {
  TransactionService(this._syncEngine, this._authRepository);
  final SyncEngine _syncEngine;
  final AuthRepository _authRepository;

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

    final currentProfileId = await _authRepository.getCurrentProfileId();

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
