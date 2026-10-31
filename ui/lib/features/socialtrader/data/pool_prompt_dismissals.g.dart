// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pool_prompt_dismissals.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(poolPromptDismissals)
final poolPromptDismissalsProvider = PoolPromptDismissalsProvider._();

final class PoolPromptDismissalsProvider
    extends
        $FunctionalProvider<
          PoolPromptDismissals,
          PoolPromptDismissals,
          PoolPromptDismissals
        >
    with $Provider<PoolPromptDismissals> {
  PoolPromptDismissalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'poolPromptDismissalsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$poolPromptDismissalsHash();

  @$internal
  @override
  $ProviderElement<PoolPromptDismissals> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PoolPromptDismissals create(Ref ref) {
    return poolPromptDismissals(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PoolPromptDismissals value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PoolPromptDismissals>(value),
    );
  }
}

String _$poolPromptDismissalsHash() =>
    r'eff163136a4e842e3788dc2904ea830e9667a80b';
