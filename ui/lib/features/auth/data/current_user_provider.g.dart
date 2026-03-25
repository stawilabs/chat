// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the current user's PROFILE ID (from JWT 'sub' claim)
/// This represents the entity (person/organization) identity
/// NOT to be confused with contact ID or subscription ID
/// Returns null if the user is not authenticated or no profile info is available

@ProviderFor(currentProfileId)
final currentProfileIdProvider = CurrentProfileIdProvider._();

/// Provider for the current user's PROFILE ID (from JWT 'sub' claim)
/// This represents the entity (person/organization) identity
/// NOT to be confused with contact ID or subscription ID
/// Returns null if the user is not authenticated or no profile info is available

final class CurrentProfileIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Provider for the current user's PROFILE ID (from JWT 'sub' claim)
  /// This represents the entity (person/organization) identity
  /// NOT to be confused with contact ID or subscription ID
  /// Returns null if the user is not authenticated or no profile info is available
  CurrentProfileIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentProfileIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentProfileIdHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return currentProfileId(ref);
  }
}

String _$currentProfileIdHash() => r'd0baf85ca2059f938b8b3a4e8147f41ab9513f8c';

/// Non-null version that throws if profile ID is not available
/// Use this in contexts where authentication is required

@ProviderFor(currentProfileIdOrThrow)
final currentProfileIdOrThrowProvider = CurrentProfileIdOrThrowProvider._();

/// Non-null version that throws if profile ID is not available
/// Use this in contexts where authentication is required

final class CurrentProfileIdOrThrowProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Non-null version that throws if profile ID is not available
  /// Use this in contexts where authentication is required
  CurrentProfileIdOrThrowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentProfileIdOrThrowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentProfileIdOrThrowHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return currentProfileIdOrThrow(ref);
  }
}

String _$currentProfileIdOrThrowHash() =>
    r'0725a0d41e7cae441b04332a5f466173d9969f66';

/// Provider for the current user's CONTACT ID (from JWT 'contact_id' claim)
/// This represents the contact method (phone/email) used for authentication
/// A single profile can have multiple contact IDs
/// Returns null if the user is not authenticated or no contact ID is available

@ProviderFor(currentContactId)
final currentContactIdProvider = CurrentContactIdProvider._();

/// Provider for the current user's CONTACT ID (from JWT 'contact_id' claim)
/// This represents the contact method (phone/email) used for authentication
/// A single profile can have multiple contact IDs
/// Returns null if the user is not authenticated or no contact ID is available

final class CurrentContactIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Provider for the current user's CONTACT ID (from JWT 'contact_id' claim)
  /// This represents the contact method (phone/email) used for authentication
  /// A single profile can have multiple contact IDs
  /// Returns null if the user is not authenticated or no contact ID is available
  CurrentContactIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentContactIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentContactIdHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return currentContactId(ref);
  }
}

String _$currentContactIdHash() => r'aa35526936044625011f016456584cac4cfbd044';

/// Non-null version that throws if contact ID is not available
/// Use this in contexts where contact ID is required

@ProviderFor(currentContactIdOrThrow)
final currentContactIdOrThrowProvider = CurrentContactIdOrThrowProvider._();

/// Non-null version that throws if contact ID is not available
/// Use this in contexts where contact ID is required

final class CurrentContactIdOrThrowProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Non-null version that throws if contact ID is not available
  /// Use this in contexts where contact ID is required
  CurrentContactIdOrThrowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentContactIdOrThrowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentContactIdOrThrowHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return currentContactIdOrThrow(ref);
  }
}

String _$currentContactIdOrThrowHash() =>
    r'50b55795da3c79535983402587334a2cb92849ce';
