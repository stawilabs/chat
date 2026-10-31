import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/pool_models.dart';
import 'pool_membership.dart';
import 'socialtrader_api.dart';
import 'wallet_service.dart';

part 'wallet_link.g.dart';

/// The wallet linked to the signed-in profile, null when none.
@riverpod
Future<LinkedWallet?> linkedWallet(Ref ref) =>
    ref.watch(socialTraderApiProvider).getLinkedWallet();

/// Where a wallet link stands.
sealed class LinkState {
  const LinkState();
}

class LinkIdle extends LinkState {
  const LinkIdle({this.error});
  final String? error;
}

class LinkWorking extends LinkState {
  const LinkWorking(this.step);

  /// What is happening, for the button label.
  final String step;
}

/// Links the connected wallet to the profile with Sign-In with Ethereum: the
/// service issues the message, the wallet signs it (personal_sign), the
/// service verifies and records the link. The app sees only the signature.
@riverpod
class WalletLinkController extends _$WalletLinkController {
  @override
  LinkState build() => const LinkIdle();

  Future<void> link() async {
    final wallet = ref.read(walletControllerProvider);
    final address = wallet.address;
    if (address == null || !wallet.canSign) {
      state = const LinkIdle(error: 'Connect a wallet that can sign first.');
      return;
    }
    state = const LinkWorking('Asking the service…');
    try {
      final api = ref.read(socialTraderApiProvider);
      final challenge = await api.issueNonce();
      if (!ref.mounted) return;
      state = const LinkWorking('Waiting for your wallet…');
      final signature = await ref
          .read(walletControllerProvider.notifier)
          .personalSign(challenge.message);
      if (!ref.mounted) return;
      state = const LinkWorking('Linking…');
      await api.linkWallet(wallet: address, signature: signature);
      if (!ref.mounted) return;
      ref.invalidate(linkedWalletProvider);
      ref.invalidate(memberWalletProvider);
      state = const LinkIdle();
    } on Exception catch (e) {
      if (!ref.mounted) return;
      state = LinkIdle(
        error: switch (e) {
          WalletReadOnlyException(:final message) => message,
          WalletNotConnectedException(:final message) => message,
          WalletUnavailableException(:final message) => message,
          _ => 'Could not link the wallet: $e',
        },
      );
    }
  }
}
