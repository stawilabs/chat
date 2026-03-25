// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider that syncs room members when entering a room
///
/// This ensures that the current user's subscription is available in the local
/// database before attempting to send messages or perform other operations.
/// Uses caching to avoid redundant syncs.
///
/// Also notifies RoomSyncManager when sync completes, which may transition
/// the room to READY state if subscription is found.

@ProviderFor(syncRoomMembersOnEntry)
final syncRoomMembersOnEntryProvider = SyncRoomMembersOnEntryFamily._();

/// Provider that syncs room members when entering a room
///
/// This ensures that the current user's subscription is available in the local
/// database before attempting to send messages or perform other operations.
/// Uses caching to avoid redundant syncs.
///
/// Also notifies RoomSyncManager when sync completes, which may transition
/// the room to READY state if subscription is found.

final class SyncRoomMembersOnEntryProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Provider that syncs room members when entering a room
  ///
  /// This ensures that the current user's subscription is available in the local
  /// database before attempting to send messages or perform other operations.
  /// Uses caching to avoid redundant syncs.
  ///
  /// Also notifies RoomSyncManager when sync completes, which may transition
  /// the room to READY state if subscription is found.
  SyncRoomMembersOnEntryProvider._({
    required SyncRoomMembersOnEntryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'syncRoomMembersOnEntryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$syncRoomMembersOnEntryHash();

  @override
  String toString() {
    return r'syncRoomMembersOnEntryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return syncRoomMembersOnEntry(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SyncRoomMembersOnEntryProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$syncRoomMembersOnEntryHash() =>
    r'ebf0e09f5f18248d69568fa15e71d0a472d6b7dc';

/// Provider that syncs room members when entering a room
///
/// This ensures that the current user's subscription is available in the local
/// database before attempting to send messages or perform other operations.
/// Uses caching to avoid redundant syncs.
///
/// Also notifies RoomSyncManager when sync completes, which may transition
/// the room to READY state if subscription is found.

final class SyncRoomMembersOnEntryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  SyncRoomMembersOnEntryFamily._()
    : super(
        retry: null,
        name: r'syncRoomMembersOnEntryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider that syncs room members when entering a room
  ///
  /// This ensures that the current user's subscription is available in the local
  /// database before attempting to send messages or perform other operations.
  /// Uses caching to avoid redundant syncs.
  ///
  /// Also notifies RoomSyncManager when sync completes, which may transition
  /// the room to READY state if subscription is found.

  SyncRoomMembersOnEntryProvider call(String roomId) =>
      SyncRoomMembersOnEntryProvider._(argument: roomId, from: this);

  @override
  String toString() => r'syncRoomMembersOnEntryProvider';
}

/// Provider for getting a room by ID

@ProviderFor(roomById)
final roomByIdProvider = RoomByIdFamily._();

/// Provider for getting a room by ID

final class RoomByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<domain.Room?>,
          domain.Room?,
          FutureOr<domain.Room?>
        >
    with $FutureModifier<domain.Room?>, $FutureProvider<domain.Room?> {
  /// Provider for getting a room by ID
  RoomByIdProvider._({
    required RoomByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'roomByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roomByIdHash();

  @override
  String toString() {
    return r'roomByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<domain.Room?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<domain.Room?> create(Ref ref) {
    final argument = this.argument as String;
    return roomById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RoomByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomByIdHash() => r'6c931dc086f3bd7443ba1455f94628b4cae07046';

/// Provider for getting a room by ID

final class RoomByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<domain.Room?>, String> {
  RoomByIdFamily._()
    : super(
        retry: null,
        name: r'roomByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting a room by ID

  RoomByIdProvider call(String roomId) =>
      RoomByIdProvider._(argument: roomId, from: this);

  @override
  String toString() => r'roomByIdProvider';
}

@ProviderFor(RoomList)
final roomListProvider = RoomListProvider._();

final class RoomListProvider
    extends $AsyncNotifierProvider<RoomList, List<domain.Room>> {
  RoomListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomListHash();

  @$internal
  @override
  RoomList create() => RoomList();
}

String _$roomListHash() => r'53d5f60fe6daf5658285f4724d77e975507567ab';

abstract class _$RoomList extends $AsyncNotifier<List<domain.Room>> {
  FutureOr<List<domain.Room>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<domain.Room>>, List<domain.Room>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<domain.Room>>, List<domain.Room>>,
              AsyncValue<List<domain.Room>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(RoomListWithMessages)
final roomListWithMessagesProvider = RoomListWithMessagesProvider._();

final class RoomListWithMessagesProvider
    extends
        $AsyncNotifierProvider<
          RoomListWithMessages,
          List<RoomWithLastMessage>
        > {
  RoomListWithMessagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomListWithMessagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomListWithMessagesHash();

  @$internal
  @override
  RoomListWithMessages create() => RoomListWithMessages();
}

String _$roomListWithMessagesHash() =>
    r'ae057dc892e3a0d435d085718fed848be9bdd3bc';

abstract class _$RoomListWithMessages
    extends $AsyncNotifier<List<RoomWithLastMessage>> {
  FutureOr<List<RoomWithLastMessage>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<RoomWithLastMessage>>,
              List<RoomWithLastMessage>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<RoomWithLastMessage>>,
                List<RoomWithLastMessage>
              >,
              AsyncValue<List<RoomWithLastMessage>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
