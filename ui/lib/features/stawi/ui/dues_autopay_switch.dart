import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import '../data/stawi_dues_plan_service.dart';
import '../data/stawi_finance_service.dart';
import '../domain/dues_plan.dart';
import '../domain/signing_checks.dart' show SigningRefused;
import 'money_review_sheet.dart';
import 'stawi_feedback.dart';

/// "Pay my dues automatically" for one room: on, a savings plan whose
/// standing grant lets settlement collect each period's dues from the
/// wallet; off, the plan cancelled and the grant revoked. Each way the
/// device checks finance's intent and the person reviews it before the
/// device lock.
class DuesAutoPaySwitch extends ConsumerStatefulWidget {
  const DuesAutoPaySwitch({
    required this.roomId,
    required this.roomName,
    super.key,
  });

  final String roomId;
  final String roomName;

  @override
  ConsumerState<DuesAutoPaySwitch> createState() => _DuesAutoPaySwitchState();
}

class _DuesAutoPaySwitchState extends ConsumerState<DuesAutoPaySwitch> {
  bool _busy = false;

  Future<void> _set(bool on, finance.SavingsPlan? plan) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(stawiDuesPlanServiceProvider);
      final prepared = await runStawiAction(context, () async {
        if (!on) {
          return service.prepareTurnOff(
            roomId: widget.roomId,
            plan: plan!,
            roomName: widget.roomName,
          );
        }
        final dues = await ref.read(stawiMyDuesProvider(widget.roomId).future);
        final perPeriod = dues == null ? null : duesPerPeriod(dues.dues);
        final cadence = dues == null || !dues.dues.hasCalendar()
            ? null
            : cadenceFor(dues.dues.calendar);
        final asset = perPeriod == null
            ? null
            : (await ref.read(stawiRoomAssetsProvider(widget.roomId).future))
                  .withAll(dues!.assets)
                  .of(perPeriod.assetId);
        if (perPeriod == null || cadence == null || asset == null) {
          throw const SigningRefused(
            'this room\'s dues could not be read just now',
          );
        }
        return service.prepareTurnOn(
          roomId: widget.roomId,
          perPeriod: perPeriod,
          cadence: cadence,
          asset: asset,
          roomName: widget.roomName,
        );
      });
      if (prepared == null || !mounted) return;
      if (prepared.digest != null &&
          (!await showMoneyReview(context, prepared.review) || !mounted)) {
        return;
      }
      await runStawiAction(
        context,
        () => service.authorize(prepared),
        success: prepared.review.done,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        ref.invalidate(stawiDuesPlanProvider(widget.roomId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(stawiDuesPlanProvider(widget.roomId));
    final live = plan.asData?.value;
    final on = live != null;
    final waiting =
        live?.state == finance.PlanState.PLAN_STATE_PENDING_AUTHORIZATION;
    return SwitchListTile(
      key: const Key('dues-autopay'),
      title: const Text('Pay my dues automatically'),
      subtitle: Text(
        plan.hasError
            ? 'Could not be read just now'
            : waiting
            ? 'Waiting for your authorization to go through'
            : on
            ? 'Each period\'s dues are collected from your wallet'
            : 'Pay each period yourself',
      ),
      value: on,
      onChanged: _busy || plan.isLoading || plan.hasError
          ? null
          : (v) => _set(v, live),
    );
  }
}
