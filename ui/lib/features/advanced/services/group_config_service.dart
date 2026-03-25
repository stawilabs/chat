import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xid/xid.dart';

import '../../../core/sync/sync_engine.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../messages/domain/room_event.dart' as domain;
import '../domain/group_finance_config.dart';

/// Provider for group config service
final groupConfigServiceProvider = FutureProvider<GroupConfigService>((
  ref,
) async {
  final syncEngine = await ref.watch(syncEngineProvider.future);
  final authRepo = ref.watch(authRepositoryProvider);
  return GroupConfigService(syncEngine, authRepo);
});

/// Service for sending group finance configuration events
class GroupConfigService {
  GroupConfigService(this._syncEngine, this._authRepository);

  final SyncEngine _syncEngine;
  final AuthRepository _authRepository;

  /// Send a group finance configuration as a room event
  Future<void> sendGroupConfig(String roomId, GroupFinanceConfig config) async {
    final errors = config.validate();
    if (errors.isNotEmpty) {
      throw Exception('Invalid config: ${errors.join(', ')}');
    }

    final currentProfileId = await _authRepository.getCurrentProfileId();
    if (currentProfileId == null) {
      throw Exception('Not authenticated');
    }

    final event = domain.RoomEvent(
      id: Xid().toString(),
      roomId: roomId,
      senderId: currentProfileId,
      type: domain.RoomEventType.groupConfig,
      content: config.toJson(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      localId: Xid().toString(),
    );

    await _syncEngine.sendSignal(event);
  }
}
