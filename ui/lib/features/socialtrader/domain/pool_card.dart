import 'dart:convert';

import 'package:flutter/foundation.dart';

/// A pool card the socialtrader service posted into a trading group: a text
/// message in the "json" format whose body is
/// `{"socialtrader": {"kind": ..., "v": 1, "pool": ..., ...}}`.
///
/// A card shows; it never authorises. Anything it offers (commit, redeem) is
/// a transaction the member's wallet signs after a tap.
@immutable
sealed class PoolCard {
  const PoolCard({
    required this.pool,
    required this.version,
    this.roomRef = '',
  });

  /// The pool the card is about, lowercase hex.
  final String pool;
  final int version;

  /// The room the pool was created for, when the card names it.
  final String roomRef;

  /// The discriminator kind of this card.
  String get kind;

  /// A one-line description for previews and notifications.
  String get summary;

  /// Parses a message body; null when it is not a pool card (not JSON, no
  /// `socialtrader` object, unknown kind, or no pool).
  static PoolCard? tryParse(String body) {
    if (body.isEmpty) return null;
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    final card = decoded['socialtrader'];
    if (card is! Map<String, dynamic>) return null;
    final kind = card['kind'];
    final pool = _string(card['pool']).toLowerCase();
    if (kind is! String || pool.isEmpty) return null;
    final version = _int(card['v'], fallback: 1);
    final roomRef = _string(card['room_ref']);
    return switch (kind) {
      JoinPromptCard.kindName => JoinPromptCard(
        pool: pool,
        version: version,
        roomRef: roomRef,
        marketSymbol: _string(card['market_symbol']),
        navPerShare: _string(card['nav_per_share']),
        memberCount: _int(card['member_count']),
        suggestedAssets: _string(card['suggested_assets']),
        walletLinked: switch (card['wallet_linked']) {
          final bool linked => linked,
          _ => null,
        },
        depositPath: _string(card['deposit_path']),
      ),
      LeavePromptCard.kindName => LeavePromptCard(
        pool: pool,
        version: version,
        roomRef: roomRef,
        shares: _optional(card['shares']),
        valueQuote: _optional(card['value_quote']),
        redeemPath: _string(card['redeem_path']),
      ),
      NavCard.kindName => NavCard(
        pool: pool,
        version: version,
        roomRef: roomRef,
        nav: _string(card['nav']),
        navPerShare: _string(card['nav_per_share']),
        returnBps: _int(card['return_bps']),
        tier: _string(card['tier']),
        asOfBlock: _int(card['as_of_block']),
      ),
      FillCard.kindName => FillCard(
        pool: pool,
        version: version,
        roomRef: roomRef,
        side: _string(card['side']),
        price: _string(card['price']),
        baseAmount: _string(card['base_amount']),
        quoteAmount: _string(card['quote_amount']),
        txHash: _string(card['tx_hash']),
        block: _int(card['block']),
      ),
      _ => null,
    };
  }

  /// A field the card may omit: null when absent or empty.
  static String? _optional(Object? value) {
    final text = _string(value);
    return text.isEmpty ? null : text;
  }

  static String _string(Object? value) => switch (value) {
    null => '',
    final String s => s,
    final num n => n.toString(),
    _ => value.toString(),
  };

  static int _int(Object? value, {int fallback = 0}) => switch (value) {
    final int i => i,
    final num n => n.round(),
    final String s =>
      int.tryParse(s) ?? (double.tryParse(s)?.round() ?? fallback),
    _ => fallback,
  };
}

/// Posted when a member joins the room: an invitation to commit funds.
class JoinPromptCard extends PoolCard {
  const JoinPromptCard({
    required super.pool,
    required super.version,
    super.roomRef,
    this.marketSymbol = '',
    this.navPerShare = '',
    this.memberCount = 0,
    this.suggestedAssets = '',
    this.walletLinked,
    this.depositPath = '',
  });

  static const kindName = 'pool_join_prompt';

  final String marketSymbol;
  final String navPerShare;
  final int memberCount;

  /// An amount the service suggests; empty lets the app use its default.
  final String suggestedAssets;

  /// Whether the service knows the member's wallet; null when the card does
  /// not say (a room card reveals nothing about a member). The app asks the
  /// authenticated service itself.
  final bool? walletLinked;
  final String depositPath;

  @override
  String get kind => kindName;

  @override
  String get summary => 'Invitation to commit to the pool';
}

/// Posted when a member holding shares leaves the room.
class LeavePromptCard extends PoolCard {
  const LeavePromptCard({
    required super.pool,
    required super.version,
    super.roomRef,
    this.shares,
    this.valueQuote,
    this.redeemPath = '',
  });

  static const kindName = 'pool_leave_prompt';

  /// The member's position, when an older card carried it. A room card must
  /// not reveal a member's position, so these are normally null and the app
  /// asks GetMembership for the viewer's own.
  final String? shares;
  final String? valueQuote;
  final String redeemPath;

  @override
  String get kind => kindName;

  @override
  String get summary => 'Your shares can be redeemed';
}

/// A periodic NAV update.
class NavCard extends PoolCard {
  const NavCard({
    required super.pool,
    required super.version,
    super.roomRef,
    this.nav = '',
    this.navPerShare = '',
    this.returnBps = 0,
    this.tier = '',
    this.asOfBlock = 0,
  });

  static const kindName = 'pool_nav';

  final String nav;
  final String navPerShare;
  final int returnBps;

  /// Verification tier; only "finalized" is shown as verified.
  final String tier;
  final int asOfBlock;

  /// Whether the NAV is derived from finalized chain events.
  bool get isFinalized => tier == 'finalized';

  @override
  String get kind => kindName;

  @override
  String get summary => 'Pool value $nav, NAV/share $navPerShare';
}

/// A fill of a leader order.
class FillCard extends PoolCard {
  const FillCard({
    required super.pool,
    required super.version,
    super.roomRef,
    this.side = '',
    this.price = '',
    this.baseAmount = '',
    this.quoteAmount = '',
    this.txHash = '',
    this.block = 0,
  });

  static const kindName = 'pool_fill';

  /// "buy" or "sell".
  final String side;
  final String price;
  final String baseAmount;
  final String quoteAmount;
  final String txHash;
  final int block;

  bool get isBuy => side.toLowerCase() == 'buy';

  @override
  String get kind => kindName;

  @override
  String get summary =>
      'Pool ${isBuy ? 'bought' : 'sold'} $baseAmount at $price';
}
