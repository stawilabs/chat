// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometric_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for LocalAuthentication instance

@ProviderFor(localAuthentication)
final localAuthenticationProvider = LocalAuthenticationProvider._();

/// Provider for LocalAuthentication instance

final class LocalAuthenticationProvider
    extends
        $FunctionalProvider<
          LocalAuthentication,
          LocalAuthentication,
          LocalAuthentication
        >
    with $Provider<LocalAuthentication> {
  /// Provider for LocalAuthentication instance
  LocalAuthenticationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localAuthenticationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localAuthenticationHash();

  @$internal
  @override
  $ProviderElement<LocalAuthentication> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalAuthentication create(Ref ref) {
    return localAuthentication(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalAuthentication value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalAuthentication>(value),
    );
  }
}

String _$localAuthenticationHash() =>
    r'2c2b36bdc9ccdb2995310d7634b8ef61ed4a6746';

/// Provider for BiometricService

@ProviderFor(biometricService)
final biometricServiceProvider = BiometricServiceProvider._();

/// Provider for BiometricService

final class BiometricServiceProvider
    extends
        $FunctionalProvider<
          BiometricService,
          BiometricService,
          BiometricService
        >
    with $Provider<BiometricService> {
  /// Provider for BiometricService
  BiometricServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricServiceHash();

  @$internal
  @override
  $ProviderElement<BiometricService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BiometricService create(Ref ref) {
    return biometricService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BiometricService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BiometricService>(value),
    );
  }
}

String _$biometricServiceHash() => r'b2ebf79b4d49548317b8b5ebab1bc2fa1620474f';

/// Provider that checks if biometric authentication is available

@ProviderFor(isBiometricAvailable)
final isBiometricAvailableProvider = IsBiometricAvailableProvider._();

/// Provider that checks if biometric authentication is available

final class IsBiometricAvailableProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Provider that checks if biometric authentication is available
  IsBiometricAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isBiometricAvailableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isBiometricAvailableHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return isBiometricAvailable(ref);
  }
}

String _$isBiometricAvailableHash() =>
    r'e0bdf52b4b3e98f87494b1b3adaf973f8a11d0d7';

/// Provider that gets available biometric types

@ProviderFor(availableBiometrics)
final availableBiometricsProvider = AvailableBiometricsProvider._();

/// Provider that gets available biometric types

final class AvailableBiometricsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppBiometricType>>,
          List<AppBiometricType>,
          FutureOr<List<AppBiometricType>>
        >
    with
        $FutureModifier<List<AppBiometricType>>,
        $FutureProvider<List<AppBiometricType>> {
  /// Provider that gets available biometric types
  AvailableBiometricsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableBiometricsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableBiometricsHash();

  @$internal
  @override
  $FutureProviderElement<List<AppBiometricType>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AppBiometricType>> create(Ref ref) {
    return availableBiometrics(ref);
  }
}

String _$availableBiometricsHash() =>
    r'91f8f6ebea0c394f217c2def636908fd9c1c8b19';

/// Provider that gets the biometric description

@ProviderFor(biometricDescription)
final biometricDescriptionProvider = BiometricDescriptionProvider._();

/// Provider that gets the biometric description

final class BiometricDescriptionProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Provider that gets the biometric description
  BiometricDescriptionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricDescriptionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricDescriptionHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return biometricDescription(ref);
  }
}

String _$biometricDescriptionHash() =>
    r'54469438a21068c992bc485446a5af6f4233733e';
