// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountService)
final accountServiceProvider = AccountServiceProvider._();

final class AccountServiceProvider
    extends $FunctionalProvider<AccountService, AccountService, AccountService>
    with $Provider<AccountService> {
  AccountServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountServiceHash();

  @$internal
  @override
  $ProviderElement<AccountService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AccountService create(Ref ref) {
    return accountService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountService>(value),
    );
  }
}

String _$accountServiceHash() => r'e06f8fbafc269a53e7ed3635f10126055194fead';

/// Provider to get linked devices

@ProviderFor(linkedDevices)
final linkedDevicesProvider = LinkedDevicesProvider._();

/// Provider to get linked devices

final class LinkedDevicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LinkedDevice>>,
          List<LinkedDevice>,
          FutureOr<List<LinkedDevice>>
        >
    with
        $FutureModifier<List<LinkedDevice>>,
        $FutureProvider<List<LinkedDevice>> {
  /// Provider to get linked devices
  LinkedDevicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkedDevicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkedDevicesHash();

  @$internal
  @override
  $FutureProviderElement<List<LinkedDevice>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LinkedDevice>> create(Ref ref) {
    return linkedDevices(ref);
  }
}

String _$linkedDevicesHash() => r'87a1cd6461b0f49228f440a1b765f83cab992f2b';

/// Provider to get 2FA status

@ProviderFor(twoFactorStatus)
final twoFactorStatusProvider = TwoFactorStatusProvider._();

/// Provider to get 2FA status

final class TwoFactorStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<TwoFactorStatus>,
          TwoFactorStatus,
          FutureOr<TwoFactorStatus>
        >
    with $FutureModifier<TwoFactorStatus>, $FutureProvider<TwoFactorStatus> {
  /// Provider to get 2FA status
  TwoFactorStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'twoFactorStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$twoFactorStatusHash();

  @$internal
  @override
  $FutureProviderElement<TwoFactorStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TwoFactorStatus> create(Ref ref) {
    return twoFactorStatus(ref);
  }
}

String _$twoFactorStatusHash() => r'a60193f38c2b2a310923c19e244811c3e2604303';
