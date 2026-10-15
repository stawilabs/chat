import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import '../data/stawi_finance_service.dart';
import '../data/stawi_room_engines.dart';
import '../data/stawi_timeline_providers.dart';
import '../domain/signing_checks.dart' show bytesEqual;

/// [numerator] / 10^[digits] percent, with trailing zeros trimmed: "10%",
/// "2.5%". No floating point.
String _percent(int numerator, int digits) {
  final scale = BigInt.from(10).pow(digits);
  final n = BigInt.from(numerator);
  final whole = n ~/ scale;
  final frac = (n % scale)
      .toString()
      .padLeft(digits, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return frac.isEmpty ? '$whole%' : '$whole.$frac%';
}

/// The Stawi fee in words: "Stawi fee 10% of interest, fees and penalties",
/// with "· 3% to Amina" when the room has an agent (their share of the fee,
/// as a share of the income). A fee that could not be read says so; it is
/// never shown as none.
String protocolFeeText(finance.RoomProtocolFee? fee, {String? agentName}) {
  if (fee == null) return 'Stawi fee: could not be read just now';
  final line =
      'Stawi fee ${_percent(fee.incomeFeeBps, 2)} of interest, fees and '
      'penalties';
  final hasAgent = fee.agent.isNotEmpty && !fee.agent.every((b) => b == 0);
  if (!hasAgent || fee.agentShareBps == 0) return line;
  // agent_share_bps × income_fee_bps / 10000 basis points of the income.
  final share = _percent(fee.agentShareBps * fee.incomeFeeBps, 6);
  return '$line · $share to ${agentName ?? "the room's agent"}';
}

/// One line stating the Stawi fee on a room's income.
class ProtocolFeeLine extends StatelessWidget {
  const ProtocolFeeLine({required this.fee, this.agentName, super.key});

  final finance.RoomProtocolFee? fee;

  /// The room's agent, by name, when known.
  final String? agentName;

  @override
  Widget build(BuildContext context) => Text(
    protocolFeeText(fee, agentName: agentName),
    key: const Key('protocol-fee-line'),
    style: Theme.of(context).textTheme.bodySmall,
  );
}

/// The Stawi fee of the room [roomId], read from its engines, its agent named
/// from the room's members.
class RoomProtocolFeeLine extends ConsumerWidget {
  const RoomProtocolFeeLine({required this.roomId, super.key});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fee = ref.watch(roomProtocolFeeProvider(roomId));
    if (fee.isLoading && !fee.hasValue) {
      return Text(
        'Stawi fee: reading…',
        key: const Key('protocol-fee-line'),
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final value = fee.hasError ? null : fee.asData?.value;
    final line = ProtocolFeeLine(
      fee: value,
      agentName: value == null ? null : agentNameOf(ref, roomId, value.agent),
    );
    if (value != null) return line;
    // Never shown as no fee: what could not be read can be read again.
    return Row(
      children: [
        Expanded(child: line),
        TextButton(
          key: const Key('protocol-fee-retry'),
          onPressed: () => ref.invalidate(roomProtocolFeeProvider(roomId)),
          child: const Text('Try again'),
        ),
      ],
    );
  }
}

/// The name of the room member whose account is [agent], when known.
String? agentNameOf(WidgetRef ref, String roomId, List<int> agent) {
  if (agent.isEmpty) return null;
  final members = ref.watch(stawiMembersProvider(roomId)).asData?.value;
  final member = members
      ?.where((m) => bytesEqual(m.accountAddress, agent))
      .firstOrNull;
  if (member == null || member.profileId.isEmpty) return null;
  return ref
      .watch(
        stawiMemberNameProvider((roomId: roomId, profileId: member.profileId)),
      )
      .asData
      ?.value;
}
