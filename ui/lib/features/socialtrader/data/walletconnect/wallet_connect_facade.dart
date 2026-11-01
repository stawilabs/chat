import 'package:flutter/foundation.dart';

/// A WalletConnect session as the module uses it: who signs, on which chain.
@immutable
class WalletConnectSession {
  const WalletConnectSession({
    required this.address,
    required this.chainId,
    required this.topic,
  });

  /// The connected account, lowercase hex.
  final String address;

  /// The chain the session is currently on (EIP-155 numeric id).
  final int chainId;

  /// The WalletConnect pairing topic requests are sent on.
  final String topic;

  WalletConnectSession withChain(int chainId) =>
      WalletConnectSession(address: address, chainId: chainId, topic: topic);
}

/// The WalletConnect (Reown AppKit) operations the wallet platform needs,
/// behind an interface so the platform is tested against a fake and the SDK
/// is touched in one adapter. Keys stay in the connected wallet app; this
/// side only passes requests and reads results.
abstract interface class WalletConnectFacade {
  /// Prepares the SDK (relay, stored pairings). Idempotent.
  Future<void> init();

  /// The live session, or null when no wallet is connected.
  WalletConnectSession? get session;

  /// Opens the AppKit modal and waits for the person to connect a wallet;
  /// returns the session, or null when the modal was dismissed.
  Future<WalletConnectSession?> openModal();

  /// Asks the wallet to switch to [chainId], adding the chain first when the
  /// wallet does not know it.
  Future<void> switchChain(int chainId);

  /// eth_sendTransaction through the session; returns the transaction hash.
  Future<String> sendTransaction({
    required String from,
    required String to,
    required String data,
    required String value,
    required int chainId,
  });

  /// personal_sign of [message] by [from]; returns the signature.
  Future<String> personalSign({required String from, required String message});

  /// Ends the session and forgets the pairing.
  Future<void> disconnect();
}
