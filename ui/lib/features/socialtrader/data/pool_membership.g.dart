// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pool_membership.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The wallet whose pool stake the app shows: the connected (or pasted)
/// wallet when there is one, else the wallet linked to the profile. Null when
/// neither is known.

@ProviderFor(memberWallet)
final memberWalletProvider = MemberWalletProvider._();

/// The wallet whose pool stake the app shows: the connected (or pasted)
/// wallet when there is one, else the wallet linked to the profile. Null when
/// neither is known.

final class MemberWalletProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// The wallet whose pool stake the app shows: the connected (or pasted)
  /// wallet when there is one, else the wallet linked to the profile. Null when
  /// neither is known.
  MemberWalletProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memberWalletProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memberWalletHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return memberWallet(ref);
  }
}

String _$memberWalletHash() => r'2ccee1fa5cb485b3f3e415b2a49722f499d8c380';

/// The signed-in person's stake in [pool]: none when no wallet is known.

@ProviderFor(myMembership)
final myMembershipProvider = MyMembershipFamily._();

/// The signed-in person's stake in [pool]: none when no wallet is known.

final class MyMembershipProvider
    extends
        $FunctionalProvider<
          AsyncValue<PoolMembership>,
          PoolMembership,
          FutureOr<PoolMembership>
        >
    with $FutureModifier<PoolMembership>, $FutureProvider<PoolMembership> {
  /// The signed-in person's stake in [pool]: none when no wallet is known.
  MyMembershipProvider._({
    required MyMembershipFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myMembershipProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myMembershipHash();

  @override
  String toString() {
    return r'myMembershipProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PoolMembership> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PoolMembership> create(Ref ref) {
    final argument = this.argument as String;
    return myMembership(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyMembershipProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myMembershipHash() => r'15ee85a54aad8a0915cf472d2b9819fadaad3df4';

/// The signed-in person's stake in [pool]: none when no wallet is known.

final class MyMembershipFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PoolMembership>, String> {
  MyMembershipFamily._()
    : super(
        retry: null,
        name: r'myMembershipProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The signed-in person's stake in [pool]: none when no wallet is known.

  MyMembershipProvider call(String pool) =>
      MyMembershipProvider._(argument: pool, from: this);

  @override
  String toString() => r'myMembershipProvider';
}
