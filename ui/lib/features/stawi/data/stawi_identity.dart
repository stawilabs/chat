import 'dart:typed_data';

import 'package:antinvestor_api_profile/antinvestor_api_profile.dart'
    show GetByIdRequest;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../core/networking/client.dart';
import '../../auth/data/current_user_provider.dart';

/// A Stawi feature that cannot work in this build or deployment yet. The
/// message says what is missing.
final class StawiUnavailable implements Exception {
  const StawiUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One chain account the profile owns (profile.v1 ProfileAccount).
class StawiAccountRef {
  const StawiAccountRef({required this.address, required this.primary});

  final Uint8List address;
  final bool primary;

  String get hex => bytesToHex0x(address).toLowerCase();
}

/// Who is acting: the signed-in profile and the accounts profile says it
/// owns, primary first. The profile owns the accounts; nothing here derives
/// an address.
class StawiIdentity {
  const StawiIdentity({required this.profileId, required this.accounts});

  final String profileId;
  final List<StawiAccountRef> accounts;

  /// The primary account, or null when profile has none for this person.
  StawiAccountRef? get primary =>
      accounts.where((a) => a.primary).firstOrNull ?? accounts.firstOrNull;

  List<Uint8List> get addresses => [for (final a in accounts) a.address];
}

/// Reads the signed-in profile's accounts from profile (GetById).
final stawiIdentityProvider = FutureProvider<StawiIdentity>((ref) async {
  final profileId = await ref.watch(currentProfileIdProvider.future);
  if (profileId == null || profileId.isEmpty) {
    throw const StawiUnavailable('Sign in to use Stawi');
  }
  final client = await ref.watch(profileClientProvider.future);
  final response = await client.stub.getById(GetByIdRequest(id: profileId));
  final accounts = <StawiAccountRef>[];
  for (final account in response.data.accounts) {
    try {
      final address = hexToBytes(account.address);
      if (address.length == 20) {
        accounts.add(
          StawiAccountRef(address: address, primary: account.primary),
        );
      }
    } on FormatException {
      continue;
    }
  }
  accounts.sort((a, b) => (b.primary ? 1 : 0) - (a.primary ? 1 : 0));
  return StawiIdentity(profileId: profileId, accounts: accounts);
});
