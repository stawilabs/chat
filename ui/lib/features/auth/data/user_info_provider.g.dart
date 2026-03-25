// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userInfo)
final userInfoProvider = UserInfoProvider._();

final class UserInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserInfo?>,
          UserInfo?,
          FutureOr<UserInfo?>
        >
    with $FutureModifier<UserInfo?>, $FutureProvider<UserInfo?> {
  UserInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userInfoHash();

  @$internal
  @override
  $FutureProviderElement<UserInfo?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<UserInfo?> create(Ref ref) {
    return userInfo(ref);
  }
}

String _$userInfoHash() => r'aea9f5b99d383fa98f013c6ad7b4e015d14eb8a4';
