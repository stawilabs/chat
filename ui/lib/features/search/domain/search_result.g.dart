// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageSearchResult _$MessageSearchResultFromJson(Map<String, dynamic> json) =>
    _MessageSearchResult(
      messageId: json['messageId'] as String,
      roomId: json['roomId'] as String,
      roomName: json['roomName'] as String,
      text: json['text'] as String,
      senderId: json['senderId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      query: json['query'] as String,
    );

Map<String, dynamic> _$MessageSearchResultToJson(
  _MessageSearchResult instance,
) => <String, dynamic>{
  'messageId': instance.messageId,
  'roomId': instance.roomId,
  'roomName': instance.roomName,
  'text': instance.text,
  'senderId': instance.senderId,
  'timestamp': instance.timestamp.toIso8601String(),
  'query': instance.query,
};
