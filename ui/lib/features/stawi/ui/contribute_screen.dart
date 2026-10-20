import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../data/stawi_account_service.dart';
import '../data/stawi_custody.dart';
import '../data/stawi_finance_service.dart';
import '../data/stawi_identity.dart';
import '../domain/rotation.dart' show exactContributionProblem, rotationPayNow;
import '../domain/stawi_money.dart';
import 'loan_widgets.dart' show settleThenRefresh;
import 'money_review_sheet.dart';
import 'room_money_screen.dart' show roomMoneyProviders;
import 'stawi_feedback.dart';

/// Pays into a Stawi room's savings straight from the member's account. The
/// device signs the contribution settlement prepares; chat is not involved.
///
/// A [rotation] contribution is held to exactly what the member owes now
/// (finance GetRotation's pay_now, read live from the RulesEngine): the
/// amount is prefilled with it, and any other amount is refused before
/// anything is prepared or signed.
class ContributeScreen extends ConsumerStatefulWidget {
  const ContributeScreen({
    required this.roomId,
    required this.roomName,
    this.rotation = false,
    super.key,
  });

  final String roomId;
  final String roomName;

  /// Contributing to the room's rotation: exactly pay_now.
  final bool rotation;

  @override
  ConsumerState<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends ConsumerState<ContributeScreen> {
  final _amount = TextEditingController();
  bool _sending = false;
  bool _prefilled = false;

  /// Once a contribution is submitted: true, and [_last] is where it stands.
  bool _submitted = false;
  settlement.AccountCall? _last;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// The rotation's exact contribution now, from the rotation read live and
  /// the person's accounts: loading while either loads, and an error when it
  /// cannot be read (nothing is then paid). Null for a plain contribution.
  AsyncValue<BigInt>? _exact({bool watch = true}) {
    if (!widget.rotation) return null;
    final rotationOf = stawiRotationProvider(widget.roomId);
    final live = watch ? ref.watch(rotationOf) : ref.read(rotationOf);
    final me = watch
        ? ref.watch(stawiIdentityProvider)
        : ref.read(stawiIdentityProvider);
    final problem = live.error ?? me.error;
    if (problem != null) return AsyncValue.error(problem, StackTrace.empty);
    if (!live.hasValue || !me.hasValue) return const AsyncValue.loading();
    final exact = rotationPayNow(live.value!.rotation, me.value!.addresses);
    return exact == null
        ? const AsyncValue.error(
            StawiUnavailable(
              'Your exact contribution to the rotation could not be read',
            ),
            StackTrace.empty,
          )
        : AsyncValue.data(exact);
  }

  /// Why the amount typed cannot be paid now; null when it can.
  String? _problem(AsyncValue<BigInt>? exact, StawiAsset? asset) {
    if (exact == null) return null;
    final want = exact.asData?.value;
    if (want == null || asset == null) {
      return exact.hasError ? stawiErrorMessage(exact.error!) : '';
    }
    final BigInt typed;
    try {
      typed = BigInt.parse(parseAmountInput(_amount.text, asset));
    } on FormatException catch (e) {
      return e.message;
    }
    return exactContributionProblem(typed, want, asset);
  }

  Future<void> _submit() async {
    final custody = ref.read(roomCustodyProvider(widget.roomId)).asData?.value;
    if (custody == null) return;
    if (widget.rotation) {
      final asset = ref
          .read(stawiRoomAssetProvider(widget.roomId))
          .asData
          ?.value;
      if (_problem(_exact(watch: false), asset) != null) return;
    }
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
        roomId: widget.roomId,
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
    if (widget.rotation) {
      // pay_now is read again: the member is paid up now.
      container.invalidate(stawiRotationProvider(widget.roomId));
    }
    if (mounted) setState(() => _last = last ?? _last);
  }

  @override
  Widget build(BuildContext context) {
    final custody = ref.watch(roomCustodyProvider(widget.roomId));
    final theme = Theme.of(context);
    final asset = ref
        .watch(stawiRoomAssetProvider(widget.roomId))
        .asData
        ?.value;
    final exact = _exact();
    final want = exact?.asData?.value;
    if (!_prefilled && want != null && asset != null) {
      _prefilled = true;
      if (want > BigInt.zero) _amount.text = plainUnits(want, asset);
    }
    final problem = _problem(exact, asset);
    final ready =
        custody.asData?.value != null &&
        !_sending &&
        !_submitted &&
        problem == null;

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
          if (exact != null && exact.isLoading)
            const LinearProgressIndicator(key: Key('contribute-exact-loading')),
          if (want != null && asset != null && want > BigInt.zero)
            Text(
              'The rotation asks exactly ${formatUnits(want, asset)} of you '
              'now: your dues for the period, with any penalty owed and less '
              'any credit.',
              key: const Key('contribute-exact'),
              style: theme.textTheme.bodyMedium,
            ),
          TextField(
            key: const Key('contribute-amount'),
            controller: _amount,
            enabled: !_submitted,
            onChanged: widget.rotation ? (_) => setState(() {}) : null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              suffixText: asset?.symbol,
            ),
          ),
          if (widget.rotation &&
              problem != null &&
              problem.isNotEmpty &&
              !_submitted)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                problem,
                key: const Key('contribute-exact-problem'),
                style: TextStyle(color: theme.colorScheme.error),
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
