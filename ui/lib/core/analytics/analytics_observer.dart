import 'package:flutter/material.dart';

import 'analytics_service.dart';

/// Navigation observer that automatically tracks screen views
///
/// Add this observer to your MaterialApp or GoRouter to automatically
/// track screen views when navigation occurs.
///
/// Example:
/// ```dart
/// MaterialApp(
///   navigatorObservers: [
///     AnalyticsNavigatorObserver(analyticsService),
///   ],
/// )
/// ```
class AnalyticsNavigatorObserver extends NavigatorObserver {
  AnalyticsNavigatorObserver(this._analyticsService);

  final AnalyticsService _analyticsService;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackScreenView(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _trackScreenView(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _trackScreenView(previousRoute);
    }
  }

  void _trackScreenView(Route<dynamic> route) {
    final screenName = _extractScreenName(route);
    if (screenName != null) {
      _analyticsService.trackScreenView(
        screenName,
        properties: {
          'route_type': route.runtimeType.toString(),
          if (route.settings.arguments != null) 'has_arguments': true,
        },
      );
    }
  }

  String? _extractScreenName(Route<dynamic> route) {
    // Try to get the route name from settings
    final routeName = route.settings.name;
    if (routeName != null && routeName.isNotEmpty && routeName != '/') {
      return _formatRouteName(routeName);
    }

    // Fall back to the route type
    final typeName = route.runtimeType.toString();
    if (typeName != 'MaterialPageRoute<dynamic>' &&
        typeName != 'PageRoute<dynamic>') {
      return typeName;
    }

    return null;
  }

  String _formatRouteName(String routeName) {
    // Remove leading slash
    var formatted = routeName.startsWith('/')
        ? routeName.substring(1)
        : routeName;

    // Remove any query parameters
    final queryIndex = formatted.indexOf('?');
    if (queryIndex != -1) {
      formatted = formatted.substring(0, queryIndex);
    }

    // Replace slashes with underscores and convert to snake_case
    formatted = formatted.replaceAll('/', '_');

    // Handle parameterized routes (e.g., /room/:roomId -> room_detail)
    if (formatted.contains(':')) {
      formatted = formatted.replaceAll(RegExp(':[^_/]+'), 'detail');
    }

    return formatted;
  }
}

/// Route-aware analytics mixin for screens
///
/// Use this mixin on stateful widgets that need to track when they become
/// visible or hidden.
///
/// Example:
/// ```dart
/// class MyScreen extends StatefulWidget {
///   @override
///   State<MyScreen> createState() => _MyScreenState();
/// }
///
/// class _MyScreenState extends State<MyScreen>
///     with RouteAware, AnalyticsRouteMixin {
///   @override
///   String get screenName => 'MyScreen';
///
///   @override
///   AnalyticsService get analyticsService => ref.read(analyticsServiceProvider);
/// }
/// ```
mixin AnalyticsRouteMixin<T extends StatefulWidget> on State<T>, RouteAware {
  /// The name of this screen for analytics
  String get screenName;

  /// The analytics service to use
  AnalyticsService get analyticsService;

  /// Additional properties to track with screen views
  Map<String, dynamic>? get screenViewProperties => null;

  @override
  void didPopNext() {
    super.didPopNext();
    _trackScreenView();
  }

  @override
  void didPush() {
    super.didPush();
    _trackScreenView();
  }

  void _trackScreenView() {
    analyticsService.trackScreenView(
      screenName,
      properties: screenViewProperties,
    );
  }
}

/// Widget wrapper for tracking time spent on a screen
///
/// Uses [WidgetsBindingObserver] to pause/resume timing when the app goes
/// to background/foreground, ensuring accurate duration tracking.
///
/// Example:
/// ```dart
/// AnalyticsScreenTracker(
///   screenName: 'ChatScreen',
///   analyticsService: analyticsService,
///   child: ChatContent(),
/// )
/// ```
class AnalyticsScreenTracker extends StatefulWidget {
  const AnalyticsScreenTracker({
    required this.screenName,
    required this.analyticsService,
    required this.child,
    this.properties,
    super.key,
  });

  final String screenName;
  final AnalyticsService analyticsService;
  final Widget child;
  final Map<String, dynamic>? properties;

  @override
  State<AnalyticsScreenTracker> createState() => _AnalyticsScreenTrackerState();
}

class _AnalyticsScreenTrackerState extends State<AnalyticsScreenTracker>
    with WidgetsBindingObserver {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stopwatch.start();
    widget.analyticsService.trackScreenView(
      widget.screenName,
      properties: widget.properties,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _stopwatch.stop();
      case AppLifecycleState.resumed:
        _stopwatch.start();
      case AppLifecycleState.detached:
        _stopwatch.stop();
    }
  }

  @override
  void dispose() {
    _stopwatch.stop();
    WidgetsBinding.instance.removeObserver(this);
    widget.analyticsService.trackEvent(
      'screen_exit',
      screenName: widget.screenName,
      properties: {
        'duration_seconds': _stopwatch.elapsed.inSeconds,
        'duration_ms': _stopwatch.elapsedMilliseconds,
        ...?widget.properties,
      },
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
