import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../messages/data/message_providers.dart';
import '../../messages/domain/room_event.dart';
import '../../profile/data/profile_providers.dart';
import '../../rooms/data/detail_panel_providers.dart';
import '../domain/stawi_payloads.dart';
import 'stawi_binding.dart';

/// The outcomes chat posted under an act (keyed by the act's event id),
/// oldest first.
final stawiOutcomesProvider = StreamProvider.autoDispose
    .family<List<RoomEvent>, String>(
      (ref, actEventId) => ref
          .watch(messageRepositoryProvider)
          .watchChildEventsByType(actEventId, RoomEventType.stawiCallOutcome),
    );

/// The genesis signatures founders sent under a conversion card.
final stawiGenesisSignaturesProvider = StreamProvider.autoDispose
    .family<List<RoomEvent>, String>(
      (ref, conversionEventId) => ref
          .watch(messageRepositoryProvider)
          .watchChildEventsByType(
            conversionEventId,
            RoomEventType.stawiGenesisSignature,
          ),
    );

/// Where a chat room stands on its way to being a Stawi room.
enum StawiRoomPhase {
  /// A plain chat room (never converted, or the last conversion did not go
  /// through and the room can be converted again).
  chatOnly,

  /// A conversion was sent; chat has not posted its genesis yet.
  preparing,

  /// The genesis card is up; founders are signing.
  awaitingSignatures,

  /// The chain has the room.
  active,
}

/// A genesis card's phase from its conversion and the outcomes under it (the
/// card shows its own progress; the room's phase comes from its binding).
StawiRoomPhase stawiRoomPhase(
  RoomEvent? conversion,
  List<RoomEvent> outcomes, {
  DateTime? now,
}) {
  if (conversion == null) return StawiRoomPhase.chatOnly;
  for (final event in outcomes.reversed) {
    final outcome = StawiOutcomeView.fromContent(event.content);
    if (outcome.state == StawiOutcomeState.observed &&
        outcome.kind == 'ROOM_ACTIVATED') {
      return StawiRoomPhase.active;
    }
    if (outcome.state == StawiOutcomeState.failed) {
      return StawiRoomPhase.chatOnly;
    }
  }
  if (conversion.status == EventStatus.failed) return StawiRoomPhase.chatOnly;
  final genesis = StawiConversionView.fromContent(conversion.content).genesis;
  if (genesis == null) return StawiRoomPhase.preparing;
  if (genesis.isExpired(now ?? DateTime.now().toUtc())) {
    return StawiRoomPhase.chatOnly;
  }
  return StawiRoomPhase.awaitingSignatures;
}

/// The room's phase from chat's binding: chat records the conversion, the
/// chain's activation and a failed genesis, so every member sees the same.
StawiRoomPhase phaseOfBinding(StawiBinding? binding) =>
    switch (binding?.state) {
      null || StawiBindingState.failed => StawiRoomPhase.chatOnly,
      StawiBindingState.pending => StawiRoomPhase.awaitingSignatures,
      StawiBindingState.bound => StawiRoomPhase.active,
    };

/// The room's phase, live, from its binding.
final stawiRoomPhaseProvider = Provider.autoDispose
    .family<AsyncValue<StawiRoomPhase>, String>(
      (ref, roomId) =>
          ref.watch(stawiBindingProvider(roomId)).whenData(phaseOfBinding),
    );

/// A member's display name in a room: the room's own member list (profile or
/// contact name), then the local profile cache. Never the raw profile id
/// unless nothing else is known.
final stawiMemberNameProvider = FutureProvider.autoDispose
    .family<String, ({String roomId, String profileId})>((ref, key) async {
      if (key.profileId.isEmpty) return 'Member';
      final members = await ref.watch(roomMembersProvider(key.roomId).future);
      for (final m in members) {
        if (m.profileId == key.profileId && m.name.trim().isNotEmpty) {
          return m.name;
        }
      }
      final profile = await ref.watch(
        profileByIdProvider(key.profileId).future,
      );
      final name = profile?.name?.trim() ?? '';
      return name.isNotEmpty ? name : 'Member ${key.profileId.substring(0, 6)}';
    });
