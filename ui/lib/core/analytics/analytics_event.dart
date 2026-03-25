import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_event.freezed.dart';
part 'analytics_event.g.dart';

/// Standard analytics event types
enum AnalyticsEventType {
  // User actions
  screenView,
  buttonTap,

  // Messaging events
  messageSent,
  messageReceived,
  messageDeleted,
  messageReacted,
  messageStarred,

  // Room events
  roomCreated,
  roomJoined,
  roomLeft,
  roomDeleted,

  // Call events
  callStarted,
  callEnded,
  callAnswered,
  callDeclined,
  callMissed,

  // User events
  userLogin,
  userLogout,
  userSignup,
  profileUpdated,
  contactAdded,
  contactVerified,

  // Feature usage
  featureUsed,
  settingChanged,

  // Error events
  errorOccurred,

  // Custom events
  custom,
}

/// Analytics event model for tracking user behavior and app usage
@freezed
abstract class AnalyticsEvent with _$AnalyticsEvent {
  const factory AnalyticsEvent({
    required String id,
    required AnalyticsEventType type,
    required String name,
    required DateTime timestamp,
    String? userId,
    String? sessionId,
    String? screenName,
    Map<String, dynamic>? properties,
    Map<String, dynamic>? userProperties,
    @Default(false) bool isSynced,
  }) = _AnalyticsEvent;
  const AnalyticsEvent._();

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsEventFromJson(json);

  /// Create a screen view event
  factory AnalyticsEvent.screenView({
    required String id,
    required String screenName,
    String? userId,
    String? sessionId,
    Map<String, dynamic>? properties,
  }) => AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.screenView,
    name: 'screen_view',
    timestamp: DateTime.now().toUtc(),
    userId: userId,
    sessionId: sessionId,
    screenName: screenName,
    properties: {'screen_name': screenName, ...?properties},
  );

  /// Create a message sent event
  factory AnalyticsEvent.messageSent({
    required String id,
    required String roomId,
    required String messageType,
    String? userId,
    String? sessionId,
    bool hasAttachment = false,
    bool isReply = false,
  }) => AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.messageSent,
    name: 'message_sent',
    timestamp: DateTime.now().toUtc(),
    userId: userId,
    sessionId: sessionId,
    properties: {
      'room_id': roomId,
      'message_type': messageType,
      'has_attachment': hasAttachment,
      'is_reply': isReply,
    },
  );

  /// Create a call started event
  factory AnalyticsEvent.callStarted({
    required String id,
    required String roomId,
    required String callType,
    String? userId,
    String? sessionId,
  }) => AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.callStarted,
    name: 'call_started',
    timestamp: DateTime.now().toUtc(),
    userId: userId,
    sessionId: sessionId,
    properties: {'room_id': roomId, 'call_type': callType},
  );

  /// Create a call ended event
  factory AnalyticsEvent.callEnded({
    required String id,
    required String roomId,
    required String callType,
    String? userId,
    String? sessionId,
    int? durationSeconds,
  }) => AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.callEnded,
    name: 'call_ended',
    timestamp: DateTime.now().toUtc(),
    userId: userId,
    sessionId: sessionId,
    properties: {
      'room_id': roomId,
      'call_type': callType,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    },
  );

  /// Create a call answered event
  factory AnalyticsEvent.callAnswered({
    required String id,
    required String roomId,
    required String callType,
    String? userId,
    String? sessionId,
  }) => AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.callAnswered,
    name: 'call_answered',
    timestamp: DateTime.now().toUtc(),
    userId: userId,
    sessionId: sessionId,
    properties: {'room_id': roomId, 'call_type': callType},
  );

  /// Create a call declined event
  factory AnalyticsEvent.callDeclined({
    required String id,
    required String roomId,
    required String callType,
    String? userId,
    String? sessionId,
  }) => AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.callDeclined,
    name: 'call_declined',
    timestamp: DateTime.now().toUtc(),
    userId: userId,
    sessionId: sessionId,
    properties: {'room_id': roomId, 'call_type': callType},
  );

  /// Create a call missed event
  factory AnalyticsEvent.callMissed({
    required String id,
    required String roomId,
    required String callType,
    String? userId,
    String? sessionId,
  }) => AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.callMissed,
    name: 'call_missed',
    timestamp: DateTime.now().toUtc(),
    userId: userId,
    sessionId: sessionId,
    properties: {'room_id': roomId, 'call_type': callType},
  );

  /// Create a room created event
  factory AnalyticsEvent.roomCreated({
    required String id,
    required String roomId,
    required String roomType,
    String? userId,
    String? sessionId,
    int? memberCount,
  }) => AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.roomCreated,
    name: 'room_created',
    timestamp: DateTime.now().toUtc(),
    userId: userId,
    sessionId: sessionId,
    properties: {
      'room_id': roomId,
      'room_type': roomType,
      if (memberCount != null) 'member_count': memberCount,
    },
  );

  /// Create a room joined event
  factory AnalyticsEvent.roomJoined({
    required String id,
    required String roomId,
    required String roomType,
    String? userId,
    String? sessionId,
    int? memberCount,
  }) => AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.roomJoined,
    name: 'room_joined',
    timestamp: DateTime.now().toUtc(),
    userId: userId,
    sessionId: sessionId,
    properties: {
      'room_id': roomId,
      'room_type': roomType,
      if (memberCount != null) 'member_count': memberCount,
    },
  );

  /// Create a room left event
  factory AnalyticsEvent.roomLeft({
    required String id,
    required String roomId,
    required String roomType,
    String? userId,
    String? sessionId,
  }) => AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.roomLeft,
    name: 'room_left',
    timestamp: DateTime.now().toUtc(),
    userId: userId,
    sessionId: sessionId,
    properties: {'room_id': roomId, 'room_type': roomType},
  );

  /// Create a room deleted event
  factory AnalyticsEvent.roomDeleted({
    required String id,
    required String roomId,
    required String roomType,
    String? userId,
    String? sessionId,
  }) => AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.roomDeleted,
    name: 'room_deleted',
    timestamp: DateTime.now().toUtc(),
    userId: userId,
    sessionId: sessionId,
    properties: {'room_id': roomId, 'room_type': roomType},
  );

  /// Create a feature usage event
  factory AnalyticsEvent.featureUsed({
    required String id,
    required String featureName,
    String? userId,
    String? sessionId,
    Map<String, dynamic>? properties,
  }) => AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.featureUsed,
    name: 'feature_used',
    timestamp: DateTime.now().toUtc(),
    userId: userId,
    sessionId: sessionId,
    properties: {'feature_name': featureName, ...?properties},
  );

  /// Create an error event
  factory AnalyticsEvent.error({
    required String id,
    required String errorType,
    required String errorMessage,
    String? userId,
    String? sessionId,
    String? screenName,
    String? stackTrace,
  }) => AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.errorOccurred,
    name: 'error_occurred',
    timestamp: DateTime.now().toUtc(),
    userId: userId,
    sessionId: sessionId,
    screenName: screenName,
    properties: {
      'error_type': errorType,
      'error_message': errorMessage,
      if (stackTrace != null) 'stack_trace': stackTrace,
    },
  );

  /// Create a custom event
  factory AnalyticsEvent.custom({
    required String id,
    required String eventName,
    String? userId,
    String? sessionId,
    String? screenName,
    Map<String, dynamic>? properties,
  }) => AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.custom,
    name: eventName,
    timestamp: DateTime.now().toUtc(),
    userId: userId,
    sessionId: sessionId,
    screenName: screenName,
    properties: properties,
  );
}

/// User properties for analytics
@freezed
abstract class AnalyticsUserProperties with _$AnalyticsUserProperties {
  const factory AnalyticsUserProperties({
    String? userId,
    String? displayName,
    String? email,
    String? phoneNumber,
    DateTime? accountCreatedAt,
    DateTime? lastLoginAt,
    String? appVersion,
    String? platform,
    String? deviceModel,
    String? osVersion,
    String? locale,
    int? totalRooms,
    int? totalContacts,
    Map<String, dynamic>? customProperties,
  }) = _AnalyticsUserProperties;

  factory AnalyticsUserProperties.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsUserPropertiesFromJson(json);
}

/// Session information for analytics
@freezed
abstract class AnalyticsSession with _$AnalyticsSession {
  const factory AnalyticsSession({
    required String id,
    required DateTime startTime,
    DateTime? endTime,
    @Default(0) int eventCount,
    @Default(0) int screenViewCount,
    String? entryScreen,
    String? exitScreen,
    String? userId,
    Map<String, dynamic>? deviceInfo,
  }) = _AnalyticsSession;
  const AnalyticsSession._();

  factory AnalyticsSession.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsSessionFromJson(json);

  /// Calculate session duration in seconds
  int get durationSeconds {
    final end = endTime ?? DateTime.now().toUtc();
    return end.difference(startTime).inSeconds;
  }

  /// Check if session is still active (no end time)
  bool get isActive => endTime == null;
}
