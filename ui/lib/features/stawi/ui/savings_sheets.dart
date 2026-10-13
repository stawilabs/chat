import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;

import '../data/stawi_account_service.dart';
import '../data/stawi_identity.dart' show StawiUnavailable;
import '../data/stawi_vault_service.dart';
import '../domain/personal_calls.dart';
import '../domain/stawi_money.dart';
import 'dm_partner_picker.dart';
import 'loan_detail_screen.dart' show invalidateLoanMoney;
import 'money_review_sheet.dart';
import 'stawi_account_screen.dart' show TestFundsDialog;
import 'stawi_feedback.dart';

/// The deployment's asset, every personal amount is in; null (with a snack
/// bar) when it cannot be read.
Future<StawiAsset?> readMoneyAsset(BuildContext context, WidgetRef ref) =>
    runStawiAction(context, () async {
      final info = (await ref.read(stawiTestAssetProvider.future)).asset;
      if (info.assetId.isEmpty) {
        throw const StawiUnavailable('The money asset could not be read');
      }
      return StawiAsset.fromInfo(info);
    });

/// Asks for an amount of [asset] (integer minor units back, no floating
/// point); null when dismissed. [max], when given, is the most allowed.
Future<BigInt?> showAmountSheet(
  BuildContext context, {
  required String title,
  required StawiAsset asset,
  required String confirmLabel,
  BigInt? max,
  String? note,
}) => showModalBottomSheet<BigInt>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _AmountSheet(
    title: title,
    asset: asset,
    confirmLabel: confirmLabel,
    max: max,
    note: note,
  ),
);

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.title,
    required this.asset,
    required this.confirmLabel,
    this.max,
    this.note,
  });

  final String title;
  final StawiAsset asset;
  final String confirmLabel;
  final BigInt? max;
  final String? note;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final _amount = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _confirm() {
    try {
      final units = BigInt.parse(parseAmountInput(_amount.text, widget.asset));
      if (units <= BigInt.zero) {
        throw const FormatException('Enter an amount greater than zero');
      }
      final max = widget.max;
      if (max != null && units > max) {
        throw FormatException(
          'That is more than ${formatUnits(max, widget.asset)}',
        );
      }
      Navigator.of(context).pop(units);
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.max;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          if (widget.note != null) ...[
            const SizedBox(height: 8),
            Text(widget.note!),
          ],
          if (max != null) Text('Up to ${formatUnits(max, widget.asset)}'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('amount-field'),
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount (${widget.asset.symbol})',
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('amount-confirm'),
            onPressed: _confirm,
            child: Text(widget.confirmLabel),
          ),
        ],
      ),
    );
  }
}

/// Waits for a submitted call to be final, then reads the person's money
/// again. Returns the call as it ended.
Future<settlement.AccountCall?> settleAndRefresh(
  WidgetRef ref,
  settlement.AccountCall call,
) async {
  settlement.AccountCall? last;
  try {
    last = await ref
        .read(stawiAccountServiceProvider)
        .followAccountCall(call.callId)
        .last;
  } on Object {
    last = null;
  }
  invalidateLoanMoney(ref);
  return last;
}

/// Adds money from the wallet to [pocket] (all zero: free savings).
Future<void> addMoney(
  BuildContext context,
  WidgetRef ref, {
  required Uint8List pocket,
  required String name,
}) async {
  final asset = await readMoneyAsset(context, ref);
  if (asset == null || !context.mounted) return;
  final amount = await showAmountSheet(
    context,
    title: 'Add money to $name',
    asset: asset,
    confirmLabel: 'Add money',
    note: 'From your wallet',
  );
  if (amount == null || !context.mounted) return;
  final call = await runMoneyAction(
    context,
    ref,
    () => ref
        .read(stawiAccountServiceProvider)
        .prepareDeposit(pocket: pocket, amount: amount, pocketName: name),
  );
  if (call != null) await settleAndRefresh(ref, call);
}

/// Takes money out of [pocket] back to the wallet, at most what it holds.
Future<void> withdrawSavings(
  BuildContext context,
  WidgetRef ref, {
  required finance.SavingsPocket pocket,
}) async {
  final asset = await readMoneyAsset(context, ref);
  if (asset == null || !context.mounted) return;
  final name = pocketName(pocket);
  final amount = await showAmountSheet(
    context,
    title: 'Withdraw from $name',
    asset: asset,
    confirmLabel: 'Withdraw my savings',
    max: moneyUnits(pocket.cash),
    note: 'Back to your wallet',
  );
  if (amount == null || !context.mounted) return;
  final call = await runMoneyAction(
    context,
    ref,
    () async => ref
        .read(stawiAccountServiceProvider)
        .preparePersonal(
          PersonalRequest.withdraw(pocket: pocketId(pocket), amount: amount),
          pocketName: name,
        ),
  );
  if (call != null) await settleAndRefresh(ref, call);
}

/// Moves money from free savings into the goal [goal].
Future<void> moveToGoal(
  BuildContext context,
  WidgetRef ref, {
  required finance.SavingsPocket goal,
  required BigInt freeCash,
}) async {
  final asset = await readMoneyAsset(context, ref);
  if (asset == null || !context.mounted) return;
  final amount = await showAmountSheet(
    context,
    title: 'Move from free savings to ${pocketName(goal)}',
    asset: asset,
    confirmLabel: 'Move my savings',
    max: freeCash,
  );
  if (amount == null || !context.mounted) return;
  final call = await runMoneyAction(
    context,
    ref,
    () async => ref
        .read(stawiAccountServiceProvider)
        .preparePersonal(
          PersonalRequest.move(
            from: Uint8List(32),
            to: pocketId(goal),
            amount: amount,
          ),
        ),
  );
  if (call != null) await settleAndRefresh(ref, call);
}

/// Sends money from the wallet to one of the person's DM partners. There is
/// no typed address.
Future<void> sendOut(BuildContext context, WidgetRef ref) async {
  final to = await showDmPartnerPicker(context);
  if (to == null || !context.mounted) return;
  final asset = await readMoneyAsset(context, ref);
  if (asset == null || !context.mounted) return;
  final amount = await showAmountSheet(
    context,
    title: 'Send to ${to.name ?? 'them'}',
    asset: asset,
    confirmLabel: 'Send',
    note: 'From your wallet',
  );
  if (amount == null || !context.mounted) return;
  final call = await runMoneyAction(
    context,
    ref,
    () => ref
        .read(stawiAccountServiceProvider)
        .prepareTransferOut(to: to, amount: amount),
  );
  if (call != null) await settleAndRefresh(ref, call);
}

/// Mints test money to the wallet (testnet only: settlement refuses it
/// unless the deployment's faucet is on).
Future<void> addTestMoney(
  BuildContext context,
  WidgetRef ref,
  StawiAsset asset,
) async {
  final amount = await showDialog<String>(
    context: context,
    builder: (_) => TestFundsDialog(asset: asset),
  );
  if (amount == null || !context.mounted) return;
  final funded = await runStawiAction(
    context,
    () => ref.read(stawiAccountServiceProvider).fundTestAccount(amount, asset),
    success: 'Test money is on its way to your wallet',
  );
  if (funded != null) invalidateSoon(ref, [stawiWalletBalanceProvider]);
}

/// What a new savings goal is to be.
typedef NewGoal = ({
  String name,
  BigInt target,
  DateTime unlockAt,
  bool loanable,
});

/// Starts a savings goal, then names it once the chain has it: the goal id
/// is read back from the vault (the newest unnamed goal with this target and
/// unlock time). [pollEvery] spaces those reads.
Future<void> startGoal(
  BuildContext context,
  WidgetRef ref, {
  Duration pollEvery = const Duration(seconds: 2),
  int pollAttempts = 10,
}) async {
  final asset = await readMoneyAsset(context, ref);
  if (asset == null || !context.mounted) return;
  final goal = await showModalBottomSheet<NewGoal>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _NewGoalSheet(asset: asset),
  );
  if (goal == null || !context.mounted) return;
  final request = await runStawiAction(
    context,
    () async => PersonalRequest.createGoal(
      name: goal.name,
      target: goal.target,
      unlockAt: goal.unlockAt,
      loanable: goal.loanable,
    ),
  );
  if (request == null || !context.mounted) return;
  final call = await runMoneyAction(
    context,
    ref,
    () => ref.read(stawiAccountServiceProvider).preparePersonal(request),
  );
  if (call == null) return;
  final last = await settleAndRefresh(ref, call);
  if (last?.state != settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL) {
    return;
  }
  final unlock = request.expected.goalUnlockAt;
  final vaults = ref.read(stawiVaultServiceProvider);
  for (var i = 0; i < pollAttempts; i++) {
    if (i > 0) await Future<void>.delayed(pollEvery);
    final vault = await vaults.vault();
    final made = vault.pockets.where(
      (p) =>
          p.isGoal &&
          p.name.isEmpty &&
          moneyUnits(p.target) == goal.target &&
          BigInt.parse(p.unlockAt.seconds.toString()) == unlock,
    );
    if (made.isNotEmpty) {
      try {
        await vaults.nameGoal(goalId: pocketId(made.last), name: goal.name);
      } on Object {
        break;
      }
      invalidateSoon(ref, [myVaultProvider]);
      return;
    }
  }
  if (context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Your goal is started; its name shows once it is read'),
      ),
    );
  }
}

class _NewGoalSheet extends StatefulWidget {
  const _NewGoalSheet({required this.asset});

  final StawiAsset asset;

  @override
  State<_NewGoalSheet> createState() => _NewGoalSheetState();
}

class _NewGoalSheetState extends State<_NewGoalSheet> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  late DateTime _unlock = _day(30);
  bool _loanable = false;
  String? _error;

  /// Midnight, [days] days from today.
  static DateTime _day(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + days);
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final tomorrow = _day(1);
    final picked = await showDatePicker(
      context: context,
      initialDate: _unlock.isBefore(tomorrow) ? tomorrow : _unlock,
      firstDate: tomorrow,
      lastDate: _day(365 * 30),
    );
    if (picked != null) setState(() => _unlock = picked);
  }

  void _confirm() {
    final name = _name.text.trim();
    try {
      if (name.isEmpty) throw const FormatException('Name the goal');
      final target = BigInt.parse(parseAmountInput(_target.text, widget.asset));
      if (target <= BigInt.zero) {
        throw const FormatException('Enter a target greater than zero');
      }
      if (_unlock.isBefore(_day(1))) {
        throw const FormatException('A goal unlocks tomorrow at the earliest');
      }
      Navigator.of(context).pop<NewGoal>((
        name: name,
        target: target,
        unlockAt: _unlock,
        loanable: _loanable,
      ));
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      16,
      16,
      16 + MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('New goal', style: Theme.of(context).textTheme.titleMedium),
        TextField(
          key: const Key('goal-name'),
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        TextField(
          key: const Key('goal-target'),
          controller: _target,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Target (${widget.asset.symbol})',
          ),
        ),
        ListTile(
          key: const Key('goal-unlock'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Unlocks'),
          subtitle: Text(DateFormat.yMMMd().format(_unlock)),
          trailing: const Icon(Icons.calendar_today),
          onTap: _pickDate,
        ),
        SwitchListTile(
          key: const Key('goal-loanable'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Others can borrow from it'),
          subtitle: const Text(
            'People you choose to lend to can be lent money from this goal; '
            'it comes back with their repayments.',
          ),
          value: _loanable,
          onChanged: (v) => setState(() => _loanable = v),
        ),
        if (_error != null)
          Text(
            _error!,
            key: const Key('goal-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('goal-create'),
          onPressed: _confirm,
          child: const Text('Start the goal'),
        ),
      ],
    ),
  );
}
