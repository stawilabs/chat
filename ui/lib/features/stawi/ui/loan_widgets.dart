import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderBase;
import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../data/stawi_account_service.dart';
import '../data/stawi_loan_service.dart';
import '../data/stawi_vault_service.dart';
import '../domain/loan_view.dart';
import '../domain/personal_calls.dart' show LoanRef;
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
    .family<bool, LoanRef>(
      (ref, loanRef) =>
          ref.watch(stawiAccountServiceProvider).standingOrderOnRef(loanRef),
    );

/// What is read again after a money action: the person's loans, savings and
/// wallet, and [loanRef]'s loan and standing order when one is named.
List<ProviderBase<Object?>> moneyProviders([LoanRef? loanRef]) => [
  if (loanRef != null) loanProvider(loanRef),
  if (loanRef != null) standingOrderOnProvider(loanRef),
  myBorrowedLoansProvider,
  myLentLoansProvider,
  myVaultProvider,
  stawiWalletBalanceProvider,
];

/// Shown while a submitted call is followed until it is final.
const String waitingForCompletion = 'Waiting for this to complete…';

/// Follows the submitted [call] until it is final (or failed, expired, or
/// the follow gave up), and only then reads [providers] again through
/// [container] (taken before the action's first await). Returns the call as
/// it ended; null when it could not be read.
Future<settlement.AccountCall?> settleThenRefresh(
  ProviderContainer container,
  StawiAccountService service,
  settlement.AccountCall call,
  Iterable<ProviderBase<Object?>> providers,
) async {
  settlement.AccountCall? last;
  try {
    last = await service
        .followAccountCall(call.callId, every: service.followEvery)
        .last;
  } on Object {
    last = null;
  }
  invalidateAll(container, providers);
  return last;
}

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
/// loan can have one. A change is followed until it is final before the
/// switch reads the account again.
class StandingOrderSwitch extends ConsumerStatefulWidget {
  const StandingOrderSwitch({
    required this.loan,
    this.enabled = true,
    super.key,
  });

  final finance.Loan loan;

  /// False while another action on the loan is under way.
  final bool enabled;

  @override
  ConsumerState<StandingOrderSwitch> createState() =>
      _StandingOrderSwitchState();
}

class _StandingOrderSwitchState extends ConsumerState<StandingOrderSwitch> {
  bool _settling = false;

  Future<void> _change(bool value) async {
    final container = moneyContainer(context);
    final service = ref.read(stawiAccountServiceProvider);
    final loan = widget.loan;
    setState(() => _settling = true);
    try {
      final call = await runMoneyAction(
        context,
        ref,
        () => service.prepareStandingOrder(loan, on: value),
      );
      if (call != null) {
        await settleThenRefresh(
          container,
          service,
          call,
          moneyProviders(LoanRef.of(loan)),
        );
      }
    } finally {
      if (mounted) setState(() => _settling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
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
    final on = ref.watch(standingOrderOnProvider(LoanRef.of(loan)));
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
        _settling
            ? waitingForCompletion
            : on.hasError
            ? 'Could not be read just now; try again shortly'
            : line,
      ),
      value: on.asData?.value ?? false,
      onChanged: on.hasValue && widget.enabled && !_settling ? _change : null,
    );
  }
}

/// A borrower's credit record: their loans from others and from their own
/// savings. Someone else's is one paragraph ("Bob's record: 2 loans from
/// others (2 on time); …"); the person's own ([mine]) is two lines.
class RecordSummary extends ConsumerWidget {
  const RecordSummary({
    required this.borrower,
    required this.name,
    this.mine = false,
    super.key,
  });

  final Uint8List borrower;
  final String name;
  final bool mine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(creditRecordProvider(bytesToHex0x(borrower)));
    return record.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) =>
          Text(stawiErrorMessage(e), key: const Key('record-summary')),
      data: (r) => mine
          ? Column(
              key: const Key('record-summary'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('From my own savings: ${_line(r.own)}'),
                Text('From others: ${_line(r.others)}'),
              ],
            )
          : Text(
              "$name's record: ${_phrase(r.others, 'from others')}; "
              '${_phrase(r.own, 'from their own savings')}.',
              key: const Key('record-summary'),
            ),
    );
  }

  static String _loans(int n) => switch (n) {
    0 => 'no loans',
    1 => '1 loan',
    _ => '$n loans',
  };

  static String _how(finance.CreditRecord r) => [
    '${r.onTime} on time',
    if (r.late > 0) '${r.late} late',
    if (r.defaults > 0) '${r.defaults} in default',
  ].join(', ');

  /// "3 loans, 3 on time".
  static String _line(finance.CreditRecord r) =>
      r.loans == 0 ? 'no loans yet' : '${_loans(r.loans)}, ${_how(r)}';

  /// "2 loans from others (2 on time)".
  static String _phrase(finance.CreditRecord r, String where) => r.loans == 0
      ? 'no loans $where'
      : '${_loans(r.loans)} $where (${_how(r)})';
}

/// Shown on money screens while the person's Stawi account is being set up
/// (the first money screen starts it), or when setting it up failed, with a
/// way to try again. Nothing once the account is ready.
class AccountSetupBanner extends ConsumerWidget {
  const AccountSetupBanner({
    this.bannerKey = const Key('account-setup'),
    super.key,
  });

  /// The key of the banner while it shows.
  final Key bannerKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(stawiAccountReadyProvider);
    if (ready.hasValue && !ready.isLoading && !ready.hasError) {
      return const SizedBox.shrink();
    }
    // An error stays shown while the account is tried again.
    if (ready.hasError) {
      return Card(
        key: bannerKey,
        child: ListTile(
          leading: const Icon(Icons.error_outline),
          title: Text(stawiErrorMessage(ready.error!)),
          trailing: TextButton(
            key: const Key('account-setup-retry'),
            onPressed: () => ref.invalidate(stawiAccountReadyProvider),
            child: const Text('Try again'),
          ),
        ),
      );
    }
    return Card(
      key: bannerKey,
      child: const ListTile(
        leading: Icon(Icons.hourglass_top),
        title: Text('Setting up your Stawi account…'),
        subtitle: Text('This takes a minute the first time.'),
      ),
    );
  }
}
