import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;

import '../../auth/data/current_user_provider.dart';
import '../data/stawi_account_service.dart';
import '../data/stawi_custody.dart';
import '../data/stawi_finance_service.dart';
import '../data/stawi_room_service.dart';
import '../domain/account_engine_calls.dart';
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
    void open(AccountEngineCall call, {String loanNumber = ''}) =>
        showDialog<void>(
          context: context,
          builder: (_) => AccountEngineDialog(
            roomId: roomId,
            call: call,
            loanNumber: loanNumber,
          ),
        );
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final call in [
                AccountEngineCall.loanRequest,
                AccountEngineCall.withdrawCredit,
                AccountEngineCall.withdrawEquity,
              ])
                OutlinedButton(
                  key: Key('engine-${call.name}'),
                  onPressed: () => open(call),
                  child: Text(call.label),
                ),
            ],
          ),
        ),
        const _Heading('Loans'),
        _AsyncList<finance.Loan>(
          value: ref.watch(stawiLoansProvider(roomId)),
          empty: 'No loans in this room',
          item: (loan) => ExpansionTile(
            key: Key('loan-${loan.loanId}'),
            title: Text(formatMoney(loan.principal)),
            subtitle: Text(
              '${_stateName(loan.state.name, 'LOAN_STATE_')}'
              ' · outstanding ${formatMoney(loan.outstandingPrincipal)}'
              '${loan.purpose.isEmpty ? '' : ' · ${loan.purpose}'}',
            ),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final call in [
                    AccountEngineCall.loanApprove,
                    AccountEngineCall.loanPledge,
                    AccountEngineCall.loanUnpledge,
                    AccountEngineCall.loanPayoff,
                    AccountEngineCall.loanCancel,
                  ])
                    TextButton(
                      onPressed: () => open(call),
                      child: Text(call.label),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    children: [
      _AsyncList<finance.Member>(
        value: ref.watch(stawiMembersProvider(roomId)),
        empty: 'No members on chain yet',
        item: (m) => ListTile(
          key: Key('member-${m.memberId}'),
          title: Text(m.profileId.isEmpty ? m.memberId : m.profileId),
          subtitle: Text(
            '${_stateName(m.state.name, 'MEMBER_STATE_')}'
            '${m.roleIds.isEmpty ? '' : ' · ${m.roleIds.join(', ')}'}',
          ),
          trailing: _MemberBalance(roomId: roomId, memberId: m.memberId),
        ),
      ),
    ],
  );
}

class _MemberBalance extends ConsumerWidget {
  const _MemberBalance({required this.roomId, required this.memberId});

  final String roomId;
  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(stawiMemberBalancesProvider((roomId: roomId, memberId: memberId)))
      .when(
        loading: () => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        // A member may not see others' balances; show nothing then.
        error: (_, _) => const Text('—'),
        data: (balances) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final b in balances)
              Text('${b.total} ${b.assetId}', key: Key('balance-$memberId')),
          ],
        ),
      );
}

/// The form for one loan or withdrawal call on the member's account.
class AccountEngineDialog extends ConsumerStatefulWidget {
  const AccountEngineDialog({
    required this.roomId,
    required this.call,
    this.loanNumber = '',
    super.key,
  });

  final String roomId;
  final AccountEngineCall call;
  final String loanNumber;

  @override
  ConsumerState<AccountEngineDialog> createState() =>
      _AccountEngineDialogState();
}

class _AccountEngineDialogState extends ConsumerState<AccountEngineDialog> {
  final _amount = TextEditingController();
  late final _loan = TextEditingController(text: widget.loanNumber);
  final _instalments = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _loan.dispose();
    _instalments.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _sending = true;
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
        loanId: int.tryParse(_loan.text.trim()) ?? 0,
        instalments: int.tryParse(_instalments.text.trim()) ?? 0,
      );
    } on FormatException catch (e) {
      setState(() {
        _sending = false;
        _error = e.message;
      });
      return;
    }
    if (!mounted) return;
    final call = await runStawiAction(
      context,
      () => ref.read(stawiAccountServiceProvider).engineCall(request),
      success: 'Signed and submitted: ${request.summary}',
    );
    if (!mounted) return;
    if (call != null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.call.label),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.call.takesLoan)
          TextField(
            key: const Key('engine-loan'),
            controller: _loan,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'On-chain loan number',
            ),
          ),
        if (widget.call.takesAmount)
          TextField(
            key: const Key('engine-amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount',
              helperText: 'In the asset’s smallest unit',
            ),
          ),
        if (widget.call == AccountEngineCall.loanRequest)
          TextField(
            key: const Key('engine-instalments'),
            controller: _instalments,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Instalments'),
          ),
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
    actions: [
      TextButton(
        onPressed: _sending ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('engine-sign'),
        onPressed: _sending ? null : _submit,
        child: Text(_sending ? 'Signing…' : 'Sign and submit'),
      ),
    ],
  );
}
