// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the router refresh listenable.

@ProviderFor(authRouterRefreshListenable)
final authRouterRefreshListenableProvider =
    AuthRouterRefreshListenableProvider._();

/// Provider for the router refresh listenable.

final class AuthRouterRefreshListenableProvider
    extends
        $FunctionalProvider<
          AuthRouterRefreshListenable,
          AuthRouterRefreshListenable,
          AuthRouterRefreshListenable
        >
    with $Provider<AuthRouterRefreshListenable> {
  /// Provider for the router refresh listenable.
  AuthRouterRefreshListenableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRouterRefreshListenableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRouterRefreshListenableHash();

  @$internal
  @override
  $ProviderElement<AuthRouterRefreshListenable> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthRouterRefreshListenable create(Ref ref) {
    return authRouterRefreshListenable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRouterRefreshListenable value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRouterRefreshListenable>(value),
    );
  }
}

String _$authRouterRefreshListenableHash() =>
    r'b75d532f0be2539747c17b413825643676322437';

@ProviderFor(router)
final routerProvider = RouterProvider._();

final class RouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  RouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return router(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerHash() => r'1e50af5ae2aeef7c246368a4b66870f2e734eabe';
