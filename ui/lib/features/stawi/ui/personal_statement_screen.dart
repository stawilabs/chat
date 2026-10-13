import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import '../data/stawi_identity.dart';
import '../data/stawi_vault_service.dart';
import '../domain/signing_checks.dart' show bytesEqual;
import '../domain/stawi_money.dart';
import 'loan_widgets.dart';
import 'stawi_feedback.dart';

/// What a vault statement line is called; null for a line that is not
/// listed (a forgiven loan moves no cash).
String? vaultEntryLabel(
  finance.VaultStatementEntry e, {
  List<Uint8List> mine = const [],
}) => switch (e.event) {
  'Deposited' => 'Added',
  'Withdrawn' => 'Withdrawn',
  'Moved' => 'Moved',
  'Gathered' => 'Collected for a loan',
  'LoanDisbursed' =>
    mine.any((a) => bytesEqual(a, e.counterparty)) ||
            moneyUnits(e.amountIn) > BigInt.zero
        ? 'Borrowed'
        : 'Lent',
  'LoanRepaid' => 'Repaid to this pocket',
  'LoanWrittenOff' => null,
  _ => e.event,
};

/// The person's savings statement: every pocket, or one ([pocket]). Newest
/// first, a page at a time.
class PersonalStatementScreen extends ConsumerStatefulWidget {
  const PersonalStatementScreen({this.pocket, this.title, super.key});

  /// One pocket (32 bytes; all zero: free savings); null for all of them.
  final Uint8List? pocket;
  final String? title;

  @override
  ConsumerState<PersonalStatementScreen> createState() =>
      _PersonalStatementScreenState();
}

class _PersonalStatementScreenState
    extends ConsumerState<PersonalStatementScreen> {
  final List<finance.VaultStatementEntry> _entries = [];
  String _next = '';
  bool _more = false;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool again = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (again) {
        _entries.clear();
        _next = '';
      }
    });
    try {
      final page = await ref
          .read(stawiVaultServiceProvider)
          .statement(pocket: widget.pocket, page: _next);
      if (!mounted) return;
      setState(() {
        _entries
          ..addAll(page.entries)
          ..sort((a, b) => b.at.seconds.compareTo(a.at.seconds));
        _next = page.page.nextCursor;
        _more = page.page.hasMore && _next.isNotEmpty;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assets = watchLoanAssets(ref);
    final mine =
        ref.watch(stawiIdentityProvider).asData?.value.addresses ?? const [];
    final rows = [
      for (final e in _entries)
        if (vaultEntryLabel(e, mine: mine) case final label?) (e, label),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Statement')),
      body: RefreshIndicator(
        onRefresh: () => _load(again: true),
        child: ListView(
          key: const Key('personal-statement'),
          children: [
            for (final (e, label) in rows)
              ListTile(
                title: Text(label),
                subtitle: Text(
                  [
                    if (e.hasAt())
                      DateFormat.yMMMd().format(e.at.toDateTime().toLocal()),
                    if (e.loanId > 0) 'Loan #${e.loanId}',
                  ].join(' · '),
                ),
                trailing: Text(_amount(e, assets)),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(stawiErrorMessage(_error!)),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_more)
              TextButton(
                key: const Key('statement-more'),
                onPressed: _load,
                child: const Text('Show older'),
              )
            else if (rows.isEmpty && _error == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nothing here yet', textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }

  static String _amount(finance.VaultStatementEntry e, StawiAssets assets) {
    final into = moneyUnits(e.amountIn);
    if (into > BigInt.zero) return '+${formatMoney(e.amountIn, assets)}';
    return '−${formatMoney(e.amountOut, assets)}';
  }
}
