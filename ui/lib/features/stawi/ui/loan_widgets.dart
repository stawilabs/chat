import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../data/stawi_account_service.dart';
import '../data/stawi_loan_service.dart';
import '../domain/loan_view.dart';
import '../domain/stawi_money.dart';
import 'money_review_sheet.dart';
import 'stawi_feedback.dart';

/// The deployment's asset as personal loan amounts name it. Empty while it
/// loads or when it cannot be read: amounts then show in minor units.
final loanAssetsProvider = FutureProvider.autoDispose<StawiAssets>(
  (ref) async =>
      StawiAssets([(await ref.watch(stawiTestAssetProvider.future)).asset]),
);

StawiAssets watchLoanAssets(WidgetRef ref) =>
    ref.watch(loanAssetsProvider).asData?.value ?? StawiAssets.empty;

/// Whether a loan's standing order is on; an error when it cannot be read.
final standingOrderOnProvider = FutureProvider.autoDispose
    .family<bool, finance.Loan>(
      (ref, loan) =>
          ref.watch(stawiAccountServiceProvider).standingOrderOn(loan),
    );

String _date(finance.LoanInstalment i) =>
    DateFormat('d MMM').format(i.dueAt.toDateTime().toLocal());

String _money(BigInt units, String assetId, StawiAssets assets) => formatMoney(
  finance.Money(amount: units.toString(), assetId: assetId),
  assets,
);

/// A loan in a list: who, how much, what is next, and where it stands.
class LoanCard extends StatelessWidget {
  const LoanCard({
    required this.view,
    required this.assets,
    this.counterpartyName,
    this.onTap,
    super.key,
  });

  final LoanView view;
  final StawiAssets assets;
  final String? counterpartyName;
  final VoidCallback? onTap;

  String get _who {
    final name = counterpartyName;
    if (view.isSelf) return 'From my savings';
    if (view.isGroup) return 'From the room';
    return switch (view.role) {
      LoanRole.lender => name == null ? 'To them' : 'To $name',
      _ => name == null ? 'From them' : 'From $name',
    };
  }

  String get _state {
    final name = counterpartyName;
    if (view.isPersonal &&
        name != null &&
        view.loan.state == finance.LoanState.LOAN_STATE_PENDING_APPROVAL) {
      return 'Waiting for $name';
    }
    return view.stateLabel;
  }

  @override
  Widget build(BuildContext context) {
    final loan = view.loan;
    final next = view.next;
    final active = loan.state == finance.LoanState.LOAN_STATE_FUNDED;
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(_who),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatMoney(loan.requested, assets)),
            if (active && next != null)
              Text(
                'Next: ${next.hasDueAt() ? _date(next) : 'after payout'}'
                ' · ${_money(view.nextOwed, loan.requested.assetId, assets)}',
                key: const Key('loan-next'),
              ),
          ],
        ),
        trailing: Text(_state, key: const Key('loan-state')),
      ),
    );
  }
}

/// A loan's schedule, or a quote's.
class ScheduleView extends StatelessWidget {
  const ScheduleView({
    required this.instalments,
    required this.assets,
    this.emptyText,
    super.key,
  });

  final List<finance.LoanInstalment> instalments;
  final StawiAssets assets;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    if (instalments.isEmpty) {
      return emptyText == null ? const SizedBox.shrink() : Text(emptyText!);
    }
    final n = instalments.length;
    return Column(children: [for (var i = 0; i < n; i++) _row(context, i, n)]);
  }

  Widget _row(BuildContext context, int i, int n) {
    final it = instalments[i];
    final total = instalmentTotal(it);
    final owed = instalmentOwed(it);
    final paid = total > BigInt.zero && owed == BigInt.zero;
    final assetId = it.principal.assetId;
    final when = it.hasDueAt()
        ? 'Instalment ${i + 1} · ${_date(it)}'
        : '${i + 1} of $n, each one room period apart after payout';
    final partly = !paid && total > owed;
    return ListTile(
      key: Key('schedule-row-$i'),
      dense: true,
      title: Text(when),
      subtitle: partly
          ? Text('${_money(total - owed, assetId, assets)} paid')
          : null,
      leading: paid
          ? Icon(Icons.check_circle, key: Key('schedule-paid-$i'))
          : it.late
          ? Icon(
              Icons.error_outline,
              key: Key('schedule-late-$i'),
              color: Theme.of(context).colorScheme.error,
            )
          : const Icon(Icons.radio_button_unchecked),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_money(total, assetId, assets)),
          if (it.late && !paid)
            Text(
              'Late',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}

/// The switch that pays a loan's instalments automatically. Only an active
/// loan can have one.
class StandingOrderSwitch extends ConsumerWidget {
  const StandingOrderSwitch({required this.loan, super.key});

  final finance.Loan loan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const title = Text('Pay automatically');
    if (loan.state != finance.LoanState.LOAN_STATE_FUNDED) {
      return const SwitchListTile(
        key: Key('standing-order-switch'),
        title: title,
        subtitle: Text('Starts once the loan is active'),
        value: false,
        onChanged: null,
      );
    }
    final on = ref.watch(standingOrderOnProvider(loan));
    final assets = watchLoanAssets(ref);
    final largest = LoanView(loan, mine: const []).largestInstalment;
    final line = largest > BigInt.zero
        ? 'Each instalment is paid from your account when it falls due, '
              'up to ${_money(largest, loan.requested.assetId, assets)} at a time'
        : 'Each instalment is paid from your account when it falls due';
    return SwitchListTile(
      key: const Key('standing-order-switch'),
      title: title,
      subtitle: Text(
        on.hasError ? 'Could not be read just now; try again shortly' : line,
      ),
      value: on.asData?.value ?? false,
      onChanged: on.hasValue
          ? (value) async {
              final service = ref.read(stawiAccountServiceProvider);
              final call = await runMoneyAction(
                context,
                ref,
                () => service.prepareStandingOrder(loan, on: value),
              );
              if (call != null) ref.invalidate(standingOrderOnProvider(loan));
            }
          : null,
    );
  }
}

/// A borrower's credit record, own and others', in one paragraph.
class RecordSummary extends ConsumerWidget {
  const RecordSummary({required this.borrower, required this.name, super.key});

  final Uint8List borrower;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(creditRecordProvider(bytesToHex0x(borrower)));
    final assets = watchLoanAssets(ref);
    return record.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) =>
          Text(stawiErrorMessage(e), key: const Key('record-summary')),
      data: (r) => Text(
        '${_describe('$name with Stawi', r.own, assets)} '
        '${_describe('Elsewhere', r.others, assets)}',
        key: const Key('record-summary'),
      ),
    );
  }

  static String _describe(String who, finance.CreditRecord r, StawiAssets a) {
    if (r.loans == 0) return '$who: no loans yet.';
    final repaid = r.hasRepaid() ? ', repaid ${formatMoney(r.repaid, a)}' : '';
    return '$who: ${r.loans} ${r.loans == 1 ? 'loan' : 'loans'}, '
        '${r.onTime} on time, ${r.late} late, ${r.defaults} in default$repaid.';
  }
}
