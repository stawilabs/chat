//
//  Generated code. Do not modify.
//  source: socialtrader/v1/pools.proto
//

import "package:connectrpc/connect.dart" as connect;
import "pools.pb.dart" as socialtraderv1pools;
import "trading.pb.dart" as socialtraderv1trading;

/// PoolService reads indexed strategy pools and prepares the calldata that
/// members and leaders sign. Reads and prepares are public: the wallet
/// signature is the authority. CreatePool is the one write the service
/// performs itself, with its pool-creator key, for an authenticated caller.
abstract final class PoolService {
  /// Fully-qualified name of the PoolService service.
  static const name = 'socialtrader.v1.PoolService';

  static const listPools = connect.Spec(
    '/$name/ListPools',
    connect.StreamType.unary,
    socialtraderv1pools.ListPoolsRequest.new,
    socialtraderv1pools.ListPoolsResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  static const getPool = connect.Spec(
    '/$name/GetPool',
    connect.StreamType.unary,
    socialtraderv1pools.GetPoolRequest.new,
    socialtraderv1pools.GetPoolResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  static const getMembership = connect.Spec(
    '/$name/GetMembership',
    connect.StreamType.unary,
    socialtraderv1pools.GetMembershipRequest.new,
    socialtraderv1pools.GetMembershipResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  static const getPoolPerformance = connect.Spec(
    '/$name/GetPoolPerformance',
    connect.StreamType.unary,
    socialtraderv1pools.GetPoolPerformanceRequest.new,
    socialtraderv1pools.GetPoolPerformanceResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  static const preparePoolDeposit = connect.Spec(
    '/$name/PreparePoolDeposit',
    connect.StreamType.unary,
    socialtraderv1pools.PreparePoolDepositRequest.new,
    socialtraderv1trading.PreparedTx.new,
  );

  static const preparePoolRedeem = connect.Spec(
    '/$name/PreparePoolRedeem',
    connect.StreamType.unary,
    socialtraderv1pools.PreparePoolRedeemRequest.new,
    socialtraderv1trading.PreparedTx.new,
  );

  static const prepareLeaderOrder = connect.Spec(
    '/$name/PrepareLeaderOrder',
    connect.StreamType.unary,
    socialtraderv1pools.PrepareLeaderOrderRequest.new,
    socialtraderv1trading.PreparedTx.new,
  );

  /// Creates a pool for the caller's room with the service's pool-creator key.
  /// The leader is the caller's linked wallet; authenticated callers only.
  static const createPool = connect.Spec(
    '/$name/CreatePool',
    connect.StreamType.unary,
    socialtraderv1pools.CreatePoolRequest.new,
    socialtraderv1pools.CreatePoolResponse.new,
  );
}
