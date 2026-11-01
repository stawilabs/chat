//
//  Generated code. Do not modify.
//  source: socialtrader/v1/pools.proto
//

import "package:connectrpc/connect.dart" as connect;

import "pools.pb.dart" as socialtraderv1pools;
import "pools.connect.spec.dart" as specs;
import "trading.pb.dart" as socialtraderv1trading;

/// PoolService reads indexed strategy pools and prepares the calldata that
/// members and leaders sign. Reads and prepares are public: the wallet
/// signature is the authority. CreatePool is the one write the service
/// performs itself, with its pool-creator key, for an authenticated caller.
extension type PoolServiceClient(connect.Transport _transport) {
  Future<socialtraderv1pools.ListPoolsResponse> listPools(
    socialtraderv1pools.ListPoolsRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.PoolService.listPools,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<socialtraderv1pools.GetPoolResponse> getPool(
    socialtraderv1pools.GetPoolRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.PoolService.getPool,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<socialtraderv1pools.GetMembershipResponse> getMembership(
    socialtraderv1pools.GetMembershipRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.PoolService.getMembership,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<socialtraderv1pools.GetPoolPerformanceResponse> getPoolPerformance(
    socialtraderv1pools.GetPoolPerformanceRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.PoolService.getPoolPerformance,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<socialtraderv1trading.PreparedTx> preparePoolDeposit(
    socialtraderv1pools.PreparePoolDepositRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.PoolService.preparePoolDeposit,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<socialtraderv1trading.PreparedTx> preparePoolRedeem(
    socialtraderv1pools.PreparePoolRedeemRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.PoolService.preparePoolRedeem,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<socialtraderv1trading.PreparedTx> prepareLeaderOrder(
    socialtraderv1pools.PrepareLeaderOrderRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.PoolService.prepareLeaderOrder,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Creates a pool for the caller's room with the service's pool-creator key.
  /// The leader is the caller's linked wallet; authenticated callers only.
  Future<socialtraderv1pools.CreatePoolResponse> createPool(
    socialtraderv1pools.CreatePoolRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.PoolService.createPool,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
