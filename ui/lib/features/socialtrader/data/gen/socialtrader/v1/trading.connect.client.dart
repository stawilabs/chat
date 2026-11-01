//
//  Generated code. Do not modify.
//  source: socialtrader/v1/trading.proto
//

import "package:connectrpc/connect.dart" as connect;

import "trading.pb.dart" as socialtraderv1trading;
import "trading.connect.spec.dart" as specs;

/// TradingService prepares vault and order calldata for a wallet to sign and
/// reads a wallet's vault portfolio. The wallet signature is the authority, so
/// prepare calls are reachable anonymously.
extension type TradingServiceClient(connect.Transport _transport) {
  /// Prepares calldata for one intent: approve, deposit, withdraw, claim_to_free,
  /// place_limit, place_ioc, cancel (and mint on local anvil deployments).
  Future<socialtraderv1trading.PreparedTx> prepareTx(
    socialtraderv1trading.PrepareTxRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.TradingService.prepareTx,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Reads a wallet's vault balances per token.
  Future<socialtraderv1trading.GetPortfolioResponse> getPortfolio(
    socialtraderv1trading.GetPortfolioRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.TradingService.getPortfolio,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Compares vault holdings to liabilities for every known token.
  Future<socialtraderv1trading.GetSolvencyResponse> getSolvency(
    socialtraderv1trading.GetSolvencyRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.TradingService.getSolvency,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
