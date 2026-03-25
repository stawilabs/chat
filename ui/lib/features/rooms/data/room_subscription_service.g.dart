// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_subscription_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for RoomSubscriptionService

@ProviderFor(roomSubscriptionService)
final roomSubscriptionServiceProvider = RoomSubscriptionServiceProvider._();

/// Provider for RoomSubscriptionService

final class RoomSubscriptionServiceProvider
    extends
        $FunctionalProvider<
          RoomSubscriptionService,
          RoomSubscriptionService,
          RoomSubscriptionService
        >
    with $Provider<RoomSubscriptionService> {
  /// Provider for RoomSubscriptionService
  RoomSubscriptionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomSubscriptionServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomSubscriptionServiceHash();

  @$internal
  @override
  $ProviderElement<RoomSubscriptionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RoomSubscriptionService create(Ref ref) {
    return roomSubscriptionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoomSubscriptionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoomSubscriptionService>(value),
    );
  }
}

String _$roomSubscriptionServiceHash() =>
    r'8252050ab218bf8a54d524ca7e7f884996578a4b';

/// Provider for current user's subscription ID for a specific room
/// Returns the subscription ID or null if not found

@ProviderFor(currentUserSubscriptionId)
final currentUserSubscriptionIdProvider = CurrentUserSubscriptionIdFamily._();

/// Provider for current user's subscription ID for a specific room
/// Returns the subscription ID or null if not found

final class CurrentUserSubscriptionIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Provider for current user's subscription ID for a specific room
  /// Returns the subscription ID or null if not found
  CurrentUserSubscriptionIdProvider._({
    required CurrentUserSubscriptionIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'currentUserSubscriptionIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currentUserSubscriptionIdHash();

  @override
  String toString() {
    return r'currentUserSubscriptionIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return currentUserSubscriptionId(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentUserSubscriptionIdProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentUserSubscriptionIdHash() =>
    r'2ab2ed937c60cce23e7f549ee6565e172940880d';

/// Provider for current user's subscription ID for a specific room
/// Returns the subscription ID or null if not found

final class CurrentUserSubscriptionIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  CurrentUserSubscriptionIdFamily._()
    : super(
        retry: null,
        name: r'currentUserSubscriptionIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for current user's subscription ID for a specific room
  /// Returns the subscription ID or null if not found

  CurrentUserSubscriptionIdProvider call(String roomId) =>
      CurrentUserSubscriptionIdProvider._(argument: roomId, from: this);

  @override
  String toString() => r'currentUserSubscriptionIdProvider';
}

/// Provider to look up profile ID from a subscription ID
/// Returns the profile ID or null if subscription not found

@ProviderFor(profileIdFromSubscription)
final profileIdFromSubscriptionProvider = ProfileIdFromSubscriptionFamily._();

/// Provider to look up profile ID from a subscription ID
/// Returns the profile ID or null if subscription not found

final class ProfileIdFromSubscriptionProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Provider to look up profile ID from a subscription ID
  /// Returns the profile ID or null if subscription not found
  ProfileIdFromSubscriptionProvider._({
    required ProfileIdFromSubscriptionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'profileIdFromSubscriptionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$profileIdFromSubscriptionHash();

  @override
  String toString() {
    return r'profileIdFromSubscriptionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return profileIdFromSubscription(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileIdFromSubscriptionProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$profileIdFromSubscriptionHash() =>
    r'108ef9b51b29245ae12db1892a0811a3c3461f07';

/// Provider to look up profile ID from a subscription ID
/// Returns the profile ID or null if subscription not found

final class ProfileIdFromSubscriptionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  ProfileIdFromSubscriptionFamily._()
    : super(
        retry: null,
        name: r'profileIdFromSubscriptionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to look up profile ID from a subscription ID
  /// Returns the profile ID or null if subscription not found

  ProfileIdFromSubscriptionProvider call(String subscriptionId) =>
      ProfileIdFromSubscriptionProvider._(argument: subscriptionId, from: this);

  @override
  String toString() => r'profileIdFromSubscriptionProvider';
}
