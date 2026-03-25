// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for storage info (async)

@ProviderFor(storageInfo)
final storageInfoProvider = StorageInfoProvider._();

/// Provider for storage info (async)

final class StorageInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<StorageInfo>,
          StorageInfo,
          FutureOr<StorageInfo>
        >
    with $FutureModifier<StorageInfo>, $FutureProvider<StorageInfo> {
  /// Provider for storage info (async)
  StorageInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageInfoHash();

  @$internal
  @override
  $FutureProviderElement<StorageInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StorageInfo> create(Ref ref) {
    return storageInfo(ref);
  }
}

String _$storageInfoHash() => r'7a6baa1e5180b5a177aa2a84558f788a7107bd21';

/// Provider for auto-delete settings

@ProviderFor(AutoDeleteSettingsNotifier)
final autoDeleteSettingsProvider = AutoDeleteSettingsNotifierProvider._();

/// Provider for auto-delete settings
final class AutoDeleteSettingsNotifierProvider
    extends $NotifierProvider<AutoDeleteSettingsNotifier, AutoDeleteSettings> {
  /// Provider for auto-delete settings
  AutoDeleteSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoDeleteSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoDeleteSettingsNotifierHash();

  @$internal
  @override
  AutoDeleteSettingsNotifier create() => AutoDeleteSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutoDeleteSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutoDeleteSettings>(value),
    );
  }
}

String _$autoDeleteSettingsNotifierHash() =>
    r'032ffa7c9784fa1ed9307bea880ac269d7c0e8ed';

/// Provider for auto-delete settings

abstract class _$AutoDeleteSettingsNotifier
    extends $Notifier<AutoDeleteSettings> {
  AutoDeleteSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AutoDeleteSettings, AutoDeleteSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AutoDeleteSettings, AutoDeleteSettings>,
              AutoDeleteSettings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
