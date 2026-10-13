import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stawi_identity.dart';

/// Another person's Stawi account, found for a contact. Only the
/// counterparty lookup ([counterpartyAccountProvider]) builds one, so money
/// can be sent to a person the app knows and never to a typed address.
final class StawiContactAccount {
  const StawiContactAccount._(this.address, {this.profileId, this.name});

  /// Used by tests in place of the lookup.
  @visibleForTesting
  factory StawiContactAccount.forTest(
    Uint8List address, {
    String? profileId,
    String? name,
  }) => StawiContactAccount._(
    Uint8List.fromList(address),
    profileId: profileId,
    name: name,
  );

  /// The 20-byte account address.
  final Uint8List address;
  final String? profileId;

  /// How the contact is shown, when known.
  final String? name;
}

/// The primary account of another person, or null when they have none.
///
/// The profile service never hands one person's accounts to another: GetById
/// and GetByContact return `accounts` only to the profile itself or to a
/// service principal (service-profile AccountBusiness.Visible). So the app
/// cannot read a counterparty's account from profile. Until a directory the
/// app may call exists (see `counterpartyAccountsProvider`) a lookup fails in
/// words rather than answering null, which would read as "has no Stawi
/// account".
typedef CounterpartyAccounts = Future<Uint8List?> Function(String profileId);

/// Where a counterparty's account is looked up. The default has no source and
/// says so; the directory lookup replaces it when it exists.
final counterpartyAccountsProvider = Provider<CounterpartyAccounts>(
  (ref) =>
      (profileId) async => throw const StawiUnavailable(
        'Finding another person\'s Stawi account is not available yet',
      ),
);

/// The account found for the profile asked about (the DM partner, a
/// contact), or null when they have none. An answer that is not a 20-byte,
/// non-zero address is refused.
final counterpartyAccountProvider = FutureProvider.autoDispose
    .family<StawiContactAccount?, String>((ref, profileId) async {
      final found = await ref.watch(counterpartyAccountsProvider)(profileId);
      if (found == null) return null;
      if (found.length != 20 || found.every((b) => b == 0)) {
        throw const StawiUnavailable('That is not a Stawi account');
      }
      return StawiContactAccount._(
        Uint8List.fromList(found),
        profileId: profileId,
      );
    }, retry: (_, _) => null);
