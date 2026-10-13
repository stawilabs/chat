import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderBase;
import 'package:stawi_api/finance_v1.dart' as finance;

import '../data/stawi_account_service.dart';
import '../data/stawi_custody.dart';
import '../data/stawi_finance_service.dart';
import '../data/stawi_loan_service.dart';
import '../data/stawi_room_engines.dart';
import '../domain/account_engine_calls.dart';
import '../domain/stawi_money.dart';
import 'loan_widgets.dart';
import 'money_review_sheet.dart';
import 'protocol_fee_line.dart';
import 'stawi_feedback.dart';

/// The note shown before a group loan is requested.
const String groupRecordNote =
    "Requesting shares your loan record with the room's approvers until it "
    'is decided.';

/// What is read again once a loan action in [roomId] is final.
List<ProviderBase<Object?>> roomLoanProviders(String roomId) => [
  ...moneyProviders(),
  stawiLoansProvider(roomId),
  roomLoansProvider(roomId),
  stawiMemberBalancesProvider(roomId),
];

/// A loan from the room on one of its loan forms: the amount and the number
/// of instalments (within the form's bounds), finance's quote with the Stawi
/// fee, then review and sign (LOAN_REQUEST).
class GroupLoanRequestScreen extends ConsumerStatefulWidget {
  const GroupLoanRequestScreen({
    required this.roomId,
    required this.product,
    this.roomName = 'the room',
    super.key,
  });

  final String roomId;
  final String roomName;
  final finance.RoomLoanProduct product;

  @override
  ConsumerState<GroupLoanRequestScreen> createState() =>
      _GroupLoanRequestScreenState();
}

class _GroupLoanRequestScreenState
    extends ConsumerState<GroupLoanRequestScreen> {
  static const _quoteDelay = Duration(milliseconds: 400);

  final _amount = TextEditingController();
  late final _instalments = TextEditingController(text: '${_minInstalments()}');

  Timer? _timer;
  int _seq = 0;
  String? _error;
  BigInt? _units;
  int? _count;
  finance.QuoteLoanResponse? _quote;
  Object? _quoteError;
  bool _quoting = false;
  bool _busy = false;

  finance.RoomLoanProduct get _p => widget.product;

  int _minInstalments() => _p.minInstalments > 0 ? _p.minInstalments : 1;

  @override
  void dispose() {
    _timer?.cancel();
    _amount.dispose();
    _instalments.dispose();
    super.dispose();
  }

  /// Reads the draft and quotes it after the last edit.
  void _edited(StawiAsset asset) {
    _timer?.cancel();
    final seq = ++_seq;
    _quote = null;
    _quoteError = null;
    _quoting = false;
    _error = null;
    _units = null;
    _count = null;
    _read(asset);
    setState(() {});
    if (_units != null && _count != null) {
      _quoting = true;
      _timer = Timer(_quoteDelay, () => _runQuote(seq));
    }
  }

  void _read(StawiAsset asset) {
    if (_amount.text.trim().isEmpty) return;
    try {
      final units = BigInt.parse(parseAmountInput(_amount.text, asset));
      final min = BigInt.tryParse(_p.minAmount.amount) ?? BigInt.zero;
      final max = BigInt.tryParse(_p.maxAmount.amount) ?? BigInt.zero;
      if (units < min) {
        _error = 'This loan is at least ${formatUnits(min, asset)}';
        return;
      }
      if (max > BigInt.zero && units > max) {
        _error = 'This loan is at most ${formatUnits(max, asset)}';
        return;
      }
      final n = int.tryParse(_instalments.text.trim());
      final lo = _minInstalments();
      final hi = _p.maxInstalments > 0 ? _p.maxInstalments : lo;
      if (n == null || n < lo || n > hi) {
        _error = lo == hi
            ? 'This loan is repaid in $lo instalments'
            : 'Choose $lo to $hi instalments';
        return;
      }
      _units = units;
      _count = n;
    } on FormatException catch (e) {
      _error = e.message;
    }
  }

  Future<void> _runQuote(int seq) async {
    final units = _units;
    final count = _count;
    if (units == null || count == null) return;
    try {
      final quote = await ref
          .read(stawiLoanServiceProvider)
          .quoteGroup(
            roomId: widget.roomId,
            productId: Uint8List.fromList(_p.productId),
            amount: units,
            instalments: count,
          );
      if (!mounted || seq != _seq) return;
      setState(() {
        _quote = quote;
        _quoting = false;
      });
    } on Object catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _quoteError = e;
        _quoting = false;
      });
    }
  }

  void _retry() {
    final seq = ++_seq;
    setState(() {
      _quoteError = null;
      _quoting = true;
    });
    unawaited(_runQuote(seq));
  }

  Future<void> _request(StawiAsset asset, finance.QuoteLoanResponse q) async {
    final units = _units;
    final count = _count;
    if (units == null || count == null || _busy) return;
    final container = moneyContainer(context);
    final service = ref.read(stawiAccountServiceProvider);
    setState(() => _busy = true);
    try {
      final custody = await ref.read(roomCustodyProvider(widget.roomId).future);
      if (!mounted) return;
      if (custody == null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('This room is not on chain yet')),
        );
        return;
      }
      final engines = await ref
          .read(roomEnginesProvider(widget.roomId).future)
          .catchError((Object _) => null);
      if (!mounted) return;
      final request = AccountEngineRequest(
        call: AccountEngineCall.loanRequest,
        custody: custody,
        amount: units.toString(),
        asset: asset,
        productId: Uint8List.fromList(_p.productId),
        instalments: count,
      );
      final call = await runMoneyAction(
        context,
        ref,
        () => service.prepareEngineCall(
          request,
          engines: engines,
          feeLine: _feeLine(q, asset),
        ),
      );
      if (call == null) return;
      await settleThenRefresh(
        container,
        service,
        call,
        roomLoanProviders(widget.roomId),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The review's Stawi fee line: finance's estimate, said to be one.
  static String _feeLine(finance.QuoteLoanResponse q, StawiAsset asset) {
    final est = BigInt.tryParse(q.protocolFeeOnInterest.amount);
    final share = protocolFeeText(
      finance.RoomProtocolFee(incomeFeeBps: q.protocolFeeBps),
    ).replaceFirst('Stawi fee ', '');
    return est == null
        ? share
        : 'About ${formatUnits(est, asset)} ($share; an estimate), from the '
              "room's income, not added to what you repay";
  }

  @override
  Widget build(BuildContext context) {
    final asset = ref.watch(stawiRoomAssetProvider(widget.roomId));
    return Scaffold(
      appBar: AppBar(title: Text(loanTypeName(_p))),
      body: asset.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(stawiErrorMessage(e))),
        data: (asset) => asset == null
            ? const Center(child: Text('The room’s asset could not be read'))
            : _form(context, asset),
      ),
    );
  }

  Widget _form(BuildContext context, StawiAsset asset) {
    final products = ref.watch(roomProductsProvider(widget.roomId));
    final assets = watchRoomAssets(ref, widget.roomId);
    final cal = RoomCalendarLabel.of(
      products.asData?.value.hasCalendar() ?? false
          ? products.asData!.value.calendar
          : null,
    );
    final quote = _quote;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AccountSetupBanner(),
        Text(plainLoanType(_p, assets, cal), key: const Key('group-loan-type')),
        const SizedBox(height: 12),
        TextField(
          key: const Key('group-loan-amount'),
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Amount (${asset.symbol})'),
          onChanged: (_) => _edited(asset),
        ),
        TextField(
          key: const Key('group-loan-instalments'),
          controller: _instalments,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Instalments'),
          onChanged: (_) => _edited(asset),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _error!,
              key: const Key('group-loan-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 12),
        _quoteView(context, asset),
        const SizedBox(height: 12),
        Text(
          groupRecordNote,
          key: const Key('group-loan-record-note'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('group-loan-submit'),
          onPressed: quote == null || _busy
              ? null
              : () => _request(asset, quote),
          child: const Text('Request'),
        ),
      ],
    );
  }

  Widget _quoteView(BuildContext context, StawiAsset asset) {
    if (_quoteError != null) {
      return Column(
        key: const Key('group-quote'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stawiErrorMessage(_quoteError!)),
          TextButton(
            key: const Key('group-quote-retry'),
            onPressed: _retry,
            child: const Text('Try again'),
          ),
        ],
      );
    }
    final q = _quote;
    if (q == null) {
      return _quoting
          ? const Text('Working out the cost…', key: Key('group-quote'))
          : const SizedBox.shrink();
    }
    String money(finance.Money m) {
      final v = BigInt.tryParse(m.amount);
      return v == null ? '—' : formatUnits(v, asset);
    }

    Widget row(String label, String value, {Key? key}) => Row(
      key: key,
      children: [
        Expanded(child: Text(label)),
        Text(value),
      ],
    );
    final fee = ref.watch(roomProtocolFeeProvider(widget.roomId)).asData?.value;
    // The quote's own rate is the one the loan form was read with; the room's
    // agent and their share come from its engines.
    final stated = finance.RoomProtocolFee(
      incomeFeeBps: q.protocolFeeBps,
      agentShareBps: fee?.agentShareBps,
      agent: fee?.agent,
    );
    return Column(
      key: const Key('group-quote'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Each instalment', style: Theme.of(context).textTheme.titleSmall),
        for (final (i, it) in q.instalments.indexed)
          Padding(
            key: Key('group-quote-row-$i'),
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${i + 1}: ${money(it.principal)} principal · '
              '${money(it.interest)} interest · ${money(it.fee)} fee',
            ),
          ),
        const SizedBox(height: 8),
        row(
          'You repay',
          money(q.totalRepayable),
          key: const Key('group-quote-total'),
        ),
        row(
          'Paid out to you',
          money(q.paidOut),
          key: const Key('group-quote-paid-out'),
        ),
        const SizedBox(height: 8),
        ProtocolFeeLine(
          fee: stated,
          agentName: fee == null
              ? null
              : agentNameOf(ref, widget.roomId, fee.agent),
        ),
        Text(
          'Of the interest and fees, ${money(q.protocolFeeOnInterest)} goes '
          'to Stawi',
          key: const Key('group-quote-stawi'),
        ),
        Text(
          "An estimate. It comes out of the room's income, not on top of what "
          'you repay.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
