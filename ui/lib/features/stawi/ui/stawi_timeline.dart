import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../../auth/data/current_user_provider.dart';
import '../../messages/domain/room_event.dart';
import '../../rooms/data/room_providers.dart';
import '../../rooms/data/room_subscription_service.dart';
import '../data/stawi_finance_service.dart';
import '../data/stawi_identity.dart';
import '../data/stawi_loan_service.dart';
import '../data/stawi_room_service.dart';
import '../data/stawi_timeline_providers.dart';
import '../domain/loan_view.dart';
import '../domain/stawi_money.dart';
import '../domain/stawi_payloads.dart';
import 'governance_sheet.dart';
import 'loan_detail_screen.dart';
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

  Future<void> _sign() async {
    setState(() => _signing = true);
    await runStawiAction(context, () async {
      final room = await ref
          .read(roomByIdProvider(widget.event.roomId).future)
          .catchError((Object _) => null);
      final name = room?.name ?? '';
      return ref
          .read(stawiRoomServiceProvider)
          .signGenesis(
            widget.event,
            roomName: name.isEmpty ? 'this room' : name,
          );
    }, success: 'Genesis signed');
    if (mounted) setState(() => _signing = false);
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
                    key: const Key('genesis-sign'),
                    onPressed: _signing ? null : _sign,
                    icon: const Icon(Icons.draw_outlined),
                    label: Text(_signing ? 'Signing…' : 'Sign as founder'),
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

/// A display-only card finance posted. A proposal card offers the signed
/// vote; nothing on a card authorizes anything by itself.
class FinanceCardBubble extends ConsumerWidget {
  const FinanceCardBubble({required this.event, super.key});

  final RoomEvent event;

  /// Data a card carries for the app, not for the person: ids, the loan's
  /// address and number, and the record's raw counts.
  static const _hidden = {
    'action',
    'payload_hash',
    'asset_id',
    'loan_book',
    'pool',
    'loan_id',
    'kind',
    'event',
    'instalment',
    'record_loans',
    'record_late',
    'record_defaults',
  };

  /// A data value as shown: an amount in its asset when the card names one.
  static String _shown(
    FinanceCardView card,
    String key,
    String value,
    StawiAssets assets,
  ) {
    final asset = card.data['asset_id'] ?? '';
    return key == 'amount' && asset.isNotEmpty
        ? formatMoney(finance.Money(assetId: asset, amount: value), assets)
        : value;
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
                for (final entry in card.data.entries.where(
                  (e) => !_hidden.contains(e.key),
                ))
                  _Line(
                    entry.key.replaceAll('_', ' '),
                    _shown(card, entry.key, entry.value, assets),
                  ),
                if (card.opensLoan) ...[
                  const SizedBox(height: 8),
                  _OpenLoanButton(card: card, roomId: event.roomId),
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
  'CONTRIBUTION' || 'CONTRIBUTION_MISSED' => Icons.savings_outlined,
  'CONTRIBUTION_FAILED' => Icons.event_busy,
  _ when kind.startsWith('LOAN') => Icons.request_quote_outlined,
  _ => Icons.account_balance_outlined,
};

/// Whether a card's kind is shown in the error colour: something went wrong
/// with the person's money.
bool alarmingCard(String kind) =>
    const {'LOAN_LATE', 'LOAN_DEFAULTED', 'CONTRIBUTION_FAILED'}.contains(kind);

/// A card's title as shown: finance's, except a missed contribution, which
/// reads "Contribution missed".
String cardTitle(FinanceCardView card) =>
    card.kind == 'CONTRIBUTION_FAILED' ? 'Contribution missed' : card.title;

/// Opens the loan a card names. On an offer or an ask, the person it waits
/// for (the borrower of an offer, the lender of an ask) sees Review instead;
/// both open the loan's page, where it is decided.
class _OpenLoanButton extends ConsumerWidget {
  const _OpenLoanButton({required this.card, required this.roomId});

  final FinanceCardView card;
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanRef = card.loanRef!;
    var review = false;
    if (card.kind == 'LOAN_OFFERED' || card.kind == 'LOAN_REQUESTED') {
      final loan = ref.watch(loanProvider(loanRef)).asData?.value.loan;
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
          builder: (_) => LoanDetailScreen(ref: loanRef, roomId: roomId),
        ),
      ),
    );
  }
}
