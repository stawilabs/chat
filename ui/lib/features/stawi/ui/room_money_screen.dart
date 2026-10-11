import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show EngineCall;

import '../../auth/data/current_user_provider.dart';
import '../data/stawi_account_service.dart';
import '../data/stawi_custody.dart';
import '../data/stawi_finance_service.dart';
import '../data/stawi_identity.dart';
import '../data/stawi_room_service.dart';
import '../domain/account_engine_calls.dart';
import '../domain/signing_checks.dart' show bytesEqual;
import 'statement_screen.dart' show formatMoney;
import 'stawi_feedback.dart';

/// A Stawi room's money, from finance's read model: savings periods and dues,
/// share-outs, loans and members' balances, with the actions each allows.
class RoomMoneyScreen extends StatelessWidget {
  const RoomMoneyScreen({
    required this.roomId,
    required this.roomName,
    super.key,
  });

  final String roomId;
  final String roomName;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: AppBar(
        title: Text('Money · $roomName'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'Savings'),
            Tab(text: 'Share-outs'),
            Tab(text: 'Loans'),
            Tab(text: 'Members'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _SavingsTab(roomId: roomId),
          _ShareOutsTab(roomId: roomId),
          _LoansTab(roomId: roomId),
          _MembersTab(roomId: roomId),
        ],
      ),
    ),
  );
}

final _dates = DateFormat.yMMMd();

String _stateName(String enumName, String prefix) =>
    enumName.replaceFirst(prefix, '').toLowerCase().replaceAll('_', ' ');

/// Pushes a rules-engine call for the signed-in member.
Future<void> _pushForMe(
  BuildContext context,
  WidgetRef ref,
  String roomId,
  settlement.RoomCallKind kind,
  String success,
) async {
  final me = await ref.read(currentProfileIdProvider.future);
  if (me == null || !context.mounted) return;
  await runStawiAction(
    context,
    () => ref
        .read(stawiRoomServiceProvider)
        .pushEngineCall(roomId: roomId, kind: kind, memberProfileId: me),
    success: success,
  );
}

class _AsyncList<T> extends StatelessWidget {
  const _AsyncList({
    required this.value,
    required this.empty,
    required this.item,
  });

  final AsyncValue<List<T>> value;
  final String empty;
  final Widget Function(T) item;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (error, _) => Padding(
      padding: const EdgeInsets.all(16),
      child: Text(stawiErrorMessage(error)),
    ),
    data: (items) => items.isEmpty
        ? Padding(padding: const EdgeInsets.all(16), child: Text(empty))
        : Column(children: [for (final i in items) item(i)]),
  );
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

class _SavingsTab extends ConsumerWidget {
  const _SavingsTab({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    children: [
      const _Heading('My dues'),
      _AsyncList<finance.Obligation>(
        value: ref.watch(stawiObligationsProvider(roomId)),
        empty: 'Nothing due',
        item: (o) => ListTile(
          title: Text('${formatMoney(o.settled)} of ${formatMoney(o.amount)}'),
          subtitle: Text(
            '${_stateName(o.state.name, 'OBLIGATION_STATE_')}'
            '${o.hasDueAt() ? ' · due ${_dates.format(o.dueAt.toDateTime())}' : ''}',
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: OutlinedButton.icon(
          key: const Key('money-settle'),
          icon: const Icon(Icons.task_alt),
          label: const Text('Settle my dues now'),
          onPressed: () => _pushForMe(
            context,
            ref,
            roomId,
            settlement.RoomCallKind.ROOM_CALL_KIND_SETTLE,
            'Settlement requested; your payments are credited on chain',
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final call in [
              AccountEngineCall.chooseAmount,
              AccountEngineCall.withdrawCredit,
              AccountEngineCall.withdrawEquity,
            ])
              OutlinedButton(
                key: Key('engine-${call.name}'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      AccountEngineDialog(roomId: roomId, call: call),
                ),
                child: Text(call.label),
              ),
          ],
        ),
      ),
      const _Heading('Periods'),
      _AsyncList<finance.Period>(
        value: ref.watch(stawiPeriodsProvider(roomId)),
        empty: 'No periods yet',
        item: (p) => ListTile(
          title: Text('Period ${p.periodIndex}'),
          subtitle: Text(
            '${formatMoney(p.settledTotal)} of ${formatMoney(p.expectedTotal)}'
            ' · ${p.obligationsSettled}/${p.obligationsSettled + p.obligationsOpen} paid',
          ),
          trailing: Text(_stateName(p.state.name, 'PERIOD_STATE_')),
        ),
      ),
    ],
  );
}

class _ShareOutsTab extends ConsumerWidget {
  const _ShareOutsTab({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    children: [
      const _Heading('My share-outs'),
      _AsyncList<finance.Entitlement>(
        value: ref.watch(stawiEntitlementsProvider(roomId)),
        empty: 'No share-outs for you yet',
        item: (e) => ListTile(
          title: Text(formatMoney(e.amount)),
          subtitle: Text(_stateName(e.state.name, 'INTENT_STATE_')),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: OutlinedButton.icon(
          key: const Key('money-collect'),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Collect my share-outs'),
          onPressed: () => _pushForMe(
            context,
            ref,
            roomId,
            settlement.RoomCallKind.ROOM_CALL_KIND_COLLECT,
            'Collection requested; your share-outs are paid on chain',
          ),
        ),
      ),
      const _Heading('Share-outs'),
      _AsyncList<finance.DistributionRecord>(
        value: ref.watch(stawiDistributionsProvider(roomId)),
        empty: 'No share-outs yet',
        item: (d) => ListTile(
          title: Text(formatMoney(d.total)),
          subtitle: Text(
            '${_stateName(d.method.name, 'METHOD_')} · '
            '${d.entitlementCount} members'
            '${d.hasCreatedAt() ? ' · ${_dates.format(d.createdAt.toDateTime())}' : ''}',
          ),
          trailing: Text(_stateName(d.state.name, 'DISTRIBUTION_STATE_')),
        ),
      ),
    ],
  );
}

class _LoansTab extends ConsumerWidget {
  const _LoansTab({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine =
        ref.watch(stawiIdentityProvider).asData?.value.addresses ??
        const <Uint8List>[];
    void open(AccountEngineCall call, {finance.Loan? loan}) => showDialog<void>(
      context: context,
      builder: (_) =>
          AccountEngineDialog(roomId: roomId, call: call, loan: loan),
    );
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            key: const Key('engine-loanRequest'),
            icon: const Icon(Icons.request_quote_outlined),
            label: const Text('Request a loan'),
            onPressed: () => open(AccountEngineCall.loanRequest),
          ),
        ),
        const _Heading('Loans'),
        _AsyncList<finance.Loan>(
          value: ref.watch(stawiLoansProvider(roomId)),
          empty: 'No loans in this room',
          item: (loan) {
            final isMine = mine.any((a) => bytesEqual(a, loan.borrowerAccount));
            return ExpansionTile(
              key: Key('loan-${loan.onchainLoanId}'),
              title: Text(
                'Loan #${loan.onchainLoanId} · ${formatMoney(loan.requested)}'
                '${isMine ? ' (mine)' : ''}',
              ),
              subtitle: Text(
                '${_stateName(loan.state.name, 'LOAN_STATE_')}'
                ' · outstanding ${formatMoney(loan.outstandingPrincipal)}',
              ),
              children: [
                _Breakdown({
                  'Paid out': loan.paidOut,
                  'Pledged': loan.pledged,
                  'Repaid principal': loan.repaidPrincipal,
                  'Repaid interest': loan.repaidInterest,
                  'Repaid fees': loan.repaidFees,
                  'Repaid penalties': loan.repaidPenalties,
                  'Recovered': loan.recovered,
                }, instalments: loan.instalments),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final call
                        in isMine
                            ? [
                                AccountEngineCall.loanPayoff,
                                AccountEngineCall.loanCancel,
                              ]
                            : [
                                AccountEngineCall.loanApprove,
                                AccountEngineCall.loanPledge,
                                AccountEngineCall.loanUnpledge,
                              ])
                      TextButton(
                        key: Key('loan-${loan.onchainLoanId}-${call.name}'),
                        onPressed: () => open(call, loan: loan),
                        child: Text(call.label),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown(this.amounts, {required this.instalments});

  final Map<String, finance.Money> amounts;
  final int instalments;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        for (final e in amounts.entries)
          if (e.value.amount.isNotEmpty && e.value.amount != '0')
            Row(
              children: [
                Expanded(child: Text(e.key)),
                Text(formatMoney(e.value)),
              ],
            ),
        if (instalments > 0)
          Row(
            children: [
              const Expanded(child: Text('Instalments')),
              Text('$instalments'),
            ],
          ),
      ],
    ),
  );
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(stawiMemberBalancesProvider(roomId))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(stawiErrorMessage(error)),
        ),
        data: (response) => ListView(
          children: [
            if (!response.booksAvailable)
              const Padding(
                key: Key('books-unavailable'),
                padding: EdgeInsets.all(16),
                child: Text(
                  'Live credit and equity are unavailable right now; totals '
                  'below are from the index.',
                ),
              ),
            if (response.balances.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No members on chain yet'),
              ),
            for (final m in response.balances)
              ExpansionTile(
                key: Key('member-${m.memberId}'),
                title: Text(m.profileId.isEmpty ? m.memberId : m.profileId),
                subtitle: Text(
                  '${m.membershipState.toLowerCase()}'
                  ' · contributed ${formatMoney(m.contributed)}'
                  '${m.hasBook() ? ' · ${_stateName(m.book.standing.name, 'MEMBER_DUES_STANDING_')}' : ''}',
                ),
                children: [
                  _Breakdown({
                    if (m.hasBook()) 'Credit': m.book.credit,
                    if (m.hasBook()) 'Equity': m.book.equity,
                    if (m.hasBook()) 'Dues owed': m.book.duesOwed,
                    if (m.hasBook()) 'Share-outs to collect': m.book.payoutOwed,
                    'Dues paid': m.duesPaid,
                    'Collected': m.collected,
                    'Withdrawn': m.withdrawn,
                    'Loans outstanding': m.loansOutstanding,
                  }, instalments: 0),
                ],
              ),
          ],
        ),
      );
}

/// The form for one loan or withdrawal call on the member's account: fill it
/// in, review what settlement prepared (checked on the device), then sign.
class AccountEngineDialog extends ConsumerStatefulWidget {
  const AccountEngineDialog({
    required this.roomId,
    required this.call,
    this.loan,
    super.key,
  });

  final String roomId;
  final AccountEngineCall call;

  /// The loan a loan action names (its on-chain number).
  final finance.Loan? loan;

  @override
  ConsumerState<AccountEngineDialog> createState() =>
      _AccountEngineDialogState();
}

class _AccountEngineDialogState extends ConsumerState<AccountEngineDialog> {
  final _amount = TextEditingController();
  final _product = TextEditingController();
  final _instalments = TextEditingController();
  bool _busy = false;
  String? _error;
  PreparedEngineCall? _prepared;

  @override
  void dispose() {
    _amount.dispose();
    _product.dispose();
    _instalments.dispose();
    super.dispose();
  }

  Future<void> _review() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final AccountEngineRequest request;
    try {
      final custody = await ref.read(roomCustodyProvider(widget.roomId).future);
      if (custody == null) {
        throw const FormatException('This room is not on chain yet');
      }
      request = AccountEngineRequest(
        call: widget.call,
        custody: custody,
        amount: _amount.text.trim(),
        loanId: widget.loan?.onchainLoanId.toInt() ?? 0,
        productId: widget.call.takesProduct && _product.text.trim().isNotEmpty
            ? productIdOf(_product.text)
            : null,
        instalments: int.tryParse(_instalments.text.trim()) ?? 0,
      );
    } on FormatException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
      return;
    }
    if (!mounted) return;
    final prepared = await runStawiAction(
      context,
      () => ref.read(stawiAccountServiceProvider).prepareEngineCall(request),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _prepared = prepared;
    });
  }

  Future<void> _sign() async {
    final prepared = _prepared!;
    setState(() => _busy = true);
    final call = await runStawiAction(
      context,
      () => ref.read(stawiAccountServiceProvider).submitEngineCall(prepared),
      success: 'Signed and submitted: ${prepared.request.summary}',
    );
    if (!mounted) return;
    if (call != null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prepared = _prepared;
    final loan = widget.loan;
    return AlertDialog(
      title: Text(
        loan == null
            ? widget.call.label
            : '${widget.call.label} #${loan.onchainLoanId}',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (prepared == null) ...[
              if (widget.call.takesProduct)
                TextField(
                  key: const Key('engine-product'),
                  controller: _product,
                  decoration: InputDecoration(
                    labelText: widget.call == AccountEngineCall.loanRequest
                        ? 'Loan form (as the room’s rules name it)'
                        : 'Dues product (as the room’s rules name it)',
                  ),
                ),
              if (widget.call.takesAmount)
                TextField(
                  key: const Key('engine-amount'),
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: widget.call == AccountEngineCall.loanPayoff
                        ? 'Most to pay (optional)'
                        : 'Amount',
                    helperText: widget.call == AccountEngineCall.loanPayoff
                        ? 'Leave empty and settlement quotes what it takes now'
                        : 'In the asset’s smallest unit',
                  ),
                ),
              if (widget.call == AccountEngineCall.loanRequest)
                TextField(
                  key: const Key('engine-instalments'),
                  controller: _instalments,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Instalments'),
                ),
            ] else
              _Review(call: prepared.call, request: prepared.request),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (prepared == null)
          FilledButton(
            key: const Key('engine-review'),
            onPressed: _busy ? null : _review,
            child: Text(_busy ? 'Preparing…' : 'Review'),
          )
        else
          FilledButton(
            key: const Key('engine-sign'),
            onPressed: _busy ? null : _sign,
            child: Text(_busy ? 'Signing…' : 'Sign and submit'),
          ),
      ],
    );
  }
}

/// What the account will do, decoded from the call settlement prepared and
/// checked on this device.
class _Review extends StatelessWidget {
  const _Review({required this.call, required this.request});

  final EngineCall call;
  final AccountEngineRequest request;

  @override
  Widget build(BuildContext context) {
    final quoted =
        request.call == AccountEngineCall.loanPayoff && request.amount.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(request.summary, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (call.loanId > BigInt.zero) Text('Loan #${call.loanId}'),
        if (call.amount > BigInt.zero)
          Text(
            quoted
                ? 'Pays at most ${call.amount} (settlement’s quote, with '
                      'headroom; only what the loan takes is paid)'
                : 'Amount ${call.amount}',
            key: const Key('engine-review-amount'),
          ),
        if (call.instalments > 0) Text('${call.instalments} instalments'),
        const SizedBox(height: 8),
        Text(
          'Checked on this device: this is the call you asked for, on this '
          'room, from your account.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
