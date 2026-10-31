// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commitment_settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(commitmentSettings)
final commitmentSettingsProvider = CommitmentSettingsProvider._();

final class CommitmentSettingsProvider
    extends
        $FunctionalProvider<
          CommitmentSettings,
          CommitmentSettings,
          CommitmentSettings
        >
    with $Provider<CommitmentSettings> {
  CommitmentSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commitmentSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commitmentSettingsHash();

  @$internal
  @override
  $ProviderElement<CommitmentSettings> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CommitmentSettings create(Ref ref) {
    return commitmentSettings(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommitmentSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommitmentSettings>(value),
    );
  }
}

String _$commitmentSettingsHash() =>
    r'd32899e6d49f6de0a119dada1cbb1b3974155616';
