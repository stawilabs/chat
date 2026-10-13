import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../messages/data/message_providers.dart';
import '../../messages/data/message_sending_service.dart';
import '../../messages/domain/room_event.dart';
import '../../rooms/data/room_subscription_service.dart';
import '../domain/stawi_payloads.dart';
import 'stawi_account_service.dart' show stawiClockProvider;

/// A DM partner may be named a room's Stawi agent only once they accepted an
/// agent invitation for exactly that room (chat's relay checks the same; room
/// members need none). Where that stands, as this device reads the DM.
enum AgentInviteStatus {
  /// No live invitation and no live acceptance for the room.
  none,

  /// The person invited the partner; the partner has not accepted yet.
  invited,

  /// The partner accepted, and the acceptance has not expired.
  accepted,
}

/// The status [events] (agent invitations and acceptances in one DM) give
/// for the room [roomId]: accepted when the partner (not [mySubscriptionId])
/// sent a live acceptance naming the room; invited when the person sent an
/// invitation for it that has not expired (or not been stamped yet).
AgentInviteStatus agentInviteStatusOf(
  List<RoomEvent> events, {
  required String roomId,
  required String? mySubscriptionId,
  required DateTime now,
}) {
  bool mine(RoomEvent e) =>
      mySubscriptionId != null && e.senderId == mySubscriptionId;
  for (final e in events) {
    if (e.type != RoomEventType.stawiAgentAcceptance || mine(e)) continue;
    final a = StawiAgentAcceptanceView.fromContent(e.content);
    if (a.roomId == roomId && a.liveAt(now)) return AgentInviteStatus.accepted;
  }
  for (final e in events) {
    if (e.type != RoomEventType.stawiAgentInvitation || !mine(e)) continue;
    final i = StawiAgentInvitationView.fromContent(e.content);
    if (i.roomId == roomId && (i.expiresAt == null || i.liveAt(now))) {
      return AgentInviteStatus.invited;
    }
  }
  return AgentInviteStatus.none;
}

/// The agent invitations and acceptances of a DM, oldest first, live.
typedef AgentEventsSource = Stream<List<RoomEvent>> Function(String dmRoomId);

/// The local store's agent invitations and acceptances.
final agentEventsSourceProvider = Provider<AgentEventsSource>(
  (ref) =>
      (dmRoomId) => ref.watch(messageRepositoryProvider).watchRoomEventsByTypes(
        dmRoomId,
        const {
          RoomEventType.stawiAgentInvitation,
          RoomEventType.stawiAgentAcceptance,
        },
      ),
);

/// The DM `dmRoomId` and the room `roomId` its partner may become agent of.
typedef AgentInviteKey = ({String dmRoomId, String roomId});

/// Where the agent invitation for a room stands in a DM, live from the
/// local timeline.
final agentInviteStatusProvider = StreamProvider.autoDispose
    .family<AgentInviteStatus, AgentInviteKey>((ref, key) async* {
      final me = await ref.watch(
        currentUserSubscriptionIdProvider(key.dmRoomId).future,
      );
      final now = ref.watch(stawiClockProvider);
      final events = ref.watch(agentEventsSourceProvider)(key.dmRoomId);
      await for (final list in events) {
        yield agentInviteStatusOf(
          list,
          roomId: key.roomId,
          mySubscriptionId: me,
          now: now(),
        );
      }
    });

/// Whether the person already accepted the invitation `invitationEventId`
/// in the DM `dmRoomId`.
final agentInvitationAcceptedProvider = StreamProvider.autoDispose
    .family<bool, ({String dmRoomId, String invitationEventId})>(
      (ref, key) => ref
          .watch(agentEventsSourceProvider)(key.dmRoomId)
          .map(
            (list) => list.any(
              (e) =>
                  e.type == RoomEventType.stawiAgentAcceptance &&
                  StawiAgentAcceptanceView.fromContent(e.content)
                          .invitationEventId ==
                      key.invitationEventId,
            ),
          ),
    );

/// Sends one Stawi act into a room (the message sending service's
/// sendStawiAct).
typedef AgentActSender = Future<RoomEvent> Function({
  required String roomId,
  required RoomEventType type,
  required Map<String, dynamic> content,
  String? parentId,
});

final agentActSenderProvider = Provider<AgentActSender>(
  (ref) => ref.watch(messageSendingServiceProvider).sendStawiAct,
);

/// Invites the partner of the DM [dmRoomId] to be the Stawi agent of the
/// room [roomId] being converted.
Future<RoomEvent> inviteAgent(
  AgentActSender send, {
  required String dmRoomId,
  required String roomId,
}) => send(
  roomId: dmRoomId,
  type: RoomEventType.stawiAgentInvitation,
  content: StawiAgentInvitationView.content(roomId: roomId),
);

/// Accepts the agent invitation [invitation] (an event in a DM).
Future<RoomEvent> acceptAgentInvitation(
  AgentActSender send,
  RoomEvent invitation,
) => send(
  roomId: invitation.roomId,
  type: RoomEventType.stawiAgentAcceptance,
  content: StawiAgentAcceptanceView.content(invitationEventId: invitation.id),
);
