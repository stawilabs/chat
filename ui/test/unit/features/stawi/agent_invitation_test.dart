import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/stawi/data/stawi_agent_invitations.dart';
import 'package:stawi/features/stawi/domain/stawi_payloads.dart';
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;

void main() {
  final now = DateTime.utc(2026, 10, 13, 12);
  String at(Duration d) => now.add(d).toIso8601String();

  RoomEvent invitation({
    String sender = 'sub-me',
    String roomId = 'r-chama',
    String? expiresAt,
  }) => RoomEvent(
    id: 'inv-$sender-$roomId',
    roomId: 'dm-agnes',
    senderId: sender,
    type: RoomEventType.stawiAgentInvitation,
    createdAt: 0,
    content: {'roomId': roomId, 'roomName': 'Chama', 'expiresAt': ?expiresAt},
  );

  RoomEvent acceptance({
    required String expiresAt,
    String sender = 'sub-agnes',
    String roomId = 'r-chama',
  }) => RoomEvent(
    id: 'acc-$sender-$roomId',
    roomId: 'dm-agnes',
    senderId: sender,
    type: RoomEventType.stawiAgentAcceptance,
    createdAt: 1,
    content: {
      'invitationEventId': 'inv-sub-me-r-chama',
      'roomId': roomId,
      'roomName': 'Chama',
      'expiresAt': expiresAt,
    },
  );

  AgentInviteStatus status(List<RoomEvent> events) => agentInviteStatusOf(
    events,
    roomId: 'r-chama',
    mySubscriptionId: 'sub-me',
    now: now,
  );

  group('where an agent invitation stands in a DM', () {
    test('nothing sent: none', () {
      expect(status(const []), AgentInviteStatus.none);
    });

    test('my invitation, not yet stamped or still live: invited', () {
      expect(status([invitation()]), AgentInviteStatus.invited);
      expect(
        status([invitation(expiresAt: at(const Duration(days: 7)))]),
        AgentInviteStatus.invited,
      );
    });

    test('an expired invitation, or one for another room: none', () {
      expect(
        status([invitation(expiresAt: at(const Duration(seconds: -1)))]),
        AgentInviteStatus.none,
      );
      expect(status([invitation(roomId: 'r-other')]), AgentInviteStatus.none);
      expect(
        status([invitation(sender: 'sub-agnes')]),
        AgentInviteStatus.none,
        reason: 'an invitation the partner sent is not mine',
      );
    });

    test('the partner\'s live acceptance for this room: accepted', () {
      expect(
        status([
          invitation(expiresAt: at(const Duration(days: 7))),
          acceptance(expiresAt: at(const Duration(days: 7))),
        ]),
        AgentInviteStatus.accepted,
      );
    });

    test(
      'an acceptance expired, for another room, or my own: not accepted',
      () {
        for (final a in [
          acceptance(expiresAt: at(Duration.zero)),
          acceptance(roomId: 'r-other', expiresAt: at(const Duration(days: 1))),
          acceptance(sender: 'sub-me', expiresAt: at(const Duration(days: 1))),
        ]) {
          expect(status([a]), AgentInviteStatus.none);
        }
      },
    );
  });

  group('the payloads', () {
    test('an invitation sends only its room; chat stamps the rest', () {
      final payload = pb.Payload();
      expect(
        StawiPayloadCodec.encode(payload, RoomEventType.stawiAgentInvitation, {
          'roomId': 'r-chama',
          'roomName': 'Forged',
          'expiresAt': at(const Duration(days: 300)),
        }),
        isTrue,
      );
      expect(payload.type, pb.PayloadType.PAYLOAD_TYPE_STAWI_AGENT_INVITATION);
      expect(payload.stawiAgentInvitation.roomId, 'r-chama');
      expect(payload.stawiAgentInvitation.roomName, isEmpty);
      expect(payload.stawiAgentInvitation.hasExpiresAt(), isFalse);
    });

    test('an acceptance sends only the invitation it accepts', () {
      final payload = pb.Payload();
      StawiPayloadCodec.encode(
        payload,
        RoomEventType.stawiAgentAcceptance,
        StawiAgentAcceptanceView.content(invitationEventId: 'inv1'),
      );
      expect(payload.type, pb.PayloadType.PAYLOAD_TYPE_STAWI_AGENT_ACCEPTANCE);
      expect(payload.stawiAgentAcceptance.invitationEventId, 'inv1');
      expect(payload.stawiAgentAcceptance.roomId, isEmpty);
    });

    test('what chat relays decodes to the cards\' events', () {
      final expires = now.add(const Duration(days: 7));
      final decoded = StawiPayloadCodec.decode(
        pb.Payload(
          type: pb.PayloadType.PAYLOAD_TYPE_STAWI_AGENT_ACCEPTANCE,
          stawiAgentAcceptance: pb.StawiAgentAcceptanceContent(
            invitationEventId: 'inv1',
            roomId: 'r-chama',
            roomName: 'Chama',
            expiresAt: pb.Timestamp.fromDateTime(expires),
          ),
        ),
      )!;
      expect(decoded.type, RoomEventType.stawiAgentAcceptance);
      final view = StawiAgentAcceptanceView.fromContent(decoded.content);
      expect(view.roomName, 'Chama');
      expect(view.expiresAt, expires);
      expect(view.liveAt(now), isTrue);
      final invitation = StawiPayloadCodec.decode(
        pb.Payload(
          type: pb.PayloadType.PAYLOAD_TYPE_STAWI_AGENT_INVITATION,
          stawiAgentInvitation: pb.StawiAgentInvitationContent(
            roomId: 'r-chama',
          ),
        ),
      )!;
      expect(invitation.type, RoomEventType.stawiAgentInvitation);
    });

    test('the new event types are stored and sent as Stawi acts', () {
      for (final t in [
        RoomEventType.stawiAgentInvitation,
        RoomEventType.stawiAgentAcceptance,
      ]) {
        expect(stawiEventTypes, contains(t));
        expect(roomEventTypeFromStorageCode(t.storageCode), t);
      }
    });
  });
}
