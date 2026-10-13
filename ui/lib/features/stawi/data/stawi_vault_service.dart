import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../domain/signing_checks.dart';
import 'stawi_clients.dart';
import 'stawi_identity.dart';

/// The person's own savings vault, as finance reads it off the chain.
class StawiVaultService {
  StawiVaultService({
    required finance.VaultServiceClient vault,
    required Future<StawiIdentity> Function() identity,
  }) : _vault = vault,
       _identity = identity;

  final finance.VaultServiceClient _vault;
  final Future<StawiIdentity> Function() _identity;

  Future<Uint8List> _account() async {
    final account = (await _identity()).primary;
    if (account == null) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
    return account.address;
  }

  /// The pockets of the person's vault.
  Future<finance.GetVaultResponse> vault() async =>
      _vault.getVault(finance.GetVaultRequest(account: await _account()));

  /// The vault and loan books a personal call is checked against. A vault or
  /// book no device should sign against is a [SigningRefused], in words.
  Future<PersonalTargets> targets() async {
    final response = await _vault.getPersonalTargets(
      finance.GetPersonalTargetsRequest(account: await _account()),
    );
    try {
      return PersonalTargets.fromResponse(
        vault: response.vault,
        loanBooks: response.loanBooks,
      );
    } on EngineCallException catch (e) {
      throw SigningRefused(engineRefusal(e.error));
    }
  }

  /// The vault's statement; of one [pocket] when given. [page] continues a
  /// previous answer.
  Future<finance.GetVaultStatementResponse> statement({
    Uint8List? pocket,
    String page = '',
  }) async => _vault.getVaultStatement(
    finance.GetVaultStatementRequest(
      account: await _account(),
      pocket: pocket,
      page: page.isEmpty ? null : finance.PageRequest(cursor: page),
    ),
  );

  /// Names the savings goal [goalId]. The goal id is the idempotency key, so
  /// naming it twice is one name.
  Future<void> nameGoal({
    required Uint8List goalId,
    required String name,
  }) async {
    await _vault.nameGoal(
      finance.NameGoalRequest(
        idempotencyKey: bytesToHex(goalId),
        account: await _account(),
        goalId: goalId,
        name: name,
      ),
    );
  }
}

final stawiVaultServiceProvider = Provider<StawiVaultService>(
  (ref) => StawiVaultService(
    vault: ref.watch(financeVaultProvider),
    identity: () => ref.read(stawiIdentityProvider.future),
  ),
);

final myVaultProvider = FutureProvider.autoDispose<finance.GetVaultResponse>(
  (ref) => ref.watch(stawiVaultServiceProvider).vault(),
);

final personalTargetsProvider = FutureProvider.autoDispose<PersonalTargets>(
  (ref) => ref.watch(stawiVaultServiceProvider).targets(),
);

/// The statement of the pocket `pocketHex` (empty for the whole vault).
final myVaultStatementProvider = FutureProvider.autoDispose
    .family<finance.GetVaultStatementResponse, String>(
      (ref, pocketHex) => ref
          .watch(stawiVaultServiceProvider)
          .statement(pocket: pocketHex.isEmpty ? null : hexToBytes(pocketHex)),
    );

/// The 32 bytes naming [p]: all zero for free savings.
Uint8List pocketId(finance.SavingsPocket p) =>
    p.pocket.length == 32 ? Uint8List.fromList(p.pocket) : Uint8List(32);

/// Whether [p] is free savings (the zero pocket).
bool isFreeSavings(finance.SavingsPocket p) =>
    !p.isGoal && pocketId(p).every((b) => b == 0);

/// What a pocket is called: "Free savings", the goal's name, or
/// "Goal 6061…7e7f" for a goal not named yet.
String pocketName(finance.SavingsPocket p) {
  if (isFreeSavings(p)) return 'Free savings';
  if (p.name.isNotEmpty) return p.name;
  final hex = bytesToHex(pocketId(p));
  return 'Goal ${hex.substring(0, 4)}…${hex.substring(hex.length - 4)}';
}

/// Integer minor units of [m]; zero when empty or unreadable.
BigInt moneyUnits(finance.Money m) => BigInt.tryParse(m.amount) ?? BigInt.zero;

/// Whether money in [p] may be lent: free savings, or a goal marked
/// loanable.
bool canLendFrom(finance.SavingsPocket p) => isFreeSavings(p) || p.loanable;
