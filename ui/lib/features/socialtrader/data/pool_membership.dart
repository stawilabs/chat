import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/pool_models.dart';
import 'socialtrader_api.dart';
import 'wallet_service.dart';

part 'pool_membership.g.dart';

/// The wallet whose pool stake the app shows: the connected (or pasted)
/// wallet when there is one, else the wallet linked to the profile. Null when
/// neither is known. A failed lookup is an error, never "no wallet": reading
/// it as none would make a shareholder look like a newcomer.
@riverpod
Future<String?> memberWallet(Ref ref) async {
  final connected = ref.watch(walletControllerProvider).address;
  if (connected != null && connected.isNotEmpty) return connected;
  return (await ref.watch(socialTraderApiProvider).getLinkedWallet())?.wallet;
}

/// The signed-in person's stake in [pool]: none when no wallet is known.
@riverpod
Future<PoolMembership> myMembership(Ref ref, String pool) async {
  final wallet = await ref.watch(memberWalletProvider.future);
  if (wallet == null) return PoolMembership.none(pool, '');
  return ref.watch(socialTraderApiProvider).getMembership(pool, wallet);
}
