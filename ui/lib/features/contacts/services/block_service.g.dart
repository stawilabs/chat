// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(blockService)
final blockServiceProvider = BlockServiceProvider._();

final class BlockServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<BlockService>,
          BlockService,
          FutureOr<BlockService>
        >
    with $FutureModifier<BlockService>, $FutureProvider<BlockService> {
  BlockServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blockServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blockServiceHash();

  @$internal
  @override
  $FutureProviderElement<BlockService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BlockService> create(Ref ref) {
    return blockService(ref);
  }
}

String _$blockServiceHash() => r'2d2553f1771240775b600f82d3c19a3a2d04495a';

/// Provider for blocked users list

@ProviderFor(blockedUsers)
final blockedUsersProvider = BlockedUsersProvider._();

/// Provider for blocked users list

final class BlockedUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RosterEntry>>,
          List<RosterEntry>,
          FutureOr<List<RosterEntry>>
        >
    with
        $FutureModifier<List<RosterEntry>>,
        $FutureProvider<List<RosterEntry>> {
  /// Provider for blocked users list
  BlockedUsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blockedUsersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blockedUsersHash();

  @$internal
  @override
  $FutureProviderElement<List<RosterEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RosterEntry>> create(Ref ref) {
    return blockedUsers(ref);
  }
}

String _$blockedUsersHash() => r'f240655ea027982277fe2d37ee136458b5202aad';

/// Provider for blocked profile IDs set

@ProviderFor(blockedProfileIds)
final blockedProfileIdsProvider = BlockedProfileIdsProvider._();

/// Provider for blocked profile IDs set

final class BlockedProfileIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          FutureOr<Set<String>>
        >
    with $FutureModifier<Set<String>>, $FutureProvider<Set<String>> {
  /// Provider for blocked profile IDs set
  BlockedProfileIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blockedProfileIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blockedProfileIdsHash();

  @$internal
  @override
  $FutureProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<String>> create(Ref ref) {
    return blockedProfileIds(ref);
  }
}

String _$blockedProfileIdsHash() => r'992e98ca9e7470820b094aca209aebc6f3f68a9a';

/// Provider to check if a specific user is blocked

@ProviderFor(isUserBlockedProvider)
final isUserBlockedProviderProvider = IsUserBlockedProviderFamily._();

/// Provider to check if a specific user is blocked

final class IsUserBlockedProviderProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Provider to check if a specific user is blocked
  IsUserBlockedProviderProvider._({
    required IsUserBlockedProviderFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isUserBlockedProviderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isUserBlockedProviderHash();

  @override
  String toString() {
    return r'isUserBlockedProviderProvider'
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
    return isUserBlockedProvider(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsUserBlockedProviderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isUserBlockedProviderHash() =>
    r'02b0b1d3fb68030bf44e1f8bf9418f205762eaee';

/// Provider to check if a specific user is blocked

final class IsUserBlockedProviderFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  IsUserBlockedProviderFamily._()
    : super(
        retry: null,
        name: r'isUserBlockedProviderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to check if a specific user is blocked

  IsUserBlockedProviderProvider call(String profileId) =>
      IsUserBlockedProviderProvider._(argument: profileId, from: this);

  @override
  String toString() => r'isUserBlockedProviderProvider';
}
