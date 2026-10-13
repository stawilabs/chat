import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/stawi_vault_service.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

void main() {
  final me = hexToBytes('0xa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3');
  final vault = hexToBytes('0x909192939495969798999a9b9c9d9e9fa0a1a2a3');
  final book = hexToBytes('0x101112131415161718191a1b1c1d1e1f20212223');
  late FakeConnectTransport transport;

  StawiVaultService service() => StawiVaultService(
    vault: finance.VaultServiceClient(transport),
    identity: () async => identityWith('p1', me),
  );

  setUp(() => transport = FakeConnectTransport());

  test('vault() asks for the primary account\'s vault', () async {
    transport.on(
      finance.VaultService.getVault,
      (req) => finance.GetVaultResponse(vault: vault),
    );
    expect((await service().vault()).vault, vault);
    expect(
      transport.requestsTo(finance.VaultService.getVault).single.account,
      me,
    );
  });

  test('targets() builds the vault and the admitted books', () async {
    transport.on(
      finance.VaultService.getPersonalTargets,
      (req) =>
          finance.GetPersonalTargetsResponse(vault: vault, loanBooks: [book]),
    );
    final t = await service().targets();
    expect(t.vault, vault);
    expect(t.loanBooks.single, book);
    expect(
      transport
          .requestsTo(finance.VaultService.getPersonalTargets)
          .single
          .account,
      me,
    );
  });

  test('a zero vault is refused in the person\'s words', () async {
    transport.on(
      finance.VaultService.getPersonalTargets,
      (req) => finance.GetPersonalTargetsResponse(
        vault: Uint8List(20),
        loanBooks: [book],
      ),
    );
    await expectLater(
      service().targets(),
      throwsA(
        isA<SigningRefused>().having(
          (e) => e.reason,
          'reason',
          engineRefusal(EngineCallError.notThePersonalTarget),
        ),
      ),
    );
  });

  test('no loan book is refused too', () async {
    transport.on(
      finance.VaultService.getPersonalTargets,
      (req) => finance.GetPersonalTargetsResponse(vault: vault),
    );
    await expectLater(service().targets(), throwsA(isA<SigningRefused>()));
  });

  test(
    'statement() of a pocket sends it, and of the vault sends none',
    () async {
      transport.on(
        finance.VaultService.getVaultStatement,
        (req) => finance.GetVaultStatementResponse(),
      );
      final pocket = Uint8List.fromList(List.filled(32, 6));
      await service().statement(pocket: pocket, page: 'next');
      await service().statement();
      final reqs = transport.requestsTo(finance.VaultService.getVaultStatement);
      expect(reqs.first.pocket, pocket);
      expect(reqs.first.page.cursor, 'next');
      expect(reqs.first.account, me);
      expect(reqs.last.hasPocket(), isFalse);
      expect(reqs.last.hasPage(), isFalse);
    },
  );

  test('nameGoal uses the goal id\'s hex as the idempotency key', () async {
    transport.on(
      finance.VaultService.nameGoal,
      (req) => finance.NameGoalResponse(),
    );
    final goal = Uint8List.fromList(List.generate(32, (i) => i));
    await service().nameGoal(goalId: goal, name: 'School fees');
    final req = transport.requestsTo(finance.VaultService.nameGoal).single;
    expect(req.idempotencyKey, bytesToHex(goal));
    expect(req.goalId, goal);
    expect(req.name, 'School fees');
    expect(req.account, me);
  });
}
