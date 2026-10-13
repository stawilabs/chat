import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stawi_identity.dart';

/// Another person's primary Stawi account, or null when they have none.
///
/// The profile service never hands one person's accounts to another: GetById
/// and GetByContact return `accounts` only to the profile itself or to a
/// service principal (service-profile AccountBusiness.Visible). So the app
/// cannot read a counterparty's account from profile, and until a directory
/// the app may call exists (see `counterpartyAccountsProvider`) a lookup
/// fails in words rather than answering null, which would read as "has no
/// Stawi account".
typedef CounterpartyAccounts = Future<Uint8List?> Function(String profileId);

/// Where a counterparty's account is looked up. The default has no source and
/// says so; the directory lookup replaces it when it exists.
final counterpartyAccountsProvider = Provider<CounterpartyAccounts>(
  (ref) =>
      (profileId) async => throw const StawiUnavailable(
        'Finding another person\'s Stawi account is not available yet',
      ),
);

/// The primary account of the profile asked about account (the DM partner's), or null.
final counterpartyAccountProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>(
      (ref, profileId) => ref.watch(counterpartyAccountsProvider)(profileId),
      retry: (_, _) => null,
    );
