// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnalyticsEvent _$AnalyticsEventFromJson(Map<String, dynamic> json) =>
    _AnalyticsEvent(
      id: json['id'] as String,
      type: $enumDecode(_$AnalyticsEventTypeEnumMap, json['type']),
      name: json['name'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['userId'] as String?,
      sessionId: json['sessionId'] as String?,
      screenName: json['screenName'] as String?,
      properties: json['properties'] as Map<String, dynamic>?,
      userProperties: json['userProperties'] as Map<String, dynamic>?,
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$AnalyticsEventToJson(_AnalyticsEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$AnalyticsEventTypeEnumMap[instance.type]!,
      'name': instance.name,
      'timestamp': instance.timestamp.toIso8601String(),
      'userId': instance.userId,
      'sessionId': instance.sessionId,
      'screenName': instance.screenName,
      'properties': instance.properties,
      'userProperties': instance.userProperties,
      'isSynced': instance.isSynced,
    };

const _$AnalyticsEventTypeEnumMap = {
  AnalyticsEventType.screenView: 'screenView',
  AnalyticsEventType.buttonTap: 'buttonTap',
  AnalyticsEventType.messageSent: 'messageSent',
  AnalyticsEventType.messageReceived: 'messageReceived',
  AnalyticsEventType.messageDeleted: 'messageDeleted',
  AnalyticsEventType.messageReacted: 'messageReacted',
  AnalyticsEventType.messageStarred: 'messageStarred',
  AnalyticsEventType.roomCreated: 'roomCreated',
  AnalyticsEventType.roomJoined: 'roomJoined',
  AnalyticsEventType.roomLeft: 'roomLeft',
  AnalyticsEventType.roomDeleted: 'roomDeleted',
  AnalyticsEventType.callStarted: 'callStarted',
  AnalyticsEventType.callEnded: 'callEnded',
  AnalyticsEventType.callAnswered: 'callAnswered',
  AnalyticsEventType.callDeclined: 'callDeclined',
  AnalyticsEventType.callMissed: 'callMissed',
  AnalyticsEventType.userLogin: 'userLogin',
  AnalyticsEventType.userLogout: 'userLogout',
  AnalyticsEventType.userSignup: 'userSignup',
  AnalyticsEventType.profileUpdated: 'profileUpdated',
  AnalyticsEventType.contactAdded: 'contactAdded',
  AnalyticsEventType.contactVerified: 'contactVerified',
  AnalyticsEventType.featureUsed: 'featureUsed',
  AnalyticsEventType.settingChanged: 'settingChanged',
  AnalyticsEventType.errorOccurred: 'errorOccurred',
  AnalyticsEventType.custom: 'custom',
};

_AnalyticsUserProperties _$AnalyticsUserPropertiesFromJson(
  Map<String, dynamic> json,
) => _AnalyticsUserProperties(
  userId: json['userId'] as String?,
  displayName: json['displayName'] as String?,
  email: json['email'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  accountCreatedAt: json['accountCreatedAt'] == null
      ? null
      : DateTime.parse(json['accountCreatedAt'] as String),
  lastLoginAt: json['lastLoginAt'] == null
      ? null
      : DateTime.parse(json['lastLoginAt'] as String),
  appVersion: json['appVersion'] as String?,
  platform: json['platform'] as String?,
  deviceModel: json['deviceModel'] as String?,
  osVersion: json['osVersion'] as String?,
  locale: json['locale'] as String?,
  totalRooms: (json['totalRooms'] as num?)?.toInt(),
  totalContacts: (json['totalContacts'] as num?)?.toInt(),
  customProperties: json['customProperties'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$AnalyticsUserPropertiesToJson(
  _AnalyticsUserProperties instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'displayName': instance.displayName,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'accountCreatedAt': instance.accountCreatedAt?.toIso8601String(),
  'lastLoginAt': instance.lastLoginAt?.toIso8601String(),
  'appVersion': instance.appVersion,
  'platform': instance.platform,
  'deviceModel': instance.deviceModel,
  'osVersion': instance.osVersion,
  'locale': instance.locale,
  'totalRooms': instance.totalRooms,
  'totalContacts': instance.totalContacts,
  'customProperties': instance.customProperties,
};

_AnalyticsSession _$AnalyticsSessionFromJson(Map<String, dynamic> json) =>
    _AnalyticsSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      eventCount: (json['eventCount'] as num?)?.toInt() ?? 0,
      screenViewCount: (json['screenViewCount'] as num?)?.toInt() ?? 0,
      entryScreen: json['entryScreen'] as String?,
      exitScreen: json['exitScreen'] as String?,
      userId: json['userId'] as String?,
      deviceInfo: json['deviceInfo'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AnalyticsSessionToJson(_AnalyticsSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'eventCount': instance.eventCount,
      'screenViewCount': instance.screenViewCount,
      'entryScreen': instance.entryScreen,
      'exitScreen': instance.exitScreen,
      'userId': instance.userId,
      'deviceInfo': instance.deviceInfo,
    };
