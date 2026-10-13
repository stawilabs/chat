import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' as sdk;

import '../data/stawi_account_service.dart';
import '../data/stawi_identity.dart';
import '../data/stawi_loan_service.dart';
import '../data/stawi_vault_service.dart';
import '../domain/loan_terms.dart';
import '../domain/loan_view.dart';
import '../domain/money_review.dart';
import '../domain/personal_calls.dart';
import '../domain/signing_checks.dart' show bytesEqual;
import '../domain/stawi_money.dart';
import 'loan_widgets.dart';
import 'money_review_sheet.dart';
import 'pay_sheets.dart';
import 'stawi_feedback.dart';

/// The review title of the standing order offered once a loan is active.
const String autoPayTitle = 'Pay automatically for this loan';

/// The quoted schedule of a personal loan not paid out yet.
final loanQuoteProvider = FutureProvider.autoDispose
    .family<finance.QuoteLoanResponse, finance.Loan>(
      (ref, loan) => ref
          .watch(stawiLoanServiceProvider)
          .quotePersonal(
            amount: moneyUnits(loan.requested),
            terms: LoanTerms(loan.terms),
            kind: loan.kind,
          ),
    );

/// Reads the person's loans and savings again after a money action.
void invalidateLoanMoney(WidgetRef ref, [LoanRef? loanRef]) {
  if (loanRef != null) ref.invalidate(loanProvider(loanRef));
  ref
    ..invalidate(myBorrowedLoansProvider)
    ..invalidate(myLentLoansProvider)
    ..invalidate(myVaultProvider)
    ..invalidate(stawiWalletBalanceProvider);
}

/// After a loan the person borrows was accepted or taken ([callId], the
/// account call that did it): follows it until it is active and then asks
/// for its automatic payment, a second signature reviewed on its own. A loan
/// still not active when the follow gives up keeps the switch on its page.
Future<void> followAndOfferAutoPay(
  BuildContext context,
  WidgetRef ref,
  LoanRef loanRef, {
  String? callId,
}) async {
  final service = ref.read(stawiAccountServiceProvider);
  final loan = await runStawiAction(
    context,
    () => service.followUntilActive(loanRef, callId: callId),
  );
  invalidateLoanMoney(ref, loanRef);
  if (loan == null || !context.mounted) return;
  if (loan.state != finance.LoanState.LOAN_STATE_FUNDED) {
    if (loan.state == finance.LoanState.LOAN_STATE_PENDING_APPROVAL ||
        loan.state == finance.LoanState.LOAN_STATE_APPROVED) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text(
            'The loan is not active yet. Turn on Pay automatically on the '
            'loan once it is.',
          ),
        ),
      );
    }
    return;
  }
  final call = await runMoneyAction(
    context,
    ref,
    () => service.prepareStandingOrder(loan, on: true, title: autoPayTitle),
  );
  if (call != null) ref.invalidate(standingOrderOnProvider(loan));
}

/// One loan: its terms, its schedule and what the person may do with it.
class LoanDetailScreen extends ConsumerStatefulWidget {
  const LoanDetailScreen({
    required this.ref,
    this.counterpartyName,
    this.roomId,
    super.key,
  });

  /// The loan, as its LoanBook names it.
  final LoanRef ref;

  /// The other person, when known (for words only).
  final String? counterpartyName;

  /// The room a group loan belongs to.
  final String? roomId;

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  bool _busy = false;
  bool _autoPay = true;

  String get _name => widget.counterpartyName ?? 'them';

  /// Runs a money action on this loan, then reads everything again.
  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      invalidateLoanMoney(ref, widget.ref);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept(finance.Loan loan) async {
    final service = ref.read(stawiAccountServiceProvider);
    final autoPay = _autoPay;
    await _act(() async {
      final call = await runMoneyAction(
        context,
        ref,
        () async => service.preparePersonal(
          PersonalRequest.acceptOffer(offer: loan),
          counterpartyName: widget.counterpartyName,
        ),
      );
      if (call == null || !autoPay || !mounted) return;
      await followAndOfferAutoPay(
        context,
        ref,
        widget.ref,
        callId: call.callId,
      );
    });
  }

  Future<void> _cancel(finance.Loan loan) => _act(
    () async => runMoneyAction(
      context,
      ref,
      () async => ref
          .read(stawiAccountServiceProvider)
          .preparePersonal(
            PersonalRequest.cancel(loan: loan),
            counterpartyName: widget.counterpartyName,
          ),
    ),
  );

  Future<void> _lend(finance.Loan loan) => _act(() async {
    final amount = moneyUnits(loan.requested);
    final vaults = ref.read(stawiVaultServiceProvider);
    final vault = await runStawiAction(context, vaults.vault);
    if (vault == null || !mounted) return;
    final pockets = [
      for (final p in vault.pockets)
        if (canLendFrom(p) && moneyUnits(p.cash) >= amount) p,
    ];
    final assets = watchLoanAssets(ref);
    if (pockets.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            'None of your savings has ${formatMoney(loan.requested, assets)} '
            'to lend',
          ),
        ),
      );
      return;
    }
    final chosen = await showModalBottomSheet<finance.SavingsPocket>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          key: const Key('lend-pocket-picker'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Lend from',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final p in pockets)
              ListTile(
                key: Key('lend-pocket-${bytesToHexKey(pocketId(p))}'),
                title: Text(pocketName(p)),
                subtitle: Text('${formatMoney(p.cash, assets)} saved'),
                onTap: () => Navigator.of(context).pop(p),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    // The pocket is read again: what was there when the list was shown may
    // have moved since.
    final fresh = await runStawiAction(context, vaults.vault);
    if (fresh == null || !mounted) return;
    final id = pocketId(chosen);
    final now = fresh.pockets
        .where((p) => bytesEqual(pocketId(p), id))
        .firstOrNull;
    if (now == null || !canLendFrom(now) || moneyUnits(now.cash) < amount) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Not enough in ${pocketName(chosen)}')),
      );
      return;
    }
    await runMoneyAction(
      context,
      ref,
      () async => ref
          .read(stawiAccountServiceProvider)
          .preparePersonal(
            PersonalRequest.acceptAsk(ask: loan, pocket: id),
            counterpartyName: widget.counterpartyName,
            pocketName: pocketName(now),
          ),
    );
  });

  Future<void> _turnOnAutoPay(finance.Loan loan) => _act(() async {
    final call = await runMoneyAction(
      context,
      ref,
      () => ref
          .read(stawiAccountServiceProvider)
          .prepareStandingOrder(loan, on: true, title: autoPayTitle),
    );
    if (call != null) ref.invalidate(standingOrderOnProvider(loan));
  });

  @override
  Widget build(BuildContext context) {
    final loan = ref.watch(loanProvider(widget.ref));
    final mine = ref.watch(stawiIdentityProvider).asData?.value.addresses;
    return Scaffold(
      appBar: AppBar(title: const Text('Loan')),
      body: loan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(stawiErrorMessage(error), textAlign: TextAlign.center),
            TextButton(
              onPressed: () => ref.invalidate(loanProvider(widget.ref)),
              child: const Text('Try again'),
            ),
          ],
        ),
        data: (r) {
          if (mine == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final view = LoanView(r.loan, mine: mine, instalments: r.instalments);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(loanProvider(widget.ref).future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: _body(context, view),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _body(BuildContext context, LoanView view) {
    final loan = view.loan;
    final assets = watchLoanAssets(ref);
    final role = view.role;
    final pending = loan.state == finance.LoanState.LOAN_STATE_PENDING_APPROVAL;
    final active = loan.state == finance.LoanState.LOAN_STATE_FUNDED;
    final waiting =
        (view.isOpenOffer && role == LoanRole.lender) ||
        (view.isOpenAsk && role == LoanRole.borrower);
    final heading = Theme.of(context).textTheme.titleSmall;
    return [
      const AccountSetupBanner(),
      LoanCard(
        view: view,
        assets: assets,
        counterpartyName: widget.counterpartyName,
      ),
      if (waiting)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('Waiting for $_name', key: const Key('loan-waiting')),
        ),
      if (view.isPersonal && loan.hasTerms())
        _TermsView(view: view, assets: assets),
      if (view.isOpenAsk && role == LoanRole.lender)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: RecordSummary(
            borrower: Uint8List.fromList(loan.borrowerAccount),
            name: widget.counterpartyName ?? 'The borrower',
          ),
        ),
      const SizedBox(height: 8),
      Text('Schedule', style: heading),
      if (view.instalments.isNotEmpty)
        ScheduleView(instalments: view.instalments, assets: assets)
      else if (pending && view.isPersonal && loan.hasTerms())
        _QuotedSchedule(loan: loan, assets: assets)
      else
        const Text('No schedule yet'),
      if (role == LoanRole.lender && !pending)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Come back so far: ${_cameBack(loan, assets)}',
            key: const Key('loan-came-back'),
          ),
        ),
      const SizedBox(height: 16),
      ..._actions(view, pending: pending, active: active),
    ];
  }

  List<Widget> _actions(
    LoanView view, {
    required bool pending,
    required bool active,
  }) {
    final loan = view.loan;
    final role = view.role;
    if (view.isGroup) return const [];
    final busy = _busy;
    if (pending && view.isOpenOffer && role == LoanRole.borrower) {
      return [
        SwitchListTile(
          key: const Key('loan-accept-autopay'),
          title: const Text('Pay automatically'),
          subtitle: const Text(
            'Once the loan is active, each instalment is paid from your '
            'wallet when it falls due. You sign this separately.',
          ),
          value: _autoPay,
          onChanged: busy ? null : (v) => setState(() => _autoPay = v),
        ),
        FilledButton(
          key: const Key('loan-accept'),
          onPressed: busy ? null : () => _accept(loan),
          child: const Text('Accept'),
        ),
        OutlinedButton(
          key: const Key('loan-decline'),
          onPressed: busy ? null : () => _cancel(loan),
          child: const Text('Decline'),
        ),
      ];
    }
    if (pending && view.isOpenOffer && role == LoanRole.lender) {
      return [
        OutlinedButton(
          key: const Key('loan-cancel'),
          onPressed: busy ? null : () => _cancel(loan),
          child: const Text('Cancel my offer'),
        ),
      ];
    }
    if (pending && view.isOpenAsk && role == LoanRole.lender) {
      return [
        FilledButton(
          key: const Key('loan-lend'),
          onPressed: busy ? null : () => _lend(loan),
          child: const Text('Lend'),
        ),
        OutlinedButton(
          key: const Key('loan-decline'),
          onPressed: busy ? null : () => _cancel(loan),
          child: const Text('Decline'),
        ),
      ];
    }
    if (pending && view.isOpenAsk && role == LoanRole.borrower) {
      return [
        OutlinedButton(
          key: const Key('loan-cancel'),
          onPressed: busy ? null : () => _cancel(loan),
          child: const Text('Cancel my request'),
        ),
      ];
    }
    if (active && role == LoanRole.borrower) {
      final on = ref.watch(standingOrderOnProvider(loan));
      return [
        if (on.asData?.value == false)
          Card(
            key: const Key('loan-autopay-banner'),
            child: ListTile(
              title: const Text('Pay automatically?'),
              subtitle: const Text(
                'Each instalment is paid from your wallet when it falls due.',
              ),
              trailing: TextButton(
                key: const Key('loan-autopay-on'),
                onPressed: busy ? null : () => _turnOnAutoPay(loan),
                child: const Text('Turn on'),
              ),
            ),
          ),
        FilledButton(
          key: const Key('loan-pay'),
          onPressed: busy
              ? null
              : () => _act(() => showPayInstalment(context, ref, view)),
          child: const Text('Pay an instalment'),
        ),
        OutlinedButton(
          key: const Key('loan-payoff'),
          onPressed: busy
              ? null
              : () => _act(() => showPayOff(context, ref, view)),
          child: const Text('Pay off the loan'),
        ),
        StandingOrderSwitch(key: const Key('loan-standing-switch'), loan: loan),
      ];
    }
    return const [];
  }

  static String _cameBack(finance.Loan loan, StawiAssets assets) {
    final total = [
      loan.repaidPrincipal,
      loan.repaidInterest,
      loan.repaidFees,
      loan.repaidPenalties,
      loan.recovered,
    ].fold(BigInt.zero, (sum, m) => sum + moneyUnits(m));
    return formatMoney(
      finance.Money(amount: '$total', assetId: loan.requested.assetId),
      assets,
    );
  }
}

/// A short, stable key form of pocket bytes.
String bytesToHexKey(List<int> bytes) => sdk.bytesToHex(bytes);

/// A personal loan's terms, what it costs when paid on time and, for its
/// borrower, the ceiling they sign.
class _TermsView extends StatelessWidget {
  const _TermsView({required this.view, required this.assets});

  final LoanView view;
  final StawiAssets assets;

  @override
  Widget build(BuildContext context) {
    final loan = view.loan;
    final terms = LoanTerms(loan.terms);
    final amount = moneyUnits(loan.requested);
    final assetId = loan.requested.assetId;
    String money(BigInt v) =>
        formatMoney(finance.Money(amount: '$v', assetId: assetId), assets);
    List<(String, String)> lines;
    BigInt? ceiling;
    try {
      final t = terms.sdk;
      lines = [
        ...personalTermLines(t),
        ('Expected to repay', money(expectedToRepay(amount, t))),
      ];
      if (!view.isSelf && view.role == LoanRole.borrower) {
        ceiling = sdk.maxRepayable(amount, t);
      }
    } on Object {
      lines = const [('Terms', 'These terms cannot be read')];
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        key: const Key('loan-terms'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Terms', style: Theme.of(context).textTheme.titleSmall),
          for (final (label, value) in [
            ...lines,
            if (ceiling != null) ('At most you will repay', money(ceiling)),
          ])
            Row(
              children: [
                Expanded(child: Text(label)),
                Text(value),
              ],
            ),
          if (ceiling != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'The most is a ceiling for late charges, not the price: paid '
                'on time, you repay the expected amount.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              terms.lateRule,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// The schedule the loan's terms give, quoted before it is paid out.
class _QuotedSchedule extends ConsumerWidget {
  const _QuotedSchedule({required this.loan, required this.assets});

  final finance.Loan loan;
  final StawiAssets assets;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(loanQuoteProvider(loan))
      .when(
        loading: () => const Text('Working out the schedule…'),
        error: (e, _) => Text(stawiErrorMessage(e)),
        data: (q) => ScheduleView(
          instalments: q.instalments,
          assets: assets,
          emptyText: 'No schedule yet',
        ),
      );
}

/// A /loan link that names no loan.
class InvalidLoanLinkScreen extends StatelessWidget {
  const InvalidLoanLinkScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Loan')),
    body: const Center(child: Text('This loan link is not valid')),
  );
}
