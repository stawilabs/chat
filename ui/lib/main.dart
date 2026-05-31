import 'dart:async';
import 'dart:io' show Platform;

import 'package:antinvestor_auth_runtime/antinvestor_auth_runtime.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/auth/migration.dart';
import 'core/auth/runtime_provider.dart';
import 'core/error/error_tracking_service.dart';
import 'core/logging/app_logger.dart';
import 'core/navigation/deep_link_handler.dart';
import 'core/security/lock_state_manager.dart';
import 'core/startup/startup_metrics.dart';
import 'core/startup/startup_service.dart';
import 'core/theme/app_theme.dart';
import 'features/security/ui/lock_screen.dart';
import 'features/splash/splash_screen.dart';

/// Sentry DSN - should be configured via environment variable in production
const String _sentryDsn = String.fromEnvironment('SENTRY_DSN');

void main() async {
  // Record app start time immediately
  final metrics = StartupMetrics.instance;
  metrics.startPhase('pre_binding');

  WidgetsFlutterBinding.ensureInitialized();
  metrics.endPhase('pre_binding');

  // Initialize error tracking with Sentry (minimal blocking)
  metrics.startPhase('error_tracking');
  if (_sentryDsn.isNotEmpty) {
    await ErrorTrackingService.initialize(
      dsn: _sentryDsn,
      tracesSampleRate: kReleaseMode ? 0.2 : 1.0,
      appRunner: () => _runApp(metrics),
    );
  } else {
    AppLogger.warning('Sentry DSN not configured, error tracking disabled');
    await _runApp(metrics);
  }
  metrics.endPhase('error_tracking');
}

/// Run the app with minimal blocking initialization
Future<void> _runApp(StartupMetrics metrics) async {
  metrics.startPhase('run_app');

  AppLogger.info(
    'Application starting',
    data: {
      'platform': Platform.operatingSystem,
      'error_tracking_enabled': ErrorTrackingService.isInitialized,
    },
  );

  // One-time migration: wipe legacy openid_client tokens from secure
  // storage so the runtime prompts for a fresh sign-in the first time a
  // pre-migration install launches the new build. Subsequent launches
  // see the flag set in SharedPreferences and no-op.
  await migrateLegacyAuthIfNeeded();

  // Construct the auth runtime before runApp so the root ProviderScope can
  // hand the same instance to every consumer. The WorkManager background
  // path builds a short-lived runtime per task via BackgroundAuthHelper
  // (core/auth/background_auth_helper.dart).
  final authRuntime = buildChatRuntime();

  runApp(
    ProviderScope(
      overrides: [authRuntimeProvider.overrideWithValue(authRuntime)],
      child: const ChatApp(),
    ),
  );

  // Mark first frame after runApp
  markFirstFrameRendered();
  metrics.endPhase('run_app');
}

class ChatApp extends ConsumerStatefulWidget {
  const ChatApp({super.key});

  @override
  ConsumerState<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends ConsumerState<ChatApp> {
  @override
  void initState() {
    super.initState();
    // Start deep-link handling after the first frame so the router exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(deepLinkHandlerProvider).initialize());
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return SplashScreen(
      child: MaterialApp.router(
        title: 'AntInvestor Chat',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return _LockScreenWrapper(child: child ?? const SizedBox.shrink());
        },
      ),
    );
  }
}

/// Wrapper that shows lock screen overlay when app is locked
class _LockScreenWrapper extends ConsumerWidget {
  const _LockScreenWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShowLock = ref.watch(shouldShowLockScreenProvider);

    return Stack(
      children: [
        child,
        if (shouldShowLock)
          Positioned.fill(
            child: LockScreen(
              onUnlock: () {
                final manager = ref.read(lockStateManagerProvider);
                manager.unlock();
              },
            ),
          ),
      ],
    );
  }
}
