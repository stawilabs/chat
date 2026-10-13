import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart'
    show EngineCall, bytesToHex0x;

import '../../auth/data/current_user_provider.dart';
import '../data/stawi_account_service.dart';
import '../data/stawi_custody.dart';
import '../data/stawi_finance_service.dart';
import '../data/stawi_identity.dart';
import '../data/stawi_room_engines.dart';
import '../data/stawi_room_service.dart';
import '../data/stawi_timeline_providers.dart';
import '../domain/account_engine_calls.dart';
import '../domain/payoff_top_up.dart';
import '../domain/signing_checks.dart' show bytesEqual;
import '../domain/stawi_money.dart';
import 'stawi_feedback.dart';

/// A Stawi room's money, from finance's read model: dues, share-outs, loans
/// and members' balances, with the actions each allows.
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
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        const _Heading('My dues'),
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
      ],
    );
  }
}

class _ShareOutsTab extends ConsumerWidget {
  const _ShareOutsTab({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = watchRoomAssets(ref, roomId);
    return ListView(
      children: [
        const _Heading('My share-outs'),
        _AsyncList<finance.Entitlement>(
          value: ref.watch(stawiEntitlementsProvider(roomId)),
          empty: 'No share-outs for you yet',
          item: (e) => ListTile(
            title: Text(formatMoney(e.amount, assets)),
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
            title: Text(formatMoney(d.total, assets)),
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
}

class _LoansTab extends ConsumerWidget {
  const _LoansTab({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine =
        ref.watch(stawiIdentityProvider).asData?.value.addresses ??
        const <Uint8List>[];
    final assets = watchRoomAssets(ref, roomId);
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
                'Loan #${loan.onchainLoanId} · ${formatMoney(loan.requested, assets)}'
                '${isMine ? ' (mine)' : ''}',
              ),
              subtitle: Text(
                '${_stateName(loan.state.name, 'LOAN_STATE_')}'
                ' · outstanding '
                '${formatMoney(loan.outstandingPrincipal, assets)}',
              ),
              children: [
                _Breakdown(
                  {
                    'Paid out': loan.paidOut,
                    'Pledged': loan.pledged,
                    'Repaid principal': loan.repaidPrincipal,
                    'Repaid interest': loan.repaidInterest,
                    'Repaid fees': loan.repaidFees,
                    'Repaid penalties': loan.repaidPenalties,
                    'Recovered': loan.recovered,
                  },
                  assets: assets,
                  instalments: loan.instalments,
                ),
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
  const _Breakdown(
    this.amounts, {
    required this.assets,
    required this.instalments,
  });

  final Map<String, finance.Money> amounts;
  final StawiAssets assets;
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
                Text(formatMoney(e.value, assets)),
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
        data: (response) {
          final assets = watchRoomAssets(ref, roomId).withAll(response.assets);
          return ListView(
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
                  title: _MemberName(roomId: roomId, profileId: m.profileId),
                  subtitle: Text(
                    '${m.membershipState.toLowerCase()}'
                    ' · contributed ${formatMoney(m.contributed, assets)}'
                    '${m.hasBook() ? ' · ${_stateName(m.book.standing.name, 'MEMBER_DUES_STANDING_')}' : ''}',
                  ),
                  children: [
                    _Breakdown(
                      {
                        if (m.hasBook()) 'Credit': m.book.credit,
                        if (m.hasBook()) 'Equity': m.book.equity,
                        if (m.hasBook()) 'Dues owed': m.book.duesOwed,
                        if (m.hasBook())
                          'Share-outs to collect': m.book.payoutOwed,
                        'Dues paid': m.duesPaid,
                        'Collected': m.collected,
                        'Withdrawn': m.withdrawn,
                        'Loans outstanding': m.loansOutstanding,
                      },
                      assets: assets,
                      instalments: 0,
                    ),
                  ],
                ),
            ],
          );
        },
      );
}

class _MemberName extends ConsumerWidget {
  const _MemberName({required this.roomId, required this.profileId});

  final String roomId;
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Text(
    ref
            .watch(
              stawiMemberNameProvider((roomId: roomId, profileId: profileId)),
            )
            .asData
            ?.value ??
        'Member',
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
  final _instalments = TextEditingController();
  bool _busy = false;
  String? _error;
  PreparedMoneyCall? _prepared;

  /// What the member asked for, kept with [_prepared].
  AccountEngineRequest? _request;

  /// For a payoff: what to pay in first, once read (null: it could not be).
  PayoffTopUp? _topUp;
  bool _toppedUp = false;

  @override
  void dispose() {
    _amount.dispose();
    _instalments.dispose();
    super.dispose();
  }

  /// The picked product's 32-byte id, passed to settlement as it is.
  Uint8List? _picked;

  Uint8List? _productId() => widget.call.takesProduct ? _picked : null;

  Future<StawiAsset> _asset() async {
    final asset = await ref
        .read(stawiRoomAssetProvider(widget.roomId).future)
        .catchError((Object _) => null);
    if (asset == null) {
      throw const FormatException('The room’s asset could not be read');
    }
    return asset;
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
      final asset = await _asset();
      final typed = _amount.text.trim();
      request = AccountEngineRequest(
        call: widget.call,
        custody: custody,
        amount: typed.isEmpty ? '' : parseAmountInput(typed, asset),
        asset: asset,
        loanId: widget.loan?.onchainLoanId.toInt() ?? 0,
        productId: _productId(),
        instalments: int.tryParse(_instalments.text.trim()) ?? 0,
      );
    } on FormatException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
      return;
    }
    final engines = await ref
        .read(roomEnginesProvider(widget.roomId).future)
        .catchError((Object _) => null);
    if (!mounted) return;
    final prepared = await runStawiAction(
      context,
      () => ref
          .read(stawiAccountServiceProvider)
          .prepareEngineCall(request, engines: engines),
    );
    if (!mounted) return;
    final topUp =
        prepared != null && widget.call == AccountEngineCall.loanPayoff
        ? await _payoffTopUp(prepared, request)
        : null;
    if (!mounted) return;
    setState(() {
      _busy = false;
      _prepared = prepared;
      _request = prepared == null ? null : request;
      _topUp = topUp;
    });
  }

  /// What the member must pay in before [prepared] can pay the loan off, from
  /// the credit their live book says a payoff can spend; null when it cannot
  /// be read.
  Future<PayoffTopUp?> _payoffTopUp(
    PreparedMoneyCall prepared,
    AccountEngineRequest request,
  ) async {
    final asset = request.asset;
    if (asset == null) return null;
    try {
      final identity = await ref.read(stawiIdentityProvider.future);
      final balances = await ref.read(
        stawiMemberBalancesProvider(widget.roomId).future,
      );
      return payoffTopUpFor(
        payoff: prepared.call!.amount,
        asset: asset.sdkAsset,
        balances: balances,
        myAccounts: identity.addresses,
      );
    } on Object {
      return null;
    }
  }

  /// Pays the top-up into the room and waits for it to land, so the payoff
  /// that follows finds the claimed dues paid and the credit there.
  Future<void> _payTopUp() async {
    final request = _request!;
    final topUp = _topUp!.topUp;
    setState(() => _busy = true);
    final service = ref.read(stawiAccountServiceProvider);
    final landed = await runStawiAction(context, () async {
      // The button that asked for the top-up names its amount; the device
      // lock shows the same amount before signing.
      final prepared = await service.prepareContribution(
        custody: request.custody,
        amount: topUp.toString(),
      );
      final submitted = await service.submit(prepared);
      final last = await service.followAccountCall(submitted.callId).last;
      if (last.state != settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL) {
        throw StawiUnavailable(
          last.failureReason.isNotEmpty
              ? 'The top-up did not go through: ${last.failureReason}'
              : 'The top-up did not go through; try again',
        );
      }
      return last;
    }, success: 'Topped up; you can sign the payoff now');
    if (!mounted) return;
    ref.invalidate(stawiMemberBalancesProvider(widget.roomId));
    setState(() {
      _busy = false;
      if (landed != null) _toppedUp = true;
    });
  }

  Future<void> _sign() async {
    final prepared = _prepared!;
    setState(() => _busy = true);
    final call = await runStawiAction(
      context,
      () => ref.read(stawiAccountServiceProvider).submit(prepared),
      success: prepared.review.done,
    );
    if (!mounted) return;
    if (call != null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
    }
  }

  /// A picker over the room's loan forms or dues products, as its rules
  /// engines hold them, with each one's key terms.
  Widget _productField() {
    final loans = widget.call == AccountEngineCall.loanRequest;
    return ref
        .watch(roomProductsProvider(widget.roomId))
        .when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text(stawiErrorMessage(error)),
          data: (products) {
            final assets = watchRoomAssets(
              ref,
              widget.roomId,
            ).withAll(products.assets);
            final entries = loans
                ? [
                    for (final p in products.loanProducts)
                      (
                        id: Uint8List.fromList(p.productId),
                        label: productLabel(p.name, p.productId),
                        terms: loanProductTerms(p, assets),
                      ),
                  ]
                : [
                    for (final p in products.duesProducts.where(
                      (p) => p.memberChoice,
                    ))
                      (
                        id: Uint8List.fromList(p.productId),
                        label: productLabel(p.name, p.productId),
                        terms: duesProductTerms(p, assets),
                      ),
                  ];
            if (!products.rulesConfigured || entries.isEmpty) {
              return Text(
                loans
                    ? 'This room offers no loans yet.'
                    : 'No dues in this room let members choose the amount.',
                key: const Key('engine-no-products'),
              );
            }
            return RadioGroup<String>(
              key: const Key('engine-product-picker'),
              groupValue: _picked == null ? null : bytesToHex0x(_picked!),
              onChanged: (value) => setState(
                () => _picked = entries
                    .firstWhere((e) => bytesToHex0x(e.id) == value)
                    .id,
              ),
              child: Column(
                children: [
                  for (final e in entries)
                    RadioListTile<String>(
                      key: Key('product-${bytesToHex0x(e.id)}'),
                      value: bytesToHex0x(e.id),
                      title: Text(e.label),
                      subtitle: Text(e.terms),
                    ),
                ],
              ),
            );
          },
        );
  }

  String? _symbol() =>
      ref.watch(stawiRoomAssetProvider(widget.roomId)).asData?.value?.symbol;

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
              if (widget.call.takesProduct) _productField(),
              if (widget.call.takesAmount)
                TextField(
                  key: const Key('engine-amount'),
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.call == AccountEngineCall.loanPayoff
                        ? 'Most to pay (optional)'
                        : 'Amount',
                    suffixText: _symbol(),
                    helperText: widget.call == AccountEngineCall.loanPayoff
                        ? 'Leave empty and settlement quotes what it takes now'
                        : null,
                  ),
                ),
              if (widget.call == AccountEngineCall.loanRequest)
                TextField(
                  key: const Key('engine-instalments'),
                  controller: _instalments,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Instalments'),
                ),
            ] else ...[
              _Review(call: prepared.call!, request: _request!),
              if (widget.call == AccountEngineCall.loanPayoff)
                _TopUpNotice(
                  topUp: _topUp,
                  toppedUp: _toppedUp,
                  request: _request!,
                ),
            ],
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
        else if (_topUp != null && _topUp!.needed && !_toppedUp)
          FilledButton(
            key: const Key('payoff-top-up'),
            onPressed: _busy ? null : _payTopUp,
            child: Text(
              _busy
                  ? 'Topping up…'
                  : 'Top up ${_formatTopUp(_request!, _topUp!.topUp)}',
            ),
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
    final asset = request.asset;
    final shown = asset == null
        ? '${call.amount}'
        : formatUnits(call.amount, asset);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(request.summary, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (call.loanId > BigInt.zero) Text('Loan #${call.loanId}'),
        if (call.amount > BigInt.zero)
          Text(
            quoted
                ? 'Pays at most $shown (settlement’s quote, with headroom; '
                      'only what the loan takes is paid)'
                : 'Amount $shown',
            key: const Key('engine-review-amount'),
          ),
        if (call.instalments > 0) Text('${call.instalments} instalments'),
        const SizedBox(height: 8),
        Text(
          'Checked on this device: this is the call you asked for, on this '
          'room, from your account, on the room’s own engine.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

String _formatTopUp(AccountEngineRequest request, BigInt units) {
  final asset = request.asset;
  return asset == null ? '$units' : formatUnits(units, asset);
}

/// Before a payoff: whether the member must pay in first, and why.
class _TopUpNotice extends StatelessWidget {
  const _TopUpNotice({
    required this.topUp,
    required this.toppedUp,
    required this.request,
  });

  final PayoffTopUp? topUp;
  final bool toppedUp;
  final AccountEngineRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = topUp;
    final String text;
    if (t == null) {
      text =
          'Your credit in the room could not be read. A payoff is paid from '
          'your credit after the dues and penalties a settle takes first; if '
          'it is refused, pay those in first.';
    } else if (!t.needed) {
      return const SizedBox.shrink();
    } else if (toppedUp) {
      text = 'Top-up received. Sign to pay the loan off.';
    } else {
      String money(BigInt units) => _formatTopUp(request, units);
      final claims = [
        if (t.duesPayable.units > BigInt.zero)
          'dues of ${money(t.duesPayable.units)}',
        if (t.penaltiesOwed.units > BigInt.zero)
          'penalties of ${money(t.penaltiesOwed.units)}',
      ];
      text =
          'Pay in ${money(t.topUp)} first. The payoff takes up to '
          '${money(t.payoff.units)} and your credit in the room is '
          '${money(t.credit.units)}'
          '${claims.isEmpty ? '' : '; a settle takes ${claims.join(' and ')} '
                    'from it first'}. Anything left over stays your credit.';
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        key: const Key('payoff-top-up-notice'),
        style: theme.textTheme.bodySmall?.copyWith(
          color: t != null && t.needed && !toppedUp
              ? theme.colorScheme.error
              : null,
        ),
      ),
    );
  }
}
