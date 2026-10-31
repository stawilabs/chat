//
//  Generated code. Do not modify.
//  source: socialtrader/v1/trading.proto
//

import "package:connectrpc/connect.dart" as connect;
import "trading.pb.dart" as socialtraderv1trading;

/// TradingService prepares vault and order calldata for a wallet to sign and
/// reads a wallet's vault portfolio. The wallet signature is the authority, so
/// prepare calls are reachable anonymously.
abstract final class TradingService {
  /// Fully-qualified name of the TradingService service.
  static const name = 'socialtrader.v1.TradingService';

  /// Prepares calldata for one intent: approve, deposit, withdraw, claim_to_free,
  /// place_limit, place_ioc, cancel (and mint on local anvil deployments).
  static const prepareTx = connect.Spec(
    '/$name/PrepareTx',
    connect.StreamType.unary,
    socialtraderv1trading.PrepareTxRequest.new,
    socialtraderv1trading.PreparedTx.new,
  );

  /// Reads a wallet's vault balances per token.
  static const getPortfolio = connect.Spec(
    '/$name/GetPortfolio',
    connect.StreamType.unary,
    socialtraderv1trading.GetPortfolioRequest.new,
    socialtraderv1trading.GetPortfolioResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  /// Compares vault holdings to liabilities for every known token.
  static const getSolvency = connect.Spec(
    '/$name/GetSolvency',
    connect.StreamType.unary,
    socialtraderv1trading.GetSolvencyRequest.new,
    socialtraderv1trading.GetSolvencyResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );
}
