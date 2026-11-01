import 'package:flutter/foundation.dart';

/// A strategy pool as the socialtrader service indexed it. Amounts are
/// decimal strings in the pool's quote asset, as the service formats them.
@immutable
class PoolInfo {
  const PoolInfo({
    required this.address,
    required this.marketId,
    required this.leader,
    this.roomRef = '',
    this.nav = '',
    this.navPerShare = '',
    this.totalShares = '',
    this.memberCount = 0,
    this.performanceFeeBps = 0,
    this.minLeaderSkinBps = 0,
    this.maxTvlQuote = '',
    this.paused = false,
    this.asOfBlock = 0,
    this.tier = '',
  });

  /// Pool contract, lowercase hex.
  final String address;
  final String marketId;

  /// The wallet that trades for the pool, lowercase hex.
  final String leader;

  /// The chat room the pool was created for, when created via the service.
  final String roomRef;
  final String nav;
  final String navPerShare;
  final String totalShares;
  final int memberCount;
  final int performanceFeeBps;
  final int minLeaderSkinBps;
  final String maxTvlQuote;
  final bool paused;
  final int asOfBlock;

  /// The verification tier of the NAV ("finalized" is the only verified one).
  final String tier;

  /// Whether [wallet] (any case) is the pool's leader.
  bool isLeader(String? wallet) =>
      wallet != null &&
      wallet.isNotEmpty &&
      wallet.toLowerCase() == leader.toLowerCase();
}

/// A wallet's stake in a pool.
@immutable
class PoolMembership {
  const PoolMembership({
    required this.pool,
    required this.wallet,
    this.shares = '0',
    this.shareBps = '0',
    this.valueQuote = '0',
    this.queuedShares = '0',
    this.previewAssets = '',
    this.previewFee = '',
  });

  const PoolMembership.none(this.pool, this.wallet)
    : shares = '0',
      shareBps = '0',
      valueQuote = '0',
      queuedShares = '0',
      previewAssets = '',
      previewFee = '';

  final String pool;
  final String wallet;
  final String shares;

  /// Share of the pool in basis points, as a decimal string.
  final String shareBps;
  final String valueQuote;

  /// Shares waiting in the redeem queue for free quote.
  final String queuedShares;

  /// What redeeming every share pays out now and the performance fee taken,
  /// as the service previews them (quote asset); empty when not previewed.
  final String previewAssets;
  final String previewFee;

  bool get hasRedeemPreview => previewAssets.isNotEmpty;

  bool get holdsShares => _positive(shares);
  bool get hasQueuedRedeem => _positive(queuedShares);

  /// Share of the pool as a percentage string, e.g. "12.5%".
  String get sharePercent =>
      '${formatPercent((double.tryParse(shareBps) ?? 0) / 100)}%';

  static bool _positive(String value) => (double.tryParse(value) ?? 0) > 0;
}

/// One point of a pool's NAV series.
@immutable
class NavPoint {
  const NavPoint({
    required this.block,
    required this.at,
    required this.navPerShare,
    required this.nav,
  });

  final int block;
  final DateTime? at;
  final String navPerShare;
  final String nav;
}

/// A pool's performance as the service derives it from indexed chain events.
@immutable
class PoolPerformance {
  const PoolPerformance({
    this.series = const [],
    this.returnBps = '0',
    this.maxDrawdownBps = '0',
    this.asOfBlock = 0,
    this.tier = '',
  });

  final List<NavPoint> series;
  final String returnBps;
  final String maxDrawdownBps;
  final int asOfBlock;
  final String tier;
}

/// A market the pools trade.
@immutable
class MarketInfo {
  const MarketInfo({
    required this.id,
    required this.marketId,
    required this.symbol,
    this.baseSymbol = '',
    this.quoteSymbol = '',
    this.active = true,
  });

  final String id;
  final String marketId;
  final String symbol;
  final String baseSymbol;
  final String quoteSymbol;
  final bool active;
}

/// One level of an order book.
@immutable
class BookLevel {
  const BookLevel({required this.price, required this.size});
  final String price;
  final String size;
}

/// The top of a market's order book as of a block.
@immutable
class OrderBook {
  const OrderBook({
    this.bids = const [],
    this.asks = const [],
    this.lastTradePrice = '',
    this.bestBid = '',
    this.bestAsk = '',
    this.asOfBlock = 0,
  });

  final List<BookLevel> bids;
  final List<BookLevel> asks;
  final String lastTradePrice;
  final String bestBid;
  final String bestAsk;
  final int asOfBlock;
}

/// A leader order kind, as PoolService.PrepareLeaderOrder names them.
enum LeaderOrderKind { limit, ioc, cancel, claim, sellForRedeems, settleQueue }

/// A leader's intent for PrepareLeaderOrder.
@immutable
class LeaderOrder {
  const LeaderOrder({
    required this.pool,
    required this.kind,
    this.isBid = true,
    this.price = '',
    this.baseAmount = '',
    this.orderId = 0,
    this.maxLevels = 0,
    this.hintPrice = '',
  });

  final String pool;
  final LeaderOrderKind kind;
  final bool isBid;
  final String price;
  final String baseAmount;
  final int orderId;

  /// Book levels to sweep; for settleQueue the most queued items to settle.
  final int maxLevels;
  final String hintPrice;
}

/// A Sign-In with Ethereum challenge the wallet signs to link itself.
@immutable
class SiweChallenge {
  const SiweChallenge({
    required this.nonce,
    required this.message,
    this.expiresAt,
  });
  final String nonce;
  final String message;
  final DateTime? expiresAt;
}

/// The wallet linked to the signed-in profile.
@immutable
class LinkedWallet {
  const LinkedWallet({required this.wallet, this.linkedAt});
  final String wallet;
  final DateTime? linkedAt;
}

/// A pool the service created for a room.
@immutable
class CreatedPool {
  const CreatedPool({required this.pool, required this.txHash});
  final String pool;
  final String txHash;
}

/// Formats basis points as a signed percentage, e.g. 500 -> "+5.00%".
String formatBps(num bps) {
  final percent = bps / 100;
  final prefix = percent > 0 ? '+' : '';
  return '$prefix${percent.toStringAsFixed(2)}%';
}

/// Formats a percentage with up to two decimals and no trailing zeros:
/// 12.5 -> "12.5", 10 -> "10", 0.125 -> "0.13".
String formatPercent(double percent) {
  var text = percent.toStringAsFixed(2);
  if (text.contains('.')) {
    text = text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
  return text;
}
