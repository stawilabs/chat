import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Refreshable;
import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../../../core/networking/api_config.dart';
import '../data/stawi_account_service.dart';
import '../data/stawi_counterparty.dart';
import '../data/stawi_identity.dart';
import '../data/stawi_loan_service.dart';
import '../data/stawi_vault_service.dart';
import '../domain/loan_view.dart';
import '../domain/personal_calls.dart';
import '../domain/stawi_money.dart';
import 'borrow_self_screen.dart';
import 'loan_detail_screen.dart';
import 'loan_widgets.dart';
import 'personal_statement_screen.dart';
import 'savings_sheets.dart';
import 'stawi_feedback.dart';

/// The person's own money: wallet, free savings, savings goals, borrowing
/// from their savings, their loans, their record and statements.
class MyMoneyScreen extends ConsumerWidget {
  MyMoneyScreen({
    bool? showTestFunds,
    this.pollEvery = const Duration(seconds: 2),
    super.key,
  }) : showTestFunds = showTestFunds ?? ApiConfig.testFundsEnabled;

  /// Offer the testnet faucet as "Add money" (never in production builds,
  /// and only when the deployment's faucet is on).
  final bool showTestFunds;

  /// How a new goal or self-loan is looked for once its call is final.
  final Duration pollEvery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(myVaultProvider);
    final assets = watchLoanAssets(ref);
    Widget section(Key key, String title, List<Widget> children) => Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
    final pockets =
        vault.asData?.value.pockets ?? const <finance.SavingsPocket>[];
    final free = pockets.where(isFreeSavings).firstOrNull;
    final goals = [
      for (final p in pockets)
        if (!isFreeSavings(p)) p,
    ];
    Widget vaultState(Widget Function() data) => vault.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => _Retry(
        message: stawiErrorMessage(e),
        onRetry: () => ref.invalidate(myVaultProvider),
      ),
      data: (_) => data(),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('My money')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(stawiAccountReadyProvider);
          Future<void> again<T>(Refreshable<Future<T>> p) async {
            final next = ref.refresh(p);
            try {
              await next;
            } on Object {
              // The section shows its own error.
            }
          }

          await Future.wait([
            again(myVaultProvider.future),
            again(myBorrowedLoansProvider.future),
            again(myLentLoansProvider.future),
            again(stawiWalletBalanceProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const AccountSetupBanner(bannerKey: Key('money-setup')),
            section(const Key('money-wallet'), 'Wallet', [
              _WalletView(showTestFunds: showTestFunds),
            ]),
            section(const Key('money-free'), 'Free savings', [
              vaultState(
                () => _FreeSavingsView(
                  pocket: free ?? finance.SavingsPocket(pocket: Uint8List(32)),
                  assets: assets,
                ),
              ),
            ]),
            section(const Key('money-goals'), 'Savings goals', [
              vaultState(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (goals.isEmpty)
                      const Text('No goals yet: save toward something.'),
                    for (final g in goals)
                      _GoalTile(
                        goal: g,
                        freeCash: free == null
                            ? BigInt.zero
                            : moneyUnits(free.cash),
                        assets: assets,
                      ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('money-new-goal'),
                  icon: const Icon(Icons.add),
                  label: const Text('New goal'),
                  onPressed: () =>
                      startGoal(context, ref, pollEvery: pollEvery),
                ),
              ),
            ]),
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                key: const Key('money-borrow-self'),
                leading: const Icon(Icons.savings_outlined),
                title: const Text('Borrow from my savings'),
                subtitle: const Text(
                  'A loan to yourself, repaid into the pocket it came from',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BorrowSelfScreen(pollEvery: pollEvery),
                  ),
                ),
              ),
            ),
            section(const Key('money-loans'), 'My loans', const [_MyLoans()]),
            section(const Key('money-record'), 'My record', const [
              _MyRecord(),
            ]),
            Card(
              child: ListTile(
                key: const Key('money-statements'),
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Statements'),
                subtitle: const Text('Every movement in your savings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PersonalStatementScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(message)),
      TextButton(onPressed: onRetry, child: const Text('Try again')),
    ],
  );
}

class _WalletView extends ConsumerWidget {
  const _WalletView({required this.showTestFunds});

  final bool showTestFunds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(stawiWalletBalanceProvider);
    final faucet = ref.watch(stawiTestAssetProvider).asData?.value;
    final info = faucet?.asset;
    final asset = info == null || info.assetId.isEmpty
        ? null
        : StawiAsset.fromInfo(info);
    final units = balance.asData?.value;
    final shown = units == null || asset == null
        ? '—'
        : formatUnits(units, asset);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          shown,
          key: const Key('wallet-balance'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Text('Money in your Stawi account, ready to use'),
        Wrap(
          spacing: 8,
          children: [
            if (showTestFunds &&
                asset != null &&
                (faucet?.faucetEnabled ?? false))
              OutlinedButton(
                key: const Key('wallet-add'),
                onPressed: () => addTestMoney(context, ref, asset),
                child: const Text('Add money'),
              ),
            OutlinedButton(
              key: const Key('wallet-send'),
              onPressed: () => sendOut(context, ref),
              child: const Text('Send'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FreeSavingsView extends ConsumerWidget {
  const _FreeSavingsView({required this.pocket, required this.assets});

  final finance.SavingsPocket pocket;
  final StawiAssets assets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cash = moneyUnits(pocket.cash);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Saved: ${_money(pocket.cash, assets)}',
          key: const Key('free-cash'),
        ),
        Text(
          'Lent out: ${_money(pocket.lent, assets)}',
          key: const Key('free-lent'),
        ),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              key: const Key('free-add'),
              onPressed: () => addMoney(
                context,
                ref,
                pocket: Uint8List(32),
                name: 'Free savings',
              ),
              child: const Text('Add money'),
            ),
            OutlinedButton(
              key: const Key('free-withdraw'),
              onPressed: cash > BigInt.zero
                  ? () => withdrawSavings(context, ref, pocket: pocket)
                  : null,
              child: const Text('Withdraw my savings'),
            ),
          ],
        ),
      ],
    );
  }
}

String _money(finance.Money m, StawiAssets assets) => m.amount.isEmpty
    ? formatMoney(finance.Money(amount: '0', assetId: m.assetId), assets)
    : formatMoney(m, assets);

/// [m] without its symbol, for "50.00 of 200.00 USDC".
String _number(finance.Money m, StawiAssets assets) {
  final shown = _money(m, assets);
  final symbol = ' ${assets.of(m.assetId).symbol}';
  return shown.endsWith(symbol)
      ? shown.substring(0, shown.length - symbol.length)
      : shown;
}

String _date(finance.SavingsPocket g) =>
    DateFormat.yMMMd().format(g.unlockAt.toDateTime().toLocal());

bool _unlocked(finance.SavingsPocket g) =>
    !g.hasUnlockAt() || !g.unlockAt.toDateTime().isAfter(DateTime.now());

/// A goal: how far along it is, when it unlocks, whether it can be lent.
class _GoalTile extends ConsumerWidget {
  const _GoalTile({
    required this.goal,
    required this.freeCash,
    required this.assets,
  });

  final finance.SavingsPocket goal;
  final BigInt freeCash;
  final StawiAssets assets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = moneyUnits(goal.cash) + moneyUnits(goal.lent);
    final target = moneyUnits(goal.target);
    final savedMoney = finance.Money(
      amount: '$saved',
      assetId: goal.target.assetId.isEmpty
          ? goal.cash.assetId
          : goal.target.assetId,
    );
    // Parts per thousand, in integers: the bar is two flexes, no fractions.
    final thousand = BigInt.from(1000);
    final ratio = target <= BigInt.zero
        ? BigInt.zero
        : saved * thousand ~/ target;
    final permille = (ratio > thousand ? thousand : ratio).toInt();
    final id = bytesToHexKey(pocketId(goal));
    final color = Theme.of(context).colorScheme;
    return ListTile(
      key: Key('goal-$id'),
      contentPadding: EdgeInsets.zero,
      title: Text(pocketName(goal)),
      onTap: () => _actions(context, ref),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  if (permille > 0)
                    Expanded(
                      flex: permille,
                      child: ColoredBox(color: color.primary),
                    ),
                  if (permille < 1000)
                    Expanded(
                      flex: 1000 - permille,
                      child: ColoredBox(color: color.surfaceContainerHighest),
                    ),
                ],
              ),
            ),
          ),
          Text(
            '${_number(savedMoney, assets)} of ${_money(goal.target, assets)}',
          ),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(_unlocked(goal) ? 'Unlocked' : 'Unlocks ${_date(goal)}'),
              if (goal.loanable)
                const Chip(
                  label: Text('Can be lent'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _actions(BuildContext context, WidgetRef ref) async {
    final name = pocketName(goal);
    final unlocked = _unlocked(goal);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(name, style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              key: const Key('goal-add'),
              leading: const Icon(Icons.add),
              title: const Text('Add money'),
              onTap: () => Navigator.of(context).pop('add'),
            ),
            ListTile(
              key: const Key('goal-move'),
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Move from free savings'),
              enabled: freeCash > BigInt.zero,
              onTap: () => Navigator.of(context).pop('move'),
            ),
            if (unlocked)
              ListTile(
                key: const Key('goal-withdraw'),
                leading: const Icon(Icons.arrow_upward),
                title: const Text('Withdraw my savings'),
                enabled: moneyUnits(goal.cash) > BigInt.zero,
                onTap: () => Navigator.of(context).pop('withdraw'),
              )
            else
              ListTile(
                key: const Key('goal-locked'),
                leading: const Icon(Icons.lock_outline),
                title: Text('Locked until ${_date(goal)}'),
                enabled: false,
              ),
            ListTile(
              key: const Key('goal-statement'),
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Statement'),
              onTap: () => Navigator.of(context).pop('statement'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'add':
        await addMoney(context, ref, pocket: pocketId(goal), name: name);
      case 'move':
        await moveToGoal(context, ref, goal: goal, freeCash: freeCash);
      case 'withdraw':
        await withdrawSavings(context, ref, pocket: goal);
      case 'statement':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                PersonalStatementScreen(pocket: pocketId(goal), title: name),
          ),
        );
    }
  }
}

/// The person's loans: borrowed and lent, those waiting for them first.
class _MyLoans extends ConsumerStatefulWidget {
  const _MyLoans();

  @override
  ConsumerState<_MyLoans> createState() => _MyLoansState();
}

class _MyLoansState extends ConsumerState<_MyLoans>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() {
      if (mounted) setState(() {});
    });

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lent = _tabs.index == 1;
    final loans = ref.watch(
      lent ? myLentLoansProvider : myBorrowedLoansProvider,
    );
    final mine = ref.watch(stawiIdentityProvider).asData?.value.addresses;
    final assets = watchLoanAssets(ref);
    // The other person of a loan between two, by their DM's name; asked of
    // chat only when there is such a loan.
    final hasPair =
        loans.asData?.value.any(
          (l) => l.kind == finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
        ) ??
        false;
    final names = hasPair
        ? ref.watch(dmPartnerNamesProvider).asData?.value ?? const {}
        : const <String, String>{};
    String? nameOf(LoanView v) {
      final other = v.counterparty;
      return other == null ? null : names[bytesToHex0x(other).toLowerCase()];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabs,
          labelColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(key: Key('loans-borrowed'), text: 'Borrowed'),
            Tab(key: Key('loans-lent'), text: 'Lent'),
          ],
        ),
        loans.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => _Retry(
            message: stawiErrorMessage(e),
            onRetry: () => ref.invalidate(
              lent ? myLentLoansProvider : myBorrowedLoansProvider,
            ),
          ),
          data: (list) {
            if (mine == null) return const SizedBox.shrink();
            // Waiting for me first, then newest first; the loan id breaks
            // ties so the order does not change between reads.
            final views = [for (final l in list) LoanView(l, mine: mine)]
              ..sort((a, b) {
                final needs = (b.awaitsMe ? 1 : 0) - (a.awaitsMe ? 1 : 0);
                if (needs != 0) return needs;
                final byId = b.loan.onchainLoanId.compareTo(
                  a.loan.onchainLoanId,
                );
                if (byId != 0) return byId;
                return bytesToHexKey(b.loan.pool)
                    .compareTo(bytesToHexKey(a.loan.pool));
              });
            if (views.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text(lent ? 'Nothing lent yet' : 'Nothing borrowed'),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final v in views)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (v.awaitsMe)
                        const Chip(
                          key: Key('loan-needs-you'),
                          label: Text('Needs you'),
                          visualDensity: VisualDensity.compact,
                        ),
                      LoanCard(
                        view: v,
                        assets: assets,
                        counterpartyName: nameOf(v),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LoanDetailScreen(
                              ref: LoanRef.of(v.loan),
                              counterpartyName: nameOf(v),
                            ),
                          ),
                        ),
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

/// The person's own credit record, and who sees it.
class _MyRecord extends ConsumerWidget {
  const _MyRecord();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(stawiIdentityProvider).asData?.value.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (me != null)
          RecordSummary(borrower: me.address, name: 'You', mine: true),
        const SizedBox(height: 4),
        Text(
          'Only you see this. It is shared with someone you ask to lend, or '
          "a group's approvers, while that request is open.",
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
