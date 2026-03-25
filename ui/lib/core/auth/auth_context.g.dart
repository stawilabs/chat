// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_context.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for AuthContextService

@ProviderFor(authContextService)
final authContextServiceProvider = AuthContextServiceProvider._();

/// Provider for AuthContextService

final class AuthContextServiceProvider
    extends
        $FunctionalProvider<
          AuthContextService,
          AuthContextService,
          AuthContextService
        >
    with $Provider<AuthContextService> {
  /// Provider for AuthContextService
  AuthContextServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authContextServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authContextServiceHash();

  @$internal
  @override
  $ProviderElement<AuthContextService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthContextService create(Ref ref) {
    return authContextService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthContextService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthContextService>(value),
    );
  }
}

String _$authContextServiceHash() =>
    r'bb4e7ba87ec14babc93f56dd8b0d3934acec5f4d';

/// Provider for current auth context
/// Returns null if user is not authenticated

@ProviderFor(currentAuthContext)
final currentAuthContextProvider = CurrentAuthContextProvider._();

/// Provider for current auth context
/// Returns null if user is not authenticated

final class CurrentAuthContextProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthContext?>,
          AuthContext?,
          FutureOr<AuthContext?>
        >
    with $FutureModifier<AuthContext?>, $FutureProvider<AuthContext?> {
  /// Provider for current auth context
  /// Returns null if user is not authenticated
  CurrentAuthContextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentAuthContextProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentAuthContextHash();

  @$internal
  @override
  $FutureProviderElement<AuthContext?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AuthContext?> create(Ref ref) {
    return currentAuthContext(ref);
  }
}

String _$currentAuthContextHash() =>
    r'85f27c7df70a57127363e0fa981f882add4a9a56';
