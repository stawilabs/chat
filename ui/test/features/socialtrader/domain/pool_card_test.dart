import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/socialtrader/domain/pool_card.dart';

const pool = '0x00000000000000000000000000000000000000a1';

void main() {
  group('PoolCard.tryParse', () {
    test('poolCard_parsesEachKind', () {
      final join = PoolCard.tryParse(
        '{"socialtrader":{"kind":"pool_join_prompt","v":1,"pool":"$pool",'
        '"market_symbol":"WETH/USDC","nav_per_share":"1.0250",'
        '"member_count":4,"suggested_assets":"250","wallet_linked":true,'
        '"deposit_path":"/v1/pools/$pool/prepare-deposit"}}',
      );
      expect(join, isA<JoinPromptCard>());
      final j = join! as JoinPromptCard;
      expect(j.pool, pool);
      expect(j.marketSymbol, 'WETH/USDC');
      expect(j.navPerShare, '1.0250');
      expect(j.memberCount, 4);
      expect(j.suggestedAssets, '250');
      expect(j.walletLinked, isTrue);

      final leave = PoolCard.tryParse(
        '{"socialtrader":{"kind":"pool_leave_prompt","v":1,"pool":"$pool",'
        '"shares":"12.5","value_quote":"13.1","redeem_path":"/x"}}',
      );
      expect(leave, isA<LeavePromptCard>());
      final l = leave! as LeavePromptCard;
      expect(l.shares, '12.5');
      expect(l.valueQuote, '13.1');

      final nav = PoolCard.tryParse(
        '{"socialtrader":{"kind":"pool_nav","v":1,"pool":"$pool",'
        '"nav":"1000","nav_per_share":"1.05","return_bps":"500",'
        '"tier":"finalized","as_of_block":123}}',
      );
      expect(nav, isA<NavCard>());
      final n = nav! as NavCard;
      expect(n.nav, '1000');
      expect(n.navPerShare, '1.05');
      expect(n.returnBps, 500);
      expect(n.tier, 'finalized');
      expect(n.asOfBlock, 123);

      final fill = PoolCard.tryParse(
        '{"socialtrader":{"kind":"pool_fill","v":1,"pool":"$pool",'
        '"side":"buy","price":"2000.5","base_amount":"0.5",'
        '"quote_amount":"1000.25","tx_hash":"0xabc","block":124}}',
      );
      expect(fill, isA<FillCard>());
      final f = fill! as FillCard;
      expect(f.side, 'buy');
      expect(f.price, '2000.5');
      expect(f.baseAmount, '0.5');
      expect(f.quoteAmount, '1000.25');
      expect(f.txHash, '0xabc');
      expect(f.block, 124);
    });

    test('poolCard_rejectsNonSocialtraderJson', () {
      expect(PoolCard.tryParse('{"hello":1}'), isNull);
      expect(PoolCard.tryParse('{"socialtrader":{"v":1}}'), isNull);
      expect(
        PoolCard.tryParse('{"socialtrader":{"kind":"pool_moon","v":1}}'),
        isNull,
        reason: 'an unknown kind is not a card',
      );
      expect(
        PoolCard.tryParse('{"socialtrader":{"kind":"pool_nav","v":1}}'),
        isNull,
        reason: 'a card without a pool is not a card',
      );
      expect(PoolCard.tryParse('not json'), isNull);
      expect(PoolCard.tryParse('[1,2]'), isNull);
      expect(PoolCard.tryParse(''), isNull);
    });

    test('poolCard_toleratesNumbersAsStringsAndMissingOptionals', () {
      final nav =
          PoolCard.tryParse(
                '{"socialtrader":{"kind":"pool_nav","v":1,"pool":"$pool",'
                '"return_bps":"-120","as_of_block":"77"}}',
              )!
              as NavCard;
      expect(nav.returnBps, -120);
      expect(nav.asOfBlock, 77);
      expect(nav.tier, '');
      expect(nav.nav, '');
      expect(nav.pool, pool);

      final join =
          PoolCard.tryParse(
                '{"socialtrader":{"kind":"pool_join_prompt","v":1,"pool":"${pool.toUpperCase()}"}}',
              )!
              as JoinPromptCard;
      expect(join.pool, pool, reason: 'addresses are lowercased');
      expect(join.memberCount, 0);
      expect(join.walletLinked, isFalse);
    });

    test('poolCard_summaryIsPlainWords', () {
      final join = PoolCard.tryParse(
        '{"socialtrader":{"kind":"pool_join_prompt","v":1,"pool":"$pool"}}',
      )!;
      expect(join.summary, 'Invitation to commit to the pool');
      final fill = PoolCard.tryParse(
        '{"socialtrader":{"kind":"pool_fill","v":1,"pool":"$pool",'
        '"side":"sell","price":"2000","base_amount":"1"}}',
      )!;
      expect(fill.summary, 'Pool sold 1 at 2000');
    });
  });
}
