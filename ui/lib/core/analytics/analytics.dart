/// Analytics module for tracking user behavior and app usage
///
/// This module provides comprehensive analytics capabilities including:
/// - Event tracking (screen views, user actions, errors)
/// - Session management
/// - User property tracking
/// - Automatic navigation observation
///
/// ## Quick Start
///
/// 1. Initialize the analytics service in main.dart:
/// ```dart
/// final analytics = AnalyticsService();
/// await analytics.initialize();
/// ```
///
/// 2. Track screen views automatically with the navigator observer:
/// ```dart
/// MaterialApp(
///   navigatorObservers: [
///     AnalyticsNavigatorObserver(analytics),
///   ],
/// )
/// ```
///
/// 3. Track events in your code:
/// ```dart
/// analytics.trackEvent('button_tap', properties: {'button_id': 'send'});
/// analytics.trackMessageSent(roomId: 'room1', messageType: 'text');
/// ```
///
/// ## Privacy
///
/// The analytics service is designed to be privacy-compliant:
/// - No PII is tracked without explicit opt-in
/// - All user identifiers can be anonymized
/// - Data is stored locally before batch upload
/// - Users can opt-out completely via settings
library;

export 'analytics_event.dart';
export 'analytics_observer.dart';
export 'analytics_repository.dart';
export 'analytics_service.dart';
