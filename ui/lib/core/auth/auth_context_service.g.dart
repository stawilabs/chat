// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_context_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [AuthContextService].

@ProviderFor(authContextService)
final authContextServiceProvider = AuthContextServiceProvider._();

/// Provider for [AuthContextService].

final class AuthContextServiceProvider
    extends
        $FunctionalProvider<
          AuthContextService,
          AuthContextService,
          AuthContextService
        >
    with $Provider<AuthContextService> {
  /// Provider for [AuthContextService].
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
    r'a837b180d7129f951471aefcf634d9655a1ac1f1';
