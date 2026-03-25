// ignore_for_file: avoid_slow_async_io

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../logging/app_logger.dart';
import 'analytics_event.dart';
import 'analytics_repository.dart';

/// Configuration for the analytics service
class AnalyticsConfig {
  const AnalyticsConfig({
    this.enabled = true,
    this.batchSize = 50,
    this.flushIntervalSeconds = 60,
    this.maxStoredEvents = 1000,
    this.enableDebugLogging = false,
  });

  /// Whether analytics is enabled
  final bool enabled;

  /// Number of events to batch before sending
  final int batchSize;

  /// Interval in seconds between automatic flushes
  final int flushIntervalSeconds;

  /// Maximum number of events to store locally
  final int maxStoredEvents;

  /// Enable debug logging for analytics events
  final bool enableDebugLogging;
}

/// Analytics service for tracking user behavior and app usage
///
/// Features:
/// - Event tracking (screen views, user actions, errors)
/// - Session management
/// - User property tracking
/// - Database-backed event storage with batch upload
/// - Privacy-compliant (no PII without consent)
///
/// Example:
/// ```dart
/// final analytics = AnalyticsService(repository: analyticsRepo);
/// await analytics.initialize();
///
/// analytics.trackScreenView('HomeScreen');
/// analytics.trackEvent('button_tap', properties: {'button_id': 'send_message'});
/// ```
class AnalyticsService {
  AnalyticsService({
    required AnalyticsRepository repository,
    AnalyticsConfig config = const AnalyticsConfig(),
  }) : _config = config,
       _repository = repository;

  final AnalyticsConfig _config;
  final AnalyticsRepository _repository;
  static const _uuid = Uuid();

  // Session management
  AnalyticsSession? _currentSession;
  String? _currentUserId;
  AnalyticsUserProperties? _userProperties;

  // In-memory event counter for batch flush triggering
  int _pendingEventCount = 0;
  Timer? _flushTimer;
  bool _initialized = false;

  /// Initialize the analytics service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Start a new session
      _startNewSession();

      // Check for any unsynced events from previous sessions
      _pendingEventCount = await _repository.getUnsyncedEventCount();

      // Set up periodic flush timer
      _flushTimer = Timer.periodic(
        Duration(seconds: _config.flushIntervalSeconds),
        (_) => _flushEvents(),
      );

      _initialized = true;
      _log('Analytics service initialized');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to initialize analytics',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Set the current user for analytics
  void setUserId(String? userId) {
    _currentUserId = userId;
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(userId: userId);
    }
    _log('User ID set: ${userId != null ? 'set' : 'cleared'}');
  }

  /// Set user properties
  void setUserProperties(AnalyticsUserProperties properties) {
    _userProperties = properties;
    _log('User properties updated');
  }

  /// Update specific user properties
  void updateUserProperty(String key, value) {
    final current = _userProperties?.customProperties ?? {};
    final updated = Map<String, dynamic>.from(current);
    updated[key] = value;
    _userProperties =
        _userProperties?.copyWith(customProperties: updated) ??
        AnalyticsUserProperties(customProperties: updated);
  }

  /// Track a screen view
  void trackScreenView(String screenName, {Map<String, dynamic>? properties}) {
    if (!_config.enabled) return;

    final event = AnalyticsEvent.screenView(
      id: _uuid.v4(),
      screenName: screenName,
      userId: _currentUserId,
      sessionId: _currentSession?.id,
      properties: properties,
    );

    _addEvent(event);

    // Update session
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        screenViewCount: _currentSession!.screenViewCount + 1,
        exitScreen: screenName,
      );
      if (_currentSession!.entryScreen == null) {
        _currentSession = _currentSession!.copyWith(entryScreen: screenName);
      }
    }

    _log('Screen view: $screenName');
  }

  /// Track a message sent event
  void trackMessageSent({
    required String roomId,
    required String messageType,
    bool hasAttachment = false,
    bool isReply = false,
  }) {
    if (!_config.enabled) return;

    final event = AnalyticsEvent.messageSent(
      id: _uuid.v4(),
      roomId: roomId,
      messageType: messageType,
      userId: _currentUserId,
      sessionId: _currentSession?.id,
      hasAttachment: hasAttachment,
      isReply: isReply,
    );

    _addEvent(event);
    _log('Message sent tracked');
  }

  /// Track a call started event
  void trackCallStarted({required String roomId, required String callType}) {
    if (!_config.enabled) return;

    final event = AnalyticsEvent.callStarted(
      id: _uuid.v4(),
      roomId: roomId,
      callType: callType,
      userId: _currentUserId,
      sessionId: _currentSession?.id,
    );

    _addEvent(event);
    _log('Call started tracked');
  }

  /// Track a call ended event
  void trackCallEnded({
    required String roomId,
    required String callType,
    int? durationSeconds,
  }) {
    if (!_config.enabled) return;

    final event = AnalyticsEvent.callEnded(
      id: _uuid.v4(),
      roomId: roomId,
      callType: callType,
      userId: _currentUserId,
      sessionId: _currentSession?.id,
      durationSeconds: durationSeconds,
    );

    _addEvent(event);
    _log('Call ended tracked');
  }

  /// Track a call answered event
  void trackCallAnswered({required String roomId, required String callType}) {
    if (!_config.enabled) return;

    final event = AnalyticsEvent.callAnswered(
      id: _uuid.v4(),
      roomId: roomId,
      callType: callType,
      userId: _currentUserId,
      sessionId: _currentSession?.id,
    );

    _addEvent(event);
    _log('Call answered tracked');
  }

  /// Track a call declined event
  void trackCallDeclined({required String roomId, required String callType}) {
    if (!_config.enabled) return;

    final event = AnalyticsEvent.callDeclined(
      id: _uuid.v4(),
      roomId: roomId,
      callType: callType,
      userId: _currentUserId,
      sessionId: _currentSession?.id,
    );

    _addEvent(event);
    _log('Call declined tracked');
  }

  /// Track a call missed event
  void trackCallMissed({required String roomId, required String callType}) {
    if (!_config.enabled) return;

    final event = AnalyticsEvent.callMissed(
      id: _uuid.v4(),
      roomId: roomId,
      callType: callType,
      userId: _currentUserId,
      sessionId: _currentSession?.id,
    );

    _addEvent(event);
    _log('Call missed tracked');
  }

  /// Track a room created event
  void trackRoomCreated({
    required String roomId,
    required String roomType,
    int? memberCount,
  }) {
    if (!_config.enabled) return;

    final event = AnalyticsEvent.roomCreated(
      id: _uuid.v4(),
      roomId: roomId,
      roomType: roomType,
      userId: _currentUserId,
      sessionId: _currentSession?.id,
      memberCount: memberCount,
    );

    _addEvent(event);
    _log('Room created tracked');
  }

  /// Track a room joined event
  void trackRoomJoined({
    required String roomId,
    required String roomType,
    int? memberCount,
  }) {
    if (!_config.enabled) return;

    final event = AnalyticsEvent.roomJoined(
      id: _uuid.v4(),
      roomId: roomId,
      roomType: roomType,
      userId: _currentUserId,
      sessionId: _currentSession?.id,
      memberCount: memberCount,
    );

    _addEvent(event);
    _log('Room joined tracked');
  }

  /// Track a room left event
  void trackRoomLeft({required String roomId, required String roomType}) {
    if (!_config.enabled) return;

    final event = AnalyticsEvent.roomLeft(
      id: _uuid.v4(),
      roomId: roomId,
      roomType: roomType,
      userId: _currentUserId,
      sessionId: _currentSession?.id,
    );

    _addEvent(event);
    _log('Room left tracked');
  }

  /// Track a room deleted event
  void trackRoomDeleted({required String roomId, required String roomType}) {
    if (!_config.enabled) return;

    final event = AnalyticsEvent.roomDeleted(
      id: _uuid.v4(),
      roomId: roomId,
      roomType: roomType,
      userId: _currentUserId,
      sessionId: _currentSession?.id,
    );

    _addEvent(event);
    _log('Room deleted tracked');
  }

  /// Track a feature usage event
  void trackFeatureUsed(
    String featureName, {
    Map<String, dynamic>? properties,
  }) {
    if (!_config.enabled) return;

    final event = AnalyticsEvent.featureUsed(
      id: _uuid.v4(),
      featureName: featureName,
      userId: _currentUserId,
      sessionId: _currentSession?.id,
      properties: properties,
    );

    _addEvent(event);
    _log('Feature used: $featureName');
  }

  /// Track a custom event
  void trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    String? screenName,
  }) {
    if (!_config.enabled) return;

    final event = AnalyticsEvent.custom(
      id: _uuid.v4(),
      eventName: eventName,
      userId: _currentUserId,
      sessionId: _currentSession?.id,
      screenName: screenName,
      properties: properties,
    );

    _addEvent(event);
    _log('Custom event: $eventName');
  }

  /// Track an error event
  void trackError({
    required String errorType,
    required String errorMessage,
    String? screenName,
    StackTrace? stackTrace,
  }) {
    if (!_config.enabled) return;

    final event = AnalyticsEvent.error(
      id: _uuid.v4(),
      errorType: errorType,
      errorMessage: errorMessage,
      userId: _currentUserId,
      sessionId: _currentSession?.id,
      screenName: screenName,
      stackTrace: stackTrace?.toString(),
    );

    _addEvent(event);
    _log('Error tracked: $errorType');
  }

  /// Track user login
  void trackUserLogin({String? method}) {
    trackEvent(
      'user_login',
      properties: {
        if (method != null) 'method': method,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  /// Track user logout
  void trackUserLogout() {
    trackEvent(
      'user_logout',
      properties: {
        'session_duration_seconds': _currentSession?.durationSeconds,
        'events_in_session': _currentSession?.eventCount,
      },
    );
    _endSession();
    _startNewSession();
  }

  /// Track setting change
  void trackSettingChanged(String settingName, oldValue, newValue) {
    trackEvent(
      'setting_changed',
      properties: {
        'setting_name': settingName,
        'old_value': oldValue?.toString(),
        'new_value': newValue?.toString(),
      },
    );
  }

  /// Get current session
  AnalyticsSession? get currentSession => _currentSession;

  /// Get user properties
  AnalyticsUserProperties? get userProperties => _userProperties;

  /// Get pending event count
  int get pendingEventCount => _pendingEventCount;

  /// Manually flush events
  Future<void> flush() async {
    await _flushEvents();
  }

  /// End the current session and close the service
  Future<void> close() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    _endSession();
    await _flushEvents();

    _initialized = false;
    _log('Analytics service closed');
  }

  // Private methods

  void _startNewSession() {
    _currentSession = AnalyticsSession(
      id: _uuid.v4(),
      startTime: DateTime.now().toUtc(),
      userId: _currentUserId,
      deviceInfo: _getDeviceInfo(),
    );
    _log('New session started: ${_currentSession!.id}');
  }

  void _endSession() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        endTime: DateTime.now().toUtc(),
      );
      _log(
        'Session ended: ${_currentSession!.id}, '
        'duration: ${_currentSession!.durationSeconds}s',
      );
    }
  }

  void _addEvent(AnalyticsEvent event) {
    // Persist the event to the repository (database)
    _repository.insertEvent(event).catchError((
      Object e,
      StackTrace stackTrace,
    ) {
      AppLogger.error(
        'Failed to persist analytics event',
        error: e,
        stackTrace: stackTrace,
      );
      return -1; // Return error indicator
    });

    _pendingEventCount++;
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        eventCount: _currentSession!.eventCount + 1,
      );
    }

    // Flush if batch size reached
    if (_pendingEventCount >= _config.batchSize) {
      _flushEvents();
    }
  }

  Future<void> _flushEvents() async {
    if (_pendingEventCount == 0) return;

    try {
      // Retrieve unsynced events from the repository
      final eventsToSend = await _repository.getUnsyncedEvents(
        limit: _config.batchSize,
      );

      if (eventsToSend.isEmpty) {
        _pendingEventCount = 0;
        return;
      }

      // Analytics events are currently local-only. Events are stored and
      // marked as synced without transmission. When a backend analytics
      // endpoint is available, add HTTP POST here to send eventsToSend.

      // Mark events as synced in the repository
      final eventIds = eventsToSend.map((e) => e.id).toList();
      await _repository.markEventsSynced(eventIds);

      // Clean up old synced events
      await _repository.deleteSyncedEventsOlderThan(const Duration(days: 7));

      // Refresh the pending count from the repository
      _pendingEventCount = await _repository.getUnsyncedEventCount();

      _log('Flushed ${eventsToSend.length} events');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to flush analytics events',
        error: e,
        stackTrace: stackTrace,
      );
      // Keep events in repository for retry
    }
  }

  Map<String, dynamic> _getDeviceInfo() {
    if (kIsWeb) {
      return {'platform': 'web', 'is_debug': kDebugMode};
    }
    return {
      'platform': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
      'is_debug': kDebugMode,
    };
  }

  void _log(String message) {
    if (_config.enableDebugLogging) {
      AppLogger.debug('Analytics: $message');
    }
  }
}

/// Provider for the analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final repository = ref.watch(analyticsRepositoryProvider);
  final service = AnalyticsService(
    repository: repository,
    config: const AnalyticsConfig(enableDebugLogging: kDebugMode),
  );

  // Initialize on first access
  service.initialize();

  ref.onDispose(service.close);

  return service;
});
