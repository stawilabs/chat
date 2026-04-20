// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Chat-level auth state notifier. Delegates to the runtime but keeps
/// the `login()` / `logout()` / `refresh()` surface expected by
/// existing UI call sites.

@ProviderFor(AuthStateNotifier)
final authStateProvider = AuthStateNotifierProvider._();

/// Chat-level auth state notifier. Delegates to the runtime but keeps
/// the `login()` / `logout()` / `refresh()` surface expected by
/// existing UI call sites.
final class AuthStateNotifierProvider
    extends $AsyncNotifierProvider<AuthStateNotifier, AuthState> {
  /// Chat-level auth state notifier. Delegates to the runtime but keeps
  /// the `login()` / `logout()` / `refresh()` surface expected by
  /// existing UI call sites.
  AuthStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateNotifierHash();

  @$internal
  @override
  AuthStateNotifier create() => AuthStateNotifier();
}

String _$authStateNotifierHash() => r'83f920a366388c41c25783be0d99398901e90eec';

/// Chat-level auth state notifier. Delegates to the runtime but keeps
/// the `login()` / `logout()` / `refresh()` surface expected by
/// existing UI call sites.

abstract class _$AuthStateNotifier extends $AsyncNotifier<AuthState> {
  FutureOr<AuthState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuthState>, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthState>, AuthState>,
              AsyncValue<AuthState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
