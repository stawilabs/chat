import '../logging/app_logger.dart';

/// Tracks startup timing metrics for performance monitoring
class StartupMetrics {
  StartupMetrics._();
  static final StartupMetrics _instance = StartupMetrics._();
  static StartupMetrics get instance => _instance;

  final DateTime _appStartTime = DateTime.now();
  final Map<String, DateTime> _phaseStartTimes = {};
  final Map<String, Duration> _phaseDurations = {};

  DateTime? _firstFrameTime;
  DateTime? _interactiveTime;
  DateTime? _fullyLoadedTime;

  /// Mark the start of a phase
  void startPhase(String phaseName) {
    _phaseStartTimes[phaseName] = DateTime.now();
    AppLogger.debug('Startup phase started: $phaseName');
  }

  /// Mark the end of a phase
  void endPhase(String phaseName) {
    final startTime = _phaseStartTimes[phaseName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _phaseDurations[phaseName] = duration;
      AppLogger.debug(
        'Startup phase completed: $phaseName',
        data: {'duration_ms': duration.inMilliseconds},
      );
    }
  }

  /// Mark when first frame is rendered
  void markFirstFrame() {
    _firstFrameTime = DateTime.now();
    final duration = _firstFrameTime!.difference(_appStartTime);
    AppLogger.info(
      'First frame rendered',
      data: {'time_to_first_frame_ms': duration.inMilliseconds},
    );
  }

  /// Mark when app becomes interactive
  void markInteractive() {
    _interactiveTime = DateTime.now();
    final duration = _interactiveTime!.difference(_appStartTime);
    AppLogger.info(
      'App is now interactive',
      data: {'time_to_interactive_ms': duration.inMilliseconds},
    );
  }

  /// Mark when app is fully loaded
  void markFullyLoaded() {
    _fullyLoadedTime = DateTime.now();
    final duration = _fullyLoadedTime!.difference(_appStartTime);
    AppLogger.info(
      'App fully loaded',
      data: {'time_to_fully_loaded_ms': duration.inMilliseconds},
    );

    // Log complete metrics summary
    _logMetricsSummary();
  }

  /// Get time since app start
  Duration get timeSinceStart => DateTime.now().difference(_appStartTime);

  /// Get time to first frame (null if not yet rendered)
  Duration? get timeToFirstFrame => _firstFrameTime?.difference(_appStartTime);

  /// Get time to interactive (null if not yet interactive)
  Duration? get timeToInteractive =>
      _interactiveTime?.difference(_appStartTime);

  /// Get time to fully loaded (null if not yet loaded)
  Duration? get timeToFullyLoaded =>
      _fullyLoadedTime?.difference(_appStartTime);

  /// Get duration for a specific phase
  Duration? getPhaseDuration(String phaseName) => _phaseDurations[phaseName];

  /// Get all phase durations
  Map<String, Duration> get allPhaseDurations =>
      Map.unmodifiable(_phaseDurations);

  /// Check if cold start target is met (< 2 seconds)
  bool get coldStartTargetMet =>
      _interactiveTime != null &&
      _interactiveTime!.difference(_appStartTime).inMilliseconds < 2000;

  /// Check if warm start target is met (< 500ms)
  /// Note: Warm start is measured differently (from resume, not from scratch)
  bool warmStartTargetMet(Duration resumeDuration) =>
      resumeDuration.inMilliseconds < 500;

  void _logMetricsSummary() {
    final summary = {
      'app_start_time': _appStartTime.toIso8601String(),
      'time_to_first_frame_ms': timeToFirstFrame?.inMilliseconds,
      'time_to_interactive_ms': timeToInteractive?.inMilliseconds,
      'time_to_fully_loaded_ms': timeToFullyLoaded?.inMilliseconds,
      'cold_start_target_met': coldStartTargetMet,
      'phases': _phaseDurations.map(
        (key, value) => MapEntry(key, value.inMilliseconds),
      ),
    };

    AppLogger.info('Startup metrics summary', data: summary);
  }

  /// Reset metrics (for testing or warm start measurement)
  void reset() {
    _phaseStartTimes.clear();
    _phaseDurations.clear();
    _firstFrameTime = null;
    _interactiveTime = null;
    _fullyLoadedTime = null;
  }
}
