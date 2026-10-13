import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/stawi_account_service.dart';
import '../domain/account_engine_calls.dart';
import '../domain/loan_view.dart';
import '../domain/personal_calls.dart';
import '../domain/stawi_money.dart';
import 'money_review_sheet.dart';
import 'room_money_screen.dart';
import 'stawi_feedback.dart';

/// The room's rule for a payment toward a loan, said before it is signed.
const String groupPaymentNote =
    'The room applies it in order: dues and penalties first, then this '
    'instalment.';

/// [units] as a plain decimal an amount field takes ("77.5", "300"), without
/// floating point.
String plainAmount(BigInt units, int decimals) {
  if (decimals == 0) return units.toString();
  final digits = units.abs().toString().padLeft(decimals + 1, '0');
  final whole = digits.substring(0, digits.length - decimals);
  final frac = digits
      .substring(digits.length - decimals)
      .replaceFirst(RegExp(r'0+$'), '');
  return '${units.isNegative ? '-' : ''}$whole${frac.isEmpty ? '' : '.$frac'}';
}

/// Pays the next instalment. A personal loan lets the person change the
/// amount; a group loan pays what is owed into the room.
Future<void> showPayInstalment(
  BuildContext context,
  WidgetRef ref,
  LoanView view,
) async {
  final owed = view.nextOwed;
  if (owed <= BigInt.zero) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Nothing is due on this loan')),
    );
    return;
  }
  final service = ref.read(stawiAccountServiceProvider);
  if (view.isGroup) {
    await runMoneyAction(
      context,
      ref,
      () async => service.prepareContribution(
        custody: Uint8List.fromList(view.loan.pool),
        amount: owed.toString(),
        note: groupPaymentNote,
      ),
    );
    return;
  }
  final asset = await runStawiAction(context, () async {
    final info = (await ref.read(stawiTestAssetProvider.future)).asset;
    return StawiAsset.fromInfo(info);
  });
  if (asset == null || !context.mounted) return;
  final amount = await showModalBottomSheet<BigInt>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PayAmountSheet(owed: owed, asset: asset),
  );
  if (amount == null || !context.mounted) return;
  await runMoneyAction(
    context,
    ref,
    () async => service.preparePersonal(
      PersonalRequest.pay(loan: view.loan, amount: amount),
    ),
  );
}

/// Pays the whole loan off. The review shows the most it can take.
Future<void> showPayOff(
  BuildContext context,
  WidgetRef ref,
  LoanView view,
) async {
  if (view.isGroup) {
    await showDialog<void>(
      context: context,
      builder: (_) => AccountEngineDialog(
        roomId: view.loan.roomId,
        call: AccountEngineCall.loanPayoff,
        loan: view.loan,
      ),
    );
    return;
  }
  final service = ref.read(stawiAccountServiceProvider);
  await runMoneyAction(
    context,
    ref,
    () async =>
        service.preparePersonal(PersonalRequest.payoff(loan: view.loan)),
  );
}

class _PayAmountSheet extends ConsumerStatefulWidget {
  const _PayAmountSheet({required this.owed, required this.asset});

  final BigInt owed;
  final StawiAsset asset;

  @override
  ConsumerState<_PayAmountSheet> createState() => _PayAmountSheetState();
}

class _PayAmountSheetState extends ConsumerState<_PayAmountSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: plainAmount(widget.owed, widget.asset.decimals),
  );
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _confirm() {
    try {
      final units = BigInt.parse(parseAmountInput(_amount.text, widget.asset));
      Navigator.of(context).pop(units);
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(stawiWalletBalanceProvider);
    final wallet = balance.asData?.value;
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
          Text(
            'Pay an instalment',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Due now: ${formatUnits(widget.owed, widget.asset)}',
            key: const Key('pay-due'),
          ),
          Text(
            'In your wallet: '
            '${wallet == null ? '—' : formatUnits(wallet, widget.asset)}',
            key: const Key('pay-wallet'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('pay-amount'),
            controller: _amount,
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
            key: const Key('pay-confirm'),
            onPressed: _confirm,
            child: const Text('Pay an instalment'),
          ),
        ],
      ),
    );
  }
}
