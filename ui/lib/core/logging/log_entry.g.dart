// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LogEntry _$LogEntryFromJson(Map<String, dynamic> json) => _LogEntry(
  id: json['id'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  level: $enumDecode(_$LogLevelEnumMap, json['level']),
  message: json['message'] as String,
  correlationId: json['correlationId'] as String?,
  error: json['error'] as String?,
  stackTrace: json['stackTrace'] as String?,
  data: json['data'] as Map<String, dynamic>?,
  tag: json['tag'] as String?,
);

Map<String, dynamic> _$LogEntryToJson(_LogEntry instance) => <String, dynamic>{
  'id': instance.id,
  'timestamp': instance.timestamp.toIso8601String(),
  'level': _$LogLevelEnumMap[instance.level]!,
  'message': instance.message,
  'correlationId': instance.correlationId,
  'error': instance.error,
  'stackTrace': instance.stackTrace,
  'data': instance.data,
  'tag': instance.tag,
};

const _$LogLevelEnumMap = {
  LogLevel.debug: 'debug',
  LogLevel.info: 'info',
  LogLevel.warning: 'warning',
  LogLevel.error: 'error',
};
