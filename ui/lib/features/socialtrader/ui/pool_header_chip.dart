import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/pool_membership.dart';
import '../data/socialtrader_api.dart';
import '../domain/pool_binding.dart';

/// The room app bar's pool chip: NAV per share and the person's share of the
/// pool; tapping opens the room's Pool tab. Nothing for a plain room.
class PoolHeaderChip extends ConsumerWidget {
  const PoolHeaderChip({required this.roomId, super.key});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final binding = ref.watch(poolBindingProvider(roomId)).asData?.value;
    if (binding == null) return const SizedBox.shrink();
    final pool = ref.watch(poolByAddressProvider(binding.poolId)).asData?.value;
    if (pool == null) return const SizedBox.shrink();
    final membership = ref
        .watch(myMembershipProvider(binding.poolId))
        .asData
        ?.value;
    final share = membership != null && membership.holdsShares
        ? ' · ${membership.sharePercent}'
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        key: const Key('pool-header-chip'),
        avatar: const Icon(Icons.show_chart, size: 16),
        label: Text('NAV ${pool.navPerShare}$share'),
        tooltip: 'Pool',
        onPressed: () => context.push('/room/$roomId/pool'),
      ),
    );
  }
}
