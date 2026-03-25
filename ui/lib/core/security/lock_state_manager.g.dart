// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lock_state_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for LockStateManager

@ProviderFor(lockStateManager)
final lockStateManagerProvider = LockStateManagerProvider._();

/// Provider for LockStateManager

final class LockStateManagerProvider
    extends
        $FunctionalProvider<
          LockStateManager,
          LockStateManager,
          LockStateManager
        >
    with $Provider<LockStateManager> {
  /// Provider for LockStateManager
  LockStateManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lockStateManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lockStateManagerHash();

  @$internal
  @override
  $ProviderElement<LockStateManager> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LockStateManager create(Ref ref) {
    return lockStateManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LockStateManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LockStateManager>(value),
    );
  }
}

String _$lockStateManagerHash() => r'44146eb9939b2887447802f6e75157d8872a9a7c';

/// Provider that exposes whether the app is currently locked

@ProviderFor(isAppLocked)
final isAppLockedProvider = IsAppLockedProvider._();

/// Provider that exposes whether the app is currently locked

final class IsAppLockedProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider that exposes whether the app is currently locked
  IsAppLockedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isAppLockedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isAppLockedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isAppLocked(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isAppLockedHash() => r'3c63b59ac387a0f8099ef2a84c53fa143c7695cd';

/// Provider that exposes whether the lock screen should be shown

@ProviderFor(shouldShowLockScreen)
final shouldShowLockScreenProvider = ShouldShowLockScreenProvider._();

/// Provider that exposes whether the lock screen should be shown

final class ShouldShowLockScreenProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider that exposes whether the lock screen should be shown
  ShouldShowLockScreenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shouldShowLockScreenProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shouldShowLockScreenHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return shouldShowLockScreen(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$shouldShowLockScreenHash() =>
    r'cdc5ffa1ce57a6898c386e909f18ad59f7d3e8f0';
