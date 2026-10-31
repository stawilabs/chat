// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trading_group_section.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The markets pools can trade.

@ProviderFor(markets)
final marketsProvider = MarketsProvider._();

/// The markets pools can trade.

final class MarketsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MarketInfo>>,
          List<MarketInfo>,
          FutureOr<List<MarketInfo>>
        >
    with $FutureModifier<List<MarketInfo>>, $FutureProvider<List<MarketInfo>> {
  /// The markets pools can trade.
  MarketsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'marketsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$marketsHash();

  @$internal
  @override
  $FutureProviderElement<List<MarketInfo>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MarketInfo>> create(Ref ref) {
    return markets(ref);
  }
}

String _$marketsHash() => r'34b3f51a9f53fd27b225098503a68c1c7e99e9bb';
