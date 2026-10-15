import 'dart:convert';
import 'dart:typed_data';

import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show hexToBytes;

import '../../messages/domain/room_event.dart';
import 'personal_calls.dart' show LoanRef;

/// Converts the chat.v1 Stawi payloads to and from the content map a
/// [RoomEvent] stores. The map is the payload's proto3 JSON, so it round-trips
/// exactly (bytes are base64, timestamps RFC 3339, enums their names).
class StawiPayloadCodec {
  const StawiPayloadCodec._();

  /// The event type and stored content of a Stawi payload, or null when
  /// [payload] carries something else.
  static ({RoomEventType type, Map<String, dynamic> content})? decode(
    pb.Payload payload,
  ) {
    if (payload.hasStawiRoomConversion()) {
      return (
        type: RoomEventType.stawiRoomConversion,
        content: _json(payload.stawiRoomConversion),
      );
    }
    if (payload.hasStawiGenesisSignature()) {
      return (
        type: RoomEventType.stawiGenesisSignature,
        content: _json(payload.stawiGenesisSignature),
      );
    }
    if (payload.hasStawiSignedCall()) {
      return (
        type: RoomEventType.stawiSignedCall,
        content: _json(payload.stawiSignedCall),
      );
    }
    if (payload.hasStawiCallOutcome()) {
      return (
        type: RoomEventType.stawiCallOutcome,
        content: _json(payload.stawiCallOutcome),
      );
    }
    if (payload.hasFinanceCard()) {
      return (
        type: RoomEventType.financeCard,
        content: _json(payload.financeCard),
      );
    }
    if (payload.hasStawiAgentInvitation()) {
      return (
        type: RoomEventType.stawiAgentInvitation,
        content: _json(payload.stawiAgentInvitation),
      );
    }
    if (payload.hasStawiAgentAcceptance()) {
      return (
        type: RoomEventType.stawiAgentAcceptance,
        content: _json(payload.stawiAgentAcceptance),
      );
    }
    return null;
  }

  /// Fills [payload] from a stored Stawi act. Only the acts a member sends
  /// are encodable: outcomes and finance cards are server-generated and chat
  /// refuses them from a client. Returns false for any other type.
  static bool encode(
    pb.Payload payload,
    RoomEventType type,
    Map<String, dynamic> content,
  ) {
    switch (type) {
      case RoomEventType.stawiRoomConversion:
        final conversion = pb.StawiRoomConversionContent()
          ..mergeFromProto3Json(content, ignoreUnknownFields: true)
          // Set by the server only; a client that sends it is refused.
          ..clearGenesis();
        payload
          ..type = pb.PayloadType.PAYLOAD_TYPE_STAWI_ROOM_CONVERSION
          ..stawiRoomConversion = conversion;
        return true;
      case RoomEventType.stawiGenesisSignature:
        payload
          ..type = pb.PayloadType.PAYLOAD_TYPE_STAWI_GENESIS_SIGNATURE
          ..stawiGenesisSignature = (pb.StawiGenesisSignatureContent()
            ..mergeFromProto3Json(content, ignoreUnknownFields: true));
        return true;
      case RoomEventType.stawiSignedCall:
        payload
          ..type = pb.PayloadType.PAYLOAD_TYPE_STAWI_SIGNED_CALL
          ..stawiSignedCall = (pb.StawiSignedCallContent()
            ..mergeFromProto3Json(content, ignoreUnknownFields: true));
        return true;
      case RoomEventType.stawiAgentInvitation:
        final invitation = pb.StawiAgentInvitationContent()
          ..mergeFromProto3Json(content, ignoreUnknownFields: true)
          // Stamped by the server; whatever a client sends is replaced.
          ..clearRoomName()
          ..clearExpiresAt();
        payload
          ..type = pb.PayloadType.PAYLOAD_TYPE_STAWI_AGENT_INVITATION
          ..stawiAgentInvitation = invitation;
        return true;
      case RoomEventType.stawiAgentAcceptance:
        final acceptance = pb.StawiAgentAcceptanceContent()
          ..mergeFromProto3Json(content, ignoreUnknownFields: true)
          ..clearRoomId()
          ..clearRoomName()
          ..clearExpiresAt();
        payload
          ..type = pb.PayloadType.PAYLOAD_TYPE_STAWI_AGENT_ACCEPTANCE
          ..stawiAgentAcceptance = acceptance;
        return true;
      default:
        return false;
    }
  }

  static Map<String, dynamic> _json(Object message) =>
      jsonDecode(jsonEncode((message as dynamic).toProto3Json()))
          as Map<String, dynamic>;
}

/// The join policy a converted room opens with.
enum StawiJoinPolicy {
  /// Entry only by an invitation the invitee accepts.
  private,

  /// Anyone may join by their own signature and is admitted later.
  public;

  pb.StawiJoinPolicy get proto => switch (this) {
    StawiJoinPolicy.private => pb.StawiJoinPolicy.STAWI_JOIN_POLICY_PRIVATE,
    StawiJoinPolicy.public => pb.StawiJoinPolicy.STAWI_JOIN_POLICY_PUBLIC,
  };

  static StawiJoinPolicy? fromName(String? name) => switch (name) {
    'STAWI_JOIN_POLICY_PRIVATE' => StawiJoinPolicy.private,
    'STAWI_JOIN_POLICY_PUBLIC' => StawiJoinPolicy.public,
    _ => null,
  };
}

/// The genesis settlement prepared for a conversion.
class StawiGenesisView {
  const StawiGenesisView({
    required this.genesisId,
    required this.genesisHash,
    required this.constitutionHash,
    required this.founderProfileIds,
    this.expiresAt,
  });

  factory StawiGenesisView.fromJson(Map<String, dynamic> json) =>
      StawiGenesisView(
        genesisId: json['genesisId'] as String? ?? '',
        genesisHash: _bytes(json['genesisHash']),
        constitutionHash: _bytes(json['constitutionHash']),
        founderProfileIds: _strings(json['founderProfileIds']),
        expiresAt: _time(json['expiresAt']),
      );

  final String genesisId;

  /// The RoomFactory genesis hash; each founder signs it account-wrapped.
  final Uint8List genesisHash;
  final Uint8List constitutionHash;
  final List<String> founderProfileIds;
  final DateTime? expiresAt;

  bool isFounder(String profileId) => founderProfileIds.contains(profileId);

  bool isExpired(DateTime now) => expiresAt != null && now.isAfter(expiresAt!);
}

/// A STAWI_ROOM_CONVERSION act: the request, and once chat has prepared it,
/// the genesis card.
class StawiConversionView {
  const StawiConversionView({
    required this.templateId,
    required this.ruleValues,
    required this.founderSubscriptionIds,
    required this.joinPolicy,
    this.agentProfileId = '',
    this.genesis,
  });

  factory StawiConversionView.fromContent(Map<String, dynamic> content) {
    final genesis = content['genesis'];
    return StawiConversionView(
      templateId: content['templateId'] as String? ?? '',
      ruleValues: {
        for (final e in ((content['ruleValues'] as Map?) ?? const {}).entries)
          e.key as String: e.value as String,
      },
      founderSubscriptionIds: _strings(content['founderSubscriptionIds']),
      joinPolicy: StawiJoinPolicy.fromName(content['joinPolicy'] as String?),
      agentProfileId: content['agentProfileId'] as String? ?? '',
      genesis: genesis is Map
          ? StawiGenesisView.fromJson(genesis.cast<String, dynamic>())
          : null,
    );
  }

  final String templateId;
  final Map<String, String> ruleValues;
  final List<String> founderSubscriptionIds;
  final StawiJoinPolicy? joinPolicy;

  /// The profile named as the room's Stawi agent; empty for none.
  final String agentProfileId;
  final StawiGenesisView? genesis;

  /// The content map to send: the proto3 JSON of the payload. [agentProfileId]
  /// names the room's Stawi agent (a member of the room, or a DM partner who
  /// has written to the sender); null or empty for none.
  static Map<String, dynamic> content({
    required String templateId,
    required Map<String, String> ruleValues,
    required List<String> founderSubscriptionIds,
    required StawiJoinPolicy joinPolicy,
    String? agentProfileId,
  }) => StawiPayloadCodec._json(
    pb.StawiRoomConversionContent(
      templateId: templateId,
      ruleValues: ruleValues.entries,
      founderSubscriptionIds: founderSubscriptionIds,
      joinPolicy: joinPolicy.proto,
      agentProfileId: (agentProfileId?.isEmpty ?? true) ? null : agentProfileId,
    ),
  );
}

/// The signature algorithm every device key here uses.
const String secp256k1Algorithm = 'secp256k1';

/// A STAWI_GENESIS_SIGNATURE act.
class StawiGenesisSignatureView {
  const StawiGenesisSignatureView({
    required this.genesisId,
    required this.signerKeyId,
  });

  factory StawiGenesisSignatureView.fromContent(Map<String, dynamic> c) =>
      StawiGenesisSignatureView(
        genesisId: c['genesisId'] as String? ?? '',
        signerKeyId: c['signerKeyId'] as String? ?? '',
      );

  final String genesisId;
  final String signerKeyId;

  static Map<String, dynamic> content({
    required String genesisId,
    required Uint8List signature,
    required String signerKeyId,
  }) => StawiPayloadCodec._json(
    pb.StawiGenesisSignatureContent(
      genesisId: genesisId,
      signature: signature,
      signerKeyId: signerKeyId,
      algorithm: secp256k1Algorithm,
    ),
  );
}

/// A STAWI_SIGNED_CALL act.
class StawiSignedCallView {
  const StawiSignedCallView({
    required this.callId,
    required this.kind,
    required this.summary,
  });

  factory StawiSignedCallView.fromContent(Map<String, dynamic> c) =>
      StawiSignedCallView(
        callId: c['callId'] as String? ?? '',
        kind: c['kind'] as String? ?? '',
        summary: c['summary'] as String? ?? '',
      );

  final String callId;

  /// Settlement's name for the call kind, e.g. "INVITE", "CAST_VOTE".
  final String kind;
  final String summary;

  static Map<String, dynamic> content({
    required String callId,
    required String kind,
    required Uint8List signature,
    required String signerKeyId,
    required String summary,
  }) => StawiPayloadCodec._json(
    pb.StawiSignedCallContent(
      callId: callId,
      kind: kind,
      signature: signature,
      signerKeyId: signerKeyId,
      summary: summary,
      algorithm: secp256k1Algorithm,
    ),
  );
}

/// What settlement or the chain said about an act.
enum StawiOutcomeState {
  unspecified,

  /// Settlement accepted the call or signature for relay.
  accepted,

  /// Settlement or the chain refused it; nothing changed.
  failed,

  /// The chain reports the act's effect in a final block.
  observed;

  static StawiOutcomeState fromName(String? name) => switch (name) {
    'STAWI_CALL_OUTCOME_STATE_ACCEPTED' => StawiOutcomeState.accepted,
    'STAWI_CALL_OUTCOME_STATE_FAILED' => StawiOutcomeState.failed,
    'STAWI_CALL_OUTCOME_STATE_OBSERVED' => StawiOutcomeState.observed,
    _ => StawiOutcomeState.unspecified,
  };
}

/// A STAWI_CALL_OUTCOME event (server-generated).
class StawiOutcomeView {
  const StawiOutcomeView({
    required this.state,
    required this.kind,
    required this.reason,
    required this.callId,
    required this.genesisId,
    required this.sourceEventId,
    required this.txHash,
    this.blockNumber,
  });

  factory StawiOutcomeView.fromContent(Map<String, dynamic> c) =>
      StawiOutcomeView(
        state: StawiOutcomeState.fromName(c['state'] as String?),
        kind: c['kind'] as String? ?? '',
        reason: c['reason'] as String? ?? '',
        callId: c['callId'] as String? ?? '',
        genesisId: c['genesisId'] as String? ?? '',
        sourceEventId: c['sourceEventId'] as String? ?? '',
        txHash: _bytes(c['txHash']),
        blockNumber: int.tryParse('${c['blockNumber'] ?? ''}'),
      );

  final StawiOutcomeState state;

  /// The act kind ("INVITE", "GENESIS_SIGNATURE", ...) or the chain event an
  /// OBSERVED outcome reports ("ROOM_ACTIVATED", ...).
  final String kind;
  final String reason;
  final String callId;
  final String genesisId;
  final String sourceEventId;
  final Uint8List txHash;
  final int? blockNumber;
}

/// A FINANCE_CARD event: display only, it never authorizes anything.
class FinanceCardView {
  const FinanceCardView({
    required this.cardId,
    required this.kind,
    required this.title,
    required this.body,
    required this.data,
  });

  factory FinanceCardView.fromContent(Map<String, dynamic> c) =>
      FinanceCardView(
        cardId: c['cardId'] as String? ?? '',
        kind: c['kind'] as String? ?? '',
        title: c['title'] as String? ?? '',
        body: c['body'] as String? ?? '',
        data: {
          for (final e in ((c['data'] as Map?) ?? const {}).entries)
            e.key as String: '${e.value}',
        },
      );

  final String cardId;
  final String kind;
  final String title;
  final String body;
  final Map<String, String> data;

  /// The loan the card is about (data `loan_book`, `pool`, `loan_id`): null
  /// unless all three are there and well formed (two 20-byte addresses in
  /// 0x hex and a uint64 loan number above zero).
  LoanRef? get loanRef {
    final book = data['loan_book'] ?? '';
    final pool = data['pool'] ?? '';
    final id = data['loan_id'] ?? '';
    if (!_address.hasMatch(book) ||
        !_address.hasMatch(pool) ||
        !_loanId.hasMatch(id)) {
      return null;
    }
    final loanId = BigInt.parse(id);
    // A loan number is a uint64 (finance's onchain_loan_id).
    if (loanId.bitLength > 64) return null;
    return LoanRef(
      loanBook: hexToBytes(book),
      pool: hexToBytes(pool),
      loanId: loanId,
    );
  }

  /// Whether the card names a loan it can open.
  bool get isLoan => loanRef != null;

  /// Whether the card offers to open its loan (data `action: open_loan`).
  bool get opensLoan => data['action'] == 'open_loan' && isLoan;
}

final RegExp _address = RegExp(r'^0x[0-9a-fA-F]{40}$');
final RegExp _loanId = RegExp(r'^[1-9][0-9]{0,19}$');

/// Where a member's Stawi act stands, as the room shows it.
enum StawiActState {
  /// Stored locally, not yet acknowledged by chat.
  sending,

  /// Chat refused the act itself (ack error); nothing was relayed.
  notSent,

  /// Chat has it; waiting for settlement's answer.
  pending,

  /// Settlement accepted it for relay; waiting for the chain.
  accepted,

  /// The chain reports its effect.
  confirmed,

  /// Settlement or the chain refused it.
  refused,
}

/// The state of [act] given the outcomes chat posted under it. A terminal
/// outcome (OBSERVED or FAILED) wins over ACCEPTED whatever the order.
({StawiActState state, String reason}) resolveActState(
  RoomEvent act,
  List<RoomEvent> outcomes,
) {
  StawiOutcomeView? accepted;
  for (final event in outcomes.reversed) {
    final outcome = StawiOutcomeView.fromContent(event.content);
    switch (outcome.state) {
      case StawiOutcomeState.observed:
        return (state: StawiActState.confirmed, reason: '');
      case StawiOutcomeState.failed:
        return (state: StawiActState.refused, reason: outcome.reason);
      case StawiOutcomeState.accepted:
        accepted ??= outcome;
      case StawiOutcomeState.unspecified:
        break;
    }
  }
  if (accepted != null) return (state: StawiActState.accepted, reason: '');
  switch (act.status) {
    case EventStatus.pending:
      return (state: StawiActState.sending, reason: '');
    case EventStatus.failed:
      return (state: StawiActState.notSent, reason: act.errorMessage ?? '');
    case EventStatus.sent:
    case EventStatus.delivered:
    case EventStatus.read:
      return (state: StawiActState.pending, reason: '');
  }
}

/// A short name for an act or chain event kind, for the timeline.
String actLabel(String kind) => switch (kind.toUpperCase()) {
  'ROOM_CONVERSION' => 'Room conversion',
  'GENESIS_SIGNATURE' => 'Genesis signature',
  'ROOM_GENESIS' => 'Room genesis',
  'ROOM_ACTIVATED' => 'Room activation',
  'INVITE' => 'Invitation',
  'REVOKE_INVITE' => 'Invitation withdrawal',
  'ACCEPT_INVITATION' => 'Invitation acceptance',
  'JOIN' => 'Join request',
  'ADMIT' => 'Admission',
  'LEAVE' => 'Leaving',
  'SUSPEND' => 'Suspension',
  'REINSTATE' => 'Reinstatement',
  'PROPOSE' => 'Proposal',
  'CAST_VOTE' => 'Vote',
  'DELEGATE' => 'Delegation',
  'REVOKE_DELEGATION' => 'Delegation revocation',
  '' => 'Stawi act',
  _ =>
    kind[0].toUpperCase() +
        kind.substring(1).toLowerCase().replaceAll('_', ' '),
};

/// One line describing an outcome, for the timeline and notifications.
String describeOutcome(StawiOutcomeView outcome) {
  final what = actLabel(outcome.kind);
  switch (outcome.state) {
    case StawiOutcomeState.observed:
      return outcome.kind == 'ROOM_ACTIVATED'
          ? 'This room is now a Stawi room on chain'
          : '$what confirmed on chain';
    case StawiOutcomeState.failed:
      return outcome.reason.isEmpty
          ? '$what refused'
          : '$what refused: ${outcome.reason}';
    case StawiOutcomeState.accepted:
      return '$what accepted by settlement';
    case StawiOutcomeState.unspecified:
      return '$what updated';
  }
}

Uint8List _bytes(Object? value) {
  if (value is! String || value.isEmpty) return Uint8List(0);
  try {
    return base64.decode(base64.normalize(value));
  } on FormatException {
    return Uint8List(0);
  }
}

List<String> _strings(Object? value) =>
    value is List ? value.map((e) => '$e').toList() : const [];

DateTime? _time(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

/// A STAWI_AGENT_INVITATION, sent in a DM by the person converting a room to
/// the partner they want as its agent. The server stamps the room's name and
/// how long it can be accepted.
class StawiAgentInvitationView {
  const StawiAgentInvitationView({
    required this.roomId,
    required this.roomName,
    this.expiresAt,
  });

  factory StawiAgentInvitationView.fromContent(Map<String, dynamic> c) =>
      StawiAgentInvitationView(
        roomId: c['roomId'] as String? ?? '',
        roomName: c['roomName'] as String? ?? '',
        expiresAt: _time(c['expiresAt']),
      );

  /// The group room being converted.
  final String roomId;

  /// The room's name as chat holds it; empty until the server stamped it.
  final String roomName;

  /// Until when it can be accepted; null until the server stamped it.
  final DateTime? expiresAt;

  /// Whether it can still be accepted at [now].
  bool liveAt(DateTime now) => expiresAt != null && now.isBefore(expiresAt!);

  /// What the converter sends: the room only; chat fills in the rest.
  static Map<String, dynamic> content({required String roomId}) =>
      StawiPayloadCodec._json(pb.StawiAgentInvitationContent(roomId: roomId));
}

/// A STAWI_AGENT_ACCEPTANCE, sent in a DM by the invited partner. The server
/// stamps the room it names and how long the inviter may name them agent.
class StawiAgentAcceptanceView {
  const StawiAgentAcceptanceView({
    required this.invitationEventId,
    required this.roomId,
    required this.roomName,
    this.expiresAt,
  });

  factory StawiAgentAcceptanceView.fromContent(Map<String, dynamic> c) =>
      StawiAgentAcceptanceView(
        invitationEventId: c['invitationEventId'] as String? ?? '',
        roomId: c['roomId'] as String? ?? '',
        roomName: c['roomName'] as String? ?? '',
        expiresAt: _time(c['expiresAt']),
      );

  final String invitationEventId;
  final String roomId;
  final String roomName;

  /// Until when the inviter may name the acceptor agent.
  final DateTime? expiresAt;

  bool liveAt(DateTime now) => expiresAt != null && now.isBefore(expiresAt!);

  /// What the invited partner sends: the invitation accepted.
  static Map<String, dynamic> content({required String invitationEventId}) =>
      StawiPayloadCodec._json(
        pb.StawiAgentAcceptanceContent(invitationEventId: invitationEventId),
      );
}
