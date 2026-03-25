import 'package:flutter/material.dart';

import '../../domain/call_stats.dart';

/// Displays call quality indicator during a call
class CallQualityIndicator extends StatelessWidget {
  const CallQualityIndicator({
    required this.stats,
    super.key,
    this.showDetails = false,
    this.onTap,
  });
  final CallStats stats;
  final bool showDetails;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QualityBars(quality: stats.quality),
            const SizedBox(width: 8),
            if (showDetails) ...[
              Text(
                stats.qualityDescription,
                style: TextStyle(
                  color: _getQualityColor(stats.quality),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (stats.isReconnecting) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.amber,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Color _getQualityColor(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return Colors.green;
      case ConnectionQuality.good:
        return Colors.lightGreen;
      case ConnectionQuality.fair:
        return Colors.amber;
      case ConnectionQuality.poor:
        return Colors.orange;
      case ConnectionQuality.veryPoor:
        return Colors.red;
      case ConnectionQuality.unknown:
        return Colors.grey;
    }
  }
}

/// Visual bars indicating connection quality
class _QualityBars extends StatelessWidget {
  const _QualityBars({required this.quality});
  final ConnectionQuality quality;

  @override
  Widget build(BuildContext context) {
    final activeBars = _getActiveBars(quality);
    final color = _getColor(quality);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Bar(height: 6, isActive: activeBars >= 1, color: color),
        const SizedBox(width: 2),
        _Bar(height: 10, isActive: activeBars >= 2, color: color),
        const SizedBox(width: 2),
        _Bar(height: 14, isActive: activeBars >= 3, color: color),
        const SizedBox(width: 2),
        _Bar(height: 18, isActive: activeBars >= 4, color: color),
      ],
    );
  }

  int _getActiveBars(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 4;
      case ConnectionQuality.good:
        return 3;
      case ConnectionQuality.fair:
        return 2;
      case ConnectionQuality.poor:
        return 1;
      case ConnectionQuality.veryPoor:
        return 0;
      case ConnectionQuality.unknown:
        return 2;
    }
  }

  Color _getColor(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return Colors.green;
      case ConnectionQuality.good:
        return Colors.lightGreen;
      case ConnectionQuality.fair:
        return Colors.amber;
      case ConnectionQuality.poor:
        return Colors.orange;
      case ConnectionQuality.veryPoor:
        return Colors.red;
      case ConnectionQuality.unknown:
        return Colors.grey;
    }
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.height,
    required this.isActive,
    required this.color,
  });
  final double height;
  final bool isActive;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: isActive ? color : Colors.grey.shade600,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Expanded stats panel shown when indicator is tapped
class CallStatsPanel extends StatelessWidget {
  const CallStatsPanel({required this.stats, super.key, this.onClose});
  final CallStats stats;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Call Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),

          // Quality
          _StatRow(
            label: 'Quality',
            value: stats.qualityDescription,
            valueColor: _getQualityColor(stats.quality),
          ),

          // Latency
          _StatRow(label: 'Latency', value: stats.latencyDescription),

          // Packet Loss
          _StatRow(label: 'Packet Loss', value: stats.packetLossDescription),

          // Jitter
          _StatRow(
            label: 'Jitter',
            value: '${stats.jitterMs.toStringAsFixed(1)}ms',
          ),

          const SizedBox(height: 8),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),

          // Video resolution sent
          if (stats.videoWidthSent > 0)
            _StatRow(
              label: 'Video Out',
              value:
                  '${stats.videoWidthSent}x${stats.videoHeightSent} @ ${stats.framesSentPerSecond.round()}fps',
            ),

          // Video resolution received
          if (stats.videoWidthReceived > 0)
            _StatRow(
              label: 'Video In',
              value:
                  '${stats.videoWidthReceived}x${stats.videoHeightReceived} @ ${stats.framesReceivedPerSecond.round()}fps',
            ),

          // Bitrate
          if (stats.videoBitrateBps > 0)
            _StatRow(
              label: 'Bitrate',
              value:
                  '${(stats.videoBitrateBps / 1000).toStringAsFixed(0)} Kbps',
            ),

          // Data transferred
          _StatRow(
            label: 'Data',
            value:
                '↑${_formatBytes(stats.bytesSent)} ↓${_formatBytes(stats.bytesReceived)}',
          ),

          // Video disabled warning
          if (stats.isVideoDisabledDueToPoorConnection) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.videocam_off, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Video disabled due to poor connection',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],

          // Reconnecting indicator
          if (stats.isReconnecting) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Reconnecting (attempt ${stats.reconnectionAttempts})...',
                    style: const TextStyle(color: Colors.amber, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getQualityColor(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return Colors.green;
      case ConnectionQuality.good:
        return Colors.lightGreen;
      case ConnectionQuality.fair:
        return Colors.amber;
      case ConnectionQuality.poor:
        return Colors.orange;
      case ConnectionQuality.veryPoor:
        return Colors.red;
      case ConnectionQuality.unknown:
        return Colors.grey;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner showing poor connection warning
class PoorConnectionBanner extends StatelessWidget {
  const PoorConnectionBanner({
    required this.message,
    super.key,
    this.onDismiss,
  });
  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade800,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.signal_cellular_connected_no_internet_4_bar,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
