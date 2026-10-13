// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detail_panel_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for room members
/// Returns list of members in a room with their profile info

@ProviderFor(roomMembers)
final roomMembersProvider = RoomMembersFamily._();

/// Provider for room members
/// Returns list of members in a room with their profile info

final class RoomMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RoomSubscriptionInfo>>,
          List<RoomSubscriptionInfo>,
          FutureOr<List<RoomSubscriptionInfo>>
        >
    with
        $FutureModifier<List<RoomSubscriptionInfo>>,
        $FutureProvider<List<RoomSubscriptionInfo>> {
  /// Provider for room members
  /// Returns list of members in a room with their profile info
  RoomMembersProvider._({
    required RoomMembersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'roomMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roomMembersHash();

  @override
  String toString() {
    return r'roomMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<RoomSubscriptionInfo>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RoomSubscriptionInfo>> create(Ref ref) {
    final argument = this.argument as String;
    return roomMembers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RoomMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomMembersHash() => r'0e2d96752a19857a6de4765486cde0d99e14386e';

/// Provider for room members
/// Returns list of members in a room with their profile info

final class RoomMembersFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<RoomSubscriptionInfo>>,
          String
        > {
  RoomMembersFamily._()
    : super(
        retry: null,
        name: r'roomMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for room members
  /// Returns list of members in a room with their profile info

  RoomMembersProvider call(String roomId) =>
      RoomMembersProvider._(argument: roomId, from: this);

  @override
  String toString() => r'roomMembersProvider';
}

/// Provider for shared media in a room (images and videos)

@ProviderFor(roomMedia)
final roomMediaProvider = RoomMediaFamily._();

/// Provider for shared media in a room (images and videos)

final class RoomMediaProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<domain.RoomEvent>>,
          List<domain.RoomEvent>,
          Stream<List<domain.RoomEvent>>
        >
    with
        $FutureModifier<List<domain.RoomEvent>>,
        $StreamProvider<List<domain.RoomEvent>> {
  /// Provider for shared media in a room (images and videos)
  RoomMediaProvider._({
    required RoomMediaFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'roomMediaProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roomMediaHash();

  @override
  String toString() {
    return r'roomMediaProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<domain.RoomEvent>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<domain.RoomEvent>> create(Ref ref) {
    final argument = this.argument as String;
    return roomMedia(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RoomMediaProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomMediaHash() => r'dd4d9d1b63b0102617e9e4f1bc0a40f8cdf27d9b';

/// Provider for shared media in a room (images and videos)

final class RoomMediaFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<domain.RoomEvent>>, String> {
  RoomMediaFamily._()
    : super(
        retry: null,
        name: r'roomMediaProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for shared media in a room (images and videos)

  RoomMediaProvider call(String roomId) =>
      RoomMediaProvider._(argument: roomId, from: this);

  @override
  String toString() => r'roomMediaProvider';
}

/// Provider to check if a room is a group chat (more than 2 members)
///
/// Returns true for group chats, false for direct messages.

@ProviderFor(isGroupChat)
final isGroupChatProvider = IsGroupChatFamily._();

/// Provider to check if a room is a group chat (more than 2 members)
///
/// Returns true for group chats, false for direct messages.

final class IsGroupChatProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Provider to check if a room is a group chat (more than 2 members)
  ///
  /// Returns true for group chats, false for direct messages.
  IsGroupChatProvider._({
    required IsGroupChatFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isGroupChatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isGroupChatHash();

  @override
  String toString() {
    return r'isGroupChatProvider'
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
    return isGroupChat(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsGroupChatProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isGroupChatHash() => r'236472a65a2b28635776526a3d32f3f48bf49d6b';

/// Provider to check if a room is a group chat (more than 2 members)
///
/// Returns true for group chats, false for direct messages.

final class IsGroupChatFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  IsGroupChatFamily._()
    : super(
        retry: null,
        name: r'isGroupChatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to check if a room is a group chat (more than 2 members)
  ///
  /// Returns true for group chats, false for direct messages.

  IsGroupChatProvider call(String roomId) =>
      IsGroupChatProvider._(argument: roomId, from: this);

  @override
  String toString() => r'isGroupChatProvider';
}
