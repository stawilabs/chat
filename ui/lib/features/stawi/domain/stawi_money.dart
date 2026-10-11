import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' as sdk;

/// An asset as the app shows it: its id (`SYMBOL.chainId`, e.g. "USDC.146"),
/// the symbol people read and the number of minor-unit digits, from finance's
/// AssetInfo.
class StawiAsset {
  const StawiAsset._(this.id, this.symbol, this.decimals, this.known);

  /// The asset finance describes. A description without usable decimals is
  /// taken as unknown.
  factory StawiAsset.fromInfo(finance.AssetInfo info) =>
      info.decimals > _maxDecimals
      ? StawiAsset.unknown(info.assetId)
      : StawiAsset._(
          info.assetId,
          info.symbol.isEmpty ? info.assetId : info.symbol,
          info.decimals,
          true,
        );

  /// An asset nothing describes: its amounts show as whole minor units under
  /// its id.
  const StawiAsset.unknown(String id) : this._(id, id, 0, false);

  static const _maxDecimals = 77;

  final String id;
  final String symbol;
  final int decimals;

  /// Whether the decimals are known; otherwise amounts are raw minor units.
  final bool known;

  sdk.Asset get sdkAsset => sdk.Asset(id, decimals);
}

/// The assets amounts name, by asset id (Money.asset_id), as finance lists
/// them with a room (Room.assets) and its products and balances.
class StawiAssets {
  StawiAssets([Iterable<finance.AssetInfo> infos = const []])
    : _byId = {
        for (final info in infos)
          if (info.assetId.isNotEmpty) info.assetId: StawiAsset.fromInfo(info),
      };

  StawiAssets._(this._byId);

  static final StawiAssets empty = StawiAssets();

  final Map<String, StawiAsset> _byId;

  /// The asset [id] names; unknown (raw minor units under the id) when none
  /// of the lists describes it.
  StawiAsset of(String id) => _byId[id] ?? StawiAsset.unknown(id);

  /// These assets and [infos], [infos] taking precedence.
  StawiAssets withAll(Iterable<finance.AssetInfo> infos) =>
      StawiAssets._({..._byId, ...StawiAssets(infos)._byId});
}

/// [units] minor units of [asset], localized: "900.00 USDC",
/// "1,234.567891 USDC". At least two fraction digits for a known asset, and
/// every significant one.
String formatUnits(BigInt units, StawiAsset asset, {String? locale}) {
  final symbols = NumberFormat.decimalPattern(locale).symbols;
  final negative = units.isNegative;
  final abs = units.abs();
  final scale = BigInt.from(10).pow(asset.decimals);
  final whole = abs ~/ scale;
  var frac = asset.decimals == 0
      ? ''
      : (abs % scale).toString().padLeft(asset.decimals, '0');
  frac = frac.replaceFirst(RegExp(r'0+$'), '');
  if (asset.known && frac.length < 2) {
    frac = frac.padRight(asset.decimals < 2 ? asset.decimals : 2, '0');
  }
  final digits = whole.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      grouped.write(symbols.GROUP_SEP);
    }
    grouped.write(digits[i]);
  }
  final number =
      '${negative ? symbols.MINUS_SIGN : ''}$grouped'
      '${frac.isEmpty ? '' : '${symbols.DECIMAL_SEP}$frac'}';
  return '$number ${asset.symbol}';
}

/// A finance.v1 Money, formatted from its minor units ("0" when empty) in the
/// asset [assets] describes for its asset id.
String formatMoney(finance.Money money, StawiAssets assets, {String? locale}) {
  final units = BigInt.tryParse(money.amount.isEmpty ? '0' : money.amount);
  if (units == null) return money.amount;
  if (money.assetId.isEmpty) return units.toString();
  return formatUnits(units, assets.of(money.assetId), locale: locale);
}

/// Parses an amount a person typed ("12.5", "900") into minor units of
/// [asset]. Refuses more fraction digits than the asset has and anything not
/// above zero.
String parseAmountInput(String input, StawiAsset asset) {
  final sdk.Amount amount;
  try {
    amount = sdk.Amount.parse(asset.sdkAsset, input.replaceAll(',', ''));
  } on sdk.MoneyException {
    throw FormatException(
      asset.decimals == 0
          ? 'Enter a whole amount'
          : 'Enter an amount with at most ${asset.decimals} decimals',
    );
  }
  if (!amount.isPositive) {
    throw const FormatException('Enter an amount greater than zero');
  }
  return amount.units.toString();
}

/// Basis points as a percentage: 300 → "3%", 250 → "2.5%", 5 → "0.05%".
String formatBps(int bps) {
  final whole = bps ~/ 100;
  final frac = (bps % 100)
      .toString()
      .padLeft(2, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return frac.isEmpty ? '$whole%' : '$whole.$frac%';
}

/// A loan rate with its basis: "3% per period", "12% a year".
String formatRate(int bps, finance.LoanRateBasis basis) =>
    '${formatBps(bps)}${switch (basis) {
      finance.LoanRateBasis.LOAN_RATE_BASIS_PER_PERIOD => ' per period',
      finance.LoanRateBasis.LOAN_RATE_BASIS_PER_YEAR => ' a year',
      _ => '',
    }}';
