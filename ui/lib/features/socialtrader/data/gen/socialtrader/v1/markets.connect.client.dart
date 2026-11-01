//
//  Generated code. Do not modify.
//  source: socialtrader/v1/markets.proto
//

import "package:connectrpc/connect.dart" as connect;

import "markets.pb.dart" as socialtraderv1markets;
import "markets.connect.spec.dart" as specs;

/// MarketService lists the spot markets and reads their order books.
extension type MarketServiceClient(connect.Transport _transport) {
  /// Lists the active markets. Public: market data is read by wallets that have no profile.
  Future<socialtraderv1markets.ListMarketsResponse> listMarkets(
    socialtraderv1markets.ListMarketsRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.MarketService.listMarkets,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Reads the top of book for a market.
  Future<socialtraderv1markets.GetBookResponse> getBook(
    socialtraderv1markets.GetBookRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.MarketService.getBook,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
