import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' as sdk;

import '../data/stawi_loan_service.dart';
import '../domain/loan_terms.dart';
import '../domain/loan_view.dart';
import '../domain/stawi_money.dart';
import 'stawi_feedback.dart';

/// Basis points from a percent a person typed ("2.5" is 250). Whole basis
/// points only, so at most two decimals; no floating point. Null when it is
/// not such a number. Empty is 0.
int? parsePercentBps(String input) {
  final text = input.trim().replaceAll('%', '');
  if (text.isEmpty) return 0;
  final m = RegExp(r'^(\d{1,3})(?:\.(\d{1,2}))?$').firstMatch(text);
  if (m == null) return null;
  final frac = (m.group(2) ?? '').padRight(2, '0');
  return int.parse(m.group(1)!) * 100 + int.parse(frac);
}

enum _Late { none, flat, percent }

/// Amount and terms of a personal loan, with a live quote. [onChanged] gets
/// the amount, terms and quote the draft has so far; all null while the draft
/// is not one that can be quoted.
class TermsEntry extends ConsumerStatefulWidget {
  const TermsEntry({
    required this.kind,
    required this.asset,
    required this.onChanged,
    this.maxAmount,
    super.key,
  });

  /// SELF or PERSON_TO_PERSON.
  final finance.LoanKind kind;
  final StawiAsset asset;
  final void Function(
    BigInt? amount,
    LoanTerms? terms,
    finance.QuoteLoanResponse? quote,
  )
  onChanged;

  /// The most that may be entered, when there is a limit (a pocket's balance).
  final BigInt? maxAmount;

  @override
  ConsumerState<TermsEntry> createState() => _TermsEntryState();
}

class _TermsEntryState extends ConsumerState<TermsEntry> {
  static const _quoteDelay = Duration(milliseconds: 400);

  final _amount = TextEditingController();
  final _rate = TextEditingController();
  final _lateFlat = TextEditingController();
  final _latePercent = TextEditingController(text: '5');
  final _defaultDays = TextEditingController(text: '30');

  LoanPreset? _preset;
  bool _more = false;
  finance.LoanInterestMethod _method =
      finance.LoanInterestMethod.LOAN_INTEREST_METHOD_FLAT;
  late _Late _late = _self ? _Late.none : _Late.percent;

  Timer? _timer;
  int _seq = 0;
  String? _error;
  BigInt? _amountUnits;
  LoanTerms? _terms;
  finance.QuoteLoanResponse? _quote;
  Object? _quoteError;
  bool _quoting = false;

  bool get _self => widget.kind == finance.LoanKind.LOAN_KIND_SELF;

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_amount, _rate, _lateFlat, _latePercent, _defaultDays]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Reads the draft: sets [_error], [_amountUnits] and [_terms], then quotes
  /// after the last edit.
  void _edited() {
    _timer?.cancel();
    final seq = ++_seq;
    _quote = null;
    _quoteError = null;
    _quoting = false;
    _error = null;
    _amountUnits = null;
    _terms = null;
    _read();
    setState(() {});
    widget.onChanged(_amountUnits, _terms, null);
    if (_terms != null) {
      _quoting = true;
      _timer = Timer(_quoteDelay, () => _runQuote(seq));
    }
  }

  void _read() {
    final preset = _preset;
    if (_amount.text.trim().isEmpty) {
      return;
    }
    try {
      final amount = BigInt.parse(parseAmountInput(_amount.text, widget.asset));
      final max = widget.maxAmount;
      if (max != null && amount > max) {
        _error = 'That is more than ${formatUnits(max, widget.asset)}';
        return;
      }
      if (preset == null) return;
      final rate = parsePercentBps(_rate.text);
      if (rate == null) {
        _error = 'Enter the interest as a percent, such as 2.5';
        return;
      }
      if (rate > 5000) {
        _error = 'Interest per instalment is at most 50%';
        return;
      }
      final base = LoanTerms.preset(preset, rateBps: rate, kind: widget.kind);
      final p = base.proto..method = _method;
      final days = int.tryParse(_defaultDays.text.trim());
      if (days == null) {
        _error = 'Enter the days after a missed instalment as a number';
        return;
      }
      p.defaultAfterDays = days;
      if (_self) {
        p
          ..latePenalty = finance.PenaltyMethod.PENALTY_METHOD_NONE
          ..lateBps = 0
          ..lateFlat = '';
      } else {
        switch (_late) {
          case _Late.none:
            p
              ..latePenalty = finance.PenaltyMethod.PENALTY_METHOD_NONE
              ..lateBps = 0
              ..lateFlat = '';
          case _Late.flat:
            p
              ..latePenalty = finance.PenaltyMethod.PENALTY_METHOD_FLAT
              ..lateBps = 0
              ..lateFlat = parseAmountInput(_lateFlat.text, widget.asset);
          case _Late.percent:
            final bps = parsePercentBps(_latePercent.text);
            if (bps == null || bps > 10000) {
              _error = 'Enter the late charge as a percent, such as 5';
              return;
            }
            p
              ..latePenalty =
                  finance.PenaltyMethod.PENALTY_METHOD_PERCENT_OF_SHORTFALL
              ..lateBps = bps
              ..lateFlat = '';
        }
      }
      final terms = LoanTerms(p);
      final why = terms.validate(amount, widget.kind);
      if (why != null) {
        _error = why;
        return;
      }
      _amountUnits = amount;
      _terms = terms;
    } on FormatException catch (e) {
      _error = e.message;
    }
  }

  Future<void> _runQuote(int seq) async {
    final amount = _amountUnits;
    final terms = _terms;
    if (amount == null || terms == null) return;
    try {
      final quote = await ref
          .read(stawiLoanServiceProvider)
          .quotePersonal(amount: amount, terms: terms, kind: widget.kind);
      if (!mounted || seq != _seq) return;
      setState(() {
        _quote = quote;
        _quoting = false;
      });
      widget.onChanged(amount, terms, quote);
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

  String _money(String units) {
    final v = BigInt.tryParse(units);
    return v == null || units.isEmpty ? '—' : formatUnits(v, widget.asset);
  }

  Widget _quoteView(BuildContext context) {
    if (_quoteError != null) {
      return Column(
        key: const Key('terms-quote'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stawiErrorMessage(_quoteError!)),
          TextButton(
            key: const Key('terms-quote-retry'),
            onPressed: _retry,
            child: const Text('Try again'),
          ),
        ],
      );
    }
    final quote = _quote;
    if (quote == null) {
      return _quoting
          ? const Text('Working out the cost…', key: Key('terms-quote'))
          : const SizedBox.shrink();
    }
    final n = quote.instalments.length;
    final first = quote.instalments.isEmpty ? null : quote.instalments.first;
    final firstOwed = first == null
        ? '—'
        : _money(instalmentTotal(first).toString());
    final when = first != null && first.hasDueAt()
        ? ' on ${DateFormat('d MMM').format(first.dueAt.toDateTime().toLocal())}'
        : '';
    final all = _money(quote.totalRepayable.amount);
    final max = _terms == null || _amountUnits == null
        ? null
        : _maxRepayable(_amountUnits!, _terms!);
    return Column(
      key: const Key('terms-quote'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'First of $n instalments: $firstOwed$when · $all in all',
          key: const Key('terms-quote-line'),
        ),
        if (max != null)
          Text(
            'At most you will repay ${formatUnits(max, widget.asset)}',
            key: const Key('terms-max-repay'),
          ),
      ],
    );
  }

  BigInt? _maxRepayable(BigInt amount, LoanTerms terms) {
    try {
      return sdk.maxRepayable(amount, terms.sdk);
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('terms-amount'),
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount (${widget.asset.symbol})',
          ),
          onChanged: (_) => _edited(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final p in LoanPreset.values)
              ChoiceChip(
                key: Key('terms-preset-${p.name}'),
                label: Text(p.label),
                selected: _preset == p,
                onSelected: (_) {
                  _preset = p;
                  _edited();
                },
              ),
          ],
        ),
        TextField(
          key: const Key('terms-rate'),
          controller: _rate,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Interest per instalment (%)',
            hintText: '0',
          ),
          onChanged: (_) => _edited(),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('terms-more'),
            onPressed: () => setState(() => _more = !_more),
            child: Text(_more ? 'Fewer choices' : 'More choices'),
          ),
        ),
        if (_more) ..._moreChoices(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _error!,
              key: const Key('terms-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        _quoteView(context),
        if (_terms != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _terms!.lateRule,
              key: const Key('terms-late-rule'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  List<Widget> _moreChoices() {
    Widget method(String key, String label, finance.LoanInterestMethod m) =>
        ChoiceChip(
          key: Key('terms-method-$key'),
          label: Text(label),
          selected: _method == m,
          onSelected: (_) {
            _method = m;
            _edited();
          },
        );
    Widget late(String key, String label, _Late l) => ChoiceChip(
      key: Key('terms-late-$key'),
      label: Text(label),
      selected: _late == l,
      onSelected: (_) {
        _late = l;
        _edited();
      },
    );
    return [
      const Text('How interest is worked out'),
      Wrap(
        spacing: 8,
        children: [
          method(
            'flat',
            'Flat',
            finance.LoanInterestMethod.LOAN_INTEREST_METHOD_FLAT,
          ),
          method(
            'declining',
            'On what is left',
            finance
                .LoanInterestMethod
                .LOAN_INTEREST_METHOD_DECLINING_EQUAL_PRINCIPAL,
          ),
          method(
            'amortized',
            'Equal instalments',
            finance.LoanInterestMethod.LOAN_INTEREST_METHOD_AMORTIZED,
          ),
        ],
      ),
      if (!_self) ...[
        const SizedBox(height: 8),
        const Text('If an instalment is late'),
        Wrap(
          spacing: 8,
          children: [
            late('none', 'No charge', _Late.none),
            late('flat', 'A set amount', _Late.flat),
            late('percent', 'A share of what is missed', _Late.percent),
          ],
        ),
        if (_late == _Late.flat)
          TextField(
            key: const Key('terms-late-flat-amount'),
            controller: _lateFlat,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Late charge (${widget.asset.symbol})',
            ),
            onChanged: (_) => _edited(),
          ),
        if (_late == _Late.percent)
          TextField(
            key: const Key('terms-late-percent-amount'),
            controller: _latePercent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Late charge (% of what is missed)',
            ),
            onChanged: (_) => _edited(),
          ),
      ],
      TextField(
        key: const Key('terms-default-days'),
        controller: _defaultDays,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Days after a missed instalment before default',
        ),
        onChanged: (_) => _edited(),
      ),
    ];
  }
}
