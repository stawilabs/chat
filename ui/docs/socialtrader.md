# Trading groups (socialtrader module)

`ui/lib/features/socialtrader` makes a chat group a trading group: a room bound
to a socialtrader strategy pool. The socialtrader service indexes the pool and
prepares every transaction; the connected wallet signs; the app never holds a
private key and never submits anything without a tap.

## Flows

**Join.** A member is added to a bound room → the service posts a
`pool_join_prompt` card → on the member's first visit the room offers
`JoinPoolSheet` once (`PoolJoinPromptGate`, flag in `pool_prompt_dismissals`);
the card stays. The amount is pre-filled from `CommitmentSettings`; "Commit"
calls `PreparePoolDeposit(pool, assets, receiver: wallet)` and asks the wallet
to sign and send the calldata. A wallet error keeps the amount; nothing retries
by itself. Members holding shares are not prompted.

**Leave.** A member holding shares is removed → `pool_leave_prompt` card. The
card names only the pool and the redeem path: a room card never reveals a
member's position, so the bubble and `LeavePoolSheet` load the viewer's own
shares and value through the authenticated `GetMembership` call, whose
`preview_assets`/`preview_fee` give the exact payout and fee of redeeming now
(the sheet falls back to the fee-rate note when the service has no preview);
"Redeem"
calls `PreparePoolRedeem` for all shares and signs. `queued_shares > 0` explains
that queued shares settle when the leader sells inventory or quote arrives.

**Pool tab.** `/room/:roomId/pool` (header chip) and the room detail panel's
third tab: value, NAV series (`GetPoolPerformance`, tier badge green only for
`finalized`), members and the person's stake, recent fills (from `pool_fill`
cards), queued redeems; "Leader actions" only when the connected or linked
wallet is the pool's leader.

**Leader trading.** `LeaderTradeSheet`: Limit/IOC, Buy/Sell, price pre-filled
from the book's best opposite level (`GetBook`), size, hint price from the same
side for limit orders; cancel by id, claim filled orders, sell inventory for
redeems (shown while shares are queued). Each button → `PrepareLeaderOrder` →
sign. "Settle queue" (permissionless, `KIND_SETTLE_QUEUE`, ten items a call)
pays queued redeems from free quote. The contract enforces `onlyLeader` on
the leader-only calls.

**Settings.** `/settings/trading`: connect or forget the wallet (read-only
address on devices without a signer), link the wallet to the profile (SIWE:
`IssueNonce` → `personal_sign` → `LinkWallet`), default commitment.

**Creating a trading group.** `GroupDetailsScreen` shows a "Trading group"
toggle only when the service announces `socialtrader_create_pool` under
`capabilities` in `GET /v1/system/capabilities`. On create the pool is made first for the room's
id (`PoolService.CreatePool`, executed by the service with its pool-creator
key, the leader being the caller's linked wallet), then the room is created
with `socialtrader.pool_id`, which the chat server accepts only from the pool's
leader.

## Cards

A card is a `TEXT` message in the `json` format: `{"socialtrader": {"kind":
"pool_join_prompt" | "pool_leave_prompt" | "pool_nav" | "pool_fill", "v": 1,
"pool": "0x…", ...}}` (`PoolCard.tryParse`). `PoolCardBubble` renders a card
only when the event was posted by the service (it has no sending
subscription; the server refuses member messages in a card's shape), names
the room's bound pool, and that pool is in `ListPools`; anything else is shown
as plain text. The Pool tab's fills are the service-posted fill cards about the
bound pool (the service API has no fills call yet).
Forward, reply and notification previews use the card's summary.

## Environment

| define | default | meaning |
|---|---|---|
| `SOCIALTRADER_URL` | `https://socialtrader.stawi.org` | the socialtrader service (PoolService, LinkService, MarketService, capabilities) |
| `WALLETCONNECT_PROJECT_ID` | empty | read for the non-web signer. The WalletConnect SDK is not bundled yet: non-web builds stay read-only (paste an address to follow a pool) and say that signing needs the web build with a browser wallet |

Web signs through the injected EIP-1193 provider (`wallet_platform_web.dart`),
switching the wallet to the prepared transaction's chain first.

## Generated clients

`data/gen` is `buf generate` output from the socialtrader repository's `proto/`
directory (`proto/buf.gen.socialtrader.dart.yaml` at the repository root);
well-known-type copies and `.pbserver.dart` files are removed after generating.
Regenerate when the service's protos change; a BSR push replaces this with a
published package.

## Tests

`test/features/socialtrader/**`: domain (card codec, settings, wallet) and
widget tests for every sheet and screen in their loading, empty, error and
ready states, over `FakeSocialTraderApi` and `FakeWalletPlatform`
(`test/features/socialtrader/support`).
