import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;

import '../data/stawi_account_service.dart';
import '../data/stawi_loan_service.dart';
import '../data/stawi_vault_service.dart';
import '../domain/loan_terms.dart';
import '../domain/personal_calls.dart';
import '../domain/signing_checks.dart' show bytesEqual;
import '../domain/stawi_money.dart';
import 'loan_detail_screen.dart';
import 'loan_widgets.dart';
import 'money_review_sheet.dart';
import 'savings_sheets.dart';
import 'stawi_feedback.dart';
import 'terms_entry.dart';

/// A loan to oneself from one's own savings: choose the pocket, the amount
/// and the terms, review, sign. Once it pays out, automatic payment of its
/// instalments is offered as a second signature.
class BorrowSelfScreen extends ConsumerStatefulWidget {
  const BorrowSelfScreen({
    this.pollEvery = const Duration(seconds: 2),
    this.pollAttempts = 15,
    super.key,
  });

  /// How the new loan is looked for once the call is final.
  final Duration pollEvery;
  final int pollAttempts;

  @override
  ConsumerState<BorrowSelfScreen> createState() => _BorrowSelfScreenState();
}

class _BorrowSelfScreenState extends ConsumerState<BorrowSelfScreen> {
  Uint8List? _pocket;
  BigInt? _amount;
  LoanTerms? _terms;
  bool _busy = false;

  /// Pockets a self-loan may come from: free savings and goals marked
  /// loanable, with money in them.
  static List<finance.SavingsPocket> _sources(finance.GetVaultResponse v) => [
    for (final p in v.pockets)
      if (canLendFrom(p) && moneyUnits(p.cash) > BigInt.zero) p,
  ];

  Future<void> _borrow(finance.SavingsPocket pocket) async {
    final amount = _amount;
    final terms = _terms;
    if (amount == null || terms == null || _busy) return;
    setState(() => _busy = true);
    try {
      final loans = ref.read(stawiLoanServiceProvider);
      final before = await runStawiAction(context, loans.borrowed);
      if (before == null || !mounted) return;
      final seen = {for (final l in before) LoanRef.of(l)};
      final call = await runMoneyAction(
        context,
        ref,
        () async => ref
            .read(stawiAccountServiceProvider)
            .preparePersonal(
              PersonalRequest.borrowSelf(
                pocket: pocketId(pocket),
                amount: amount,
                terms: terms,
              ),
              pocketName: pocketName(pocket),
            ),
      );
      if (call == null || !mounted) return;
      final last = await settleAndRefresh(ref, call);
      if (!mounted) return;
      if (last?.state != settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL) {
        Navigator.of(context).pop();
        return;
      }
      final made = await _findNewLoan(seen, amount);
      if (!mounted) return;
      if (made == null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text(
              'Your loan is on its way. Turn on Pay automatically on the loan '
              'once it shows.',
            ),
          ),
        );
        Navigator.of(context).pop();
        return;
      }
      await followAndOfferAutoPay(context, ref, LoanRef.of(made));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The self-loan of [amount] that was not among [seen], once finance has
  /// it; null when it does not show in time.
  Future<finance.Loan?> _findNewLoan(Set<LoanRef> seen, BigInt amount) async {
    final loans = ref.read(stawiLoanServiceProvider);
    for (var i = 0; i < widget.pollAttempts; i++) {
      if (i > 0) await Future<void>.delayed(widget.pollEvery);
      try {
        for (final l in await loans.borrowed()) {
          if (l.kind == finance.LoanKind.LOAN_KIND_SELF &&
              moneyUnits(l.requested) == amount &&
              !seen.contains(LoanRef.of(l))) {
            return l;
          }
        }
      } on Object {
        continue;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(myVaultProvider);
    final asset = ref.watch(stawiTestAssetProvider).asData?.value.asset;
    return Scaffold(
      appBar: AppBar(title: const Text('Borrow from my savings')),
      body: vault.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(stawiErrorMessage(e))),
        data: (v) {
          final sources = _sources(v);
          if (sources.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Add money to your free savings, or to a goal others can '
                  'borrow from, to borrow from it.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final chosen = sources
              .where(
                (p) => _pocket != null && bytesEqual(pocketId(p), _pocket!),
              )
              .firstOrNull;
          final money = asset == null || asset.assetId.isEmpty
              ? null
              : StawiAsset.fromInfo(asset);
          final assets = watchLoanAssets(ref);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AccountSetupBanner(),
              Text('From', style: Theme.of(context).textTheme.titleSmall),
              for (final p in sources)
                RadioListTile<String>(
                  key: Key('borrow-pocket-${bytesToHexKey(pocketId(p))}'),
                  value: bytesToHexKey(pocketId(p)),
                  // ignore: deprecated_member_use
                  groupValue: chosen == null
                      ? null
                      : bytesToHexKey(pocketId(chosen)),
                  // ignore: deprecated_member_use
                  onChanged: (_) => setState(() => _pocket = pocketId(p)),
                  title: Text(pocketName(p)),
                  subtitle: Text('${formatMoney(p.cash, assets)} saved'),
                ),
              const SizedBox(height: 12),
              if (chosen != null && money != null)
                TermsEntry(
                  key: ValueKey(bytesToHexKey(pocketId(chosen))),
                  kind: finance.LoanKind.LOAN_KIND_SELF,
                  asset: money,
                  maxAmount: moneyUnits(chosen.cash),
                  onChanged: (amount, terms, _) => setState(() {
                    _amount = amount;
                    _terms = terms;
                  }),
                ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('borrow-self-submit'),
                onPressed:
                    chosen == null || _amount == null || _terms == null || _busy
                    ? null
                    : () => _borrow(chosen),
                child: const Text('Borrow from my savings'),
              ),
            ],
          );
        },
      ),
    );
  }
}
