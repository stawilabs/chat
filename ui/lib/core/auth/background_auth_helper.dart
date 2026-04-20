import 'package:antinvestor_auth_runtime/antinvestor_auth_runtime.dart';

import 'runtime_provider.dart';

/// Utilities for WorkManager / headless task contexts that cannot
/// access the UI Isolate's Riverpod tree.
///
/// Every call constructs a fresh `AuthRuntime`, invokes the supplied
/// callback, and disposes — do NOT share runtime instances across tasks
/// (the runtime owns isolate-like state and is not safe to share across
/// Isolates).
class BackgroundAuthHelper {
  BackgroundAuthHelper._();

  /// Runs [fn] with an authenticated runtime, if the user is signed in.
  /// Returns null if not authenticated (the caller should treat this as
  /// "skip this job; user is signed out").
  static Future<T?> withRuntime<T>(Future<T> Function(AuthRuntime) fn) async {
    final runtime = buildChatRuntime();
    try {
      if (!runtime.isAuthenticated) return null;
      return await fn(runtime);
    } finally {
      await runtime.dispose();
    }
  }

  /// Convenience: authenticated fetch from a headless context.
  static Future<ApiResponse?> fetch(
    String path, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) {
    return withRuntime(
      (rt) => rt.fetch(
        path,
        method: method,
        headers: headers,
        body: body,
        timeout: timeout,
      ),
    );
  }
}
