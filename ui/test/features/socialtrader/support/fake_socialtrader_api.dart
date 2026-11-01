import 'package:stawi/features/socialtrader/data/socialtrader_api.dart';
import 'package:stawi/features/socialtrader/data/wallet_service.dart';
import 'package:stawi/features/socialtrader/domain/pool_models.dart';

/// An in-memory socialtrader service for widget tests. Set [failWith] to make
/// every call fail; recorded calls let tests assert what was asked.
class FakeSocialTraderApi implements SocialTraderApi {
  final pools = <PoolInfo>[];
  final memberships = <String, PoolMembership>{};
  final markets = <MarketInfo>[];
  final books = <String, OrderBook>{};
  PoolPerformance performance = const PoolPerformance();
  LinkedWallet? linked;
  SiweChallenge challenge = const SiweChallenge(
    nonce: 'n-1',
    message: 'stawi.org wants you to sign in\nNonce: n-1',
  );
  CreatedPool created = const CreatedPool(
    pool: '0x00000000000000000000000000000000000000c0',
    txHash: '0xcreate',
  );
  Exception? failWith;

  /// Fails only getLinkedWallet (an outage of the link lookup alone).
  Exception? linkFailWith;

  final deposits =
      <({String pool, String assets, String receiver, String minShares})>[];
  final redeems =
      <({String pool, String shares, String receiver, String minAssets})>[];
  final leaderOrders = <LeaderOrder>[];
  final links = <({String wallet, String signature})>[];
  int nonceCalls = 0;
  final nonceWallets = <String>[];
  final createPools =
      <({String roomRef, String marketId, int feeBps, int skinBps})>[];

  PreparedTx preparedTx = const PreparedTx(
    to: '0x2222222222222222222222222222222222222222',
    data: '0xdeadbeef',
    value: '0x0',
    chainId: 14601,
    description: 'Prepared by the fake',
  );

  void _maybeFail() {
    if (failWith case final e?) throw e;
  }

  @override
  Future<List<PoolInfo>> listPools() async {
    _maybeFail();
    return List.of(pools);
  }

  @override
  Future<PoolInfo?> getPool(String pool) async {
    _maybeFail();
    final key = pool.toLowerCase();
    for (final p in pools) {
      if (p.address == key || p.roomRef == pool) return p;
    }
    return null;
  }

  @override
  Future<PoolMembership> getMembership(String pool, String wallet) async {
    _maybeFail();
    return memberships['${pool.toLowerCase()}:${wallet.toLowerCase()}'] ??
        PoolMembership.none(pool.toLowerCase(), wallet.toLowerCase());
  }

  @override
  Future<PoolPerformance> getPerformance(String pool, {int limit = 200}) async {
    _maybeFail();
    return performance;
  }

  @override
  Future<List<MarketInfo>> listMarkets() async {
    _maybeFail();
    return List.of(markets);
  }

  @override
  Future<OrderBook> getBook(String marketId, {int depth = 5}) async {
    _maybeFail();
    return books[marketId] ?? const OrderBook();
  }

  @override
  Future<PreparedTx> prepareDeposit({
    required String pool,
    required String assets,
    required String receiver,
    String minShares = '',
  }) async {
    _maybeFail();
    deposits.add((
      pool: pool,
      assets: assets,
      receiver: receiver,
      minShares: minShares,
    ));
    return preparedTx;
  }

  @override
  Future<PreparedTx> prepareRedeem({
    required String pool,
    required String shares,
    required String receiver,
    String minAssets = '',
  }) async {
    _maybeFail();
    redeems.add((
      pool: pool,
      shares: shares,
      receiver: receiver,
      minAssets: minAssets,
    ));
    return preparedTx;
  }

  @override
  Future<PreparedTx> prepareLeaderOrder(LeaderOrder order) async {
    _maybeFail();
    leaderOrders.add(order);
    return preparedTx;
  }

  @override
  Future<SiweChallenge> issueNonce({required String wallet}) async {
    _maybeFail();
    nonceCalls++;
    nonceWallets.add(wallet);
    return challenge;
  }

  @override
  Future<LinkedWallet> linkWallet({
    required String wallet,
    required String signature,
  }) async {
    _maybeFail();
    links.add((wallet: wallet, signature: signature));
    linked = LinkedWallet(
      wallet: wallet.toLowerCase(),
      linkedAt: DateTime(2026),
    );
    return linked!;
  }

  @override
  Future<LinkedWallet?> getLinkedWallet() async {
    _maybeFail();
    if (linkFailWith case final e?) throw e;
    return linked;
  }

  @override
  Future<CreatedPool> createPool({
    required String roomRef,
    required String marketId,
    required int performanceFeeBps,
    required int minLeaderSkinBps,
    required String maxTvlQuote,
  }) async {
    _maybeFail();
    createPools.add((
      roomRef: roomRef,
      marketId: marketId,
      feeBps: performanceFeeBps,
      skinBps: minLeaderSkinBps,
    ));
    return created;
  }
}
