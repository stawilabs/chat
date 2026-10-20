import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../data/stawi_account_service.dart';
import '../data/stawi_custody.dart';
import '../data/stawi_finance_service.dart';
import '../data/stawi_identity.dart';
import '../data/stawi_loan_service.dart';
import '../data/stawi_room_engines.dart';
import '../data/stawi_room_service.dart';
import '../data/stawi_timeline_providers.dart';
import '../domain/account_engine_calls.dart';
import '../domain/governance_requests.dart';
import '../domain/loan_view.dart';
import '../domain/personal_calls.dart' show LoanRef;
import '../domain/signing_checks.dart' show SigningRefused, bytesEqual;
import '../domain/stawi_money.dart';
import 'group_loan_request_screen.dart';
import 'loan_vote.dart';
import 'loan_widgets.dart';
import 'money_review_sheet.dart';
import 'protocol_fee_line.dart';
import 'room_money_screen.dart' show AccountEngineDialog;
import 'stawi_feedback.dart';

/// The note on a group instalment: it is a contribution, applied by the
/// room's rules.
const String groupInstalmentNote =
    "This is paid into the room. The room's rules pay your dues and penalties "
    'first, then this loan.';

bool _pending(finance.Loan l) =>
    l.state == finance.LoanState.LOAN_STATE_PENDING_APPROVAL ||
    l.state == finance.LoanState.LOAN_STATE_SUBMITTED;

/// A room's loans: the loan types it offers in plain words, others' requests
/// waiting for approval (with their record, for those who decide), the
/// person's own loans with what they can do, and everyone else's.
class RoomLoansTab extends ConsumerWidget {
  const RoomLoansTab({
    required this.roomId,
    this.roomName = 'the room',
    super.key,
  });

  final String roomId;
  final String roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(stawiLoansProvider(roomId));
    final identity = ref.watch(stawiIdentityProvider).asData?.value;
    final mine = identity?.addresses ?? const <Uint8List>[];
    bool isMine(finance.Loan l) =>
        mine.any((a) => bytesEqual(a, l.borrowerAccount));
    return RefreshIndicator(
      onRefresh: () {
        // The fee and the loan types are read again with the loans.
        ref
          ..invalidate(roomProtocolFeeProvider(roomId))
          ..invalidate(roomProductsProvider(roomId));
        return ref.refresh(stawiLoansProvider(roomId).future);
      },
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: RoomProtocolFeeLine(roomId: roomId),
          ),
          const _Heading('Loan types'),
          _LoanTypes(roomId: roomId, roomName: roomName),
          ...loans.when(
            loading: () => const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(stawiErrorMessage(e)),
              ),
            ],
            data: (all) {
              final pending = [
                for (final l in all)
                  if (_pending(l) && !isMine(l)) l,
              ];
              final my = [
                for (final l in all)
                  if (isMine(l)) l,
              ];
              final others = [
                for (final l in all)
                  if (!_pending(l) && !isMine(l)) l,
              ];
              Widget section(String key, String empty, List<Widget> items) =>
                  Column(
                    key: Key(key),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: items.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(empty),
                            ),
                          ]
                        : items,
                  );
              return [
                const _Heading('Waiting for approval'),
                section('loans-pending', 'No requests waiting', [
                  for (final l in pending)
                    _PendingLoan(
                      key: Key('pending-loan-${l.onchainLoanId}'),
                      roomId: roomId,
                      roomName: roomName,
                      loan: l,
                    ),
                ]),
                const _Heading('My loans in this room'),
                section('loans-mine', 'You have no loans here', [
                  for (final l in my)
                    _MyGroupLoan(
                      key: Key('my-loan-${l.onchainLoanId}'),
                      roomId: roomId,
                      roomName: roomName,
                      loan: l,
                    ),
                ]),
                const _Heading('All loans'),
                section('loans-all', 'No other loans', [
                  for (final l in others)
                    Column(
                      key: Key('room-loan-${l.onchainLoanId}'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          title: Text(
                            '${_borrowerName(ref, roomId, l)} · '
                            '${formatMoney(l.requested, watchRoomAssets(ref, roomId))}',
                          ),
                          trailing: Text(LoanView(l, mine: mine).stateLabel),
                        ),
                        if (l.state == finance.LoanState.LOAN_STATE_DEFAULTED)
                          _DefaultedLoanActions(roomId: roomId, loan: l),
                      ],
                    ),
                ]),
                const SizedBox(height: 24),
              ];
            },
          ),
        ],
      ),
    );
  }
}

/// The borrower of [loan] by name, from the room's members.
String _borrowerName(WidgetRef ref, String roomId, finance.Loan loan) {
  final members = ref.watch(stawiMembersProvider(roomId)).asData?.value;
  final member = members
      ?.where((m) => bytesEqual(m.accountAddress, loan.borrowerAccount))
      .firstOrNull;
  if (member == null || member.profileId.isEmpty) return 'A member';
  return ref
          .watch(
            stawiMemberNameProvider((
              roomId: roomId,
              profileId: member.profileId,
            )),
          )
          .asData
          ?.value ??
      'A member';
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// One card per loan form, in plain words, each with a Request button.
class _LoanTypes extends ConsumerWidget {
  const _LoanTypes({required this.roomId, required this.roomName});

  final String roomId;
  final String roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(roomProductsProvider(roomId))
      .when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        ),
        error: (e, _) => Padding(
          key: const Key('loans-types'),
          padding: const EdgeInsets.all(16),
          child: Text(stawiErrorMessage(e)),
        ),
        data: (products) {
          final assets = watchRoomAssets(ref, roomId).withAll(products.assets);
          final cal = RoomCalendarLabel.of(
            products.hasCalendar() ? products.calendar : null,
          );
          return Column(
            key: const Key('loans-types'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: products.loanProducts.isEmpty
                ? const [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text('This room offers no loans yet.'),
                    ),
                  ]
                : [
                    for (final p in products.loanProducts)
                      Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(plainLoanType(p, assets, cal)),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  key: Key(
                                    'loan-type-request-'
                                    '${bytesToHex0x(p.productId)}',
                                  ),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => GroupLoanRequestScreen(
                                        roomId: roomId,
                                        roomName: roomName,
                                        product: p,
                                      ),
                                    ),
                                  ),
                                  child: const Text('Request'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
          );
        },
      );
}

/// Whether the person may approve the room's loans, as far as it is known.
enum _Approver { loading, unknown, officer, member }

/// An officer is a member whose chain-granted roles hold CAP_LEND (finance's
/// Member.capabilities, the mask the LoanBook checks). Unknown when the
/// members could not be read: then neither Approve nor Guarantee is offered.
_Approver _approver(WidgetRef ref, String roomId) {
  final me = ref.watch(stawiIdentityProvider);
  final members = ref.watch(stawiMembersProvider(roomId));
  if (members.hasError || me.hasError) return _Approver.unknown;
  final who = me.asData?.value;
  final list = members.asData?.value;
  if (who == null || list == null) return _Approver.loading;
  final member = list
      .where(
        (m) =>
            m.profileId == who.profileId ||
            who.addresses.any((a) => bytesEqual(a, m.accountAddress)),
      )
      .firstOrNull;
  return member != null &&
          member.capabilities.contains(
            finance.RoomCapability.ROOM_CAPABILITY_LEND,
          )
      ? _Approver.officer
      : _Approver.member;
}

/// The vote on a loan the room decides by vote, on the proposal finance
/// names for it: Yes or No, each prepared, checked against the room's
/// governance, reviewed and signed (loan_vote.dart). Said so while it has
/// not opened.
class _LoanVote extends ConsumerWidget {
  const _LoanVote({
    required this.roomId,
    required this.roomName,
    required this.loan,
  });

  final String roomId;
  final String roomName;
  final finance.Loan loan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (roomId: roomId, loan: loan);
    final id = loan.onchainLoanId;
    return ref
        .watch(stawiLoanVoteProvider(key))
        .when(
          loading: () => const Text('Finding the vote…'),
          error: (e, _) => Row(
            children: [
              Expanded(child: Text(stawiErrorMessage(e))),
              TextButton(
                key: Key('loan-$id-vote-retry'),
                onPressed: () => ref.invalidate(stawiLoanVoteProvider(key)),
                child: const Text('Try again'),
              ),
            ],
          ),
          data: (proposal) {
            final number = proposal?.onchainProposalId.toInt() ?? 0;
            if (proposal == null || number <= 0) {
              return Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    "The vote hasn't opened yet",
                    key: Key('loan-$id-vote-pending'),
                  ),
                  _ProposeButton(
                    key: Key('loan-$id-open-vote'),
                    roomId: roomId,
                    label: 'Open the vote',
                    icon: Icons.how_to_vote_outlined,
                    request: () => openLoanVoteRequest(
                      loan,
                      borrower: _borrowerName(ref, roomId, loan),
                    ),
                    onDone: () => ref.invalidate(stawiLoanVoteProvider(key)),
                  ),
                ],
              );
            }
            return Align(
              key: Key('loan-$id-vote'),
              alignment: Alignment.centerLeft,
              child: LoanVoteButtons(
                roomId: roomId,
                roomName: roomName,
                proposal: proposal,
                loanNumber: '$id',
                onVoted: () => ref.invalidate(stawiLoanVoteProvider(key)),
              ),
            );
          },
        );
  }
}

/// Whether a loan of [product] for [loan]'s amount is decided by the room's
/// vote: the form names no officers and the amount is above what it
/// approves by itself (rules.DecidedByVote).
bool _byVote(finance.RoomLoanProduct product, finance.Loan loan) {
  if (product.officerApprovals != 0) return false;
  final below = BigInt.tryParse(product.autoApproveBelow.amount) ?? BigInt.zero;
  final amount = BigInt.tryParse(loan.requested.amount) ?? BigInt.zero;
  return amount > below;
}

bool _decidedByVote(WidgetRef ref, String roomId, finance.Loan loan) {
  final product = ref
      .watch(roomProductsProvider(roomId))
      .asData
      ?.value
      .loanProducts
      .where((p) => bytesEqual(p.productId, loan.productId))
      .firstOrNull;
  return product != null && _byVote(product, loan);
}

/// A signed proposal from the loans tab: prepared with settlement, checked
/// on the device against the room's contracts, reviewed, then signed.
class _ProposeButton extends ConsumerStatefulWidget {
  const _ProposeButton({
    required this.roomId,
    required this.label,
    required this.icon,
    required this.request,
    this.onDone,
    this.outlined = false,
    super.key,
  });

  final String roomId;
  final String label;
  final IconData icon;

  /// The act, built when tapped (null: the person cancelled choosing it).
  final FutureOr<GovernanceRequest?> Function() request;
  final VoidCallback? onDone;
  final bool outlined;

  @override
  ConsumerState<_ProposeButton> createState() => _ProposeButtonState();
}

class _ProposeButtonState extends ConsumerState<_ProposeButton> {
  bool _busy = false;

  Future<void> _go() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final sent = await proposeFromLoans(
        context,
        ref,
        roomId: widget.roomId,
        request: widget.request,
      );
      if (sent) widget.onDone?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => widget.outlined
      ? OutlinedButton.icon(
          icon: Icon(widget.icon),
          label: Text(widget.label),
          onPressed: _busy ? null : _go,
        )
      : FilledButton.tonalIcon(
          icon: Icon(widget.icon),
          label: Text(widget.label),
          onPressed: _busy ? null : _go,
        );
}

/// Prepares, checks, reviews and signs the proposal [request] builds; true
/// once it was sent.
Future<bool> proposeFromLoans(
  BuildContext context,
  WidgetRef ref, {
  required String roomId,
  required FutureOr<GovernanceRequest?> Function() request,
}) async {
  final service = ref.read(stawiRoomServiceProvider);
  final GovernanceRequest? chosen;
  try {
    chosen = await request();
  } on SigningRefused catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(e.reason)));
    }
    return false;
  }
  if (chosen == null || !context.mounted) return false;
  final prepared = await runStawiAction(
    context,
    () => service.prepareAct(roomId: roomId, request: chosen!),
  );
  if (prepared == null || !context.mounted) return false;
  if (!await showMoneyReview(context, prepared.review) || !context.mounted) {
    return false;
  }
  final sent = await runStawiAction(
    context,
    () => service.submitAct(prepared),
    success: prepared.review.done,
  );
  return sent != null;
}

/// A loan in default: any member of the room on chain may propose writing it
/// off or restructuring it; the room votes, and settlement applies it.
class _DefaultedLoanActions extends ConsumerWidget {
  const _DefaultedLoanActions({required this.roomId, required this.loan});

  final String roomId;
  final finance.Loan loan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final who = _approver(ref, roomId);
    if (who != _Approver.member && who != _Approver.officer) {
      return const SizedBox.shrink();
    }
    final id = loan.onchainLoanId;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _ProposeButton(
            key: Key('loan-$id-write-off'),
            roomId: roomId,
            label: 'Propose a write-off',
            icon: Icons.delete_sweep_outlined,
            outlined: true,
            request: () => writeOffRequest(loan),
          ),
          _ProposeButton(
            key: Key('loan-$id-restructure'),
            roomId: roomId,
            label: 'Propose a restructure',
            icon: Icons.event_repeat_outlined,
            outlined: true,
            request: () => _askRestructure(context, loan),
          ),
        ],
      ),
    );
  }
}

/// Asks how a defaulted loan is to be repaid from now: instalments and the
/// interest per instalment. Null when cancelled.
Future<GovernanceRequest?> _askRestructure(
  BuildContext context,
  finance.Loan loan,
) async {
  final terms = await showDialog<({int instalments, int rateBps})>(
    context: context,
    builder: (_) => _RestructureDialog(loan: loan),
  );
  if (terms == null) return null;
  return restructureRequest(
    loan,
    instalments: terms.instalments,
    rateBps: terms.rateBps,
  );
}

class _RestructureDialog extends StatefulWidget {
  const _RestructureDialog({required this.loan});

  final finance.Loan loan;

  @override
  State<_RestructureDialog> createState() => _RestructureDialogState();
}

class _RestructureDialogState extends State<_RestructureDialog> {
  late final _instalments = TextEditingController(
    text: widget.loan.instalments > 0 ? '${widget.loan.instalments}' : '',
  );
  final _rate = TextEditingController(text: '0');
  String? _error;

  @override
  void dispose() {
    _instalments.dispose();
    _rate.dispose();
    super.dispose();
  }

  void _review() {
    final n = int.tryParse(_instalments.text.trim());
    final bps = int.tryParse(_rate.text.trim());
    if (n == null || n < 1 || n > 65535 || bps == null || bps < 0) {
      setState(
        () => _error =
            'Enter whole instalments (1 or more) and a rate of 0 or more',
      );
      return;
    }
    Navigator.of(context).pop((instalments: n, rateBps: bps));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Restructure loan #${widget.loan.onchainLoanId}'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const Key('restructure-instalments'),
          controller: _instalments,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Instalments from now'),
        ),
        TextField(
          key: const Key('restructure-rate'),
          controller: _rate,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Interest per instalment (basis points)',
            helperText: '100 basis points is 1%',
            errorText: _error,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('restructure-review'),
        onPressed: _review,
        child: const Text('Review'),
      ),
    ],
  );
}

/// Runs an engine call on [loan] (approve, pledge, cancel) through the
/// review and the device lock, then follows it until it is final before the
/// room's loans are read again.
Future<void> _engineAction(
  BuildContext context,
  WidgetRef ref,
  String roomId,
  AccountEngineCall call,
  finance.Loan loan, {
  String amount = '',
  void Function(bool settling)? onSettling,
}) async {
  final container = moneyContainer(context);
  final service = ref.read(stawiAccountServiceProvider);
  final custody = await ref.read(roomCustodyProvider(roomId).future);
  final asset = await ref
      .read(stawiRoomAssetProvider(roomId).future)
      .catchError((Object _) => null);
  final engines = await ref
      .read(roomEnginesProvider(roomId).future)
      .catchError((Object _) => null);
  if (!context.mounted) return;
  if (custody == null) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('This room is not on chain yet')),
    );
    return;
  }
  final submitted = await runMoneyAction(
    context,
    ref,
    () async => service.prepareEngineCall(
      AccountEngineRequest(
        call: call,
        custody: custody,
        amount: amount,
        asset: asset,
        loanId: loan.onchainLoanId.toInt(),
      ),
      engines: engines,
    ),
  );
  if (submitted == null) return;
  onSettling?.call(true);
  try {
    await settleThenRefresh(container, service, submitted, [
      ...roomLoanProviders(roomId),
      loanProvider(LoanRef.of(loan)),
    ]);
  } finally {
    onSettling?.call(false);
  }
}

/// Shown while a submitted call is followed until it is final.
class _Settling extends StatelessWidget {
  const _Settling({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 8),
        Expanded(child: Text(waitingForCompletion)),
      ],
    ),
  );
}

/// Another member's request waiting for approval: who asks, how much, their
/// record (finance shares it with those who decide while it is open), and
/// what the person may do: approve it (an officer), or guarantee part of it.
class _PendingLoan extends ConsumerStatefulWidget {
  const _PendingLoan({
    required this.roomId,
    required this.roomName,
    required this.loan,
    super.key,
  });

  final String roomId;
  final String roomName;
  final finance.Loan loan;

  @override
  ConsumerState<_PendingLoan> createState() => _PendingLoanState();
}

class _PendingLoanState extends ConsumerState<_PendingLoan> {
  final _amount = TextEditingController();
  bool _busy = false;
  bool _settling = false;

  void _onSettling(bool on) {
    if (mounted) setState(() => _settling = on);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _guarantee() => _run(() async {
    final asset = await ref
        .read(stawiRoomAssetProvider(widget.roomId).future)
        .catchError((Object _) => null);
    if (!mounted) return;
    final String units;
    try {
      if (asset == null) {
        throw const FormatException('The room’s asset could not be read');
      }
      units = parseAmountInput(_amount.text, asset);
    } on FormatException catch (e) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    await _engineAction(
      context,
      ref,
      widget.roomId,
      AccountEngineCall.loanPledge,
      widget.loan,
      amount: units,
      onSettling: _onSettling,
    );
  });

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final id = loan.onchainLoanId;
    final name = _borrowerName(ref, widget.roomId, loan);
    final assets = watchRoomAssets(ref, widget.roomId);
    final product = ref
        .watch(roomProductsProvider(widget.roomId))
        .asData
        ?.value
        .loanProducts
        .where((p) => bytesEqual(p.productId, loan.productId))
        .firstOrNull;
    final byVote = product != null && _byVote(product, loan);
    final approver = _approver(ref, widget.roomId);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$name asks for ${formatMoney(loan.requested, assets)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (product != null)
              Text(
                loanTypeName(product),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 4),
            RecordSummary(
              borrower: Uint8List.fromList(loan.borrowerAccount),
              name: name,
            ),
            const SizedBox(height: 8),
            if (_settling) const _Settling(key: Key('pending-settling')),
            if (byVote) ...[
              const Text('Decided by a room vote'),
              _LoanVote(
                roomId: widget.roomId,
                roomName: widget.roomName,
                loan: loan,
              ),
            ],
            if (approver == _Approver.unknown)
              Row(
                children: [
                  const Expanded(
                    child: Text('Who may approve could not be read just now'),
                  ),
                  TextButton(
                    key: Key('loan-$id-roles-retry'),
                    onPressed: () =>
                        ref.invalidate(stawiMembersProvider(widget.roomId)),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            if (approver == _Approver.officer && !byVote)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  key: Key('loan-$id-approve'),
                  onPressed: _busy
                      ? null
                      : () => _run(
                          () => _engineAction(
                            context,
                            ref,
                            widget.roomId,
                            AccountEngineCall.loanApprove,
                            loan,
                            onSettling: _onSettling,
                          ),
                        ),
                  child: const Text('Approve'),
                ),
              ),
            if (approver == _Approver.member)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: Key('loan-$id-guarantee-amount'),
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount to guarantee',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    key: Key('loan-$id-guarantee'),
                    onPressed: _busy ? null : _guarantee,
                    child: const Text('Guarantee'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// One of the person's own loans in the room: its card and schedule (from
/// GetLoan), and what they may do with it.
class _MyGroupLoan extends ConsumerStatefulWidget {
  const _MyGroupLoan({
    required this.roomId,
    required this.roomName,
    required this.loan,
    super.key,
  });

  final String roomId;
  final String roomName;
  final finance.Loan loan;

  @override
  ConsumerState<_MyGroupLoan> createState() => _MyGroupLoanState();
}

class _MyGroupLoanState extends ConsumerState<_MyGroupLoan> {
  bool _busy = false;
  bool _settling = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Pays the next instalment still owed: a contribution of that amount,
  /// which the room's rules apply (dues and penalties first).
  Future<void> _payInstalment(LoanView view) => _run(() async {
    final owed = view.nextOwedIfKnown;
    if (owed == null || owed <= BigInt.zero) return;
    final container = moneyContainer(context);
    final service = ref.read(stawiAccountServiceProvider);
    final custody = await ref.read(roomCustodyProvider(widget.roomId).future);
    if (!mounted) return;
    if (custody == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('This room is not on chain yet')),
      );
      return;
    }
    final call = await runMoneyAction(
      context,
      ref,
      () => service.prepareContribution(
        roomId: widget.roomId,
        custody: custody,
        amount: owed.toString(),
        roomName: widget.roomName,
        title: (amount) =>
            'Pay $amount toward loan #${widget.loan.onchainLoanId} in '
            '${widget.roomName}',
        note: groupInstalmentNote,
      ),
    );
    await _settle(container, service, call);
  });

  /// Pays the loan off: the payoff form (with its top-up when the credit
  /// falls short) reviews and signs it; the call it submits is followed
  /// until it is final before anything is read again, and nothing else on
  /// the loan can be paid meanwhile.
  Future<void> _payOff(finance.Loan loan) => _run(() async {
    final container = moneyContainer(context);
    final service = ref.read(stawiAccountServiceProvider);
    final call = await showDialog<settlement.AccountCall>(
      context: context,
      builder: (_) => AccountEngineDialog(
        roomId: widget.roomId,
        call: AccountEngineCall.loanPayoff,
        loan: loan,
      ),
    );
    await _settle(container, service, call);
  });

  /// Follows [call], when one was submitted, until it is final, showing that
  /// it is under way, then reads the room's loans and this loan again.
  Future<void> _settle(
    ProviderContainer container,
    StawiAccountService service,
    settlement.AccountCall? call,
  ) async {
    if (call == null) return;
    if (mounted) setState(() => _settling = true);
    try {
      await settleThenRefresh(container, service, call, [
        ...roomLoanProviders(widget.roomId),
        loanProvider(LoanRef.of(widget.loan)),
      ]);
    } finally {
      if (mounted) setState(() => _settling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loanRef = LoanRef.of(widget.loan);
    final detail = ref.watch(loanProvider(loanRef));
    final mine = ref.watch(stawiIdentityProvider).asData?.value.addresses;
    final loan = detail.asData?.value.loan ?? widget.loan;
    final view = LoanView(
      loan,
      mine: mine ?? const [],
      instalments: detail.asData?.value.instalments ?? const [],
      instalmentsUnavailable:
          detail.asData?.value.instalmentsUnavailable ?? false,
    );
    final assets = watchRoomAssets(ref, widget.roomId);
    final id = widget.loan.onchainLoanId;
    final active = loan.state == finance.LoanState.LOAN_STATE_FUNDED;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LoanCard(view: view, assets: assets),
            detail.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Reading the schedule…'),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(8),
                child: Text(stawiErrorMessage(e)),
              ),
              data: (_) => ScheduleView(
                key: Key('loan-$id-schedule'),
                instalments: view.instalments,
                assets: assets,
                emptyText: 'No schedule yet',
                unavailable: view.instalmentsUnavailable,
                onRetry: () => ref.invalidate(loanProvider(loanRef)),
              ),
            ),
            if (_settling) const _Settling(key: Key('loan-settling')),
            if (_pending(loan) && _decidedByVote(ref, widget.roomId, loan))
              _LoanVote(
                roomId: widget.roomId,
                roomName: widget.roomName,
                loan: loan,
              ),
            Wrap(
              spacing: 8,
              children: [
                if (active) ...[
                  FilledButton(
                    key: Key('loan-$id-pay'),
                    onPressed:
                        _busy ||
                            (view.nextOwedIfKnown ?? BigInt.zero) <= BigInt.zero
                        ? null
                        : () => _payInstalment(view),
                    child: const Text('Pay an instalment'),
                  ),
                  OutlinedButton(
                    key: Key('loan-$id-payoff'),
                    onPressed: _busy ? null : () => _payOff(loan),
                    child: const Text('Pay off the loan'),
                  ),
                ],
                if (_pending(loan))
                  OutlinedButton(
                    key: Key('loan-$id-cancel'),
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => _engineAction(
                              context,
                              ref,
                              widget.roomId,
                              AccountEngineCall.loanCancel,
                              loan,
                              onSettling: (on) {
                                if (mounted) setState(() => _settling = on);
                              },
                            ),
                          ),
                    child: const Text('Cancel my request'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
