//
//  Generated code. Do not modify.
//  source: socialtrader/v1/markets.proto
//

import "package:connectrpc/connect.dart" as connect;
import "markets.pb.dart" as socialtraderv1markets;

/// MarketService lists the spot markets and reads their order books.
abstract final class MarketService {
  /// Fully-qualified name of the MarketService service.
  static const name = 'socialtrader.v1.MarketService';

  /// Lists the active markets. Public: market data is read by wallets that have no profile.
  static const listMarkets = connect.Spec(
    '/$name/ListMarkets',
    connect.StreamType.unary,
    socialtraderv1markets.ListMarketsRequest.new,
    socialtraderv1markets.ListMarketsResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  /// Reads the top of book for a market.
  static const getBook = connect.Spec(
    '/$name/GetBook',
    connect.StreamType.unary,
    socialtraderv1markets.GetBookRequest.new,
    socialtraderv1markets.GetBookResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );
}
