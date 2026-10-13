## 1.57.0

- Add `ChatService.GetDirectPartnerAccount` (`GetDirectPartnerAccountRequest`, `GetDirectPartnerAccountResponse`): the Stawi account of the other person in the caller's DM, once that person has taken part in it. Limited to 60 calls a minute per person (`RESOURCE_EXHAUSTED` beyond).
- Add `StawiRoomConversionContent.agentProfileId`: the room's optional Stawi agent, by profile.
- Add the agent invitation payloads, sent in a DM: `PAYLOAD_TYPE_STAWI_AGENT_INVITATION` (`StawiAgentInvitationContent`: `roomId`; server-set `roomName`, `expiresAt`) and `PAYLOAD_TYPE_STAWI_AGENT_ACCEPTANCE` (`StawiAgentAcceptanceContent`: `invitationEventId`; server-set `roomId`, `roomName`, `expiresAt`). A DM partner who is not a member of the room may be named its agent only after accepting an invitation for exactly that room.

## 1.56.0

- Add `Room.stawi` (`StawiRoomBinding`, `StawiRoomState`): a room's Stawi binding (state, genesis, chain id, custody and governance addresses, policy epoch, bound time), returned by `GetRoom`, `SearchRooms`, `CreateRoom` and `UpdateRoom` for every member.

## 1.55.0

- Add typed form request and form submission result payloads for schema-driven form messages.
- Regenerate the Dart SDK from the updated chat proto definitions.

## 1.54.0

- Generated Dart SDK from proto definitions
