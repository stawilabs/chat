/// Slippage floors for the pool calls the wallet signs. The service prepares
/// deposit and redeem calldata with a minimum the contract enforces; the app
/// derives it from the preview so a NAV move between preview and inclusion
/// cannot hand the member fewer shares (or less quote) than they saw, within
/// one percent. Arithmetic is exact (integers scaled to 18 decimals), never
/// floating point.
library;

/// Basis points of tolerated slippage: 1%.
const int slippageBps = 100;

/// The shares [assets] buys at the pool's current NAV: assets * totalShares /
/// nav. An empty pool (no shares or no value yet) mints 1:1, so the shares
/// equal the assets. Decimal strings in; null when the amount is malformed or
/// not positive.
String? previewShares({
  required String assets,
  required String nav,
  required String totalShares,
}) {
  final a = _parse(assets);
  if (a == null || a <= BigInt.zero) return null;
  final n = _parse(nav) ?? BigInt.zero;
  final t = _parse(totalShares) ?? BigInt.zero;
  if (n <= BigInt.zero || t <= BigInt.zero) return _format(a);
  return _format(a * t ~/ n);
}

/// [value] less [slippageBps] basis points, as a decimal string; '' (which the
/// service reads as no floor) when [value] is empty or not a positive number.
String minimumWithSlippage(String value, {int bps = slippageBps}) {
  final v = _parse(value);
  if (v == null || v <= BigInt.zero) return '';
  return _format(v * BigInt.from(10000 - bps) ~/ BigInt.from(10000));
}

const int _scale = 18;
final BigInt _one = BigInt.from(10).pow(_scale);

/// A decimal string as an integer scaled by 10^18; null when malformed.
BigInt? _parse(String text) {
  final trimmed = text.trim();
  if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(trimmed)) return null;
  final negative = trimmed.startsWith('-');
  final body = negative ? trimmed.substring(1) : trimmed;
  final parts = body.split('.');
  final whole = BigInt.parse(parts[0]);
  var fraction = parts.length > 1 ? parts[1] : '';
  if (fraction.length > _scale) fraction = fraction.substring(0, _scale);
  final fractional = fraction.isEmpty
      ? BigInt.zero
      : BigInt.parse(fraction.padRight(_scale, '0'));
  final scaled = whole * _one + fractional;
  return negative ? -scaled : scaled;
}

/// Up to 18 decimals, trailing zeros and a dangling point removed.
String _format(BigInt scaled) {
  final whole = scaled ~/ _one;
  final fraction = (scaled % _one).toString().padLeft(_scale, '0');
  final trimmed = fraction.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.isEmpty ? '$whole' : '$whole.$trimmed';
}
