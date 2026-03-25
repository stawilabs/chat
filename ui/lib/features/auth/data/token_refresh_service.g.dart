// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_refresh_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the token refresh service

@ProviderFor(tokenRefreshService)
final tokenRefreshServiceProvider = TokenRefreshServiceProvider._();

/// Provider for the token refresh service

final class TokenRefreshServiceProvider
    extends
        $FunctionalProvider<
          TokenRefreshService,
          TokenRefreshService,
          TokenRefreshService
        >
    with $Provider<TokenRefreshService> {
  /// Provider for the token refresh service
  TokenRefreshServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tokenRefreshServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tokenRefreshServiceHash();

  @$internal
  @override
  $ProviderElement<TokenRefreshService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TokenRefreshService create(Ref ref) {
    return tokenRefreshService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TokenRefreshService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TokenRefreshService>(value),
    );
  }
}

String _$tokenRefreshServiceHash() =>
    r'f5993e54d22ddd2fa82212ecfc81239a0ea82617';
