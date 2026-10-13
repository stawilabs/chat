import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/sync/chat_event_codec.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/stawi/data/stawi_timeline_providers.dart';
import 'package:stawi/features/stawi/domain/stawi_payloads.dart';
import 'package:stawi/features/stawi/domain/template_rules.dart';
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;

RoomEvent event(
  RoomEventType type,
  Map<String, dynamic> content, {
  String id = 'e1',
  String? parentId,
  EventStatus status = EventStatus.delivered,
  String? errorMessage,
}) => RoomEvent(
  id: id,
  roomId: 'room00000000000000aa',
  senderId: 'sub-1',
  type: type,
  content: content,
  parentId: parentId,
  createdAt: 0,
  status: status,
  errorMessage: errorMessage,
);

RoomEvent outcome(String state, {String kind = 'INVITE', String reason = ''}) =>
    event(RoomEventType.stawiCallOutcome, {
      'state': state,
      'kind': kind,
      'reason': reason,
    }, id: 'o-$state');

void main() {
  group('StawiPayloadCodec', () {
    test('a conversion goes out as ROOM_EVENT_TYPE_EVENT without genesis', () {
      final content = StawiConversionView.content(
        templateId: 'ug_savings_basic',
        ruleValues: const {'period': 'MONTHLY'},
        founderSubscriptionIds: const ['sub-1', 'sub-2'],
        joinPolicy: StawiJoinPolicy.public,
      )..['genesis'] = {'genesisId': 'spoofed'};

      final built = ChatEventCodec.buildRoomEvent(
        eventId: 'e1',
        roomId: 'room00000000000000aa',
        subscriptionId: 'sub-1',
        localType: RoomEventType.stawiRoomConversion,
        content: content,
        timestamp: pb.Timestamp.fromDateTime(DateTime.utc(2026)),
      );

      expect(built.type, pb.RoomEventType.ROOM_EVENT_TYPE_EVENT);
      expect(
        built.payload.type,
        pb.PayloadType.PAYLOAD_TYPE_STAWI_ROOM_CONVERSION,
      );
      final sent = built.payload.stawiRoomConversion;
      expect(sent.templateId, 'ug_savings_basic');
      expect(sent.ruleValues, {'period': 'MONTHLY'});
      expect(sent.founderSubscriptionIds, ['sub-1', 'sub-2']);
      expect(sent.joinPolicy, pb.StawiJoinPolicy.STAWI_JOIN_POLICY_PUBLIC);
      expect(sent.hasGenesis(), isFalse);
    });

    test('signed calls and signatures round-trip through the stored map', () {
      final signature = Uint8List.fromList(List.generate(65, (i) => i));
      final call = StawiSignedCallView.content(
        callId: 'call0000000000000001',
        kind: 'CAST_VOTE',
        signature: signature,
        signerKeyId: '0xabc',
        summary: 'Vote approve on proposal #3',
      );
      final payload = pb.Payload();
      expect(
        StawiPayloadCodec.encode(payload, RoomEventType.stawiSignedCall, call),
        isTrue,
      );
      expect(payload.type, pb.PayloadType.PAYLOAD_TYPE_STAWI_SIGNED_CALL);
      expect(payload.stawiSignedCall.signature, signature);
      expect(payload.stawiSignedCall.algorithm, 'secp256k1');

      final decoded = StawiPayloadCodec.decode(payload)!;
      expect(decoded.type, RoomEventType.stawiSignedCall);
      final view = StawiSignedCallView.fromContent(decoded.content);
      expect(view.kind, 'CAST_VOTE');
      expect(view.summary, 'Vote approve on proposal #3');

      final sig = StawiGenesisSignatureView.content(
        genesisId: 'gen1',
        signature: signature,
        signerKeyId: '0xabc',
      );
      final sigPayload = pb.Payload();
      StawiPayloadCodec.encode(
        sigPayload,
        RoomEventType.stawiGenesisSignature,
        sig,
      );
      expect(sigPayload.stawiGenesisSignature.genesisId, 'gen1');
      expect(sigPayload.stawiGenesisSignature.signature, signature);
    });

    test('outcomes and finance cards are never encoded by a client', () {
      for (final type in [
        RoomEventType.stawiCallOutcome,
        RoomEventType.financeCard,
      ]) {
        expect(StawiPayloadCodec.encode(pb.Payload(), type, {}), isFalse);
      }
    });

    test('decodes the server genesis, outcomes and finance cards', () {
      final hash = Uint8List.fromList(List.filled(32, 7));
      final conversion = StawiPayloadCodec.decode(
        pb.Payload(
          stawiRoomConversion: pb.StawiRoomConversionContent(
            templateId: 't1',
            joinPolicy: pb.StawiJoinPolicy.STAWI_JOIN_POLICY_PRIVATE,
            genesis: pb.StawiGenesis(
              genesisId: 'gen1',
              genesisHash: hash,
              founderProfileIds: ['p1', 'p2'],
              expiresAt: pb.Timestamp.fromDateTime(DateTime.utc(2026, 10, 12)),
            ),
          ),
        ),
      )!;
      final genesis = StawiConversionView.fromContent(
        conversion.content,
      ).genesis!;
      expect(genesis.genesisId, 'gen1');
      expect(genesis.genesisHash, hash);
      expect(genesis.isFounder('p2'), isTrue);
      expect(genesis.expiresAt, DateTime.utc(2026, 10, 12));

      final observed = StawiPayloadCodec.decode(
        pb.Payload(
          stawiCallOutcome: pb.StawiCallOutcomeContent(
            callId: 'c1',
            state: pb.StawiCallOutcomeState.STAWI_CALL_OUTCOME_STATE_OBSERVED,
            kind: 'INVITE',
            txHash: Uint8List.fromList(List.filled(32, 1)),
            blockNumber: Int64(99),
          ),
        ),
      )!;
      expect(observed.type, RoomEventType.stawiCallOutcome);
      final view = StawiOutcomeView.fromContent(observed.content);
      expect(view.state, StawiOutcomeState.observed);
      expect(view.blockNumber, 99);
      expect(describeOutcome(view), 'Invitation confirmed on chain');

      final card = StawiPayloadCodec.decode(
        pb.Payload(
          financeCard: pb.FinanceCardContent(
            cardId: 'k1',
            kind: 'PROPOSAL',
            title: 'New proposal',
            data: {'proposal_id': 'prop1'}.entries,
          ),
        ),
      )!;
      expect(card.type, RoomEventType.financeCard);
      expect(FinanceCardView.fromContent(card.content).data, {
        'proposal_id': 'prop1',
      });

      expect(
        StawiPayloadCodec.decode(pb.Payload(text: pb.TextContent(body: 'hi'))),
        isNull,
      );
    });

    test('new event types persist under stable storage codes', () {
      for (final type in stawiEventTypes) {
        expect(roomEventTypeFromStorageCode(type.storageCode), type);
        expect(tryRoomEventTypeFromWireName(type.wireName), type);
      }
    });
  });

  group('resolveActState', () {
    final act = event(RoomEventType.stawiSignedCall, const {});

    test('pending until an outcome arrives', () {
      expect(resolveActState(act, const []).state, StawiActState.pending);
      expect(
        resolveActState(
          act.copyWith(status: EventStatus.pending),
          const [],
        ).state,
        StawiActState.sending,
      );
      final notSent = resolveActState(
        act.copyWith(status: EventStatus.failed, errorMessage: 'not a founder'),
        const [],
      );
      expect(notSent.state, StawiActState.notSent);
      expect(notSent.reason, 'not a founder');
    });

    test('a terminal outcome wins over acceptance in any order', () {
      final accepted = outcome('STAWI_CALL_OUTCOME_STATE_ACCEPTED');
      final observed = outcome('STAWI_CALL_OUTCOME_STATE_OBSERVED');
      final failed = outcome(
        'STAWI_CALL_OUTCOME_STATE_FAILED',
        reason: 'NotOfficer',
      );
      expect(resolveActState(act, [accepted]).state, StawiActState.accepted);
      expect(
        resolveActState(act, [accepted, observed]).state,
        StawiActState.confirmed,
      );
      expect(
        resolveActState(act, [observed, accepted]).state,
        StawiActState.confirmed,
      );
      final refused = resolveActState(act, [accepted, failed]);
      expect(refused.state, StawiActState.refused);
      expect(refused.reason, 'NotOfficer');
    });
  });

  group('stawiRoomPhase', () {
    final now = DateTime.utc(2026, 10, 11);
    Map<String, dynamic> withGenesis(DateTime expires) => {
      'templateId': 't1',
      'genesis': {
        'genesisId': 'gen1',
        'founderProfileIds': ['p1'],
        'expiresAt': expires.toIso8601String(),
      },
    };

    test('follows the conversion from request to chain', () {
      expect(stawiRoomPhase(null, const []), StawiRoomPhase.chatOnly);
      final sent = event(RoomEventType.stawiRoomConversion, const {
        'templateId': 't1',
      });
      expect(
        stawiRoomPhase(sent, const [], now: now),
        StawiRoomPhase.preparing,
      );
      final card = event(
        RoomEventType.stawiRoomConversion,
        withGenesis(DateTime.utc(2026, 10, 12)),
      );
      expect(
        stawiRoomPhase(card, const [], now: now),
        StawiRoomPhase.awaitingSignatures,
      );
      expect(
        stawiRoomPhase(card, [
          outcome('STAWI_CALL_OUTCOME_STATE_OBSERVED', kind: 'ROOM_ACTIVATED'),
        ], now: now),
        StawiRoomPhase.active,
      );
    });

    test('a refused, failed or expired conversion can be retried', () {
      final card = event(
        RoomEventType.stawiRoomConversion,
        withGenesis(DateTime.utc(2026, 10, 10)),
      );
      expect(stawiRoomPhase(card, const [], now: now), StawiRoomPhase.chatOnly);
      expect(
        stawiRoomPhase(event(RoomEventType.stawiRoomConversion, const {}), [
          outcome('STAWI_CALL_OUTCOME_STATE_FAILED', kind: 'ROOM_CONVERSION'),
        ], now: now),
        StawiRoomPhase.chatOnly,
      );
      expect(
        stawiRoomPhase(
          event(
            RoomEventType.stawiRoomConversion,
            const {},
            status: EventStatus.failed,
          ),
          const [],
          now: now,
        ),
        StawiRoomPhase.chatOnly,
      );
    });
  });

  group('founding quorum', () {
    test('is met by as many founders or more', () {
      for (final (entered, fallback, founders) in [
        ('', 3, 3),
        ('', 3, 5),
        ('2', 3, 2),
        ('', 0, 1),
        ('1', 0, 1),
      ]) {
        expect(
          foundingQuorumProblem(
            entered: entered,
            templateDefault: fallback,
            founders: founders,
          ),
          isNull,
          reason: '$entered/$fallback with $founders founders',
        );
      }
    });

    test('above the founders is refused, typed or the template\'s', () {
      expect(
        foundingQuorumProblem(entered: '', templateDefault: 3, founders: 2),
        contains('needs 3 founders'),
      );
      expect(
        foundingQuorumProblem(entered: '4', templateDefault: 0, founders: 3),
        contains('more than the 3 founders'),
      );
    });
  });

  group('template rules', () {
    test('keeps the values given and drops empty ones', () {
      expect(
        ruleValuesFrom(const {
          'contribution_amount': '250000',
          'period': 'WEEKLY',
          'voting_period': '',
        }),
        {'contribution_amount': '250000', 'period': 'WEEKLY'},
      );
    });

    test('refuses values settlement would refuse', () {
      for (final bad in [
        {'grace_days': '31'},
        {'quorum_bps': '999'},
        {'pass_bps': '5000'},
        {'voting_period': '3600'},
        {'contribution_amount': '012'},
        {'contribution_amount': '-5'},
        {'period': 'YEARLY'},
      ]) {
        expect(
          () => ruleValuesFrom(bad),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });
  });
}
