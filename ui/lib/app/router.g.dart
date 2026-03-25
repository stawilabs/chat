// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the auth change notifier

@ProviderFor(authChangeNotifier)
final authChangeProvider = AuthChangeNotifierProvider._();

/// Provider for the auth change notifier

final class AuthChangeNotifierProvider
    extends
        $FunctionalProvider<
          AuthChangeNotifier,
          AuthChangeNotifier,
          AuthChangeNotifier
        >
    with $Provider<AuthChangeNotifier> {
  /// Provider for the auth change notifier
  AuthChangeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authChangeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authChangeNotifierHash();

  @$internal
  @override
  $ProviderElement<AuthChangeNotifier> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthChangeNotifier create(Ref ref) {
    return authChangeNotifier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthChangeNotifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthChangeNotifier>(value),
    );
  }
}

String _$authChangeNotifierHash() =>
    r'f12de69a77a4a5895af2ea6c1785be9f2931fd0a';

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

String _$routerHash() => r'82bd258752921632fc9c66cd18111b991d599b8b';
