import 'package:fixnum/fixnum.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/pool_models.dart';
import 'socialtrader_clients.dart' as st;
import 'wallet_service.dart' show PreparedTx;

part 'socialtrader_api.g.dart';

/// What the trading-group module asks the socialtrader service, in domain
/// terms. Widgets and controllers depend on this, never on the generated
/// clients, so tests can stand in a fake.
abstract interface class SocialTraderApi {
  Future<List<PoolInfo>> listPools();

  /// The pool at [pool] (address or room reference), or null when unknown.
  Future<PoolInfo?> getPool(String pool);
  Future<PoolMembership> getMembership(String pool, String wallet);
  Future<PoolPerformance> getPerformance(String pool, {int limit = 200});
  Future<List<MarketInfo>> listMarkets();
  Future<OrderBook> getBook(String marketId, {int depth = 5});

  /// Calldata for a deposit of [assets] (quote asset, decimal string) into
  /// [pool], minting at least [minShares] (empty = no floor) to [receiver].
  /// The wallet signs it.
  Future<PreparedTx> prepareDeposit({
    required String pool,
    required String assets,
    required String receiver,
    String minShares = '',
  });

  /// Calldata for redeeming [shares] of [pool] to [receiver], paying at least
  /// [minAssets] (empty = no floor).
  Future<PreparedTx> prepareRedeem({
    required String pool,
    required String shares,
    required String receiver,
    String minAssets = '',
  });

  /// Calldata for a leader-only call; the contract enforces onlyLeader.
  Future<PreparedTx> prepareLeaderOrder(LeaderOrder order);

  /// The SIWE message [wallet] signs to link itself to the profile (EIP-4361
  /// puts the address in the message).
  Future<SiweChallenge> issueNonce({required String wallet});
  Future<LinkedWallet> linkWallet({
    required String wallet,
    required String signature,
  });

  /// The wallet linked to the signed-in profile, or null when none.
  Future<LinkedWallet?> getLinkedWallet();

  /// Asks the service to create a pool for [roomRef] with its creator key.
  Future<CreatedPool> createPool({
    required String roomRef,
    required String marketId,
    required int performanceFeeBps,
    required int minLeaderSkinBps,
    required String maxTvlQuote,
  });
}

/// The service's Connect clients behind [SocialTraderApi].
class ConnectSocialTraderApi implements SocialTraderApi {
  const ConnectSocialTraderApi({
    required st.PoolServiceClient pools,
    required st.LinkServiceClient links,
    required st.MarketServiceClient markets,
  }) : this._(pools, links, markets);

  const ConnectSocialTraderApi._(this._pools, this._links, this._markets);

  final st.PoolServiceClient _pools;
  final st.LinkServiceClient _links;
  final st.MarketServiceClient _markets;

  @override
  Future<List<PoolInfo>> listPools() async {
    final resp = await _pools.listPools(st.ListPoolsRequest());
    return [for (final p in resp.pools) _pool(p)];
  }

  @override
  Future<PoolInfo?> getPool(String pool) async {
    final resp = await _pools.getPool(st.GetPoolRequest(pool: pool));
    if (!resp.hasPool() || resp.pool.address.isEmpty) return null;
    return _pool(resp.pool);
  }

  @override
  Future<PoolMembership> getMembership(String pool, String wallet) async {
    final resp = await _pools.getMembership(
      st.GetMembershipRequest(pool: pool, wallet: wallet),
    );
    final m = resp.membership;
    return PoolMembership(
      pool: m.pool.isEmpty ? pool : m.pool.toLowerCase(),
      wallet: m.wallet.isEmpty ? wallet : m.wallet.toLowerCase(),
      shares: _orZero(m.shares),
      shareBps: _orZero(m.shareBps),
      valueQuote: _orZero(m.valueQuote),
      queuedShares: _orZero(m.queuedShares),
      previewAssets: m.previewAssets,
      previewFee: m.previewFee,
    );
  }

  @override
  Future<PoolPerformance> getPerformance(String pool, {int limit = 200}) async {
    final resp = await _pools.getPoolPerformance(
      st.GetPoolPerformanceRequest(pool: pool, limit: limit),
    );
    return PoolPerformance(
      series: [
        for (final p in resp.series)
          NavPoint(
            block: p.block.toInt(),
            at: p.hasAt() ? p.at.toDateTime() : null,
            navPerShare: p.navPerShare,
            nav: p.nav,
          ),
      ],
      returnBps: _orZero(resp.returnBps),
      maxDrawdownBps: _orZero(resp.maxDrawdownBps),
      asOfBlock: resp.asOfBlock.toInt(),
      tier: resp.tier,
    );
  }

  @override
  Future<List<MarketInfo>> listMarkets() async {
    final resp = await _markets.listMarkets(st.ListMarketsRequest());
    return [
      for (final m in resp.markets)
        MarketInfo(
          id: m.id,
          marketId: m.marketId,
          symbol: m.symbol,
          baseSymbol: m.baseSymbol,
          quoteSymbol: m.quoteSymbol,
          active: m.active,
        ),
    ];
  }

  @override
  Future<OrderBook> getBook(String marketId, {int depth = 5}) async {
    final resp = await _markets.getBook(
      st.GetBookRequest(marketId: marketId, depth: depth),
    );
    return OrderBook(
      bids: [
        for (final l in resp.bids) BookLevel(price: l.price, size: l.size),
      ],
      asks: [
        for (final l in resp.asks) BookLevel(price: l.price, size: l.size),
      ],
      lastTradePrice: resp.lastTradePrice,
      bestBid: resp.bestBid,
      bestAsk: resp.bestAsk,
      asOfBlock: resp.asOfBlock.toInt(),
    );
  }

  @override
  Future<PreparedTx> prepareDeposit({
    required String pool,
    required String assets,
    required String receiver,
    String minShares = '',
  }) async => _tx(
    await _pools.preparePoolDeposit(
      st.PreparePoolDepositRequest(
        pool: pool,
        assets: assets,
        receiver: receiver,
        minShares: minShares,
      ),
    ),
  );

  @override
  Future<PreparedTx> prepareRedeem({
    required String pool,
    required String shares,
    required String receiver,
    String minAssets = '',
  }) async => _tx(
    await _pools.preparePoolRedeem(
      st.PreparePoolRedeemRequest(
        pool: pool,
        shares: shares,
        receiver: receiver,
        minAssets: minAssets,
      ),
    ),
  );

  @override
  Future<PreparedTx> prepareLeaderOrder(LeaderOrder order) async => _tx(
    await _pools.prepareLeaderOrder(
      st.PrepareLeaderOrderRequest(
        pool: order.pool,
        kind: switch (order.kind) {
          LeaderOrderKind.limit => st.PrepareLeaderOrderRequest_Kind.KIND_LIMIT,
          LeaderOrderKind.ioc => st.PrepareLeaderOrderRequest_Kind.KIND_IOC,
          LeaderOrderKind.cancel =>
            st.PrepareLeaderOrderRequest_Kind.KIND_CANCEL,
          LeaderOrderKind.claim => st.PrepareLeaderOrderRequest_Kind.KIND_CLAIM,
          LeaderOrderKind.sellForRedeems =>
            st.PrepareLeaderOrderRequest_Kind.KIND_SELL_FOR_REDEEMS,
          LeaderOrderKind.settleQueue =>
            st.PrepareLeaderOrderRequest_Kind.KIND_SETTLE_QUEUE,
          LeaderOrderKind.cancelForRedeems =>
            st.PrepareLeaderOrderRequest_Kind.KIND_CANCEL_FOR_REDEEMS,
          LeaderOrderKind.crystallizeFee =>
            st.PrepareLeaderOrderRequest_Kind.KIND_CRYSTALLIZE_FEE,
        },
        isBid: order.isBid,
        price: order.price,
        baseAmount: order.baseAmount,
        orderId: Int64(order.orderId),
        maxLevels: order.maxLevels,
        hintPrice: order.hintPrice,
      ),
    ),
  );

  @override
  Future<SiweChallenge> issueNonce({required String wallet}) async {
    final resp = await _links.issueNonce(st.IssueNonceRequest(wallet: wallet));
    return SiweChallenge(
      nonce: resp.nonce,
      message: resp.message,
      expiresAt: resp.hasExpiresAt() ? resp.expiresAt.toDateTime() : null,
    );
  }

  @override
  Future<LinkedWallet> linkWallet({
    required String wallet,
    required String signature,
  }) async {
    final resp = await _links.linkWallet(
      st.LinkWalletRequest(wallet: wallet, signature: signature),
    );
    return LinkedWallet(
      wallet: resp.wallet.toLowerCase(),
      linkedAt: resp.hasLinkedAt() ? resp.linkedAt.toDateTime() : null,
    );
  }

  @override
  Future<LinkedWallet?> getLinkedWallet() async {
    final resp = await _links.getLinkedWallet(st.GetLinkedWalletRequest());
    if (resp.wallet.isEmpty) return null;
    return LinkedWallet(
      wallet: resp.wallet.toLowerCase(),
      linkedAt: resp.hasLinkedAt() ? resp.linkedAt.toDateTime() : null,
    );
  }

  @override
  Future<CreatedPool> createPool({
    required String roomRef,
    required String marketId,
    required int performanceFeeBps,
    required int minLeaderSkinBps,
    required String maxTvlQuote,
  }) async {
    final resp = await _pools.createPool(
      st.CreatePoolRequest(
        roomRef: roomRef,
        marketId: marketId,
        performanceFeeBps: performanceFeeBps,
        minLeaderSkinBps: minLeaderSkinBps,
        maxTvlQuote: maxTvlQuote,
      ),
    );
    return CreatedPool(pool: resp.pool.toLowerCase(), txHash: resp.txHash);
  }

  static PoolInfo _pool(st.Pool p) => PoolInfo(
    address: p.address.toLowerCase(),
    marketId: p.marketId,
    leader: p.leader.toLowerCase(),
    roomRef: p.roomRef,
    nav: p.nav,
    navPerShare: p.navPerShare,
    totalShares: p.totalShares,
    memberCount: p.memberCount,
    performanceFeeBps: p.performanceFeeBps,
    minLeaderSkinBps: p.minLeaderSkinBps,
    maxTvlQuote: p.maxTvlQuote,
    paused: p.paused,
    asOfBlock: p.asOfBlock.toInt(),
    tier: p.tier,
    mark: p.mark,
  );

  static PreparedTx _tx(st.PreparedTx tx) => PreparedTx(
    to: tx.to,
    data: tx.data,
    value: tx.value.isEmpty ? '0x0' : tx.value,
    chainId: tx.chainId.toInt(),
    description: tx.description,
  );

  static String _orZero(String value) => value.isEmpty ? '0' : value;
}

@Riverpod(keepAlive: true)
SocialTraderApi socialTraderApi(Ref ref) => ConnectSocialTraderApi(
  pools: ref.watch(st.poolServiceProvider),
  links: ref.watch(st.linkServiceProvider),
  markets: ref.watch(st.marketServiceProvider),
);

/// Every pool the service knows, by lowercase address. Cards from a pool not
/// in it render as plain text.
@riverpod
Future<Map<String, PoolInfo>> knownPools(Ref ref) async {
  final pools = await ref.watch(socialTraderApiProvider).listPools();
  return {for (final p in pools) p.address: p};
}

/// The pool at [address], or null when the service does not know it.
@riverpod
Future<PoolInfo?> poolByAddress(Ref ref, String address) async {
  final pools = await ref.watch(knownPoolsProvider.future);
  return pools[address.toLowerCase()];
}
