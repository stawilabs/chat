// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_link_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for watching invite links for a specific room

@ProviderFor(roomInviteLinks)
final roomInviteLinksProvider = RoomInviteLinksFamily._();

/// Provider for watching invite links for a specific room

final class RoomInviteLinksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InviteLink>>,
          List<InviteLink>,
          Stream<List<InviteLink>>
        >
    with $FutureModifier<List<InviteLink>>, $StreamProvider<List<InviteLink>> {
  /// Provider for watching invite links for a specific room
  RoomInviteLinksProvider._({
    required RoomInviteLinksFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'roomInviteLinksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roomInviteLinksHash();

  @override
  String toString() {
    return r'roomInviteLinksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<InviteLink>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<InviteLink>> create(Ref ref) {
    final argument = this.argument as String;
    return roomInviteLinks(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RoomInviteLinksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomInviteLinksHash() => r'94f53e180fba26ea82155f029e6983107a0a8f6a';

/// Provider for watching invite links for a specific room

final class RoomInviteLinksFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<InviteLink>>, String> {
  RoomInviteLinksFamily._()
    : super(
        retry: null,
        name: r'roomInviteLinksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for watching invite links for a specific room

  RoomInviteLinksProvider call(String roomId) =>
      RoomInviteLinksProvider._(argument: roomId, from: this);

  @override
  String toString() => r'roomInviteLinksProvider';
}

/// Provider for getting active invite links for a room

@ProviderFor(activeRoomInviteLinks)
final activeRoomInviteLinksProvider = ActiveRoomInviteLinksFamily._();

/// Provider for getting active invite links for a room

final class ActiveRoomInviteLinksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InviteLink>>,
          List<InviteLink>,
          FutureOr<List<InviteLink>>
        >
    with $FutureModifier<List<InviteLink>>, $FutureProvider<List<InviteLink>> {
  /// Provider for getting active invite links for a room
  ActiveRoomInviteLinksProvider._({
    required ActiveRoomInviteLinksFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeRoomInviteLinksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeRoomInviteLinksHash();

  @override
  String toString() {
    return r'activeRoomInviteLinksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<InviteLink>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InviteLink>> create(Ref ref) {
    final argument = this.argument as String;
    return activeRoomInviteLinks(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveRoomInviteLinksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeRoomInviteLinksHash() =>
    r'b6193429896c302c047490fe7e9405e454a8c3fd';

/// Provider for getting active invite links for a room

final class ActiveRoomInviteLinksFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<InviteLink>>, String> {
  ActiveRoomInviteLinksFamily._()
    : super(
        retry: null,
        name: r'activeRoomInviteLinksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting active invite links for a room

  ActiveRoomInviteLinksProvider call(String roomId) =>
      ActiveRoomInviteLinksProvider._(argument: roomId, from: this);

  @override
  String toString() => r'activeRoomInviteLinksProvider';
}

/// Provider for getting an invite link by code

@ProviderFor(inviteLinkByCode)
final inviteLinkByCodeProvider = InviteLinkByCodeFamily._();

/// Provider for getting an invite link by code

final class InviteLinkByCodeProvider
    extends
        $FunctionalProvider<
          AsyncValue<InviteLink?>,
          InviteLink?,
          FutureOr<InviteLink?>
        >
    with $FutureModifier<InviteLink?>, $FutureProvider<InviteLink?> {
  /// Provider for getting an invite link by code
  InviteLinkByCodeProvider._({
    required InviteLinkByCodeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'inviteLinkByCodeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inviteLinkByCodeHash();

  @override
  String toString() {
    return r'inviteLinkByCodeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<InviteLink?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InviteLink?> create(Ref ref) {
    final argument = this.argument as String;
    return inviteLinkByCode(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InviteLinkByCodeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inviteLinkByCodeHash() => r'3e4ab54ba9263037f0d3f984d3e09a0ce9ec00cf';

/// Provider for getting an invite link by code

final class InviteLinkByCodeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<InviteLink?>, String> {
  InviteLinkByCodeFamily._()
    : super(
        retry: null,
        name: r'inviteLinkByCodeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting an invite link by code

  InviteLinkByCodeProvider call(String code) =>
      InviteLinkByCodeProvider._(argument: code, from: this);

  @override
  String toString() => r'inviteLinkByCodeProvider';
}

/// Provider for getting users who joined via a specific link

@ProviderFor(inviteLinkJoins)
final inviteLinkJoinsProvider = InviteLinkJoinsFamily._();

/// Provider for getting users who joined via a specific link

final class InviteLinkJoinsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InviteLinkJoin>>,
          List<InviteLinkJoin>,
          FutureOr<List<InviteLinkJoin>>
        >
    with
        $FutureModifier<List<InviteLinkJoin>>,
        $FutureProvider<List<InviteLinkJoin>> {
  /// Provider for getting users who joined via a specific link
  InviteLinkJoinsProvider._({
    required InviteLinkJoinsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'inviteLinkJoinsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inviteLinkJoinsHash();

  @override
  String toString() {
    return r'inviteLinkJoinsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<InviteLinkJoin>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InviteLinkJoin>> create(Ref ref) {
    final argument = this.argument as String;
    return inviteLinkJoins(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InviteLinkJoinsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inviteLinkJoinsHash() => r'dc54a8432ee302c8e9bc46c4e6197bbe1c9737b6';

/// Provider for getting users who joined via a specific link

final class InviteLinkJoinsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<InviteLinkJoin>>, String> {
  InviteLinkJoinsFamily._()
    : super(
        retry: null,
        name: r'inviteLinkJoinsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting users who joined via a specific link

  InviteLinkJoinsProvider call(String linkId) =>
      InviteLinkJoinsProvider._(argument: linkId, from: this);

  @override
  String toString() => r'inviteLinkJoinsProvider';
}

/// Provider for pending approval requests for a room

@ProviderFor(pendingApprovals)
final pendingApprovalsProvider = PendingApprovalsFamily._();

/// Provider for pending approval requests for a room

final class PendingApprovalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InviteLinkJoin>>,
          List<InviteLinkJoin>,
          FutureOr<List<InviteLinkJoin>>
        >
    with
        $FutureModifier<List<InviteLinkJoin>>,
        $FutureProvider<List<InviteLinkJoin>> {
  /// Provider for pending approval requests for a room
  PendingApprovalsProvider._({
    required PendingApprovalsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pendingApprovalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingApprovalsHash();

  @override
  String toString() {
    return r'pendingApprovalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<InviteLinkJoin>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InviteLinkJoin>> create(Ref ref) {
    final argument = this.argument as String;
    return pendingApprovals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingApprovalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingApprovalsHash() => r'fa2b2a9bc9914d7c5729cc8ab8c0fa4f539eba64';

/// Provider for pending approval requests for a room

final class PendingApprovalsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<InviteLinkJoin>>, String> {
  PendingApprovalsFamily._()
    : super(
        retry: null,
        name: r'pendingApprovalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for pending approval requests for a room

  PendingApprovalsProvider call(String roomId) =>
      PendingApprovalsProvider._(argument: roomId, from: this);

  @override
  String toString() => r'pendingApprovalsProvider';
}

/// Notifier for managing invite link creation and actions

@ProviderFor(InviteLinkNotifier)
final inviteLinkProvider = InviteLinkNotifierProvider._();

/// Notifier for managing invite link creation and actions
final class InviteLinkNotifierProvider
    extends $AsyncNotifierProvider<InviteLinkNotifier, void> {
  /// Notifier for managing invite link creation and actions
  InviteLinkNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inviteLinkProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inviteLinkNotifierHash();

  @$internal
  @override
  InviteLinkNotifier create() => InviteLinkNotifier();
}

String _$inviteLinkNotifierHash() =>
    r'aea77d5e497c6af9eac2745ddd2696a6278096f9';

/// Notifier for managing invite link creation and actions

abstract class _$InviteLinkNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
