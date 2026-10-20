import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../../auth/data/current_user_provider.dart';
import '../../messages/domain/room_event.dart';
import '../../rooms/data/room_providers.dart';
import '../../rooms/data/room_subscription_service.dart';
import '../data/stawi_account_service.dart' show stawiClockProvider;
import '../data/stawi_agent_invitations.dart';
import '../data/stawi_finance_service.dart';
import '../data/stawi_identity.dart';
import '../data/stawi_loan_service.dart';
import '../data/stawi_room_service.dart';
import '../data/stawi_timeline_providers.dart';
import '../domain/loan_view.dart';
import '../domain/personal_calls.dart' show LoanRef;
import '../domain/stawi_money.dart';
import '../domain/stawi_payloads.dart';
import 'genesis_review_dialog.dart';
import 'governance_sheet.dart';
import 'loan_detail_screen.dart';
import 'loan_vote.dart';
import 'my_money_screen.dart';
import 'room_money_screen.dart';
import 'room_setup_card.dart';
import 'stawi_feedback.dart';

/// The timeline widget for a Stawi event.
class StawiTimelineItem extends StatelessWidget {
  const StawiTimelineItem({required this.event, required this.isMe, super.key});

  final RoomEvent event;
  final bool isMe;

  @override
  Widget build(BuildContext context) => switch (event.type) {
    RoomEventType.stawiRoomConversion => GenesisCard(event: event),
    RoomEventType.stawiGenesisSignature ||
    RoomEventType.stawiSignedCall => StawiActBubble(event: event, isMe: isMe),
    RoomEventType.stawiCallOutcome => StawiOutcomeBubble(event: event),
    RoomEventType.financeCard => FinanceCardBubble(event: event),
    RoomEventType.stawiAgentInvitation => AgentInvitationCard(
      event: event,
      isMe: isMe,
    ),
    RoomEventType.stawiAgentAcceptance => AgentAcceptanceCard(
      event: event,
      isMe: isMe,
    ),
    _ => const SizedBox.shrink(),
  };
}

/// A conversion request; once chat has prepared it, the genesis card founders
/// sign from.
class GenesisCard extends ConsumerStatefulWidget {
  const GenesisCard({required this.event, super.key});

  final RoomEvent event;

  @override
  ConsumerState<GenesisCard> createState() => _GenesisCardState();
}

class _GenesisCardState extends ConsumerState<GenesisCard> {
  bool _signing = false;

  /// Checks the genesis on this device, shows the founder what they are
  /// signing, and signs only if they choose to. Cancelling signs nothing.
  Future<void> _sign() async {
    setState(() => _signing = true);
    try {
      final service = ref.read(stawiRoomServiceProvider);
      final prepared = await runStawiAction(
        context,
        () => service.prepareGenesisSignature(widget.event),
      );
      if (prepared == null || !mounted) return;
      final room = await ref
          .read(roomByIdProvider(widget.event.roomId).future)
          .catchError((Object _) => null);
      final roomName = (room?.name ?? '').isEmpty ? 'this room' : room!.name;
      // The name is held while it is read: an auto-disposed read is
      // disposed at its first await, and a name from the profile store (an
      // agent who is not a member) would always read as "Member".
      Future<String> nameOf(String profileId) async {
        final name = stawiMemberNameProvider((
          roomId: widget.event.roomId,
          profileId: profileId,
        ));
        final held = ref.listenManual(name, (_, _) {});
        try {
          return await ref.read(name.future);
        } on Object {
          return 'Member';
        } finally {
          held.close();
        }
      }

      final founderNames = [
        for (final f in prepared.genesis.founders) await nameOf(f.profileId),
      ];
      final agentId = prepared.genesis.agentProfileId;
      final agentName = agentId.isEmpty ? null : await nameOf(agentId);
      if (!mounted) return;
      final confirmed = await showGenesisReview(
        context,
        genesis: prepared.genesis,
        card: prepared.card,
        roomName: roomName,
        founderNames: founderNames,
        agentConfirmed: prepared.agentConfirmed,
        agentName: agentName,
        setupSteps: prepared.setupDigests.length,
        setupProblem: prepared.setupProblem,
      );
      if (!confirmed || !mounted) return;
      final signed = await runStawiAction(
        context,
        () => service.submitGenesisSignature(prepared, roomName: roomName),
        success: prepared.setupDigests.isEmpty
            ? 'Genesis signed'
            : 'Genesis and lending setup signed',
      );
      if (signed != null && signed.setupError != null && mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(setupNotSignedMessage(signed.setupError!))),
        );
      }
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final theme = Theme.of(context);
    final view = StawiConversionView.fromContent(event.content);
    final genesis = view.genesis;
    final outcomes =
        ref.watch(stawiOutcomesProvider(event.id)).asData?.value ??
        const <RoomEvent>[];
    final signatures =
        ref.watch(stawiGenesisSignaturesProvider(event.id)).asData?.value ??
        const <RoomEvent>[];
    final me = ref.watch(currentProfileIdProvider).asData?.value;
    final mySubscription = ref
        .watch(currentUserSubscriptionIdProvider(event.roomId))
        .asData
        ?.value;
    final phase = stawiRoomPhase(event, outcomes);
    final refusal = outcomes
        .map((o) => StawiOutcomeView.fromContent(o.content))
        .where((o) => o.state == StawiOutcomeState.failed)
        .lastOrNull;
    final signedByMe = signatures.any(
      (s) => s.senderId == mySubscription && s.status != EventStatus.failed,
    );
    final canSign =
        phase == StawiRoomPhase.awaitingSignatures &&
        genesis != null &&
        me != null &&
        genesis.isFounder(me) &&
        !signedByMe;

    final status = switch (phase) {
      StawiRoomPhase.active => 'On chain',
      StawiRoomPhase.awaitingSignatures =>
        'Awaiting founder signatures (${signatures.length} sent)',
      StawiRoomPhase.preparing => 'Preparing the genesis…',
      StawiRoomPhase.chatOnly =>
        refusal != null
            ? describeOutcome(refusal)
            : event.status == EventStatus.failed
            ? 'Not sent: ${event.errorMessage ?? 'refused'}'
            : 'Expired before the founders signed',
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          key: Key('genesis-card-${event.id}'),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Stawi room genesis',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _Line('Template', view.templateId),
                _Line(
                  'Joining',
                  view.joinPolicy == StawiJoinPolicy.public
                      ? 'Anyone, then admitted'
                      : 'By invitation',
                ),
                for (final rule in view.ruleValues.entries)
                  _Line(rule.key.replaceAll('_', ' '), rule.value),
                _Line(
                  'Founders',
                  '${genesis?.founderProfileIds.length ?? view.founderSubscriptionIds.length}',
                ),
                if (genesis != null) ...[
                  _Line('Genesis', shortHex(bytesToHex0x(genesis.genesisHash))),
                  _Line(
                    'Constitution',
                    shortHex(bytesToHex0x(genesis.constitutionHash)),
                  ),
                  if (genesis.expiresAt != null)
                    _Line(
                      'Sign by',
                      DateFormat.yMMMd().add_jm().format(
                        genesis.expiresAt!.toLocal(),
                      ),
                    ),
                ],
                const SizedBox(height: 8),
                Text(
                  status,
                  key: const Key('genesis-status'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: phase == StawiRoomPhase.chatOnly
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (canSign) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('genesis-open-review'),
                    onPressed: _signing ? null : _sign,
                    icon: const Icon(Icons.draw_outlined),
                    label: Text(_signing ? 'Signing…' : 'Review and sign'),
                  ),
                ],
                if (phase == StawiRoomPhase.active) ...[
                  const SizedBox(height: 8),
                  RoomSetupCard(
                    roomId: event.roomId,
                    roomName: _roomName(ref, event.roomId),
                  ),
                ],
                if (signedByMe && phase == StawiRoomPhase.awaitingSignatures)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('You signed', style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

/// A member's signed act (a genesis signature or a governance call), with
/// where it stands: sending, pending, accepted, confirmed or refused.
class StawiActBubble extends ConsumerWidget {
  const StawiActBubble({required this.event, required this.isMe, super.key});

  final RoomEvent event;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final outcomes =
        ref.watch(stawiOutcomesProvider(event.id)).asData?.value ??
        const <RoomEvent>[];
    final (:state, :reason) = resolveActState(event, outcomes);
    final title = event.type == RoomEventType.stawiGenesisSignature
        ? 'Signed the room genesis'
        : _callTitle(StawiSignedCallView.fromContent(event.content));

    final (icon, color, label) = switch (state) {
      StawiActState.sending => (
        Icons.schedule,
        theme.colorScheme.outline,
        'Sending',
      ),
      StawiActState.pending => (
        Icons.hourglass_top,
        theme.colorScheme.outline,
        'Pending',
      ),
      StawiActState.accepted => (
        Icons.sync,
        theme.colorScheme.primary,
        'Accepted, waiting for the chain',
      ),
      StawiActState.confirmed => (
        Icons.verified,
        theme.colorScheme.primary,
        'Confirmed on chain',
      ),
      StawiActState.refused => (
        Icons.block,
        theme.colorScheme.error,
        reason.isEmpty ? 'Refused' : 'Refused: $reason',
      ),
      StawiActState.notSent => (
        Icons.error_outline,
        theme.colorScheme.error,
        reason.isEmpty ? 'Not sent' : 'Not sent: $reason',
      ),
    };

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Card(
          key: Key('stawi-act-${event.id}'),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.draw_outlined, size: 18, color: color),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(title, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        key: const Key('stawi-act-state'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _callTitle(StawiSignedCallView call) =>
      call.summary.isNotEmpty ? call.summary : actLabel(call.kind);
}

/// What settlement or the chain said about an act, as a system line.
class StawiOutcomeBubble extends StatelessWidget {
  const StawiOutcomeBubble({required this.event, super.key});

  final RoomEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outcome = StawiOutcomeView.fromContent(event.content);
    final (icon, color) = switch (outcome.state) {
      StawiOutcomeState.observed => (Icons.verified, theme.colorScheme.primary),
      StawiOutcomeState.failed => (Icons.block, theme.colorScheme.error),
      StawiOutcomeState.accepted => (
        Icons.check_circle_outline,
        theme.colorScheme.onSurfaceVariant,
      ),
      StawiOutcomeState.unspecified => (
        Icons.info_outline,
        theme.colorScheme.onSurfaceVariant,
      ),
    };
    final tx = outcome.txHash.isEmpty
        ? ''
        : ' · tx ${shortHex(bytesToHex0x(outcome.txHash))}';
    return Center(
      child: Container(
        key: Key('stawi-outcome-${event.id}'),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${describeOutcome(outcome)}$tx',
                style: theme.textTheme.bodySmall?.copyWith(color: color),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Said when the genesis was signed but its lending setup was not.
String setupNotSignedMessage(Object why) =>
    'Genesis signed. The lending setup was not signed '
    '(${why is String ? why : stawiErrorMessage(why)}); once the room is on '
    'chain it asks a founder to sign it.';

/// A display-only card finance posted. A proposal card offers the signed
/// vote; nothing on a card authorizes anything by itself.
class FinanceCardBubble extends ConsumerWidget {
  const FinanceCardBubble({required this.event, super.key});

  final RoomEvent event;

  /// The card's data lines a person reads, as (label, value). Only what can
  /// be shown in words is: an amount in its asset when the card names one
  /// (else the title already states it, formatted), and a number of
  /// instalments. Ids, addresses, raw minor units and the record's counts
  /// are for the app.
  static List<(String, String)> shownLines(
    FinanceCardView card,
    StawiAssets assets,
  ) {
    final asset = card.data['asset_id'] ?? '';
    final amount = card.data['amount'] ?? '';
    final instalments = card.data['instalments'] ?? '';
    return [
      if (asset.isNotEmpty && amount.isNotEmpty)
        (
          'amount',
          formatMoney(finance.Money(assetId: asset, amount: amount), assets),
        ),
      if (RegExp(r'^[1-9][0-9]{0,4}$').hasMatch(instalments))
        ('instalments', instalments),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final card = FinanceCardView.fromContent(event.content);
    final proposalId = card.data['proposal_id'] ?? '';
    final offersVote =
        card.data['action'] == 'open_signing_flow' && proposalId.isNotEmpty;
    final assets = (card.data['asset_id'] ?? '').isEmpty
        ? StawiAssets.empty
        : watchRoomAssets(ref, event.roomId);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          key: Key('finance-card-${event.id}'),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      iconForCard(card.kind),
                      key: const Key('finance-card-icon'),
                      color: alarmingCard(card.kind)
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cardTitle(card),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                if (card.body.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(card.body, style: theme.textTheme.bodyMedium),
                ],
                for (final (label, value) in shownLines(card, assets))
                  _Line(label, value),
                if (card.opensLoan) ...[
                  const SizedBox(height: 8),
                  _OpenLoanButton(card: card, roomId: event.roomId),
                ],
                if (card.kind == roomSetupCardKind) ...[
                  const SizedBox(height: 8),
                  RoomSetupCard(
                    roomId: event.roomId,
                    roomName: _roomName(ref, event.roomId),
                  ),
                ],
                if (moneyCardAction(card) case final action?) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('finance-card-open-money'),
                    icon: Icon(action.icon),
                    label: Text(action.label),
                    onPressed: () =>
                        _openMoney(context, ref, event.roomId, action),
                  ),
                ],
                if (offersVote) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('finance-card-vote'),
                    icon: const Icon(Icons.how_to_vote_outlined),
                    label: const Text('Review and vote'),
                    onPressed: () =>
                        _openVote(context, ref, event.roomId, proposalId),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _openMoney(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    MoneyCardAction action,
  ) {
    final room = ref.read(roomByIdProvider(roomId)).asData?.value;
    final name = room == null || room.name.isEmpty ? 'this room' : room.name;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => action.roomMoney
            ? RoomMoneyScreen(roomId: roomId, roomName: name)
            : MyMoneyScreen(),
      ),
    );
  }

  static Future<void> _openVote(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    String proposalId,
  ) async {
    final proposal = await runStawiAction(
      context,
      () => ref.read(stawiFinanceServiceProvider).proposal(proposalId),
    );
    if (proposal == null || !context.mounted) return;
    if (proposal.onchainProposalId.toInt() <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The proposal is not on chain yet')),
      );
      return;
    }
    if (proposal.hasLoan()) {
      // A loan's vote moves the room's money: it is checked and reviewed
      // like a money call.
      final room = ref.read(roomByIdProvider(roomId)).asData?.value;
      await showLoanVoteSheet(
        context,
        roomId: roomId,
        roomName: room == null || room.name.isEmpty ? 'this room' : room.name,
        proposal: proposal,
        loanNumber: proposal.loan.loanId.toStringUnsigned(),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => GovernanceDialog(
        roomId: roomId,
        // A secret ballot is committed now and revealed after voting closes.
        action: proposal.ballot == finance.BallotMode.BALLOT_MODE_SECRET
            ? GovernanceAction.secretVote
            : GovernanceAction.vote,
        onchainProposalId: proposal.onchainProposalId.toInt(),
        revealClosesAt: proposal.hasRevealClosesAt()
            ? proposal.revealClosesAt.toDateTime()
            : null,
      ),
    );
  }
}

/// A finance card's icon by its kind.
IconData iconForCard(String kind) => switch (kind) {
  'PROPOSAL' || 'PROPOSAL_OPEN' => Icons.how_to_vote_outlined,
  'MOTION_TALLY' => Icons.poll_outlined,
  'LOAN_OFFERED' => Icons.volunteer_activism_outlined,
  'LOAN_REQUESTED' => Icons.request_quote_outlined,
  'LOAN_PAID_OUT' => Icons.payments_outlined,
  'LOAN_PAYMENT' => Icons.check_circle_outline,
  'LOAN_LATE' => Icons.schedule,
  'LOAN_DEFAULTED' => Icons.report_gmailerrorred,
  'LOAN_RECOVERED' => Icons.restore,
  'LOAN_REPAID' => Icons.verified_outlined,
  'LOAN_CLOSED' || 'LOAN_CLOSED_UNACCEPTED' => Icons.cancel_outlined,
  'CONTRIBUTION' || 'CONTRIBUTION_MISSED' => Icons.savings_outlined,
  'CONTRIBUTION_FAILED' => Icons.event_busy,
  'DUES_DUE' => Icons.event_note_outlined,
  'WITHDRAWAL' => Icons.outbox_outlined,
  'SHARE_OUT_COLLECTED' => Icons.redeem_outlined,
  'MONEY_RECEIVED' => Icons.call_received,
  'DEPOSIT' => Icons.savings_outlined,
  roomSetupCardKind => Icons.construction_outlined,
  _ when kind.startsWith('LOAN') => Icons.request_quote_outlined,
  _ => Icons.account_balance_outlined,
};

/// A room's lending setup card ("Setting up lending: vote 1 of 3").
const String roomSetupCardKind = 'ROOM_SETUP';

/// Where a money card's button goes: the room's money (its dues on the
/// Savings tab), or the person's own money (savings, wallet).
typedef MoneyCardAction = ({String label, IconData icon, bool roomMoney});

/// The button a money card offers by its data `action`; null for none.
MoneyCardAction? moneyCardAction(FinanceCardView card) =>
    switch (card.data['action']) {
      'open_dues' => (
        label: 'See my dues',
        icon: Icons.event_note_outlined,
        roomMoney: true,
      ),
      'open_money' => (
        label: 'Open the room\'s money',
        icon: Icons.account_balance_outlined,
        roomMoney: true,
      ),
      'open_savings' => (
        label: 'Open my savings',
        icon: Icons.savings_outlined,
        roomMoney: false,
      ),
      'open_wallet' => (
        label: 'Open my wallet',
        icon: Icons.account_balance_wallet_outlined,
        roomMoney: false,
      ),
      _ => null,
    };

/// Whether a card's kind is shown in the error colour: something went wrong
/// with the person's money.
bool alarmingCard(String kind) =>
    const {'LOAN_LATE', 'LOAN_DEFAULTED', 'CONTRIBUTION_FAILED'}.contains(kind);

/// A card's title as shown: finance's, except a missed contribution, which
/// reads "Contribution missed".
String cardTitle(FinanceCardView card) =>
    card.kind == 'CONTRIBUTION_FAILED' ? 'Contribution missed' : card.title;

/// The loan a card names, read once per loan for the session: a timeline
/// scrolling past its cards does not read the loan again for each. Null
/// when it cannot be read (the card then offers Open loan).
final cardLoanProvider = FutureProvider.family<finance.Loan?, LoanRef>((
  ref,
  loanRef,
) async {
  try {
    return (await ref.watch(stawiLoanServiceProvider).loan(loanRef)).loan;
  } on Object {
    return null;
  }
});

/// Opens the loan a card names. On an offer or an ask, the person it waits
/// for (the borrower of an offer, the lender of an ask) sees Review instead;
/// both open the loan's page, where it is decided. That page names the other
/// person by the loan's counterparty account, never by this room.
class _OpenLoanButton extends ConsumerWidget {
  const _OpenLoanButton({required this.card, required this.roomId});

  final FinanceCardView card;
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanRef = card.loanRef!;
    var review = false;
    if (card.kind == 'LOAN_OFFERED' || card.kind == 'LOAN_REQUESTED') {
      final loan = ref.watch(cardLoanProvider(loanRef)).asData?.value;
      final mine = ref.watch(stawiIdentityProvider).asData?.value.addresses;
      review =
          loan != null && mine != null && LoanView(loan, mine: mine).awaitsMe;
    }
    return OutlinedButton.icon(
      key: const Key('finance-card-open-loan'),
      icon: Icon(review ? Icons.rate_review_outlined : Icons.open_in_new),
      label: Text(review ? 'Review' : 'Open loan'),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          // The page names the other person by the loan's own account.
          builder: (_) => LoanDetailScreen(ref: loanRef, roomId: roomId),
        ),
      ),
    );
  }
}

/// The room's name, or "this room".
String _roomName(WidgetRef ref, String roomId) {
  final room = ref.watch(roomByIdProvider(roomId)).asData?.value;
  return room == null || room.name.isEmpty ? 'this room' : room.name;
}

/// "until 20 Oct, 14:05" in local time.
String _until(DateTime t) => DateFormat('d MMM, HH:mm').format(t.toLocal());

/// The name a DM's partner is shown by in its own timeline.
String _partnerName(WidgetRef ref, String dmRoomId) {
  final room = ref.watch(roomByIdProvider(dmRoomId)).asData?.value;
  return room == null || room.name.isEmpty ? 'They' : room.name;
}

/// An agent invitation in a DM. The invited partner (not its sender) sees
/// Accept while it can still be accepted and they have not accepted it;
/// accepting sends STAWI_AGENT_ACCEPTANCE naming it.
class AgentInvitationCard extends ConsumerStatefulWidget {
  const AgentInvitationCard({
    required this.event,
    required this.isMe,
    super.key,
  });

  final RoomEvent event;
  final bool isMe;

  @override
  ConsumerState<AgentInvitationCard> createState() =>
      _AgentInvitationCardState();
}

class _AgentInvitationCardState extends ConsumerState<AgentInvitationCard> {
  bool _sending = false;

  Future<void> _accept() async {
    if (_sending) return;
    setState(() => _sending = true);
    await runStawiAction(
      context,
      () =>
          acceptAgentInvitation(ref.read(agentActSenderProvider), widget.event),
      success: 'Accepted; they can now name you the room\'s agent',
    );
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = widget.event;
    final invitation = StawiAgentInvitationView.fromContent(event.content);
    final room = invitation.roomName.isEmpty ? 'a room' : invitation.roomName;
    final now = ref.watch(stawiClockProvider)();
    final live = invitation.liveAt(now);
    final accepted =
        ref
            .watch(
              agentInvitationAcceptedProvider((
                dmRoomId: event.roomId,
                invitationEventId: event.id,
              )),
            )
            .asData
            ?.value ??
        false;
    final who = _partnerName(ref, event.roomId);
    final expires = invitation.expiresAt;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          key: Key('agent-invitation-${event.id}'),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isMe
                            ? 'You invited $who to be the Stawi agent of $room'
                            : '$who invited you to be the Stawi agent of $room',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'An agent receives part of the Stawi fee on the room\'s '
                  'income. Accepting lets the room\'s founders see your '
                  'Stawi account address.',
                  style: theme.textTheme.bodySmall,
                ),
                if (expires != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      accepted
                          ? 'Accepted'
                          : live
                          ? 'Can be accepted until ${_until(expires)}'
                          : 'Expired',
                      key: const Key('agent-invitation-state'),
                    ),
                  ),
                if (!widget.isMe && live && !accepted) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      key: const Key('agent-invitation-accept'),
                      onPressed: _sending ? null : _accept,
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An acceptance of an agent invitation in a DM: the inviter may name the
/// acceptor agent of the room until it expires.
class AgentAcceptanceCard extends ConsumerWidget {
  const AgentAcceptanceCard({
    required this.event,
    required this.isMe,
    super.key,
  });

  final RoomEvent event;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final a = StawiAgentAcceptanceView.fromContent(event.content);
    final room = a.roomName.isEmpty ? 'the room' : a.roomName;
    final now = ref.watch(stawiClockProvider)();
    final expires = a.expiresAt;
    final who = _partnerName(ref, event.roomId);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          key: Key('agent-acceptance-${event.id}'),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Icon(
              Icons.verified_user_outlined,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              isMe
                  ? 'You accepted being agent for $room'
                  : '$who accepted being agent for $room',
            ),
            subtitle: expires == null
                ? null
                : Text(
                    a.liveAt(now)
                        ? 'Can be named agent until ${_until(expires)}'
                        : 'Expired',
                    key: const Key('agent-acceptance-state'),
                  ),
          ),
        ),
      ),
    );
  }
}
