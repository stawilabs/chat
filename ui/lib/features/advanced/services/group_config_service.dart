import 'package:antinvestor_auth_runtime/antinvestor_auth_runtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xid/xid.dart';

import '../../../core/sync/sync_engine.dart';
import '../../messages/domain/room_event.dart' as domain;
import '../domain/group_finance_config.dart';

/// Provider for group config service
final groupConfigServiceProvider = FutureProvider<GroupConfigService>((
  ref,
) async {
  final syncEngine = await ref.watch(syncEngineProvider.future);
  final runtime = ref.watch(authRuntimeProvider);
  return GroupConfigService(syncEngine, runtime);
});

/// Service for sending group finance configuration events
class GroupConfigService {
  GroupConfigService(this._syncEngine, this._authRuntime);

  final SyncEngine _syncEngine;
  final AuthRuntime _authRuntime;

  /// Send a group finance configuration as a room event
  Future<void> sendGroupConfig(String roomId, GroupFinanceConfig config) async {
    final errors = config.validate();
    if (errors.isNotEmpty) {
      throw Exception('Invalid config: ${errors.join(', ')}');
    }

    final currentProfileId = (await _authRuntime.getUserClaims()).sub;
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
