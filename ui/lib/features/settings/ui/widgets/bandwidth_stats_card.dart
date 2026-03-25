import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/network_optimizer.dart';
import '../../../../core/theme/app_theme.dart';

/// Card widget displaying network bandwidth usage statistics
///
/// Uses StreamProvider for automatic updates instead of Timer.periodic
/// for more idiomatic Riverpod state management.
class BandwidthStatsCard extends ConsumerWidget {
  const BandwidthStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(bandwidthStatsProvider);

    return statsAsync.when(
      data: (stats) => _buildCard(context, theme, stats, ref),
      loading: () => const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ThemeData theme,
    BandwidthStats stats,
    WidgetRef ref,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.data_usage,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Network Usage',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => ref.invalidate(bandwidthStatsProvider),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const Divider(height: 24),

            // Total usage
            _buildStatRow(
              context,
              icon: Icons.swap_vert,
              label: 'Total Data',
              value: stats.formattedTotal,
            ),
            const SizedBox(height: 12),

            // Download
            _buildStatRow(
              context,
              icon: Icons.download,
              iconColor: Colors.green,
              label: 'Downloaded',
              value: stats.formattedTotalReceived,
              subtitle: 'Rate: ${stats.formattedReceiveRate}',
            ),
            const SizedBox(height: 12),

            // Upload
            _buildStatRow(
              context,
              icon: Icons.upload,
              iconColor: Colors.blue,
              label: 'Uploaded',
              value: stats.formattedTotalSent,
              subtitle: 'Rate: ${stats.formattedSendRate}',
            ),

            if (stats.trackingDuration.inMinutes > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Tracking for ${_formatDuration(stats.trackingDuration)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor ?? theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }
}

/// Compact bandwidth indicator for status bars
class BandwidthIndicator extends ConsumerWidget {
  const BandwidthIndicator({super.key, this.showRate = true});

  final bool showRate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(bandwidthStatsProvider);
    final theme = Theme.of(context);

    return statsAsync.when(
      data: (stats) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.data_usage,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              stats.formattedTotal,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showRate && stats.receiveRateBps > 0) ...[
              const SizedBox(width: 4),
              Icon(Icons.download, size: 12, color: Colors.green.shade700),
              Text(
                stats.formattedReceiveRate,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
