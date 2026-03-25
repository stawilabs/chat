// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mute_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for MuteService

@ProviderFor(muteService)
final muteServiceProvider = MuteServiceProvider._();

/// Provider for MuteService

final class MuteServiceProvider
    extends $FunctionalProvider<MuteService, MuteService, MuteService>
    with $Provider<MuteService> {
  /// Provider for MuteService
  MuteServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'muteServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$muteServiceHash();

  @$internal
  @override
  $ProviderElement<MuteService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MuteService create(Ref ref) {
    return muteService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MuteService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MuteService>(value),
    );
  }
}

String _$muteServiceHash() => r'b7756f970df2e533d1d6d389b25822563c0abe16';

/// Provider to check if a specific room is muted

@ProviderFor(isRoomMuted)
final isRoomMutedProvider = IsRoomMutedFamily._();

/// Provider to check if a specific room is muted

final class IsRoomMutedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Provider to check if a specific room is muted
  IsRoomMutedProvider._({
    required IsRoomMutedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isRoomMutedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isRoomMutedHash();

  @override
  String toString() {
    return r'isRoomMutedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return isRoomMuted(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsRoomMutedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isRoomMutedHash() => r'd0ca0304cd6373042c8e69784dda3f4f2c8c7c43';

/// Provider to check if a specific room is muted

final class IsRoomMutedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  IsRoomMutedFamily._()
    : super(
        retry: null,
        name: r'isRoomMutedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to check if a specific room is muted

  IsRoomMutedProvider call(String roomId) =>
      IsRoomMutedProvider._(argument: roomId, from: this);

  @override
  String toString() => r'isRoomMutedProvider';
}

/// Provider to get mute time remaining for a room

@ProviderFor(muteTimeRemaining)
final muteTimeRemainingProvider = MuteTimeRemainingFamily._();

/// Provider to get mute time remaining for a room

final class MuteTimeRemainingProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Provider to get mute time remaining for a room
  MuteTimeRemainingProvider._({
    required MuteTimeRemainingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'muteTimeRemainingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$muteTimeRemainingHash();

  @override
  String toString() {
    return r'muteTimeRemainingProvider'
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
    return muteTimeRemaining(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MuteTimeRemainingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$muteTimeRemainingHash() => r'39a99593ff42cc10524325efb8530885d1ca792b';

/// Provider to get mute time remaining for a room

final class MuteTimeRemainingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  MuteTimeRemainingFamily._()
    : super(
        retry: null,
        name: r'muteTimeRemainingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to get mute time remaining for a room

  MuteTimeRemainingProvider call(String roomId) =>
      MuteTimeRemainingProvider._(argument: roomId, from: this);

  @override
  String toString() => r'muteTimeRemainingProvider';
}

/// Notifier for managing room mute state
///
/// Use this when you need to reactively update UI based on mute state changes.

@ProviderFor(RoomMuteState)
final roomMuteStateProvider = RoomMuteStateFamily._();

/// Notifier for managing room mute state
///
/// Use this when you need to reactively update UI based on mute state changes.
final class RoomMuteStateProvider
    extends $AsyncNotifierProvider<RoomMuteState, bool> {
  /// Notifier for managing room mute state
  ///
  /// Use this when you need to reactively update UI based on mute state changes.
  RoomMuteStateProvider._({
    required RoomMuteStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'roomMuteStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roomMuteStateHash();

  @override
  String toString() {
    return r'roomMuteStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RoomMuteState create() => RoomMuteState();

  @override
  bool operator ==(Object other) {
    return other is RoomMuteStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomMuteStateHash() => r'4b8dc29dcef688765f68eb5836b00eb7352fffa3';

/// Notifier for managing room mute state
///
/// Use this when you need to reactively update UI based on mute state changes.

final class RoomMuteStateFamily extends $Family
    with
        $ClassFamilyOverride<
          RoomMuteState,
          AsyncValue<bool>,
          bool,
          FutureOr<bool>,
          String
        > {
  RoomMuteStateFamily._()
    : super(
        retry: null,
        name: r'roomMuteStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier for managing room mute state
  ///
  /// Use this when you need to reactively update UI based on mute state changes.

  RoomMuteStateProvider call(String roomId) =>
      RoomMuteStateProvider._(argument: roomId, from: this);

  @override
  String toString() => r'roomMuteStateProvider';
}

/// Notifier for managing room mute state
///
/// Use this when you need to reactively update UI based on mute state changes.

abstract class _$RoomMuteState extends $AsyncNotifier<bool> {
  late final _$args = ref.$arg as String;
  String get roomId => _$args;

  FutureOr<bool> build(String roomId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
