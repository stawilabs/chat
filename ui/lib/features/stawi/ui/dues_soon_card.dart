import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import '../data/stawi_finance_service.dart';
import '../data/stawi_room_engines.dart' show productLabel;
import '../data/stawi_timeline_providers.dart';
import '../domain/stawi_money.dart';
import 'contribute_screen.dart';

/// How far ahead the room's chat warns of dues.
const Duration duesSoonWindow = Duration(days: 3);

/// The member's products whose next dues fall within [window] of [now] with
/// something still to pay by then (finance's GetMemberDues, the same numbers
/// the dues reminder and My dues use), earliest first.
List<finance.MemberProductDues> duesDueSoon(
  finance.MemberDues dues, {
  required DateTime now,
  Duration window = duesSoonWindow,
}) {
  final until = now.add(window);
  final soon =
      [
        for (final p in dues.products)
          if (p.hasNextDueAt() &&
              !p.nextDueAt.toDateTime().isBefore(now) &&
              !p.nextDueAt.toDateTime().isAfter(until) &&
              (BigInt.tryParse(p.owedAtNextDue.amount) ?? BigInt.zero) >
                  BigInt.zero)
            p,
      ]..sort(
        (a, b) => a.nextDueAt.toDateTime().compareTo(b.nextDueAt.toDateTime()),
      );
  return soon;
}

/// A card at the top of a Stawi room's chat while the member's dues fall due
/// within [duesSoonWindow]: what to pay by when, and a way to pay. Nothing
/// otherwise, and nothing when the dues cannot be read.
class DuesSoonCard extends ConsumerWidget {
  const DuesSoonCard({
    required this.roomId,
    required this.roomName,
    this.now,
    super.key,
  });

  final String roomId;
  final String roomName;

  /// The clock (tests).
  final DateTime Function()? now;

  static final _day = DateFormat('EEE d MMM');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(stawiRoomPhaseProvider(roomId)).asData?.value;
    if (phase != StawiRoomPhase.active) return const SizedBox.shrink();
    final response = ref.watch(stawiMyDuesProvider(roomId)).asData?.value;
    if (response == null || !response.dues.rulesConfigured) {
      return const SizedBox.shrink();
    }
    final soon = duesDueSoon(
      response.dues,
      now: (now ?? DateTime.now)().toUtc(),
    );
    if (soon.isEmpty) return const SizedBox.shrink();
    final assets = watchRoomAssets(ref, roomId).withAll(response.assets);
    final dues = response.dues;
    final tz = Duration(
      seconds: dues.hasCalendar() ? dues.calendar.tzOffsetSeconds : 0,
    );
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const Key('dues-soon-card'),
      color: scheme.tertiaryContainer,
      child: ListTile(
        leading: Icon(Icons.event_outlined, color: scheme.onTertiaryContainer),
        title: Text(
          'Dues due soon',
          style: TextStyle(color: scheme.onTertiaryContainer),
        ),
        subtitle: Text(
          [
            for (final p in soon)
              '${productLabel(p.name, p.productId)}: '
                  '${formatMoney(p.owedAtNextDue, assets)} by '
                  '${_day.format(p.nextDueAt.toDateTime().add(tz))}',
          ].join('\n'),
          style: TextStyle(color: scheme.onTertiaryContainer),
        ),
        trailing: TextButton(
          key: const Key('dues-soon-pay'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  ContributeScreen(roomId: roomId, roomName: roomName),
            ),
          ),
          child: const Text('Pay'),
        ),
      ),
    );
  }
}
