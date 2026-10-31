import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/current_user_provider.dart';
import 'package:stawi/features/socialtrader/data/commitment_settings.dart';
import 'package:stawi/features/socialtrader/data/socialtrader_api.dart';
import 'package:stawi/features/socialtrader/data/wallet_service.dart';
import 'package:stawi/features/socialtrader/domain/pool_models.dart';
import 'package:stawi/features/socialtrader/ui/trading_settings_screen.dart';

import '../support/fake_socialtrader_api.dart';
import '../support/fake_wallet_platform.dart';

const profileId = 'profile-1';

class Harness {
  Harness({WalletPlatform? platform})
    : platform = platform ?? FakeWalletPlatform();

  final api = FakeSocialTraderApi();
  final settings = MemoryCommitmentSettings();
  final WalletPlatform platform;

  List<Override> get overrides => [
    socialTraderApiProvider.overrideWithValue(api),
    commitmentSettingsProvider.overrideWithValue(settings),
    walletPlatformProvider.overrideWithValue(platform),
    currentProfileIdProvider.overrideWith((ref) async => profileId),
  ];

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: TradingSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('settings_showsLinkedWallet', (tester) async {
    final h = Harness();
    h.api.linked = const LinkedWallet(
      wallet: '0xabcdef0000000000000000000000000000000001',
    );
    await h.pump(tester);
    expect(find.byKey(const Key('trading-linked-wallet')), findsOneWidget);
    expect(find.textContaining('0xabcd…0001'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Link this wallet'), findsNothing);
  });

  testWidgets('settings_noLinkedWalletYet', (tester) async {
    final h = Harness();
    await h.pump(tester);
    expect(find.textContaining('No wallet linked'), findsOneWidget);
  });

  testWidgets('settings_linkFlowCallsIssueThenLink', (tester) async {
    final h = Harness();
    await h.pump(tester);
    final platform = h.platform as FakeWalletPlatform;

    expect(find.widgetWithText(FilledButton, 'Link this wallet'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Connect wallet'));
    await tester.pumpAndSettle();
    expect(h.api.nonceCalls, 0, reason: 'connecting links nothing');

    await tester.tap(find.widgetWithText(FilledButton, 'Link this wallet'));
    await tester.pumpAndSettle();

    expect(h.api.nonceCalls, 1);
    expect(platform.signed, [
      h.api.challenge.message,
    ], reason: 'the wallet signs the SIWE message the service issued');
    expect(h.api.links.single.wallet, FakeWalletPlatform.defaultAddress);
    expect(h.api.links.single.signature, '0xsig');
    expect(find.byKey(const Key('trading-linked-wallet')), findsOneWidget);
    expect(find.textContaining('0x1111…1111'), findsWidgets);
  });

  testWidgets('settings_linkFailureIsShownAndNothingLinked', (tester) async {
    final h = Harness();
    await h.pump(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Connect wallet'));
    await tester.pumpAndSettle();
    (h.platform as FakeWalletPlatform).failWith =
        const WalletUnavailableException('Signature rejected');

    await tester.tap(find.widgetWithText(FilledButton, 'Link this wallet'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Signature rejected'), findsOneWidget);
    expect(h.api.links, isEmpty);
    expect(
      find.widgetWithText(FilledButton, 'Link this wallet'),
      findsOneWidget,
    );
  });

  testWidgets('settings_readOnlyDeviceExplainsAndTakesAnAddress', (
    tester,
  ) async {
    final h = Harness(platform: ReadOnlyWalletPlatform());
    await h.pump(tester);
    expect(find.widgetWithText(FilledButton, 'Connect wallet'), findsNothing);
    expect(find.textContaining('cannot sign'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('trading-address')),
      '0x3333333333333333333333333333333333333333',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Follow address'));
    await tester.pumpAndSettle();
    expect(find.textContaining('0x3333…3333'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Link this wallet'),
      findsNothing,
      reason: 'a pasted address cannot sign the link',
    );
  });

  testWidgets('settings_savesDefaultCommitment', (tester) async {
    final h = Harness();
    await h.settings.save(profileId, '50');
    await h.pump(tester);
    final field = tester.widget<TextField>(
      find.byKey(const Key('trading-default-commitment')),
    );
    expect(field.controller!.text, '50');

    await tester.enterText(
      find.byKey(const Key('trading-default-commitment')),
      '125',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(await h.settings.defaultFor(profileId), '125');
    expect(find.textContaining('Saved'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Clear'));
    await tester.pumpAndSettle();
    expect(await h.settings.defaultFor(profileId), isNull);
  });

  testWidgets('settings_rejectsAnInvalidDefault', (tester) async {
    final h = Harness();
    await h.pump(tester);
    await tester.enterText(
      find.byKey(const Key('trading-default-commitment')),
      '-5',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('positive amount'), findsOneWidget);
    expect(await h.settings.defaultFor(profileId), isNull);
  });
}
