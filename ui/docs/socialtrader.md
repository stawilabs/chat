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
calls `PreparePoolDeposit(pool, assets, receiver: wallet, min_shares)` and asks
the wallet to sign and send the calldata; `min_shares` is 99% of the shares the
pool's current NAV previews (`assets * totalShares / nav`, exact decimal
arithmetic in `domain/slippage.dart`), so a NAV move before inclusion cannot
mint far fewer than shown. A wallet error keeps the amount; nothing retries
by itself. Members holding shares are not prompted.

**Leave.** A member holding shares is removed → `pool_leave_prompt` card. The
card names only the pool and the redeem path: a room card never reveals a
member's position, so the bubble and `LeavePoolSheet` load the viewer's own
shares and value through the authenticated `GetMembership` call, whose
`preview_assets`/`preview_fee` give the exact payout and fee of redeeming now
(the sheet falls back to the fee-rate note when the service has no preview);
"Redeem"
calls `PreparePoolRedeem` for all shares with `min_assets` at 99% of
`preview_assets` and signs. `queued_shares > 0` explains
that queued shares settle when the leader sells inventory or quote arrives.

**Pool tab.** `/room/:roomId/pool` (header chip) and the room detail panel's
third tab: value, NAV per share with the pool's mark price, NAV series
(`GetPoolPerformance`, tier badge green only for `finalized`), members and the
person's stake, recent fills (from `pool_fill` cards), queued redeems with
"Cancel pool order for redeems" (permissionless `KIND_CANCEL_FOR_REDEEMS`, any
member with queued redeems, by order id; `KIND_CRYSTALLIZE_FEE` is never called
from the app); "Leader actions" only when the connected or linked
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
| `WALLETCONNECT_PROJECT_ID` | empty | Reown AppKit (WalletConnect v2) project id. Set: Android, iOS and desktop sign through a wallet app. Empty: those platforms stay read-only (paste an address to follow a pool) and say that signing needs the web build or a project id. Never commit it; CI passes it with `--dart-define` |
| `STAWI_RPC_URL` / `STAWI_EXPLORER_URL` | Sonic testnet | what a wallet app is told when it has to add the chain (`wallet_addEthereumChain`) |

Web signs through the injected EIP-1193 provider (`wallet_platform_web.dart`),
switching the wallet to the prepared transaction's chain first.

## WalletConnect (Android, iOS, desktop)

`WalletPlatform` on non-web builds is `WalletConnectPlatform` over the
`WalletConnectFacade` interface, implemented by `ReownAppKitFacade`
(`reown_appkit`). `connect()` opens the AppKit modal from the app's root
navigator (`walletConnectNavigatorKey`, installed by `app/router.dart`) and
keeps the session (address, chain, topic); `sendPrepared` asks the wallet to
switch (or add, then switch) to the prepared transaction's chain when the
session is elsewhere, then sends `eth_sendTransaction`; the wallet-link flow
signs the SIWE message with `personal_sign`; `disconnect()` ends the session.
Keys never leave the wallet app. Tests drive `WalletConnectPlatform` against
`FakeWalletConnectFacade` (`test/features/socialtrader/support`).

Setup per platform:

- **Android** (`android/app/src/main/AndroidManifest.xml`, done): a
  `<queries>` block so the picker can detect installed wallets and open
  `https` links, and an intent filter on the main activity for the redirect
  `org.stawi.chat://wc`. If the build complains about the NDK, pin
  `ndkVersion` to the version the package's README names.
- **iOS** (`ios/Runner/Info.plist`, to apply when the iOS runner is generated):
  `platform :ios, '13.0'` as the first line of `ios/Podfile`, then
  `pod install`; add `CFBundleURLTypes` with `CFBundleURLSchemes` containing
  `org.stawi.chat` (the redirect `org.stawi.chat://wc`), and
  `LSApplicationQueriesSchemes` with the wallet schemes the picker may open
  (`metamask`, `trust`, `safe`, `rainbow`, `zerion`, `ledgerlive`, at most 50
  entries). The Reown project's dashboard must list the redirect
  `org.stawi.chat://wc` as the app's native link.
- **Desktop**: the modal shows a QR code; no platform setup.
- **Web**: unaffected; the injected provider is used.

The dependency overrides in `pubspec.yaml` (`cupertino_icons`,
`cached_network_image`, `package_info_plus`) exist only because `reown_appkit`
1.9 pins older majors than the app uses; drop them when it catches up.

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
