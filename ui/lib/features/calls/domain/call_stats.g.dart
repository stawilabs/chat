// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CallStats _$CallStatsFromJson(Map<String, dynamic> json) => _CallStats(
  roundTripTimeMs: (json['roundTripTimeMs'] as num?)?.toDouble() ?? 0,
  jitterMs: (json['jitterMs'] as num?)?.toDouble() ?? 0,
  packetLossPercent: (json['packetLossPercent'] as num?)?.toDouble() ?? 0,
  availableBandwidthBps: (json['availableBandwidthBps'] as num?)?.toInt() ?? 0,
  videoBitrateBps: (json['videoBitrateBps'] as num?)?.toInt() ?? 0,
  audioBitrateBps: (json['audioBitrateBps'] as num?)?.toInt() ?? 0,
  framesSentPerSecond: (json['framesSentPerSecond'] as num?)?.toDouble() ?? 0,
  framesReceivedPerSecond:
      (json['framesReceivedPerSecond'] as num?)?.toDouble() ?? 0,
  videoWidthSent: (json['videoWidthSent'] as num?)?.toInt() ?? 0,
  videoHeightSent: (json['videoHeightSent'] as num?)?.toInt() ?? 0,
  videoWidthReceived: (json['videoWidthReceived'] as num?)?.toInt() ?? 0,
  videoHeightReceived: (json['videoHeightReceived'] as num?)?.toInt() ?? 0,
  bytesSent: (json['bytesSent'] as num?)?.toInt() ?? 0,
  bytesReceived: (json['bytesReceived'] as num?)?.toInt() ?? 0,
  packetsSent: (json['packetsSent'] as num?)?.toInt() ?? 0,
  packetsReceived: (json['packetsReceived'] as num?)?.toInt() ?? 0,
  packetsLost: (json['packetsLost'] as num?)?.toInt() ?? 0,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  quality:
      $enumDecodeNullable(_$ConnectionQualityEnumMap, json['quality']) ??
      ConnectionQuality.unknown,
  isVideoDisabledDueToPoorConnection:
      json['isVideoDisabledDueToPoorConnection'] as bool? ?? false,
  isReconnecting: json['isReconnecting'] as bool? ?? false,
  reconnectionAttempts: (json['reconnectionAttempts'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CallStatsToJson(_CallStats instance) =>
    <String, dynamic>{
      'roundTripTimeMs': instance.roundTripTimeMs,
      'jitterMs': instance.jitterMs,
      'packetLossPercent': instance.packetLossPercent,
      'availableBandwidthBps': instance.availableBandwidthBps,
      'videoBitrateBps': instance.videoBitrateBps,
      'audioBitrateBps': instance.audioBitrateBps,
      'framesSentPerSecond': instance.framesSentPerSecond,
      'framesReceivedPerSecond': instance.framesReceivedPerSecond,
      'videoWidthSent': instance.videoWidthSent,
      'videoHeightSent': instance.videoHeightSent,
      'videoWidthReceived': instance.videoWidthReceived,
      'videoHeightReceived': instance.videoHeightReceived,
      'bytesSent': instance.bytesSent,
      'bytesReceived': instance.bytesReceived,
      'packetsSent': instance.packetsSent,
      'packetsReceived': instance.packetsReceived,
      'packetsLost': instance.packetsLost,
      'timestamp': instance.timestamp?.toIso8601String(),
      'quality': _$ConnectionQualityEnumMap[instance.quality]!,
      'isVideoDisabledDueToPoorConnection':
          instance.isVideoDisabledDueToPoorConnection,
      'isReconnecting': instance.isReconnecting,
      'reconnectionAttempts': instance.reconnectionAttempts,
    };

const _$ConnectionQualityEnumMap = {
  ConnectionQuality.excellent: 'excellent',
  ConnectionQuality.good: 'good',
  ConnectionQuality.fair: 'fair',
  ConnectionQuality.poor: 'poor',
  ConnectionQuality.veryPoor: 'veryPoor',
  ConnectionQuality.unknown: 'unknown',
};
