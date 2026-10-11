import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' as sdk;

/// An asset as the app shows it: its id (`SYMBOL.chainId`, e.g. "USDC.146"),
/// the symbol people read and the number of minor-unit digits.
///
/// No API serves the protocol manifest's asset registry to the app yet
/// (protocol.v1 Asset carries symbol and decimals), so the decimals of the
/// settlement assets Stawi rooms use are kept here, keyed by symbol.
class StawiAsset {
  const StawiAsset._(this.id, this.symbol, this.decimals, this.known);

  /// The asset an id names. An unknown symbol shows its amounts as whole
  /// minor units under its id.
  factory StawiAsset.fromId(String id) {
    final symbol = id.split('.').first.toUpperCase();
    final decimals = knownAssetDecimals[symbol];
    return decimals == null
        ? StawiAsset._(id, id, 0, false)
        : StawiAsset._(id, symbol, decimals, true);
  }

  final String id;
  final String symbol;
  final int decimals;

  /// Whether the decimals are known; otherwise amounts are raw minor units.
  final bool known;

  sdk.Asset get sdkAsset => sdk.Asset(id, decimals);
}

/// Minor-unit digits of the settlement assets rooms hold (ERC-20 decimals).
const Map<String, int> knownAssetDecimals = {'USDC': 6, 'USDT': 6, 'EURC': 6};

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

/// A finance.v1 Money, formatted from its minor units ("0" when empty).
String formatMoney(finance.Money money, {String? locale}) {
  final units = BigInt.tryParse(money.amount.isEmpty ? '0' : money.amount);
  if (units == null) return money.amount;
  if (money.assetId.isEmpty) return units.toString();
  return formatUnits(units, StawiAsset.fromId(money.assetId), locale: locale);
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
