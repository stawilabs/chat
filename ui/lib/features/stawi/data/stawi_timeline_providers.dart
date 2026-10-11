import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../messages/data/message_providers.dart';
import '../../messages/domain/room_event.dart';
import '../domain/stawi_payloads.dart';

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

/// The room's latest conversion request, if any.
final stawiConversionProvider = StreamProvider.autoDispose
    .family<RoomEvent?, String>(
      (ref, roomId) => ref
          .watch(messageRepositoryProvider)
          .watchLatestEventByType(roomId, RoomEventType.stawiRoomConversion),
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

/// The room's phase from its latest conversion and the outcomes under it.
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

/// The room's phase, live.
final stawiRoomPhaseProvider = Provider.autoDispose
    .family<AsyncValue<StawiRoomPhase>, String>((ref, roomId) {
      final conversion = ref.watch(stawiConversionProvider(roomId));
      return conversion.whenData((event) {
        if (event == null) return StawiRoomPhase.chatOnly;
        final outcomes =
            ref.watch(stawiOutcomesProvider(event.id)).asData?.value ??
            const <RoomEvent>[];
        return stawiRoomPhase(event, outcomes);
      });
    });
