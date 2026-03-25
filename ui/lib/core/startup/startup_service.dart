import 'dart:async';
import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/token_refresh_service.dart';
import '../../features/contacts/services/contact_background_sync_task.dart';
import '../../features/notifications/badge_service.dart';
import '../../features/notifications/notification_service.dart';
import '../error/error_tracking_service.dart';
import '../logging/app_logger.dart';
import '../networking/client.dart';
import '../networking/connectivity_service.dart';
import '../sync/background_sync_task.dart';
import '../sync/post_login_sync_service.dart';
import '../sync/sync_engine.dart';
import 'startup_metrics.dart';

part 'startup_service.g.dart';

/// Initialization phases
enum StartupPhase {
  /// Critical: Must complete before showing any UI
  critical,

  /// Essential: Needed for basic app functionality
  essential,

  /// Deferred: Can happen after app is interactive
  deferred,
}

/// Current state of startup initialization
enum StartupState {
  /// Initial state before any initialization
  initial,

  /// Critical services being initialized
  initializingCritical,

  /// Essential services being initialized
  initializingEssential,

  /// App is interactive, deferred tasks running in background
  interactive,

  /// All initialization complete
  complete,

  /// Error occurred during startup
  error,
}

// Sentinel value for copyWith to distinguish "not provided" from "explicitly null"
const _sentinel = Object();

/// Startup progress information
class StartupProgress {
  const StartupProgress({
    required this.state,
    this.currentTask,
    this.progress = 0.0,
    this.errorMessage,
  });
  final StartupState state;
  final String? currentTask;
  final double progress; // 0.0 to 1.0
  final String? errorMessage;

  /// Creates a copy with the given fields replaced.
  ///
  /// To clear a nullable field, explicitly pass null:
  /// ```dart
  /// progress.copyWith(currentTask: null) // clears currentTask
  /// ```
  StartupProgress copyWith({
    StartupState? state,
    Object? currentTask = _sentinel,
    double? progress,
    Object? errorMessage = _sentinel,
  }) {
    return StartupProgress(
      state: state ?? this.state,
      currentTask: identical(currentTask, _sentinel)
          ? this.currentTask
          : currentTask as String?,
      progress: progress ?? this.progress,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  bool get isComplete => state == StartupState.complete;
  bool get isInteractive =>
      state == StartupState.interactive || state == StartupState.complete;
  bool get hasError => state == StartupState.error;
}

/// Background task callback - must be top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    AppLogger.info('Workmanager executing task', data: {'task': task});

    try {
      bool success;

      // Route to appropriate task handler
      switch (task) {
        case contactSyncTaskIdentifier:
          success = await ContactBackgroundSyncTask.run();
        default:
          // Default: message sync task
          success = await BackgroundSyncTask.run();
      }

      AppLogger.info(
        'Workmanager task completed',
        data: {'task': task, 'success': success},
      );
      return success;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Workmanager task failed',
        error: e,
        stackTrace: stackTrace,
        data: {'task': task},
      );
      return false;
    }
  });
}

/// Manages phased app initialization for optimized startup time
@riverpod
class StartupService extends _$StartupService {
  static const Duration _networkTimeout = Duration(seconds: 5);
  static const Duration _dnsReadyDelay = Duration(milliseconds: 200);

  @override
  StartupProgress build() {
    return const StartupProgress(state: StartupState.initial);
  }

  /// Run the complete startup sequence
  Future<void> initialize() async {
    final metrics = StartupMetrics.instance;

    try {
      // Phase 1: Critical initialization
      state = state.copyWith(
        state: StartupState.initializingCritical,
        currentTask: 'Initializing core services...',
        progress: 0.1,
      );
      metrics.startPhase('critical');
      await _initializeCritical();
      metrics.endPhase('critical');

      // Phase 2: Essential initialization
      state = state.copyWith(
        state: StartupState.initializingEssential,
        currentTask: 'Loading user data...',
        progress: 0.4,
      );
      metrics.startPhase('essential');
      await _initializeEssential();
      metrics.endPhase('essential');

      // App is now interactive
      state = state.copyWith(
        state: StartupState.interactive,
        currentTask: 'Finishing setup...',
        progress: 0.8,
      );
      metrics.markInteractive();

      // Phase 3: Deferred initialization (non-blocking)
      metrics.startPhase('deferred');
      _initializeDeferred().then((_) {
        metrics.endPhase('deferred');
        metrics.markFullyLoaded();
        state = state.copyWith(state: StartupState.complete, progress: 1);
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        'Startup initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        state: StartupState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Phase 1: Critical initialization
  /// Must complete before showing any UI
  Future<void> _initializeCritical() async {
    final isMobile = Platform.isAndroid || Platform.isIOS;

    // Firebase is needed for notifications - initialize early
    if (isMobile) {
      state = state.copyWith(currentTask: 'Initializing Firebase...');
      try {
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
        AppLogger.info('Firebase initialized');
      } catch (e) {
        // Firebase may not be configured (missing google-services.json)
        // Continue without Firebase - notifications won't work
        AppLogger.warning(
          'Firebase initialization failed - notifications disabled',
          data: {'error': e.toString()},
        );
      }
    }

    // Add breadcrumb for app start
    if (ErrorTrackingService.isInitialized) {
      await ErrorTrackingService.addBreadcrumb(
        message: 'App started',
        category: 'lifecycle',
        data: {'platform': Platform.operatingSystem},
      );
    }

    AppLogger.info(
      'Critical initialization complete',
      data: {
        'firebase_initialized': isMobile,
        'error_tracking_enabled': ErrorTrackingService.isInitialized,
      },
    );
  }

  /// Phase 2: Essential initialization
  /// Needed for basic app functionality
  Future<void> _initializeEssential() async {
    final authRepo = ref.read(authRepositoryProvider);
    final isLoggedIn = await authRepo.isLoggedIn();

    if (!isLoggedIn) {
      AppLogger.debug('User not logged in, skipping service initialization');
      return;
    }

    state = state.copyWith(currentTask: 'Verifying authentication...');
    AppLogger.info('User is logged in, ensuring valid access token');

    // Ensure we have a valid access token (will refresh if expired)
    final token = await authRepo.ensureValidAccessToken();

    if (token == null) {
      AppLogger.warning(
        'Token refresh failed on app start, user needs to re-login',
      );
      return;
    }

    AppLogger.info('Valid access token obtained');

    // IMPORTANT: Reload TokenManager from storage to sync its in-memory cache
    // AuthService saves tokens to storage, but TokenManager has its own cache
    // that needs to be refreshed for API clients to use the new token
    final tokenManager = ref.read(tokenManagerProvider);
    await reloadTokenManager(tokenManager);

    // Invalidate API client providers to force them to recreate with fresh token
    // This is needed because FutureProviders cache their result
    ref.invalidate(chatClientProvider);
    ref.invalidate(chatServiceClientProvider);
    AppLogger.debug('Invalidated chat client providers to pick up new token');

    // Set user context for error tracking
    if (ErrorTrackingService.isInitialized) {
      final userInfoMap = await authRepo.getUserInfo();
      if (userInfoMap != null) {
        final userInfo = _UserInfo.fromOidcClaims(userInfoMap);
        await ErrorTrackingService.setUser(
          id: userInfo.id,
          email: userInfo.email,
          username: userInfo.username,
        );
        await ErrorTrackingService.addBreadcrumb(
          message: 'User authenticated',
          category: 'auth',
        );
      }
    }

    // Wait for network with timeout
    state = state.copyWith(currentTask: 'Checking network...');
    await _waitForNetworkWithTimeout();

    // Start background token refresh service
    // This ensures tokens are proactively refreshed before they expire,
    // minimizing the chance of auth errors during API calls
    final tokenRefreshService = ref.read(tokenRefreshServiceProvider);
    tokenRefreshService.start();

    // Create post-login sync service (not a provider to avoid lifecycle issues)
    final postLoginSync = await createPostLoginSyncService(ref);

    // Check if this is first login (no local rooms)
    final hasLocalRooms = await postLoginSync.hasLocalRooms();

    if (!hasLocalRooms) {
      // First login: Sync rooms first, then start real-time engine
      // This ensures user sees their rooms immediately after login
      // Note: No progress update - sync happens silently in background
      AppLogger.info(
        'First login detected - syncing rooms before starting engine',
      );
      await postLoginSync.runPostLoginSync();

      // Now start sync engine for real-time updates
      final syncEngine = await ref.read(syncEngineProvider.future);
      syncEngine.start();
    } else {
      // Returning user: Start sync engine first for real-time updates
      final syncEngine = await ref.read(syncEngineProvider.future);
      syncEngine.start();

      // Run post-login sync in background (non-blocking)
      // This catches any rooms created on other devices, etc.
      unawaited(
        postLoginSync.runPostLoginSync().then((_) {
          AppLogger.debug('Background post-login sync completed');
        }),
      );
    }

    AppLogger.info('Essential initialization complete');
  }

  /// Phase 3: Deferred initialization
  /// Runs in background after app is interactive
  Future<void> _initializeDeferred() async {
    final isMobile = Platform.isAndroid || Platform.isIOS;

    // Start connectivity monitoring for auto-sync on reconnection
    final connectivityService = await ref.read(
      connectivityServiceProvider.future,
    );
    connectivityService.start();

    // Initialize push notifications
    final authRepo = ref.read(authRepositoryProvider);
    final isLoggedIn = await authRepo.isLoggedIn();

    if (isLoggedIn && NotificationService.isSupported) {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
    }

    // Initialize badge service for app icon badge count
    if (isLoggedIn && BadgeService.isSupported) {
      final badgeService = ref.read(badgeServiceProvider);
      await badgeService.initialize();
    }

    // Register background sync (only on mobile)
    if (isMobile) {
      await Workmanager().initialize(callbackDispatcher);

      // Register message sync task (every 15 minutes)
      await Workmanager().registerPeriodicTask(
        'background-sync',
        'backgroundSync',
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );

      // Register contact sync task (every 24 hours)
      await Workmanager().registerPeriodicTask(
        contactSyncTaskName,
        contactSyncTaskIdentifier,
        frequency: const Duration(hours: 24),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    }

    AppLogger.info(
      'Deferred initialization complete',
      data: {
        'workmanager_registered': isMobile,
        'contact_sync_task_registered': isMobile,
        'notifications_initialized':
            isLoggedIn && NotificationService.isSupported,
      },
    );
  }

  /// Wait for network connectivity with a timeout
  /// Returns true if connected, false if timed out
  Future<bool> _waitForNetworkWithTimeout() async {
    final connectivity = Connectivity();
    final results = await connectivity.checkConnectivity();

    final hasConnection = _hasValidConnection(results);

    if (hasConnection) {
      // Small delay for DNS readiness
      await Future.delayed(_dnsReadyDelay);
      return true;
    }

    AppLogger.info(
      'Waiting for network connectivity (max ${_networkTimeout.inSeconds}s)...',
    );

    // Wait for connectivity with timeout
    try {
      await for (final results in connectivity.onConnectivityChanged.timeout(
        _networkTimeout,
        onTimeout: (sink) {
          AppLogger.warning('Network wait timed out, proceeding anyway');
          sink.close();
        },
      )) {
        if (_hasValidConnection(results)) {
          AppLogger.info('Network connectivity established');
          await Future.delayed(_dnsReadyDelay);
          return true;
        }
      }
    } catch (e) {
      AppLogger.warning('Network connectivity wait interrupted: $e');
    }

    return false;
  }

  bool _hasValidConnection(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
  }
}

/// Type-safe wrapper for user info from OIDC token
class _UserInfo {
  _UserInfo({required this.id, this.email, this.username});

  factory _UserInfo.fromOidcClaims(Map<String, dynamic> claims) {
    return _UserInfo(
      id: claims['sub'] as String? ?? 'unknown',
      email: claims['email'] as String?,
      username: claims['preferred_username'] as String?,
    );
  }
  final String id;
  final String? email;
  final String? username;
}

/// Marks when first frame is rendered
void markFirstFrameRendered() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    StartupMetrics.instance.markFirstFrame();
  });
}
