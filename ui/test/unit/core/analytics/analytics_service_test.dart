import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/analytics/analytics_event.dart';
import 'package:stawi/core/analytics/analytics_repository.dart';
import 'package:stawi/core/analytics/analytics_service.dart';
import 'package:stawi/core/db/database.dart' hide AnalyticsEvent;

/// In-memory fake of [AnalyticsRepository] for testing purposes.
///
/// Stores events in a list so tests can run without a real database.
class FakeAnalyticsRepository extends AnalyticsRepository {
  FakeAnalyticsRepository()
    : super(AppDatabase.forTesting(NativeDatabase.memory()));

  final List<AnalyticsEvent> _events = [];

  @override
  Future<int> insertEvent(AnalyticsEvent event) async {
    _events.add(event);
    return _events.length;
  }

  @override
  Future<void> insertEvents(List<AnalyticsEvent> events) async {
    _events.addAll(events);
  }

  @override
  Future<List<AnalyticsEvent>> getUnsyncedEvents({int limit = 100}) async {
    return _events.where((e) => !e.isSynced).take(limit).toList();
  }

  @override
  Future<void> markEventsSynced(List<String> eventIds) async {
    _events.removeWhere((e) => eventIds.contains(e.id));
  }

  @override
  Future<int> deleteSyncedEventsOlderThan(Duration duration) async {
    return 0;
  }

  @override
  Future<int> deleteAllSyncedEvents() async {
    final before = _events.length;
    _events.removeWhere((e) => e.isSynced);
    return before - _events.length;
  }

  @override
  Future<int> getUnsyncedEventCount() async {
    return _events.where((e) => !e.isSynced).length;
  }

  @override
  Future<int> getTotalEventCount() async {
    return _events.length;
  }

  @override
  Future<List<AnalyticsEvent>> getEventsBySession(String sessionId) async {
    return _events.where((e) => e.sessionId == sessionId).toList();
  }

  @override
  Future<List<AnalyticsEvent>> getEventsByType(
    AnalyticsEventType type, {
    int limit = 100,
    int offset = 0,
  }) async {
    return _events
        .where((e) => e.type == type)
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<List<AnalyticsEvent>> getEventsInRange(
    DateTime start,
    DateTime end, {
    int limit = 1000,
  }) async {
    return _events
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end))
        .take(limit)
        .toList();
  }

  @override
  Future<int> clearAllEvents() async {
    final count = _events.length;
    _events.clear();
    return count;
  }
}

void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;
    late FakeAnalyticsRepository fakeRepository;

    setUp(() async {
      fakeRepository = FakeAnalyticsRepository();
      analyticsService = AnalyticsService(repository: fakeRepository);
      await analyticsService.initialize();
    });

    group('configuration', () {
      test('can be disabled via config', () {
        final service = AnalyticsService(
          repository: fakeRepository,
          config: const AnalyticsConfig(enabled: false),
        );

        // When disabled, tracking should not add events
        service.trackEvent('test_event');
        expect(service.pendingEventCount, equals(0));
      });

      test('respects batch size configuration', () {
        const config = AnalyticsConfig(batchSize: 100);
        expect(config.batchSize, equals(100));
      });

      test('respects flush interval configuration', () {
        const config = AnalyticsConfig(flushIntervalSeconds: 120);
        expect(config.flushIntervalSeconds, equals(120));
      });
    });

    group('event tracking', () {
      test('trackEvent adds event to queue', () {
        analyticsService.trackEvent('test_event');
        expect(analyticsService.pendingEventCount, equals(1));
      });

      test('trackScreenView adds event to queue', () {
        analyticsService.trackScreenView('HomeScreen');
        expect(analyticsService.pendingEventCount, equals(1));
      });

      test('trackEvent with properties', () {
        analyticsService.trackEvent(
          'button_tap',
          properties: {'button_id': 'send_message'},
        );
        expect(analyticsService.pendingEventCount, equals(1));
      });

      test('trackMessageSent creates correct event', () {
        analyticsService.trackMessageSent(
          roomId: 'room-1',
          messageType: 'text',
          isReply: true,
        );
        expect(analyticsService.pendingEventCount, equals(1));
      });

      test('trackFeatureUsed creates correct event', () {
        analyticsService.trackFeatureUsed(
          'starred_messages',
          properties: {'action': 'view'},
        );
        expect(analyticsService.pendingEventCount, equals(1));
      });

      test('trackError creates correct event', () {
        analyticsService.trackError(
          errorType: 'NetworkError',
          errorMessage: 'Connection timeout',
          screenName: 'ChatScreen',
        );
        expect(analyticsService.pendingEventCount, equals(1));
      });
    });

    group('user management', () {
      // TODO(developer): These tests require platform channels for path_provider.
      // Consider adding a test-specific constructor to AnalyticsService that
      // skips file system access, or use integration tests instead.
      test(
        'setUserId updates current user',
        skip: 'Requires platform channels for path_provider',
        () async {
          // Initialize to start a session
          await analyticsService.initialize();
          analyticsService.setUserId('user-123');
          expect(analyticsService.currentSession?.userId, equals('user-123'));
        },
      );

      test('setUserId can clear user', () {
        analyticsService.setUserId('user-123');
        analyticsService.setUserId(null);
        expect(analyticsService.currentSession?.userId, isNull);
      });

      test('setUserProperties updates properties', () {
        const properties = AnalyticsUserProperties(
          displayName: 'Test User',
          appVersion: '1.0.0',
        );
        analyticsService.setUserProperties(properties);
        expect(
          analyticsService.userProperties?.displayName,
          equals('Test User'),
        );
      });

      test('updateUserProperty adds custom property', () {
        analyticsService.updateUserProperty('premium_user', true);
        expect(
          analyticsService.userProperties?.customProperties?['premium_user'],
          isTrue,
        );
      });
    });

    // TODO(developer): Session management tests require platform channels for
    // path_provider which isn't available in unit tests. Consider using
    // integration tests or a test-specific constructor.
    group('session management', () {
      test(
        'tracks screen view count in session',
        skip: 'Requires platform channels for path_provider',
        () async {
          // Initialize to start a session
          await analyticsService.initialize();
          analyticsService.trackScreenView('Screen1');
          analyticsService.trackScreenView('Screen2');
          expect(analyticsService.currentSession?.screenViewCount, equals(2));
        },
      );

      test(
        'tracks event count in session',
        skip: 'Requires platform channels for path_provider',
        () async {
          // Initialize to start a session
          await analyticsService.initialize();
          analyticsService.trackEvent('event1');
          analyticsService.trackEvent('event2');
          analyticsService.trackEvent('event3');
          expect(analyticsService.currentSession?.eventCount, equals(3));
        },
      );

      test(
        'tracks entry and exit screens',
        skip: 'Requires platform channels for path_provider',
        () async {
          // Initialize to start a session
          await analyticsService.initialize();
          analyticsService.trackScreenView('EntryScreen');
          analyticsService.trackScreenView('MiddleScreen');
          analyticsService.trackScreenView('ExitScreen');
          expect(
            analyticsService.currentSession?.entryScreen,
            equals('EntryScreen'),
          );
          expect(
            analyticsService.currentSession?.exitScreen,
            equals('ExitScreen'),
          );
        },
      );

      test(
        'trackUserLogout resets session',
        skip: 'Requires platform channels for path_provider',
        () async {
          // Initialize to start a session
          await analyticsService.initialize();
          analyticsService.trackEvent('event1');
          analyticsService.trackUserLogout();
          expect(analyticsService.currentSession?.eventCount, equals(0));
        },
      );
    });

    group('setting tracking', () {
      test('trackSettingChanged records old and new values', () {
        analyticsService.trackSettingChanged('theme', 'light', 'dark');
        expect(analyticsService.pendingEventCount, equals(1));
      });
    });
  });

  group('AnalyticsEvent', () {
    test('screenView factory creates correct event', () {
      final event = AnalyticsEvent.screenView(
        id: 'event-1',
        screenName: 'HomeScreen',
        userId: 'user-1',
        sessionId: 'session-1',
      );

      expect(event.type, equals(AnalyticsEventType.screenView));
      expect(event.name, equals('screen_view'));
      expect(event.screenName, equals('HomeScreen'));
      expect(event.properties?['screen_name'], equals('HomeScreen'));
    });

    test('messageSent factory creates correct event', () {
      final event = AnalyticsEvent.messageSent(
        id: 'event-2',
        roomId: 'room-1',
        messageType: 'text',
        hasAttachment: true,
      );

      expect(event.type, equals(AnalyticsEventType.messageSent));
      expect(event.properties?['room_id'], equals('room-1'));
      expect(event.properties?['message_type'], equals('text'));
      expect(event.properties?['has_attachment'], isTrue);
      expect(event.properties?['is_reply'], isFalse);
    });

    test('error factory creates correct event', () {
      final event = AnalyticsEvent.error(
        id: 'event-3',
        errorType: 'NetworkError',
        errorMessage: 'Connection failed',
        screenName: 'ChatScreen',
      );

      expect(event.type, equals(AnalyticsEventType.errorOccurred));
      expect(event.properties?['error_type'], equals('NetworkError'));
      expect(event.properties?['error_message'], equals('Connection failed'));
    });

    test('featureUsed factory creates correct event', () {
      final event = AnalyticsEvent.featureUsed(
        id: 'event-4',
        featureName: 'starred_messages',
        properties: {'action': 'star'},
      );

      expect(event.type, equals(AnalyticsEventType.featureUsed));
      expect(event.properties?['feature_name'], equals('starred_messages'));
      expect(event.properties?['action'], equals('star'));
    });

    test('custom factory creates correct event', () {
      final event = AnalyticsEvent.custom(
        id: 'event-5',
        eventName: 'custom_action',
        properties: {'key': 'value'},
      );

      expect(event.type, equals(AnalyticsEventType.custom));
      expect(event.name, equals('custom_action'));
    });

    test('callStarted factory creates correct event', () {
      final event = AnalyticsEvent.callStarted(
        id: 'event-6',
        roomId: 'room-1',
        callType: 'video',
        userId: 'user-1',
      );

      expect(event.type, equals(AnalyticsEventType.callStarted));
      expect(event.name, equals('call_started'));
      expect(event.properties?['room_id'], equals('room-1'));
      expect(event.properties?['call_type'], equals('video'));
    });

    test('callEnded factory creates correct event with duration', () {
      final event = AnalyticsEvent.callEnded(
        id: 'event-7',
        roomId: 'room-1',
        callType: 'audio',
        durationSeconds: 120,
      );

      expect(event.type, equals(AnalyticsEventType.callEnded));
      expect(event.name, equals('call_ended'));
      expect(event.properties?['duration_seconds'], equals(120));
    });

    test('callMissed factory creates correct event', () {
      final event = AnalyticsEvent.callMissed(
        id: 'event-8',
        roomId: 'room-1',
        callType: 'video',
      );

      expect(event.type, equals(AnalyticsEventType.callMissed));
      expect(event.name, equals('call_missed'));
    });

    test('roomCreated factory creates correct event', () {
      final event = AnalyticsEvent.roomCreated(
        id: 'event-9',
        roomId: 'room-1',
        roomType: 'group',
        memberCount: 5,
      );

      expect(event.type, equals(AnalyticsEventType.roomCreated));
      expect(event.name, equals('room_created'));
      expect(event.properties?['room_id'], equals('room-1'));
      expect(event.properties?['room_type'], equals('group'));
      expect(event.properties?['member_count'], equals(5));
    });

    test('roomJoined factory creates correct event', () {
      final event = AnalyticsEvent.roomJoined(
        id: 'event-10',
        roomId: 'room-1',
        roomType: 'direct',
      );

      expect(event.type, equals(AnalyticsEventType.roomJoined));
      expect(event.name, equals('room_joined'));
    });

    test('roomLeft factory creates correct event', () {
      final event = AnalyticsEvent.roomLeft(
        id: 'event-11',
        roomId: 'room-1',
        roomType: 'group',
      );

      expect(event.type, equals(AnalyticsEventType.roomLeft));
      expect(event.name, equals('room_left'));
    });
  });

  group('AnalyticsSession', () {
    test('calculates duration correctly', () {
      final session = AnalyticsSession(
        id: 'session-1',
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        endTime: DateTime.now(),
      );

      expect(session.durationSeconds, greaterThanOrEqualTo(299));
      expect(session.durationSeconds, lessThanOrEqualTo(301));
    });

    test('isActive returns true when no end time', () {
      final session = AnalyticsSession(
        id: 'session-1',
        startTime: DateTime.now(),
      );

      expect(session.isActive, isTrue);
    });

    test('isActive returns false when end time is set', () {
      final session = AnalyticsSession(
        id: 'session-1',
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
      );

      expect(session.isActive, isFalse);
    });
  });

  group('AnalyticsUserProperties', () {
    test('can create with all properties', () {
      final props = AnalyticsUserProperties(
        userId: 'user-1',
        displayName: 'Test User',
        email: 'test@example.com',
        phoneNumber: '+1234567890',
        accountCreatedAt: DateTime(2024),
        lastLoginAt: DateTime.now(),
        appVersion: '1.0.0',
        platform: 'android',
        deviceModel: 'Pixel 6',
        osVersion: '14',
        locale: 'en_US',
        totalRooms: 10,
        totalContacts: 50,
        customProperties: {'premium': true},
      );

      expect(props.userId, equals('user-1'));
      expect(props.displayName, equals('Test User'));
      expect(props.customProperties?['premium'], isTrue);
    });
  });

  group('AnalyticsEventType', () {
    test('all event types are defined', () {
      expect(AnalyticsEventType.values, isNotEmpty);
      expect(AnalyticsEventType.screenView, isNotNull);
      expect(AnalyticsEventType.messageSent, isNotNull);
      expect(AnalyticsEventType.callStarted, isNotNull);
      expect(AnalyticsEventType.roomCreated, isNotNull);
      expect(AnalyticsEventType.userLogin, isNotNull);
      expect(AnalyticsEventType.errorOccurred, isNotNull);
      expect(AnalyticsEventType.custom, isNotNull);
    });
  });

  group('AnalyticsConfig', () {
    test('has sensible defaults', () {
      const config = AnalyticsConfig();

      expect(config.enabled, isTrue);
      expect(config.batchSize, equals(50));
      expect(config.flushIntervalSeconds, equals(60));
      expect(config.maxStoredEvents, equals(1000));
      expect(config.enableDebugLogging, isFalse);
    });

    test('can be customized', () {
      const config = AnalyticsConfig(
        enabled: false,
        batchSize: 100,
        flushIntervalSeconds: 120,
        maxStoredEvents: 500,
        enableDebugLogging: true,
      );

      expect(config.enabled, isFalse);
      expect(config.batchSize, equals(100));
      expect(config.flushIntervalSeconds, equals(120));
      expect(config.maxStoredEvents, equals(500));
      expect(config.enableDebugLogging, isTrue);
    });
  });
}
