import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../data/stawi_account_service.dart';
import '../data/stawi_custody.dart';
import '../data/stawi_finance_service.dart';
import '../domain/stawi_money.dart';
import 'loan_widgets.dart' show settleThenRefresh;
import 'money_review_sheet.dart';
import 'room_money_screen.dart' show roomMoneyProviders;
import 'stawi_feedback.dart';

/// Pays into a Stawi room's savings straight from the member's account. The
/// device signs the contribution settlement prepares; chat is not involved.
class ContributeScreen extends ConsumerStatefulWidget {
  const ContributeScreen({
    required this.roomId,
    required this.roomName,
    super.key,
  });

  final String roomId;
  final String roomName;

  @override
  ConsumerState<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends ConsumerState<ContributeScreen> {
  final _amount = TextEditingController();
  bool _sending = false;

  /// Once a contribution is submitted: true, and [_last] is where it stands.
  bool _submitted = false;
  settlement.AccountCall? _last;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final custody = ref.read(roomCustodyProvider(widget.roomId)).asData?.value;
    if (custody == null) return;
    setState(() => _sending = true);
    final container = moneyContainer(context);
    final service = ref.read(stawiAccountServiceProvider);
    final call = await runMoneyAction(context, ref, () async {
      final asset = await ref.read(
        stawiRoomAssetProvider(widget.roomId).future,
      );
      if (asset == null) {
        throw const FormatException('The room’s asset could not be read');
      }
      return service.prepareContribution(
        custody: custody,
        amount: parseAmountInput(_amount.text, asset),
        roomName: widget.roomName,
      );
    });
    if (!mounted) return;
    setState(() {
      _sending = false;
      _submitted = call != null;
    });
    if (call == null) return;
    // Followed until it is final; only then are the dues and balances read
    // again, and the outcome said.
    final last = await settleThenRefresh(
      container,
      service,
      call,
      roomMoneyProviders(widget.roomId),
      onProgress: (c) {
        if (mounted) setState(() => _last = c);
      },
    );
    if (mounted) setState(() => _last = last ?? _last);
  }

  @override
  Widget build(BuildContext context) {
    final custody = ref.watch(roomCustodyProvider(widget.roomId));
    final theme = Theme.of(context);
    final ready = custody.asData?.value != null && !_sending && !_submitted;

    return Scaffold(
      appBar: AppBar(title: Text('Contribute · ${widget.roomName}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          custody.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(stawiErrorMessage(error)),
            data: (address) => ListTile(
              key: const Key('contribute-custody'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_balance_outlined),
              title: const Text('Room savings'),
              subtitle: Text(
                address == null
                    ? 'This room is not on chain yet'
                    : shortHex(bytesToHex0x(address)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('contribute-amount'),
            controller: _amount,
            enabled: !_submitted,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              suffixText: ref
                  .watch(stawiRoomAssetProvider(widget.roomId))
                  .asData
                  ?.value
                  ?.symbol,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('contribute-submit'),
            onPressed: ready ? _submit : null,
            icon: const Icon(Icons.savings_outlined),
            label: Text(_sending ? 'Signing…' : 'Sign and contribute'),
          ),
          const SizedBox(height: 8),
          Text(
            'Paid from your Stawi account into the room’s savings; the room’s '
            'rules decide how it is applied.',
            style: theme.textTheme.bodySmall,
          ),
          if (_submitted)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                _last == null ? 'Submitted' : describeAccountCall(_last!),
                key: const Key('contribute-state'),
                style: theme.textTheme.titleMedium,
              ),
            ),
        ],
      ),
    );
  }
}

/// One line for where an account call stands.
String describeAccountCall(settlement.AccountCall call) => switch (call.state) {
  settlement.AccountCallState.ACCOUNT_CALL_STATE_PREPARED => 'Prepared',
  settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED =>
    'Submitted to the chain',
  settlement.AccountCallState.ACCOUNT_CALL_STATE_INCLUDED =>
    'Included in a block; waiting for finality',
  settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL => 'Confirmed on chain',
  settlement.AccountCallState.ACCOUNT_CALL_STATE_FAILED =>
    call.failureReason.isEmpty ? 'Failed' : 'Failed: ${call.failureReason}',
  settlement.AccountCallState.ACCOUNT_CALL_STATE_EXPIRED => 'Expired',
  _ => 'Pending',
};
